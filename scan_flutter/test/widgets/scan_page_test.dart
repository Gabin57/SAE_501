import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scan_flutter/src/pages/scan/scan_page.dart';
import '../mocks/mock_camera.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("Shows fallback text when camera not initialized",
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ScanPage(
          cameras: [MockCameraDescription()],
        ),
      ),
    );

    await tester.pump(); // initial frame

    expect(find.text("Caméra non disponible"), findsOneWidget);
  });

  testWidgets("Buttons are visible", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ScanPage(
          cameras: [MockCameraDescription()],
        ),
      ),
    );

    expect(find.byIcon(Icons.photo_library), findsOneWidget);
    expect(find.byIcon(Icons.cameraswitch), findsOneWidget);
  });

  // Note: Testing loading state requires accessing private state
  // This test is commented out as it's not recommended
  // testWidgets("Loading screen appears", (tester) async {
  //   // This test would require accessing private state
  // });
}
