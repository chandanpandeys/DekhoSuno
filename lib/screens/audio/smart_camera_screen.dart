import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:provider/provider.dart';
import 'package:senseplay/services/gemini_service.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:vibration/vibration.dart';

/// Premium Smart Camera Screen
/// AI-powered scene description for visually impaired users
class SmartCameraScreen extends StatefulWidget {
  const SmartCameraScreen({super.key});

  @override
  State<SmartCameraScreen> createState() => _SmartCameraScreenState();
}

class _SmartCameraScreenState extends State<SmartCameraScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  ImageLabeler? _imageLabeler;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isProcessing = false;
  bool _isCameraReady = false;
  String _currentStatus = "Initializing camera...";
  String _lastDescription = "";

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeCamera();
    _initializeLabeler();
    _initTTS();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(
      "Smart Camera ready. Double tap anywhere to describe what's in front of you.",
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _updateStatus("No camera available");
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
        _currentStatus = "Ready! Double tap for description";
      });
    } catch (e) {
      _updateStatus("Camera error: $e");
      await _flutterTts.speak("Camera initialization failed.");
    }
  }

  void _initializeLabeler() {
    final options = ImageLabelerOptions(confidenceThreshold: 0.7);
    _imageLabeler = ImageLabeler(options: options);
  }

  void _updateStatus(String status) {
    if (!mounted) return;
    setState(() {
      _currentStatus = status;
    });
  }

  Future<void> _captureAndDescribe() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await _flutterTts.speak("Camera not ready yet.");
      return;
    }

    if (_isProcessing) {
      await _flutterTts.speak("Still analyzing. Please wait.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStatus = "Analyzing scene...";
    });

    await Vibration.vibrate(duration: 100);
    await _flutterTts.speak("Analyzing...");

    try {
      final image = await _controller!.takePicture();

      // Get AI description
      final geminiService = context.read<GeminiService>();
      final description = await geminiService.describeScene(File(image.path));

      setState(() {
        _lastDescription = description;
        _currentStatus = "Description ready";
      });

      await Vibration.vibrate(pattern: [0, 100, 50, 100]);
      await _flutterTts.speak(description);
    } catch (e) {
      _updateStatus("Analysis failed");
      await _flutterTts.speak("Sorry, could not analyze. Please try again.");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _repeatLastDescription() async {
    if (_lastDescription.isNotEmpty) {
      await Vibration.vibrate(duration: 50);
      await _flutterTts.speak(_lastDescription);
    } else {
      await _flutterTts
          .speak("No previous description. Double tap to analyze.");
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller?.dispose();
    _imageLabeler?.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.audioBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _captureAndDescribe,
        onLongPress: _repeatLastDescription,
        child: Stack(
          children: [
            // Camera preview (dimmed)
            if (_isCameraReady && _controller != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: CameraPreview(_controller!),
                ),
              ),

            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.audioBackground.withOpacity(0.7),
                    AppColors.audioBackground,
                  ],
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Central area
                  Expanded(
                    child: Center(
                      child: _buildCentralContent(),
                    ),
                  ),

                  // Status and hints
                  _buildBottomSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          Semantics(
            label: "Go back",
            button: true,
            child: GestureDetector(
              onTap: () {
                Vibration.vibrate(duration: 50);
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.audioSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.audioText,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Smart Camera",
                  style: TextStyle(
                    color: AppColors.audioText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "AI-powered scene description",
                  style: TextStyle(
                    color: AppColors.audioTextMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Camera status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isCameraReady
                  ? AppColors.audioPrimary.withOpacity(0.2)
                  : AppColors.audioAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isCameraReady
                        ? AppColors.audioPrimary
                        : AppColors.audioAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isCameraReady ? "Ready" : "Loading",
                  style: TextStyle(
                    color: _isCameraReady
                        ? AppColors.audioPrimary
                        : AppColors.audioAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralContent() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isProcessing ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (_isProcessing
                          ? AppColors.audioSecondary
                          : AppColors.audioPrimary)
                      .withOpacity(0.3),
                  (_isProcessing
                          ? AppColors.audioSecondary
                          : AppColors.audioPrimary)
                      .withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: (_isProcessing
                        ? AppColors.audioSecondary
                        : AppColors.audioPrimary)
                    .withOpacity(0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isProcessing
                          ? AppColors.audioSecondary
                          : AppColors.audioPrimary)
                      .withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isProcessing
                      ? Icons.auto_awesome
                      : Icons.camera_enhance_rounded,
                  size: 64,
                  color: _isProcessing
                      ? AppColors.audioSecondary
                      : AppColors.audioPrimary,
                ),
                const SizedBox(height: 12),
                Text(
                  _isProcessing ? "Analyzing..." : "Double Tap",
                  style: TextStyle(
                    color: AppColors.audioText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.audioSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status
          Row(
            children: [
              Icon(
                _isProcessing
                    ? Icons.hourglass_top_rounded
                    : Icons.info_outline_rounded,
                color: AppColors.audioPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentStatus,
                  style: const TextStyle(
                    color: AppColors.audioText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (_lastDescription.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.glassBorder),
            const SizedBox(height: 12),

            // Last description
            const Text(
              "Last description:",
              style: TextStyle(
                color: AppColors.audioTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _lastDescription,
              style: const TextStyle(
                color: AppColors.audioText,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // Gesture hints
          Row(
            children: [
              _buildGestureHint(
                icon: Icons.touch_app_rounded,
                label: "Double tap",
                action: "Describe",
              ),
              const SizedBox(width: 16),
              _buildGestureHint(
                icon: Icons.pan_tool_rounded,
                label: "Long press",
                action: "Repeat",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGestureHint({
    required IconData icon,
    required String label,
    required String action,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.audioPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.audioPrimary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.audioTextMuted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    action,
                    style: const TextStyle(
                      color: AppColors.audioPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
