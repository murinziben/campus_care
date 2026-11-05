import 'package:flutter/material.dart';

import 'register_screen.dart';
import 'sign_in_screen.dart';
import 'welcome_screen.dart';

/// Self-contained navigator for the signed-out screens. When the auth state
/// changes, [AuthGate] replaces this whole widget, so no stale routes remain.
class AuthFlow extends StatelessWidget {
  const AuthFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        final Widget page = switch (settings.name) {
          '/signin' => const SignInScreen(),
          '/register' => const RegisterScreen(),
          _ => const WelcomeScreen(),
        };
        return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
      },
    );
  }
}
