import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/theme_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/incident_repository.dart';
import 'repositories/storage_repository.dart';
import 'screens/auth/auth_flow.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/staff/staff_shell.dart';
import 'screens/student/student_shell.dart';

/// Root widget. Repositories are injected so tests can swap in fakes.
class CampusCareApp extends StatelessWidget {
  const CampusCareApp({
    super.key,
    required this.authRepository,
    required this.incidentRepository,
    required this.storageRepository,
  });

  final AuthRepository authRepository;
  final IncidentRepository incidentRepository;
  final StorageRepository storageRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository),
        ),
        // IncidentProvider follows the signed-in user: it starts the live
        // Firestore stream on login and tears it down on logout.
        ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
          // Bind immediately on creation (the provider is built lazily, possibly
          // after the user is already signed in), and again on every auth change.
          create: (context) {
            final auth = context.read<AuthProvider>();
            return IncidentProvider(incidentRepository, storageRepository)
              ..bindUser(auth.status == AuthStatus.authenticated
                  ? auth.user
                  : null);
          },
          update: (_, auth, previous) =>
              (previous ?? IncidentProvider(incidentRepository, storageRepository))
                ..bindUser(auth.status == AuthStatus.authenticated
                    ? auth.user
                    : null),
        ),
      ],
      child: const _ThemedApp(),
    );
  }
}

/// Builds the MaterialApp for the chosen appearance (system / light / dark).
///
/// Colours live in [AppColors] and change at runtime, so after the mode flips
/// every element is marked dirty once to repaint with the new palette while
/// keeping navigation and form state.
class _ThemedApp extends StatefulWidget {
  const _ThemedApp();

  @override
  State<_ThemedApp> createState() => _ThemedAppState();
}

class _ThemedAppState extends State<_ThemedApp> with WidgetsBindingObserver {
  Brightness? _applied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (mounted) setState(() {});
  }

  void _repaintEverything() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeProvider>().mode;
    final platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platform,
    };

    // Applies the palette; must run before any descendant builds.
    final theme = AppTheme.build(brightness);

    if (_applied != brightness) {
      final firstBuild = _applied == null;
      _applied = brightness;
      if (!firstBuild) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _repaintEverything();
        });
      }
    }

    final dark = brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: AppColors.navBar,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: theme,
        themeAnimationDuration: Duration.zero,
        home: const AuthGate(),
      ),
    );
  }
}

/// Chooses the screen tree from the authentication state and role.
/// This is the app's top-level "route guard".
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((a) => a.status);
    final isStaff = context.select<AuthProvider, bool>((a) => a.isStaff);

    return switch (status) {
      AuthStatus.initializing => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.unauthenticated => const AuthFlow(),
      AuthStatus.unverified => const VerifyEmailScreen(),
      AuthStatus.authenticated =>
        isStaff ? const StaffShell() : const StudentShell(),
    };
  }
}
