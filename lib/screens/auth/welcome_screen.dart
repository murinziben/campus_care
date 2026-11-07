import 'package:flutter/material.dart';

import '../../core/app_images.dart';
import '../../core/theme.dart';
import '../../widgets/app_photo.dart';
import '../../widgets/campus_illustration.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';

/// First screen for signed-out users: a full-width campus photo on top,
/// short pitch and the Get Started button below.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: (height * 0.5).clamp(300.0, 520.0),
            child: const _HeroPhoto(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco_rounded,
                            size: 15, color: AppColors.forest),
                        SizedBox(width: 6),
                        Text('CARE. REPORT. IMPROVE.',
                            style: AppText.eyebrow),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('A better campus\nstarts with you.',
                        style: AppText.h1),
                    const SizedBox(height: 10),
                    Text(
                      'Report campus issues in a few simple steps and follow '
                      'every update through to resolution.',
                      style: AppText.body,
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: 'Get Started',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/signin'),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/signin'),
                        child: const Text('I already have an account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(36),
        bottomRight: Radius.circular(36),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppPhoto(
            asset: AppImages.welcomeHero,
            overlay: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66131321), Color(0x00131321), Color(0x99131321)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
            fallback: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.softGreen, AppColors.lightGreen],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: CampusIllustration(
                    width: 280, height: 200, onDark: false),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppShadows.card,
                  ),
                  child: const LogoLockup(compact: true),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 26,
            child: _FloatingCard(
                icon: Icons.check_rounded,
                title: 'Issue resolved',
                subtitle: 'Block B · Room 204',
                color: AppColors.green),
          ),
          Positioned(
            left: 20,
            bottom: 74,
            child: _FloatingCard(
                icon: Icons.water_drop_outlined,
                title: 'Report received',
                subtitle: 'Residence · East Wing',
                color: AppColors.sky),
          ),
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 10.5, color: AppColors.slate500)),
            ],
          ),
        ],
      ),
    );
  }
}
