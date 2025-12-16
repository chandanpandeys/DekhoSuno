import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:senseplay/services/ml_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VisualModeScreen extends StatefulWidget {
  const VisualModeScreen({super.key});

  @override
  State<VisualModeScreen> createState() => _VisualModeScreenState();
}

class _VisualModeScreenState extends State<VisualModeScreen> {
  final MLService _mlService = MLService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  CameraController? _controller;
  bool _isDetecting = false;
  List<String> _detectedLabels = [];
  String _captionText = "Listening for speech...";
  double _soundLevel = 0.0; // For visualizer

  // Game State
  bool _isGameMode = false;
  String? _targetObject;
  int _score = 0;
  final List<String> _gameTargets = [
    "Bottle",
    "Cup",
    "Chair",
    "Laptop",
    "Phone"
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeSTT();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {});
          _startDetectionLoop();
        }
      }
    }
  }

  Future<void> _initializeSTT() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('STT Status: $status'),
      // onError: (error) => debugPrint('STT Error: $error'), // Commented out to fix Web TypeError
    );

    if (available) {
      if (_speech.isListening) return; // Prevent already started error
      _speech.listen(
        onResult: (val) {
          setState(() {
            _captionText = val.recognizedWords;
          });
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        onSoundLevelChange: (level) {
          if (mounted) {
            setState(() => _soundLevel = level);
          }
        },
      );
    } else {
      setState(() => _captionText = "Speech recognition unavailable");
    }
  }

  void _startDetectionLoop() {
    // Run detection every 1 second to avoid overloading non-stream ML Service
    Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      if (!mounted ||
          _controller == null ||
          !_controller!.value.isInitialized ||
          _isDetecting) {
        return;
      }

      setState(() => _isDetecting = true);
      try {
        final image = await _controller!.takePicture();
        final labels = await _mlService.detectObjects(File(image.path));

        if (mounted) {
          setState(() {
            _detectedLabels = labels;
            _checkGameCondition(labels);
          });
        }
      } catch (e) {
        debugPrint("Detection error: $e");
      } finally {
        if (mounted) setState(() => _isDetecting = false);
      }
    });
  }

  void _checkGameCondition(List<String> labels) {
    if (_isGameMode && _targetObject != null) {
      bool found = labels.any((l) {
        final label = l.toLowerCase();
        final target = _targetObject!.toLowerCase();
        return label.contains(target) || target.contains(label);
      });

      if (found) {
        _handleGameWin();
      }
    }
  }

  void _handleGameWin() {
    setState(() {
      _score++;
      _targetObject = null; // Reset target
      _isGameMode = false; // End round
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        title: const Text("🎉 Found it!"),
        content: Text("Great job! Score: $_score"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            child: const Text("Next Object"),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    setState(() {
      _isGameMode = true;
      _targetObject =
          _gameTargets[DateTime.now().millisecond % _gameTargets.length];
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _mlService.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Sign World Explorer",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isGameMode ? Icons.stop_circle : Icons.play_circle,
                size: 32),
            onPressed: () {
              if (_isGameMode) {
                setState(() => _isGameMode = false);
              } else {
                _startGame();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          // Game Overlay (HUD)
          if (_isGameMode)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "FIND THIS OBJECT",
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _targetObject ?? "...",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Success Overlay (Green Flash)
          if (_score > 0 && !_isGameMode) // Just won
            Container(
              color: Colors.green.withOpacity(0.3),
            ),

          // Detected Objects Chips
          Positioned(
            bottom: 140,
            left: 16,
            right: 16,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _detectedLabels
                  .map((label) => Chip(
                        label: Text(label),
                        backgroundColor: Colors.black.withOpacity(0.6),
                        labelStyle: const TextStyle(color: Colors.white),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ))
                  .toList(),
            ),
          ),

          // Captions Overlay (Glassmorphism)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "CAPTIONS",
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _captionText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sound Visualizer (Top Right)
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.graphic_eq, color: Colors.white),
                  const SizedBox(height: 4),
                  Container(
                    width: 10,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 10,
                      height:
                          100 * (_soundLevel / 10).clamp(0.0, 1.0), // Normalize
                      decoration: BoxDecoration(
                        color: _soundLevel > 5
                            ? Colors.red
                            : (_soundLevel > 2 ? Colors.yellow : Colors.green),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
