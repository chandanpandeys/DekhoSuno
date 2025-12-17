import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Voice Command Service - Google Assistant style wake word detection
/// Implements VUI (Voice User Interface) with keyword-based NLP
class VoiceCommandService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAwake = false; // True when wake word detected
  bool _continuousListening = false; // Auto-restart after timeout
  String _lastWords = '';
  String _currentCommand = '';

  // Wake words
  static const List<String> _wakeWords = [
    'dekho suno',
    'dekhosuno',
    'dekho sunno',
    'open dekho suno',
    'hey dekho suno',
    'ok dekho suno',
  ];

  // Command mappings for Audio Mode
  static const Map<String, String> _audioCommands = {
    'camera': 'smart_camera',
    'smart camera': 'smart_camera',
    'photo': 'smart_camera',
    'picture': 'smart_camera',
    'currency': 'currency_reader',
    'money': 'currency_reader',
    'note': 'currency_reader',
    'rupee': 'currency_reader',
    'light': 'light_detector',
    'brightness': 'light_detector',
    'dark': 'light_detector',
    'text': 'text_reader',
    'read': 'text_reader',
    'document': 'text_reader',
    'walk': 'guided_walking',
    'walking': 'guided_walking',
    'guide': 'guided_walking',
    'navigate': 'guided_walking',
    'chalo': 'guided_walking',
    'back': 'go_back',
    'home': 'go_home',
  };

  // Command mappings for Visual Mode
  static const Map<String, String> _visualCommands = {
    'subtitles': 'live_subtitles',
    'caption': 'live_subtitles',
    'live': 'live_subtitles',
    'sound': 'sound_watch',
    'audio': 'sound_watch',
    'noise': 'sound_watch',
    'call': 'call_assistant',
    'phone': 'call_assistant',
    'assistant': 'call_assistant',
    'sign': 'sign_world',
    'language': 'sign_world',
    'gesture': 'sign_world',
    'back': 'go_back',
    'home': 'go_home',
  };

  // Mode selection commands (for landing screen)
  static const Map<String, String> _modeCommands = {
    'dekho': 'visual_mode',
    'visual': 'visual_mode',
    'see': 'visual_mode',
    'suno': 'audio_mode',
    'audio': 'audio_mode',
    'listen': 'audio_mode',
    'hear': 'audio_mode',
  };

  // Callbacks
  Function(String command)? onCommand;
  Function(String mode)? onModeSelect;
  Function(bool isListening)? onListeningStateChange;
  Function(bool isAwake)? onWakeStateChange;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isAwake => _isAwake;
  String get lastWords => _lastWords;
  String get currentCommand => _currentCommand;

  /// Initialize the speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: _onStatus,
        onError: (error) => debugPrint('Speech error: $error'),
      );
      debugPrint('VoiceCommandService initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize VoiceCommandService: $e');
      return false;
    }
  }

  /// Start listening for wake word or commands
  Future<void> startListening({bool waitForWakeWord = true}) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    if (_isListening) return;

    _isAwake = !waitForWakeWord;
    _isListening = true;
    _continuousListening = true; // Enable auto-restart
    onListeningStateChange?.call(true);
    notifyListeners();

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_IN', // English India for mixed Hindi-English
      cancelOnError: false,
      partialResults: true,
    );
  }

  /// Stop listening completely (disables auto-restart)
  Future<void> stopListening() async {
    _continuousListening = false; // Disable auto-restart
    await _speechToText.stop();
    _isListening = false;
    _isAwake = false;
    onListeningStateChange?.call(false);
    onWakeStateChange?.call(false);
    notifyListeners();
  }

  /// Process speech results
  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords.toLowerCase();
    debugPrint('Heard: $_lastWords');

    // Check for wake word if not already awake
    if (!_isAwake) {
      if (_containsWakeWord(_lastWords)) {
        _isAwake = true;
        onWakeStateChange?.call(true);
        notifyListeners();
        debugPrint('Wake word detected!');
        return;
      }
    }

    // Process command if awake
    if (_isAwake && result.finalResult) {
      _processCommand(_lastWords);
    }
  }

  /// Check if text contains a wake word
  bool _containsWakeWord(String text) {
    for (final wakeWord in _wakeWords) {
      if (text.contains(wakeWord)) {
        return true;
      }
    }
    return false;
  }

  /// Process the command
  void _processCommand(String text) {
    // Remove wake words from command
    String cleanedText = text;
    for (final wakeWord in _wakeWords) {
      cleanedText = cleanedText.replaceAll(wakeWord, '').trim();
    }

    // Check mode commands first
    for (final entry in _modeCommands.entries) {
      if (cleanedText.contains(entry.key)) {
        _currentCommand = entry.value;
        onModeSelect?.call(entry.value);
        notifyListeners();
        return;
      }
    }

    // Check audio commands
    for (final entry in _audioCommands.entries) {
      if (cleanedText.contains(entry.key)) {
        _currentCommand = entry.value;
        onCommand?.call(entry.value);
        notifyListeners();
        return;
      }
    }

    // Check visual commands
    for (final entry in _visualCommands.entries) {
      if (cleanedText.contains(entry.key)) {
        _currentCommand = entry.value;
        onCommand?.call(entry.value);
        notifyListeners();
        return;
      }
    }

    debugPrint('No matching command found for: $cleanedText');
  }

  void _onStatus(String status) {
    debugPrint('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      onListeningStateChange?.call(false);
      notifyListeners();

      // Auto-restart if continuous listening is enabled
      if (_continuousListening) {
        debugPrint('Auto-restarting listening...');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_continuousListening) {
            startListening(waitForWakeWord: !_isAwake);
          }
        });
      }
    }
  }

  /// Get available commands for current mode
  List<String> getCommandHints(String mode) {
    if (mode == 'audio') {
      return ['Camera', 'Currency', 'Light', 'Text reader', 'Back', 'Home'];
    } else if (mode == 'visual') {
      return [
        'Subtitles',
        'Sound watch',
        'Call assistant',
        'Sign world',
        'Back',
        'Home'
      ];
    } else {
      return ['Dekho (Visual)', 'Suno (Audio)'];
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
