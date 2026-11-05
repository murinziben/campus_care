import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/campus_illustration.dart';
import '../../widgets/common.dart';
import '../../widgets/form_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LogoLockup(tagline: true),
              const Expanded(child: _HeroVisual()),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco_rounded, size: 15, color: AppColors.forest),
                  SizedBox(width: 6),
                  Text('CARE. REPORT. IMPROVE.', style: AppText.eyebrow),
                ],
              ),
              const SizedBox(height: 10),
              const Text('A better campus\nstarts with you.', style: AppText.h1),
              const SizedBox(height: 10),
              const Text(
                'Report campus issues in a few simple steps and follow every '
                'update through to resolution.',
                style: AppText.body,
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Get Started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => Navigator.of(context).pushNamed('/signin'),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/signin'),
                  child: const Text('I already have an account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.softGreen,
              AppColors.softGreen.withValues(alpha: 0),
            ]),
          ),
        ),
        const CampusIllustration(width: 220, height: 160, onDark: false),
        const Positioned(
          top: 18,
          right: 0,
          child: _FloatingCard(
              icon: Icons.check_rounded,
              title: 'Issue resolved',
              subtitle: 'Block B · Room 204',
              color: AppColors.green),
        ),
        const Positioned(
          bottom: 18,
          left: 0,
          child: _FloatingCard(
              icon: Icons.water_drop_outlined,
              title: 'Report received',
              subtitle: 'Residence · East Wing',
              color: AppColors.sky),
        ),
      ],
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
        color: Colors.white,
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
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.slate500)),
            ],
          ),
        ],
      ),
    );
  }
}
