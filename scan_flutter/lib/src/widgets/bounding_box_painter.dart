import 'package:flutter/material.dart';
import 'package:scan_flutter/src/services/object_detection_service.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<DetectionResult> detections;

  BoundingBoxPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final textPaint = TextPainter(textDirection: TextDirection.ltr);

    for (final detection in detections) {
      final box = detection.box;
      final rect = Rect.fromLTRB(
        (box['x1'] as num).toDouble(),
        (box['y1'] as num).toDouble(),
        (box['x2'] as num).toDouble(),
        (box['y2'] as num).toDouble(),
      );

      // Draw rounded corners (brackets)
      final double cornerLength = 20.0;
      final double cornerRadius = 12.0;

      final Path path = Path();

      // Top Left
      path.moveTo(rect.left + cornerLength, rect.top);
      path.lineTo(rect.left + cornerRadius, rect.top);
      path.quadraticBezierTo(
        rect.left,
        rect.top,
        rect.left,
        rect.top + cornerRadius,
      );
      path.lineTo(rect.left, rect.top + cornerLength);

      // Top Right
      path.moveTo(rect.right - cornerLength, rect.top);
      path.lineTo(rect.right - cornerRadius, rect.top);
      path.quadraticBezierTo(
        rect.right,
        rect.top,
        rect.right,
        rect.top + cornerRadius,
      );
      path.lineTo(rect.right, rect.top + cornerLength);

      // Bottom Right
      path.moveTo(rect.right - cornerLength, rect.bottom);
      path.lineTo(rect.right - cornerRadius, rect.bottom);
      path.quadraticBezierTo(
        rect.right,
        rect.bottom,
        rect.right,
        rect.bottom - cornerRadius,
      );
      path.lineTo(rect.right, rect.bottom - cornerLength);

      // Bottom Left
      path.moveTo(rect.left + cornerLength, rect.bottom);
      path.lineTo(rect.left + cornerRadius, rect.bottom);
      path.quadraticBezierTo(
        rect.left,
        rect.bottom,
        rect.left,
        rect.bottom - cornerRadius,
      );
      path.lineTo(rect.left, rect.bottom - cornerLength);

      canvas.drawPath(path, paint);

      // Draw label background
      final text =
          '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%';
      textPaint.text = TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black, // Text color changed to black for contrast
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPaint.layout();

      final textBackground = Rect.fromLTWH(
        rect.left,
        rect.top - textPaint.height - 8,
        textPaint.width + 16,
        textPaint.height + 8,
      );

      // Draw white rounded background for text
      canvas.drawRRect(
        RRect.fromRectAndRadius(textBackground, const Radius.circular(8)),
        Paint()..color = Colors.white,
      );

      textPaint.paint(
        canvas,
        Offset(rect.left + 8, rect.top - textPaint.height - 4),
      );
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
