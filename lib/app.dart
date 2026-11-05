import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
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
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
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
