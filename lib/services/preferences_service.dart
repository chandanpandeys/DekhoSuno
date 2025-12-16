import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyLanguage = 'language';
  static const String _keyVoiceSpeed = 'voice_speed';
  static const String _keyHighContrast = 'high_contrast';
  static const String _keyWakeWordEnabled = 'wake_word_enabled';

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }

  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'en';
  }

  Future<void> setVoiceSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVoiceSpeed, speed);
  }

  Future<double> getVoiceSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyVoiceSpeed) ?? 0.5;
  }

  Future<void> setHighContrast(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHighContrast, enabled);
  }

  Future<bool> getHighContrast() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHighContrast) ?? false;
  }

  Future<void> setWakeWordEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWakeWordEnabled, enabled);
  }

  Future<bool> getWakeWordEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWakeWordEnabled) ?? true;
  }
}
