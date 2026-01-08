import 'package:flutter/material.dart';
import 'package:scan_flutter/src/services/object_detection_service.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<DetectionResult> detections;

  BoundingBoxPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty) return;

    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPaint = TextPainter(textDirection: TextDirection.ltr);

    // Scale factors (assuming input image was resized or different aspect ratio)
    // For now, we assume the boxes are normalized or in the same coordinate space as the canvas
    // Or we rely on the fact that CameraPreview fills the screen or aspect ratio is maintained.
    // If boxes are absolute coordinates from the image (e.g. 640x640), we need to scale them
    // to the canvas size.
    // However, on Web, CameraPreview often matches the resolution.
    // Let's assume for now that we might need to handle scaling if the camera resolution differs from canvas size.
    // But typically ObjectDetectionService returns boxes relative to the image size.
    // Since we don't know the exact image size here without more context,
    // let's assume the canvas size matches the image stream size for now,
    // or we might need to pass the image size.

    // For simplicity in this first iteration:
    // We'll iterate assuming coordinates match. If they are off, we'll need to adjust.
    // Note: The detection service likely returns absolute coordinates based on the image size sent.

    for (final detection in detections) {
      final box = detection.box;

      // Draw rect
      final rect = Rect.fromLTRB(
        (box['x1'] as num).toDouble(),
        (box['y1'] as num).toDouble(),
        (box['x2'] as num).toDouble(),
        (box['y2'] as num).toDouble(),
      );

      canvas.drawRect(rect, paint);

      // Draw label background
      final text =
          '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%';
      textPaint.text = TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPaint.layout();

      final textBackground = Rect.fromLTWH(
        rect.left,
        rect.top - textPaint.height - 4,
        textPaint.width + 8,
        textPaint.height + 4,
      );

      canvas.drawRect(textBackground, Paint()..color = Colors.green);

      textPaint.paint(
        canvas,
        Offset(rect.left + 4, rect.top - textPaint.height - 2),
      );
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return oldDelegate.detections != detections;
  }
}
