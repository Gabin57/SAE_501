import 'package:scan_flutter/src/services/local_profile_service.dart';

class MockLocalProfileService extends LocalProfileService {
  static Map<String, String> _mockData = {};

  static void setMockData(Map<String, String> data) {
    _mockData = data;
  }

  static void clear() {
    _mockData = {};
  }

  // Note: Static methods cannot be overridden in Dart
  // These methods shadow the parent class methods for testing purposes
  static Future<Map<String, String>> getProfile() async {
    return _mockData;
  }

  static Future<void> saveProfile({required String name, required String email, required String theme}) async {
    _mockData = {
      'name': name,
      'email': email,
      'theme': theme,
    };
  }

  static Future<void> clearProfile() async {
    _mockData = {};
  }
}
