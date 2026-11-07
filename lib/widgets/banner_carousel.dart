import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_images.dart';
import '../core/theme.dart';
import 'app_photo.dart';
import 'campus_illustration.dart';

/// Auto-advancing photo carousel at the top of Home. Each slide is a photo
/// from `assets/images/` with the headline and button drawn on top, so the
/// text stays sharp and translatable.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.onReport,
    required this.onTrack,
    required this.onUpdates,
  });

  final VoidCallback onReport;
  final VoidCallback onTrack;
  final VoidCallback onUpdates;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  late final List<_Slide> _slides = [
    _Slide(
      image: AppImages.banner1,
      eyebrow: 'African Leadership University',
      title: 'Your campus,\nyour voice.',
      subtitle: 'Report an issue in under a minute.',
      button: 'Report an Issue',
      icon: Icons.add_circle_outline_rounded,
      onTap: widget.onReport,
    ),
    _Slide(
      image: AppImages.banner2,
      eyebrow: 'Follow every step',
      title: 'Know exactly what\nis happening.',
      subtitle: 'Live status from submitted to resolved.',
      button: 'My Reports',
      icon: Icons.timeline_rounded,
      onTap: widget.onTrack,
    ),
    _Slide(
      image: AppImages.banner3,
      eyebrow: 'Campus updates',
      title: 'A safer, cleaner\ncampus together.',
      subtitle: 'See what the team has fixed.',
      button: 'View Updates',
      icon: Icons.notifications_none_rounded,
      onTap: widget.onUpdates,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage((_page + 1) % _slides.length,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.9,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _SlideView(slide: _slides[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.forest : AppColors.slate200,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Slide {
  const _Slide({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.icon,
    required this.onTap,
  });

  final String image;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String button;
  final IconData icon;
  final VoidCallback onTap;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppPhoto(
            asset: slide.image,
            alignment: Alignment.centerRight,
            overlay: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF2131321),
                    Color(0xB3131321),
                    Color(0x00131321),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            fallback: const _FallbackBackground(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slide.eyebrow.toUpperCase(),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1)),
                const SizedBox(height: 6),
                Text(slide.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 190,
                  child: Text(slide.subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          height: 1.3)),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: slide.onTap,
                  icon: Icon(slide.icon, size: 16),
                  label: Text(slide.button),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.aqua,
                    foregroundColor: AppColors.navy,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown only while a slide's photo file is missing.
class _FallbackBackground extends StatelessWidget {
  const _FallbackBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.deepGreen, AppColors.forest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Align(
        alignment: Alignment.bottomRight,
        child: CampusIllustration(width: 150, height: 112),
      ),
    );
  }
}
