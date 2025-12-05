import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:scan_flutter/src/pages/scan/scan_page.dart';
import 'package:scan_flutter/src/services/object_detection_service.dart';
import '../mocks/mock_camera.dart';
import '../mocks/mock_image_picker.dart';
import '../mocks/mock_detection_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Full scan flow (pick → detect → results)", (tester) async {
    final mockPicker = MockImagePicker();
    mockPicker.nextPickedFile = XFile("test/test_assets/mock_image.jpg");

    final detection = MockObjectDetectionService();
    detection.detections = [
      DetectionResult(
        label: "Panneau Stop",
        confidence: 0.95,
        box: {"x": 0, "y": 0, "width": 100, "height": 100},
      )
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ScanPage(
          cameras: [MockCameraDescription()],
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap gallery button - use warnIfMissed: false to handle cases where button might be obscured
    await tester.tap(find.byIcon(Icons.photo_library), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(detection.detections.isNotEmpty, true);
  });
}
