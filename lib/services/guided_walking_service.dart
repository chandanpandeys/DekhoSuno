import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:senseplay/models/walking_detection.dart';
import 'package:senseplay/services/gemini_service.dart';

/// Guided Walking Service
/// Provides real-time navigation assistance for visually impaired users
/// with continuous object detection, distance estimation, and audio/haptic guidance
class GuidedWalkingService extends ChangeNotifier {
  final GeminiService _geminiService;
  final FlutterTts _tts = FlutterTts();

  CameraController? _cameraController;
  Timer? _analysisTimer;

  bool _isActive = false;
  bool _isPaused = false;
  bool _isAnalyzing = false;

  WalkingDetection? _lastDetection;
  WalkingSensitivity _sensitivity = WalkingSensitivity.medium;
  Duration _analysisInterval = const Duration(milliseconds: 1500); // Faster scanning

  // Cooldown tracking to avoid repeating same obstacle
  final Map<String, DateTime> _announcedObstacles = {};
  static const Duration _announcementCooldown = Duration(seconds: 5);

  // Callbacks
  Function(WalkingDetection)? onDetection;
  Function(String)? onError;
  Function(bool)? onActiveStateChange;

  GuidedWalkingService(this._geminiService);

  // Getters
  bool get isActive => _isActive;
  bool get isPaused => _isPaused;
  bool get isAnalyzing => _isAnalyzing;
  WalkingDetection? get lastDetection => _lastDetection;
  WalkingSensitivity get sensitivity => _sensitivity;
  CameraController? get cameraController => _cameraController;

