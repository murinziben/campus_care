import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';

/// Shown to signed-in users whose email is not verified yet. This is the gate
/// that keeps the app ALU-only: nothing else is reachable until the link in the
/// verification email has been opened.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          child: Column(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(Icons.mark_email_unread_outlined,
                    size: 42, color: AppColors.forest),
              ),
              const SizedBox(height: 26),
              Text('ONE LAST STEP', style: AppText.eyebrow),
              const SizedBox(height: 8),
              Text('Check your inbox', style: AppText.h1),
              const SizedBox(height: 10),
              Text('We sent a verification link to',
                  style: AppText.body, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                auth.email,
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.forest),
              ),
              const SizedBox(height: 8),
              Text(
                'Open the email and tap the link. It may take a minute to arrive.',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              if (auth.error != null) ...[
                InlineMessage(message: auth.error!),
                const SizedBox(height: 14),
              ],
              PrimaryButton(
                label: "I've Verified My Email",
                loading: auth.isBusy,
                onPressed: () async {
                  // Success flips AuthStatus to authenticated -> home screen.
                  await context.read<AuthProvider>().checkVerification();
                },
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Resend Email',
                onPressed: auth.isBusy
                    ? null
                    : () async {
                        final provider = context.read<AuthProvider>();
                        final ok = await provider.resendVerification();
                        if (context.mounted && ok) {
                          showSnack(context, 'Verification email sent again.');
                        }
                      },
              ),
              TextButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                child: const Text('Return to sign in'),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 18, color: AppColors.slate500),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: "Can't find it? ",
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(
                              text: 'Check your spam folder or confirm your '
                                  'email address.'),
                        ]),
                        style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.slate500,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
