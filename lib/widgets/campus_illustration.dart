import 'package:flutter/material.dart';

/// A small vector illustration of a campus building with trees, drawn in
/// code so the app needs no image assets. Used on the welcome, sign-in and
/// dashboard banners.
class CampusIllustration extends StatelessWidget {
  const CampusIllustration({
    super.key,
    this.width = 150,
    this.height = 110,
    this.onDark = true,
  });

  final double width;
  final double height;

  /// True when drawn on a dark green banner (white building), false on light.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _CampusPainter(onDark)),
    );
  }
}

class _CampusPainter extends CustomPainter {
  _CampusPainter(this.onDark);
  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wall = Paint()..color = onDark ? const Color(0xFFF4F7F1) : const Color(0xFFFFFFFF);
    final wallShade = Paint()..color = onDark ? const Color(0xFFD9E6DD) : const Color(0xFFE5EFE8);
    final roof = Paint()..color = onDark ? const Color(0xFF0E3B31) : const Color(0xFF124C3F);
    final window = Paint()..color = onDark ? const Color(0xFF7FB8A3) : const Color(0xFF8CC4AE);
    final door = Paint()..color = const Color(0xFF124C3F);
    final treeDark = Paint()..color = const Color(0xFF2E8F6A);
    final treeLight = Paint()..color = const Color(0xFF4DB38A);
    final trunk = Paint()..color = const Color(0xFF6B4F2E);
    final ground = Paint()..color = onDark ? const Color(0x33FFFFFF) : const Color(0xFFCFE7D9);

    // Ground
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.9, w, h * 0.1), const Radius.circular(6)),
      ground,
    );

    // Main building body
    final bx = w * 0.26, bw = w * 0.5, by = h * 0.3, bh = h * 0.6;
    canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh), wall);
    canvas.drawRect(Rect.fromLTWH(bx + bw * 0.78, by, bw * 0.22, bh), wallShade);

    // Roof + flag pole
    final roofPath = Path()
      ..moveTo(bx - w * 0.03, by)
      ..lineTo(bx + bw / 2, by - h * 0.2)
      ..lineTo(bx + bw + w * 0.03, by)
      ..close();
    canvas.drawPath(roofPath, roof);
    canvas.drawRect(
        Rect.fromLTWH(bx + bw / 2 - 1, by - h * 0.3, 2, h * 0.12), trunk);

    // Windows (3 columns x 3 rows)
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 4; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              bx + bw * (0.08 + c * 0.22),
              by + bh * (0.1 + r * 0.24),
              bw * 0.13,
              bh * 0.14,
            ),
            const Radius.circular(2),
          ),
          window,
        );
      }
    }
    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx + bw * 0.42, by + bh * 0.78, bw * 0.16, bh * 0.22),
        const Radius.circular(3),
      ),
      door,
    );

    // Trees
    void tree(double cx, double base, double r) {
      canvas.drawRect(Rect.fromLTWH(cx - 1.5, base - r * 0.6, 3, r * 0.8), trunk);
      canvas.drawCircle(Offset(cx, base - r * 1.2), r, treeDark);
      canvas.drawCircle(Offset(cx - r * 0.4, base - r * 1.5), r * 0.7, treeLight);
    }

    tree(w * 0.1, h * 0.92, h * 0.16);
    tree(w * 0.2, h * 0.92, h * 0.11);
    tree(w * 0.9, h * 0.92, h * 0.15);
    tree(w * 0.82, h * 0.92, h * 0.1);
  }

  @override
  bool shouldRepaint(covariant _CampusPainter old) => old.onDark != onDark;
}
