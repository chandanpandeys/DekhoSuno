import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:senseplay/services/road_crossing_service.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:vibration/vibration.dart';

/// Road Crossing Assistant Screen
/// Uses camera and AI to help visually impaired users cross roads safely
class RoadCrossingScreen extends StatefulWidget {
  const RoadCrossingScreen({super.key});

  @override
  State<RoadCrossingScreen> createState() => _RoadCrossingScreenState();
}

class _RoadCrossingScreenState extends State<RoadCrossingScreen>
    with TickerProviderStateMixin {
  final RoadCrossingService _service = RoadCrossingService();
  final FlutterTts _tts = FlutterTts();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _currentStatus = 'caution';
  String _instruction = 'Initializing...';
  List<String> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initialize();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initialize() async {
    await _tts.setLanguage("hi-IN");
    await _tts.setSpeechRate(0.5);

    _service.onSpeak = (message) async {
      await _tts.speak(message);
    };

    _service.onAnalysisComplete = (analysis) {
      if (!mounted) return;

      setState(() {
        _currentStatus = analysis.status;
        _instruction = analysis.hindiInstruction;
        _vehicles = analysis.vehicles;
      });

      // Vibration feedback based on status
      if (analysis.status == 'safe') {
        Vibration.vibrate(pattern: [0, 100, 100, 100]); // Short pulses = safe
        _tts.speak(analysis.hindiInstruction);
      } else if (analysis.status == 'danger') {
        Vibration.vibrate(pattern: [0, 500, 100, 500]); // Long = danger
        _tts.speak("Khabar daar! ${analysis.hindiInstruction}");
      } else {
        Vibration.vibrate(duration: 200); // Medium = caution
      }
    };

    final success = await _service.initialize();
    if (success) {
      await _tts.speak(
          "Road crossing assistant chalu. Phone ko road ki taraf rakhein.");
      await _service.startAnalysis();
    } else {
      await _tts.speak("Camera nahi mil raha.");
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _service.dispose();
    _tts.stop();
    super.dispose();
  }

  Color get _statusColor {
    switch (_currentStatus) {
      case 'safe':
        return Colors.green;
      case 'danger':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (_currentStatus) {
      case 'safe':
        return Icons.check_circle_rounded;
      case 'danger':
        return Icons.dangerous_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  String get _statusText {
    switch (_currentStatus) {
      case 'safe':
        return 'SAFE TO CROSS';
      case 'danger':
        return 'DANGER - STOP';
      default:
        return 'CAUTION - WAIT';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.audioBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCameraView()),
            _buildStatusPanel(),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.audioSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.audioText),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Road Crossing",
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.audioText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Status indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(_statusIcon, color: Colors.white, size: 28),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_service.isInitialized || _service.cameraController == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.audioSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.audioPrimary),
              const SizedBox(height: 16),
              Text(
                "Camera loading...",
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.audioTextMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _statusColor, width: 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_service.cameraController!),
          // Analyzing overlay
          if (_service.isAnalyzing)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          // Vehicle detection overlay
          if (_vehicles.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Detected: ${_vehicles.join(', ')}",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_statusIcon, color: _statusColor, size: 32),
              const SizedBox(width: 12),
              Text(
                _statusText,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _instruction,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.audioText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Check now button
          Expanded(
            child: GestureDetector(
              onTap: () async {
                HapticFeedback.heavyImpact();
                await _tts.speak("Checking...");
                await _service.checkNow();
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.audioPrimaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "Check Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Speak instruction button
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              await _tts.speak(_instruction);
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.audioSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: AppColors.audioPrimary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
