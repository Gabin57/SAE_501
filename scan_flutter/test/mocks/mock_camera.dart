import 'package:camera/camera.dart';

class MockCameraDescription implements CameraDescription {
  @override
  final String name;
  @override
  final CameraLensDirection lensDirection;
  @override
  final CameraLensType lensType;
  @override
  final int sensorOrientation;

  // Note: Using a non-const constructor to allow dynamic lensType
  MockCameraDescription({
    this.name = "MockCamera",
    this.lensDirection = CameraLensDirection.back,
    CameraLensType? lensType,
    this.sensorOrientation = 90,
  }) : lensType = lensType ?? (CameraLensType.values.isNotEmpty ? CameraLensType.values.first : throw StateError('No CameraLensType available'));

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(other) => identical(this, other);
}

class MockCameraController extends CameraController {
  MockCameraController(CameraDescription description)
      : super(description, ResolutionPreset.medium);

  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<XFile> takePicture() async {
    return XFile("test/test_assets/mock_image.jpg");
  }
}
