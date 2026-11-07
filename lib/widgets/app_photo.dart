import 'package:flutter/material.dart';

/// Asset photo that fills its parent. If the file is missing or broken it
/// shows [fallback] instead, so the UI never breaks while images are added.
/// [overlay] (for example a text-protection gradient) is only drawn when the
/// photo itself loaded.
class AppPhoto extends StatelessWidget {
  const AppPhoto({
    super.key,
    required this.asset,
    required this.fallback,
    this.overlay,
    this.alignment = Alignment.center,
  });

  final String asset;
  final Widget fallback;
  final Widget? overlay;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      excludeFromSemantics: true,
      frameBuilder: (context, child, frame, wasSync) {
        if (overlay == null) return child;
        return Stack(fit: StackFit.expand, children: [child, overlay!]);
      },
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