  /// Initialize the service and camera
  Future<bool> initialize() async {
    try {
      // Initialize TTS
      await _tts.setLanguage("hi-IN");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);

      // Initialize camera with low resolution for faster processing
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        onError?.call("No camera available");
        return false;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.low, // Lower resolution for faster processing
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      debugPrint("GuidedWalkingService initialized");
      return true;
    } catch (e) {
      debugPrint("GuidedWalkingService init error: $e");
      onError?.call("Failed to initialize: $e");
      return false;
    }
  }

  /// Start walking guidance
  Future<void> start() async {
    if (_isActive) return;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    _isActive = true;
    _isPaused = false;
    onActiveStateChange?.call(true);
    notifyListeners();

    // Announce start
    await _speak(
        "Guided walking started. I will announce obstacles in your path.");
    await Vibration.vibrate(pattern: [0, 100, 50, 100]);

    // Start periodic analysis
    _startAnalysisLoop();
  }

  /// Pause walking guidance
  void pause() {
    if (!_isActive || _isPaused) return;

    _isPaused = true;
    _analysisTimer?.cancel();
    notifyListeners();

    _speak("Walking guidance paused. Double tap to resume.");
    Vibration.vibrate(duration: 50);
  }

  /// Resume walking guidance
  void resume() {
    if (!_isActive || !_isPaused) return;

    _isPaused = false;
    notifyListeners();

    _speak("Walking guidance resumed.");
    Vibration.vibrate(pattern: [0, 50, 30, 50]);

    _startAnalysisLoop();
  }

  /// Stop walking guidance
  Future<void> stop() async {
    if (!_isActive) return;

    _isActive = false;
    _isPaused = false;
    _analysisTimer?.cancel();
    onActiveStateChange?.call(false);
    notifyListeners();

    await _speak("Walking guidance stopped.");
    await Vibration.vibrate(duration: 100);
  }

  /// Toggle pause/resume
  void togglePause() {
    if (_isPaused) {
      resume();
    } else {
      pause();
    }
  }

  /// Set walking sensitivity
  void setSensitivity(WalkingSensitivity level) {
    _sensitivity = level;
    notifyListeners();
    _speak("Sensitivity set to ${level.displayName}");
  }

  /// Set analysis interval
  void setAnalysisInterval(Duration interval) {
    _analysisInterval = interval;
    if (_isActive && !_isPaused) {
      _analysisTimer?.cancel();
      _startAnalysisLoop();
    }
  }

  /// Repeat last announcement
  Future<void> repeatLastAnnouncement() async {
    if (_lastDetection != null) {
      await Vibration.vibrate(duration: 50);
      await _speak(_lastDetection!.fullAnnouncement);
    } else {
      await _speak("No previous detection. Please wait.");
    }
  }

  /// Manually trigger a full scene description
  Future<void> describeScene() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _speak("Camera not ready.");
      return;
    }

    await _speak("Describing complete scene...");
    await Vibration.vibrate(duration: 100);

    try {
      final image = await _cameraController!.takePicture();
      final description = await _geminiService.describeScene(File(image.path));
      await _speak(description);
    } catch (e) {
      await _speak("Could not describe scene.");
    }
  }

  void _startAnalysisLoop() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(_analysisInterval, (_) => _analyzeFrame());

    // Run immediate analysis
    _analyzeFrame();
  }

  Future<void> _analyzeFrame() async {
    if (_isPaused || _isAnalyzing) return;
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    _isAnalyzing = true;
    notifyListeners();

    try {
      // Capture frame
      final image = await _cameraController!.takePicture();

      // Analyze with Gemini
      final response =
          await _geminiService.analyzeWalkingPath(File(image.path));

      // Parse response
      final detection = _parseDetectionResponse(response);
      _lastDetection = detection;

      // Notify listeners
      onDetection?.call(detection);
      notifyListeners();

      // Announce and haptic feedback
      await _processDetection(detection);

      // Clean up temp file
      try {
        await File(image.path).delete();
      } catch (_) {}
    } catch (e) {
      debugPrint("Analysis error: $e");
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  WalkingDetection _parseDetectionResponse(String response) {
    final lines = response.split('\n');
    String pathStatus = 'unknown';
    String guidance = 'Be careful.';
    List<DetectedObstacle> obstacles = [];

    bool inObstacles = false;

    for (var line in lines) {
      line = line.trim();

      if (line.startsWith('PATH_STATUS:')) {
        pathStatus = line.split(':')[1].trim().toLowerCase();
      } else if (line.startsWith('GUIDANCE:')) {
        guidance = line.substring(line.indexOf(':') + 1).trim();
      } else if (line.startsWith('OBSTACLES:')) {
        inObstacles = true;
        if (line.toLowerCase().contains('none')) {
          inObstacles = false;
        }
      } else if (inObstacles && line.startsWith('-')) {
        final obstacle = _parseObstacleLine(line);
        if (obstacle != null) {
          // Filter by sensitivity
          if (obstacle.distanceMeters <= _sensitivity.maxDistance) {
            obstacles.add(obstacle);
          }
        }
      }
    }

    return WalkingDetection(
      obstacles: obstacles,
      pathStatus: pathStatus,
      navigationGuidance: guidance,
      timestamp: DateTime.now(),
    );
  }

  DetectedObstacle? _parseObstacleLine(String line) {
    try {
      // Format: - [name]|[distance]|[position]|[urgency]
      final content = line.substring(1).trim(); // Remove leading -
      final parts = content.split('|');

      if (parts.length >= 4) {
        final name = parts[0].trim();
        final distanceStr = parts[1].trim();
        final position = parts[2].trim().toLowerCase();
        final urgency = parts[3].trim().toLowerCase();

        // Parse distance
        final distanceMatch = RegExp(r'[\d.]+').firstMatch(distanceStr);
        final distanceMeters = distanceMatch != null
            ? double.tryParse(distanceMatch.group(0)!) ?? 5.0
            : 5.0;

        // Format distance for speech
        String estimatedDistance;
        if (distanceMeters < 1) {
          estimatedDistance = 'less than 1 meter';
        } else if (distanceMeters < 2) {
          estimatedDistance =
              'about ${distanceMeters.toStringAsFixed(0)} meter';
        } else {
          estimatedDistance =
              'about ${distanceMeters.toStringAsFixed(0)} meters';
        }

        return DetectedObstacle(
          name: name,
          position: position,
          estimatedDistance: estimatedDistance,
          distanceMeters: distanceMeters,
          urgency: urgency,
        );
      }
    } catch (e) {
      debugPrint("Failed to parse obstacle: $line - $e");
    }
    return null;
  }

  Future<void> _processDetection(WalkingDetection detection) async {
    // Handle critical obstacles immediately
    if (detection.hasCriticalObstacles) {
      await Vibration.vibrate(pattern: [0, 200, 50, 200, 50, 200]);
      await _speak(detection.fullAnnouncement);
      return;
    }

    // For non-critical, check cooldown and announce new obstacles
    final newObstacles = detection.obstacles.where((o) {
      final key = '${o.name}_${o.position}';
      final lastAnnounced = _announcedObstacles[key];
      if (lastAnnounced == null) return true;
      return DateTime.now().difference(lastAnnounced) > _announcementCooldown;
    }).toList();

    if (newObstacles.isEmpty && detection.pathStatus == 'clear') {
      // Occasionally remind path is clear
      if (_lastDetection?.pathStatus != 'clear') {
        await _speak(detection.navigationGuidance);
      }
      return;
    }

    // Provide haptic feedback for closest obstacle
    final mostUrgent = detection.mostUrgent;
    if (mostUrgent != null) {
      final pattern = mostUrgent.hapticPattern;
      if (pattern.isNotEmpty) {
        await Vibration.vibrate(pattern: pattern);
      }
    }

    // Announce new obstacles
    if (newObstacles.isNotEmpty) {
      final announcement =
          newObstacles.take(2).map((o) => o.announcement).join('. ');
      await _speak(announcement);

      // Update cooldown tracking
      for (var o in newObstacles) {
        _announcedObstacles['${o.name}_${o.position}'] = DateTime.now();
      }
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _cameraController?.dispose();
    _tts.stop();
    super.dispose();
  }
}
