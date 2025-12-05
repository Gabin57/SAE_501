import 'package:permission_handler/permission_handler.dart';

class MockPermissionHandler {
  static PermissionStatus nextStatus = PermissionStatus.granted;

  static Future<PermissionStatus> requestCameraPermission() async {
    return nextStatus;
  }
}
