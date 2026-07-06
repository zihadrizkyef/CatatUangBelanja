import 'package:flutter/material.dart';

/// Horizontal dashed divider matching the mockups' `border: 1px dashed ...`
/// styling (hero header dividers, transaction row separators).
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, required this.color, this.thickness = 1, this.dashWidth = 4, this.gap = 3});

  final Color color;
  final double thickness;
  final double dashWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: thickness,
      child: CustomPaint(painter: _DashedLinePainter(color: color, dashWidth: dashWidth, gap: gap)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color, required this.dashWidth, required this.gap});

  final Color color;
  final double dashWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawRect(Rect.fromLTWH(startX, 0, dashWidth, size.height), paint);
      startX += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashWidth != dashWidth || oldDelegate.gap != gap;
}
