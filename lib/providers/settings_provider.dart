import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { visual, audio, notSet }

class SettingsProvider with ChangeNotifier {
  AppMode _appMode = AppMode.notSet;

  AppMode get appMode => _appMode;

  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt('appMode');
    if (modeIndex != null) {
      _appMode = AppMode.values[modeIndex];
    }
    notifyListeners();
  }

  Future<void> setAppMode(AppMode mode) async {
    _appMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appMode', mode.index);
    notifyListeners();
  }

  Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _appMode = AppMode.notSet;
    notifyListeners();
  }
}
