import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senseplay/services/preferences_service.dart';
import 'package:senseplay/services/wake_word_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefs = PreferencesService();
  String _language = 'en';
  double _voiceSpeed = 0.5;
  bool _highContrast = false;
  bool _wakeWordEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lang = await _prefs.getLanguage();
    final speed = await _prefs.getVoiceSpeed();
    final contrast = await _prefs.getHighContrast();
    final wakeWord = await _prefs.getWakeWordEnabled();

    if (mounted) {
      setState(() {
        _language = lang;
        _voiceSpeed = speed;
        _highContrast = contrast;
        _wakeWordEnabled = wakeWord;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLanguage(String? value) async {
    if (value != null) {
      await _prefs.setLanguage(value);
      setState(() => _language = value);
    }
  }

  Future<void> _saveVoiceSpeed(double value) async {
    await _prefs.setVoiceSpeed(value);
    setState(() => _voiceSpeed = value);
  }

  Future<void> _saveHighContrast(bool value) async {
    await _prefs.setHighContrast(value);
    setState(() => _highContrast = value);
  }

  Future<void> _saveWakeWordEnabled(bool value) async {
    await _prefs.setWakeWordEnabled(value);
    setState(() => _wakeWordEnabled = value);

    // Update wake word service
    final wakeWordService = context.read<WakeWordService>();
    await wakeWordService.setEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Wake Word Section
          const Text("Wake Word Detection",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text("Enable \"Help DekhoSuno\""),
            subtitle: Text(_wakeWordEnabled
                ? "Say \"help decko sueno\" to activate app"
                : "Wake word detection disabled"),
            value: _wakeWordEnabled,
            onChanged: _saveWakeWordEnabled,
          ),
          const Divider(),

          // Language Section
          const Text("Language",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          RadioListTile<String>(
            title: const Text("English"),
            value: 'en',
            groupValue: _language,
            onChanged: _saveLanguage,
          ),
          RadioListTile<String>(
            title: const Text("Hindi (हिंदी)"),
            value: 'hi',
            groupValue: _language,
            onChanged: _saveLanguage,
          ),
          const Divider(),

          // Voice Speed Section
          const Text("Voice Speed",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Slider(
            value: _voiceSpeed,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: _voiceSpeed.toString(),
            onChanged: _saveVoiceSpeed,
          ),
          const Divider(),

          // High Contrast Section
          SwitchListTile(
            title: const Text("High Contrast Mode",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            value: _highContrast,
            onChanged: _saveHighContrast,
          ),
        ],
      ),
    );
  }
}
