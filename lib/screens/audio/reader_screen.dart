import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:vibration/vibration.dart';

/// Premium Reader Screen (OCR)
/// Text recognition and reading for visually impaired users
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;

  // Multiple text recognizers for different scripts
  final TextRecognizer _latinRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final TextRecognizer _devanagariRecognizer =
      TextRecognizer(script: TextRecognitionScript.devanagiri);

  final FlutterTts _flutterTts = FlutterTts();

  bool _isProcessing = false;
  bool _isCameraReady = false;
  String _currentStatus = "Initializing...";
  String _recognizedText = "";
  bool _isPaused = false;
  bool _useHindi = false; // Toggle for Hindi/English recognition

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeCamera();
    _initTTS();
  }

  void _setupAnimations() {
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(
      "Text Reader. Document ya board ko camera ke saamne rakhein aur double tap karein.",
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _updateStatus("No camera found");
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.auto);

      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
        _currentStatus = "Ready! Double tap to read text";
      });
    } catch (e) {
      _updateStatus("Camera error");
      await _flutterTts.speak("Camera could not start.");
    }
  }

  void _updateStatus(String status) {
    if (!mounted) return;
    setState(() {
      _currentStatus = status;
    });
  }

  Future<void> _captureAndRead() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await _flutterTts.speak("Camera not ready.");
      return;
    }

    if (_isProcessing) {
      await _flutterTts.speak("Still reading. Please wait.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStatus = "Reading text...";
      _recognizedText = "";
    });

    await Vibration.vibrate(duration: 100);
    await _flutterTts.speak("Padh raha hoon...");

    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // Use appropriate recognizer based on language setting
      final recognizer = _useHindi ? _devanagariRecognizer : _latinRecognizer;
      final recognizedText = await recognizer.processImage(inputImage);

      final text = recognizedText.text.trim();

      if (text.isEmpty) {
        _updateStatus("No text found");
        await Vibration.vibrate(pattern: [0, 100, 100, 100]);
        await _flutterTts.speak("Koi text nahi mila. Phir se try karein.");
      } else {
        setState(() {
          _recognizedText = text;
          _currentStatus = "Text found! Reading...";
        });

        await Vibration.vibrate(pattern: [0, 200, 100, 200]);
        await _flutterTts.speak(text);
      }
    } catch (e) {
      _updateStatus("Error reading");
      await _flutterTts.speak("Error. Phir se try karein.");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pauseOrRepeat() async {
    if (_recognizedText.isEmpty) {
      await _flutterTts.speak("Pehle text padhein. Double tap karein.");
      return;
    }

    if (_isPaused) {
      setState(() {
        _isPaused = false;
      });
      await _flutterTts.speak(_recognizedText);
    } else {
      await _flutterTts.stop();
      setState(() {
        _isPaused = true;
      });
      await Vibration.vibrate(duration: 50);
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _controller?.dispose();
    _latinRecognizer.close();
    _devanagariRecognizer.close();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.audioBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _captureAndRead,
        onLongPress: _pauseOrRepeat,
        child: Stack(
          children: [
            // Camera preview
            if (_isCameraReady && _controller != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: CameraPreview(_controller!),
                ),
              ),

            // Scanning line
            if (_isProcessing) _buildScanningLine(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.audioBackground.withAlpha(180),
                    AppColors.audioBackground,
                  ],
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildCentralContent()),
                  if (_recognizedText.isNotEmpty) _buildTextPreview(),
                  _buildBottomHints(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningLine() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.15 +
              (_scanAnimation.value * MediaQuery.of(context).size.height * 0.5),
          left: 30,
          right: 30,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.audioPrimary,
                  AppColors.audioPrimary,
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.audioPrimary.withAlpha(200),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Text Reader",
                  style: TextStyle(
                    color: AppColors.audioText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "OCR powered text recognition",
                  style: TextStyle(
                    color: AppColors.audioTextMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Language toggle
          GestureDetector(
            onTap: () async {
              setState(() => _useHindi = !_useHindi);
              await Vibration.vibrate(duration: 50);
              await _flutterTts
                  .speak(_useHindi ? "Hindi mode" : "English mode");
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _useHindi
                    ? AppColors.audioSecondary.withAlpha(50)
                    : AppColors.audioPrimary.withAlpha(50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _useHindi ? "हिंदी" : "EN",
                style: TextStyle(
                  color: _useHindi
                      ? AppColors.audioSecondary
                      : AppColors.audioPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isCameraReady
                  ? AppColors.audioPrimary.withAlpha(50)
                  : AppColors.audioAccent.withAlpha(50),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Central indicator
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.audioPrimary.withAlpha(80),
                  AppColors.audioPrimary.withAlpha(30),
                ],
              ),
              border: Border.all(
                color: AppColors.audioPrimary.withAlpha(130),
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isProcessing
                      ? Icons.auto_awesome
                      : Icons.document_scanner_rounded,
                  size: 56,
                  color: AppColors.audioPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  _isProcessing ? "Reading..." : "Double Tap",
                  style: const TextStyle(
                    color: AppColors.audioPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.audioSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentStatus,
              style: const TextStyle(
                color: AppColors.audioText,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: AppColors.audioSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.audioPrimary.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recognized Text:",
                style: TextStyle(
                  color: AppColors.audioPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: AppColors.audioPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPaused ? "Long press to play" : "Long press to pause",
                    style: const TextStyle(
                      color: AppColors.audioTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _recognizedText,
                style: const TextStyle(
                  color: AppColors.audioText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomHints() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHintChip(Icons.touch_app, "Double tap", "Read text"),
            const SizedBox(width: 8),
            _buildHintChip(Icons.pan_tool, "Long press", "Pause/Repeat"),
          ],
        ),
      ),
    );
  }

  Widget _buildHintChip(IconData icon, String gesture, String action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.audioSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.audioPrimary),
          const SizedBox(width: 6),
          Text(
            "$gesture: $action",
            style:
                const TextStyle(color: AppColors.audioTextMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
