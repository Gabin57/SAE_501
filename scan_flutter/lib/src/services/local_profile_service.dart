import 'package:shared_preferences/shared_preferences.dart';

class LocalProfileService {
  static const _keyName = 'profile_name';
  static const _keyEmail = 'profile_email';
  static const _keyTheme = 'profile_theme';

  /// Récupère le profil local (map avec keys: name, email, theme)
  static Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName) ?? '',
      'email': prefs.getString(_keyEmail) ?? '',
      'theme': prefs.getString(_keyTheme) ?? 'light',
    };
  }

  /// Sauvegarde le profil local
  static Future<void> saveProfile({required String name, required String email, required String theme}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyTheme, theme);
  }

  /// Efface le profil local
  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyTheme);
  }
}
