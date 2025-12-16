import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:senseplay/services/gemini_service.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:vibration/vibration.dart';

/// Premium Currency Reader Screen
/// AI-powered Indian currency identification for visually impaired users
class CurrencyReaderScreen extends StatefulWidget {
  const CurrencyReaderScreen({super.key});

  @override
  State<CurrencyReaderScreen> createState() => _CurrencyReaderScreenState();
}

class _CurrencyReaderScreenState extends State<CurrencyReaderScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isProcessing = false;
  bool _isCameraReady = false;
  String _currentStatus = "Initializing...";
  int _totalAmount = 0;
  List<_CurrencyEntry> _history = [];

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  final Map<String, Color> _currencyColors = {
    "10": const Color(0xFFFF6B00),
    "20": const Color(0xFFE53935),
    "50": const Color(0xFF00BCD4),
    "100": const Color(0xFF8BC34A),
    "200": const Color(0xFFFF9800),
    "500": const Color(0xFF9C27B0),
    "2000": const Color(0xFFE91E63),
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeCamera();
    _initTTS();
  }

  void _setupAnimations() {
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(
      "Currency Reader. Note ko camera ke saamne rakhein aur double tap karein.",
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
        ResolutionPreset.high, // Higher res for currency details
        enableAudio: false,
      );

      await _controller!.initialize();
      // Enable flash for better currency reading
      await _controller!.setFlashMode(FlashMode.auto);

      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
        _currentStatus = "Ready! Double tap to read note";
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

  Future<void> _captureAndIdentify() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await _flutterTts.speak("Camera not ready.");
      return;
    }

    if (_isProcessing) {
      await _flutterTts.speak("Still processing. Please wait.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStatus = "Scanning note...";
    });

    await Vibration.vibrate(duration: 100);
    await _flutterTts.speak("Scanning...");

    try {
      final image = await _controller!.takePicture();
      final geminiService = context.read<GeminiService>();
      final result = await geminiService.identifyCurrency(File(image.path));

      // Parse the result
      final cleanResult = result.trim().replaceAll(RegExp(r'[^0-9]'), '');

      if (cleanResult.isEmpty || cleanResult == "0") {
        _updateStatus("No currency detected");
        await Vibration.vibrate(pattern: [0, 100, 100, 100]);
        await _flutterTts.speak("Koi note nahi mila. Phir se try karein.");
      } else {
        final amount = int.tryParse(cleanResult) ?? 0;

        if ([10, 20, 50, 100, 200, 500, 2000].contains(amount)) {
          setState(() {
            _totalAmount += amount;
            _history.insert(
              0,
              _CurrencyEntry(
                amount: amount,
                time: DateTime.now(),
                color: _currencyColors[amount.toString()] ??
                    AppColors.audioPrimary,
              ),
            );
            _currentStatus = "₹$amount detected!";
          });

          await Vibration.vibrate(pattern: [0, 200, 100, 200]);
          await _flutterTts.speak("$amount Rupay. Total $amount Rupay.");
        } else {
          _updateStatus("Could not identify");
          await _flutterTts.speak("Note samajh nahi aaya. Phir se try karein.");
        }
      }
    } catch (e) {
      _updateStatus("Error reading note");
      await _flutterTts.speak("Error. Phir se try karein.");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _clearTotal() async {
    await Vibration.vibrate(duration: 50);
    await _flutterTts.speak("Total clear ho gaya.");
    setState(() {
      _totalAmount = 0;
      _history.clear();
    });
  }

  void _announceTotal() async {
    await Vibration.vibrate(duration: 50);
    if (_totalAmount > 0) {
      await _flutterTts.speak("Total $_totalAmount Rupay.");
    } else {
      await _flutterTts.speak("Abhi tak koi note nahi padha.");
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _controller?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.audioBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _captureAndIdentify,
        onLongPress: _announceTotal,
        child: Stack(
          children: [
            // Camera preview
            if (_isCameraReady && _controller != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: CameraPreview(_controller!),
                ),
              ),

            // Scanning overlay
            if (_isProcessing) _buildScanningOverlay(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.audioBackground.withOpacity(0.6),
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
                  Flexible(child: _buildCentralContent()),
                  _buildTotalSection(),
                  if (_history.isNotEmpty) _buildHistorySection(),
                  _buildBottomHints(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height * 0.2 +
              (_scanAnimation.value * MediaQuery.of(context).size.height * 0.4),
          left: 40,
          right: 40,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.audioSecondary,
                  AppColors.audioSecondary,
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.audioSecondary.withOpacity(0.8),
                  blurRadius: 20,
                  spreadRadius: 5,
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
                  "Currency Reader",
                  style: TextStyle(
                    color: AppColors.audioText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Indian currency recognition",
                  style:
                      TextStyle(color: AppColors.audioTextMuted, fontSize: 14),
                ),
              ],
            ),
          ),
          // Clear button
          GestureDetector(
            onTap: _clearTotal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.audioAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Clear",
                style: TextStyle(
                  color: AppColors.audioAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          // Currency icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.audioSecondary.withOpacity(0.3),
                  AppColors.audioSecondary.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: AppColors.audioSecondary.withOpacity(0.5),
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isProcessing
                      ? Icons.document_scanner
                      : Icons.currency_rupee_rounded,
                  size: 56,
                  color: AppColors.audioSecondary,
                ),
                if (!_isProcessing)
                  const Text(
                    "Double Tap",
                    style: TextStyle(
                      color: AppColors.audioSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.audioSurface,
              borderRadius: BorderRadius.circular(20),
            ),
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
    );
  }

  Widget _buildTotalSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.audioSecondary.withOpacity(0.2),
            AppColors.audioSecondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.audioSecondary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Amount",
                style: TextStyle(color: AppColors.audioTextMuted, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "₹$_totalAmount",
                style: const TextStyle(
                  color: AppColors.audioSecondary,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.audioSecondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: AppColors.audioSecondary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final entry = _history[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: entry.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: entry.color.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "₹${entry.amount}",
                  style: TextStyle(
                    color: entry.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomHints() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHintChip(Icons.touch_app, "Double tap", "Read note"),
          const SizedBox(width: 12),
          _buildHintChip(Icons.pan_tool, "Long press", "Hear total"),
        ],
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

class _CurrencyEntry {
  final int amount;
  final DateTime time;
  final Color color;

  _CurrencyEntry({
    required this.amount,
    required this.time,
    required this.color,
  });
}
