import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:senseplay/services/gemini_service.dart';

/// Traffic analysis result from Gemini
class TrafficAnalysis {
  final String status; // 'safe', 'caution', 'danger'
  final String instruction;
  final String hindiInstruction;
  final List<String> vehicles;
  final bool canCross;

  TrafficAnalysis({
    required this.status,
    required this.instruction,
    required this.hindiInstruction,
    required this.vehicles,
    required this.canCross,
  });

  factory TrafficAnalysis.fromResponse(String response) {
    // Parse Gemini response
    final lines = response.split('\n');
    String status = 'caution';
    String instruction = 'Check both ways before crossing';
    String hindiInstruction = 'Dono taraf dekh ke paar karein';
    List<String> vehicles = [];
    bool canCross = false;

    for (final line in lines) {
      if (line.startsWith('STATUS:')) {
        final s = line.substring(7).trim().toLowerCase();
        if (s.contains('safe') || s.contains('clear')) {
          status = 'safe';
          canCross = true;
        } else if (s.contains('danger') || s.contains('stop')) {
          status = 'danger';
          canCross = false;
        } else {
          status = 'caution';
          canCross = false;
        }
      } else if (line.startsWith('VEHICLES:')) {
        final v = line.substring(9).trim();
        if (v.isNotEmpty && v.toLowerCase() != 'none') {
          vehicles = v.split(',').map((e) => e.trim()).toList();
        }
      } else if (line.startsWith('INSTRUCTION:')) {
        instruction = line.substring(12).trim();
      } else if (line.startsWith('HINDI:')) {
        hindiInstruction = line.substring(6).trim();
      }
    }

    return TrafficAnalysis(
      status: status,
      instruction: instruction,
      hindiInstruction: hindiInstruction,
      vehicles: vehicles,
      canCross: canCross,
    );
  }

  factory TrafficAnalysis.error() => TrafficAnalysis(
        status: 'caution',
        instruction: 'Could not analyze. Be careful.',
        hindiInstruction: 'Analysis nahi ho payi. Savdhaan rahein.',
        vehicles: [],
        canCross: false,
      );
}

/// Road Crossing Assistant Service
/// Uses camera to analyze traffic and provide voice guidance for safe crossing
class RoadCrossingService extends ChangeNotifier {
  CameraController? _cameraController;
  final GeminiService _geminiService = GeminiService();

  Timer? _analysisTimer;
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _isActive = false;

  TrafficAnalysis? _lastAnalysis;
  String? _lastError;

  // Callbacks
  Function(TrafficAnalysis analysis)? onAnalysisComplete;
  Function(String message)? onSpeak;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isAnalyzing => _isAnalyzing;
  bool get isActive => _isActive;
  TrafficAnalysis? get lastAnalysis => _lastAnalysis;
  String? get lastError => _lastError;
  CameraController? get cameraController => _cameraController;

  /// Initialize the service with camera
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _lastError = 'No cameras available';
        return false;
      }

      // Use back camera
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      _isInitialized = true;
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('RoadCrossingService: Error initializing: $_lastError');
      return false;
    }
  }

  /// Start continuous traffic analysis
  Future<void> startAnalysis() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized || _cameraController == null) return;

    _isActive = true;
    notifyListeners();

    // Initial analysis
    await _analyzeTraffic();

    // Set up periodic analysis every 2 seconds
    _analysisTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isActive && !_isAnalyzing) {
        _analyzeTraffic();
      }
    });
  }

  /// Stop analysis
  void stopAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _isActive = false;
    _isAnalyzing = false;
    notifyListeners();
  }

  /// Analyze current traffic
  Future<void> _analyzeTraffic() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _isAnalyzing = true;
    notifyListeners();

    try {
      // Capture image
      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      // Analyze with Gemini
      final response = await _analyzeWithGemini(imageFile);

      _lastAnalysis = TrafficAnalysis.fromResponse(response);
      onAnalysisComplete?.call(_lastAnalysis!);

      // Clean up temp file
      await imageFile.delete();
    } catch (e) {
      debugPrint('Traffic analysis error: $e');
      _lastAnalysis = TrafficAnalysis.error();
      onAnalysisComplete?.call(_lastAnalysis!);
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  /// Analyze image with Gemini for traffic safety
  Future<String> _analyzeWithGemini(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      // Use Gemini to analyze traffic
      final prompt =
          '''You are a road crossing safety assistant helping a blind person cross the road safely.
      
Analyze this image of a road/street and determine if it's safe to cross.

Look for:
1. Moving vehicles (cars, bikes, trucks, buses, autos)
2. Traffic signals (red, green, yellow)
3. Pedestrian crossings
4. Speed of approaching vehicles
5. Overall road conditions

RESPOND IN THIS EXACT FORMAT:
STATUS: [SAFE/CAUTION/DANGER]
VEHICLES: [list of vehicles seen, or 'none']
INSTRUCTION: [One short English instruction]
HINDI: [Same instruction in Hinglish]

Examples:
STATUS: SAFE
VEHICLES: none
INSTRUCTION: Road is clear. You can cross now.
HINDI: Raasta saaf hai. Aap paar kar sakte hain.

STATUS: DANGER
VEHICLES: car, bike
INSTRUCTION: Stop! Fast moving car approaching from left.
HINDI: Ruko! Baayein se tez car aa rahi hai.

STATUS: CAUTION
VEHICLES: auto
INSTRUCTION: Wait. Auto-rickshaw is passing. Cross after it.
HINDI: Ruko. Auto ja raha hai. Uske baad paar karo.

Be very careful and conservative. If unsure, say CAUTION.''';

      final response = await _geminiService.chatWithImage(prompt, imageFile);
      return response;
    } catch (e) {
      debugPrint('Gemini analysis error: $e');
      return 'STATUS: CAUTION\nVEHICLES: unknown\nINSTRUCTION: Could not analyze traffic.\nHINDI: Traffic analysis nahi ho payi.';
    }
  }

  /// Request immediate analysis (user triggered)
  Future<void> checkNow() async {
    await _analyzeTraffic();

    if (_lastAnalysis != null) {
      onSpeak?.call(_lastAnalysis!.hindiInstruction);
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    stopAnalysis();
    _cameraController?.dispose();
    super.dispose();
  }
}
