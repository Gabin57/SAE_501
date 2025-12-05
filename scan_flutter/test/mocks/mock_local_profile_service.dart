// Mock pour LocalProfileService
// Note: Les méthodes statiques ne peuvent pas être surchargées en Dart
// Ce mock est utilisé pour les tests uniquement
class MockLocalProfileService {
  static Map<String, String> _mockData = {};

  // Getter public pour les tests
  static Map<String, String> get mockData => _mockData;

  static void setMockData(Map<String, String> data) {
    _mockData = Map<String, String>.from(data);
  }

  static void clear() {
    _mockData = {};
  }

  // Méthodes qui simulent LocalProfileService pour les tests
  static Future<Map<String, String>> getProfile() async {
    return Map<String, String>.from(_mockData);
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

