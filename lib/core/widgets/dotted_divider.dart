import 'package:flutter/material.dart';

import '../theme/unified_theme_manager.dart';

class DottedDivider extends StatelessWidget {
  final Color? color;
  final double thickness;
  final double dashWidth;
  final double gap;
  final double height;

  const DottedDivider({
    super.key,
    this.color,
    this.thickness = 1.0,
    this.dashWidth = 6.0,
    this.gap = 4.0,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.themeColors.borderBase;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _DottedLinePainter(
          color: c,
          thickness: thickness,
          dashWidth: dashWidth,
          gap: gap,
        ),
        size: Size.fromHeight(height),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double dashWidth;
  final double gap;

  _DottedLinePainter({
    required this.color,
    required this.thickness,
    required this.dashWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    double x = 0;
    final total = size.width;
    while (x < total) {
      final candidate = x + dashWidth;
      final end = candidate > total ? total : candidate;
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
