import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:permission_handler/permission_handler.dart';

/// Callback when wake word is detected
typedef WakeWordCallback = void Function();

/// Wake Word Service using Picovoice Porcupine
///
/// Listens for the wake word "Help DekhoSuno" (phonetic: "help decko sueno")
/// to activate the app, similar to "OK Google" for Google Assistant.
class WakeWordService extends ChangeNotifier {
  PorcupineManager? _porcupineManager;

  bool _isInitialized = false;
  bool _isListening = false;
  bool _isEnabled = true;
  String? _errorMessage;

  // Callback when wake word is detected
  WakeWordCallback? onWakeWordDetected;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  bool get isEnabled => _isEnabled;
  String? get errorMessage => _errorMessage;

  /// Get the Picovoice Access Key from environment
  String get _accessKey => dotenv.env['PICOVOICE_ACCESS_KEY'] ?? '';

  /// Enable or disable wake word detection
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (enabled && !_isListening) {
      await startListening();
    } else if (!enabled && _isListening) {
      await stopListening();
    }
    notifyListeners();
  }

  /// Extract asset file to temp directory
  Future<String?> _extractAsset(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(bytes);
      debugPrint('WakeWordService: Extracted $assetPath to ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('WakeWordService: Failed to extract asset: $e');
      return null;
    }
  }

  /// Initialize the wake word detection engine
  /// Uses custom "help decko sueno" wake word trained in Picovoice Console
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check microphone permission
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          _errorMessage =
              'Microphone permission required for wake word detection';
          notifyListeners();
          return false;
        }
      }

      if (_accessKey.isEmpty) {
        _errorMessage = 'Picovoice Access Key not found in .env file';
        debugPrint('WakeWordService: $_errorMessage');
        notifyListeners();
        return false;
      }

      // Extract .ppn asset to file system
      const assetPath = 'assets/help-decko-sueno_en_android_v4_0_0.ppn';
      final keywordPath = await _extractAsset(assetPath);

      if (keywordPath == null) {
        _errorMessage = 'Failed to load wake word model';
        notifyListeners();
        return false;
      }

      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        [keywordPath],
        _onWakeWordDetected,
        sensitivities: [0.7],
        errorCallback: _onError,
      );

      _isInitialized = true;
      _errorMessage = null;
      debugPrint(
          'WakeWordService: Initialized with "help decko sueno" wake word');
      notifyListeners();
      return true;
    } on PorcupineActivationException catch (e) {
      _errorMessage = 'Picovoice activation error: ${e.message}';
      debugPrint('WakeWordService: $_errorMessage');
      notifyListeners();
      return false;
    } on PorcupineActivationLimitException catch (e) {
      _errorMessage = 'Picovoice activation limit reached: ${e.message}';
      debugPrint('WakeWordService: $_errorMessage');
      notifyListeners();
      return false;
    } on PorcupineException catch (e) {
      _errorMessage = 'Porcupine error: ${e.message}';
      debugPrint('WakeWordService: $_errorMessage');
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to initialize wake word service: $e';
      debugPrint('WakeWordService: $_errorMessage');
      notifyListeners();
      return false;
    }
  }

  /// Start listening for wake word
  Future<void> startListening() async {
    if (!_isEnabled) return;

    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    if (_isListening) return;

    try {
      await _porcupineManager?.start();
      _isListening = true;
      debugPrint('WakeWordService: Started listening for wake word');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start listening: $e';
      debugPrint('WakeWordService: $_errorMessage');
      notifyListeners();
    }
  }

  /// Stop listening for wake word
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _porcupineManager?.stop();
      _isListening = false;
      debugPrint('WakeWordService: Stopped listening');
      notifyListeners();
    } catch (e) {
      debugPrint('WakeWordService: Error stopping: $e');
    }
  }

  /// Handle wake word detection
  void _onWakeWordDetected(int keywordIndex) {
    debugPrint('WakeWordService: Wake word detected! Opening app...');
    onWakeWordDetected?.call();
    notifyListeners();
  }

  /// Handle errors from Porcupine
  void _onError(PorcupineException error) {
    _errorMessage = 'Wake word error: ${error.message}';
    debugPrint('WakeWordService: $_errorMessage');
    notifyListeners();
  }

  /// Dispose the service
  @override
  Future<void> dispose() async {
    await stopListening();
    await _porcupineManager?.delete();
    _porcupineManager = null;
    _isInitialized = false;
    super.dispose();
  }
}
