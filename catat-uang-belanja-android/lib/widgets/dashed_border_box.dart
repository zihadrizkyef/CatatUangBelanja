import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Dashed rounded-rectangle border matching the mockups' `border: 1px dashed
/// ...` card styling (e.g. empty-state placeholders). Wraps [child] and
/// paints the dash pattern along its rounded-rect outline.
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    super.key,
    required this.color,
    required this.borderRadius,
    required this.child,
    this.strokeWidth = 1,
    this.dashWidth = 4,
    this.gap = 3,
  });

  final Color color;
  final double borderRadius;
  final Widget child;
  final double strokeWidth;
  final double dashWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: color,
        radius: borderRadius,
        strokeWidth: strokeWidth,
        dashWidth: dashWidth,
        gap: gap,
      ),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final metric = (Path()..addRRect(rrect)).computeMetrics().first;
    var distance = 0.0;
    while (distance < metric.length) {
      final next = (distance + dashWidth).clamp(0.0, metric.length);
      canvas.drawPath(metric.extractPath(distance, next), paint);
      distance = next + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.gap != gap;
}

@Preview(name: 'DashedBorderBox')
Widget previewDashedBorderBox() {
  return DashedBorderBox(
    color: Colors.grey,
    borderRadius: 16,
    child: const SizedBox(width: 220, height: 100),
  );
}
