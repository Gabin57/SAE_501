import 'dart:io';
import 'package:scan_flutter/src/services/object_detection_service.dart';

class MockObjectDetectionService extends ObjectDetectionService {
  List<DetectionResult> detections = [];

  @override
  Future<List<DetectionResult>> detectObjects(File file) async {
    return detections;
  }
}
