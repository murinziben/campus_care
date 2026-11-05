import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';

/// Profile tab shared by students and staff (staff see queue stats instead).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final incidents = context.watch<IncidentProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final mine = incidents.mine;
    final resolved = incidents.count(mine, IncidentStatus.resolved);
    final rate = mine.isEmpty ? 0 : (resolved * 100 / mine.length).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(child: AppAvatar(name: user.displayName, radius: 38)),
          const SizedBox(height: 12),
          Center(child: Text(user.displayName, style: AppText.h2)),
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: user.isStaff ? AppColors.lightGreen : AppColors.green50,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      user.isStaff
                          ? Icons.admin_panel_settings_outlined
                          : Icons.verified_rounded,
                      size: 13,
                      color:
                          user.isStaff ? AppColors.forest : AppColors.green),
                  const SizedBox(width: 5),
                  Text(
                    user.isStaff ? 'Authorized staff' : 'Verified student',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color:
                          user.isStaff ? AppColors.forest : AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(child: Text(user.email, style: AppText.muted)),
          const SizedBox(height: 20),
          if (!user.isStaff)
            Row(
              children: [
                Expanded(child: _Impact(value: '${mine.length}', label: 'Total reports')),
                const SizedBox(width: 10),
                Expanded(child: _Impact(value: '$resolved', label: 'Resolved')),
                const SizedBox(width: 10),
                Expanded(child: _Impact(value: '$rate%', label: 'Resolution rate')),
              ],
            ),
          const SizedBox(height: 22),
          const Text('ACCOUNT', style: AppText.eyebrow),
          const SizedBox(height: 8),
          _SettingTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal information',
            subtitle: 'Name and university email',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Personal information', style: AppText.h2),
                    const SizedBox(height: 16),
                    const Text('NAME', style: AppText.eyebrow),
                    Text(user.displayName, style: AppText.body),
                    const SizedBox(height: 12),
                    const Text('EMAIL', style: AppText.eyebrow),
                    Text(user.email, style: AppText.body),
                    const SizedBox(height: 12),
                    const Text('ROLE', style: AppText.eyebrow),
                    Text(user.isStaff ? 'Campus staff' : 'Student',
                        style: AppText.body),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SettingTile(
            icon: Icons.lock_reset_rounded,
            title: 'Account security',
            subtitle: 'Email me a password reset link',
            onTap: () async {
              final ok = await confirmDialog(
                context,
                title: 'Reset password?',
                message: 'We will email a reset link to ${user.email}.',
                confirmLabel: 'Send link',
              );
              if (!ok || !context.mounted) return;
              final sent =
                  await context.read<AuthProvider>().sendPasswordReset(user.email);
              if (!context.mounted) return;
              showSnack(
                  context,
                  sent
                      ? 'Password reset email sent.'
                      : (context.read<AuthProvider>().error ??
                          'Could not send the email.'));
            },
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final ok = await confirmDialog(
                context,
                title: 'Sign out?',
                message: 'You will need to sign in again to report or track issues.',
                confirmLabel: 'Sign out',
                destructive: true,
              );
              if (ok) await auth.signOut();
            },
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.slate200),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
              child: Text('CampusCare · Version 1.0.0', style: AppText.muted)),
        ],
      ),
    );
  }
}

class _Impact extends StatelessWidget {
  const _Impact({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forest)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.forest, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle, style: AppText.muted),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
        ],
      ),
    );
  }
}
