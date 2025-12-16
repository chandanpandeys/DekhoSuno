import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:senseplay/services/hardware_service.dart';

/// Premium Light Detector Screen
/// Real-time light level monitoring for visually impaired users
class LightDetectorScreen extends StatefulWidget {
  const LightDetectorScreen({super.key});

  @override
  State<LightDetectorScreen> createState() => _LightDetectorScreenState();
}

class _LightDetectorScreenState extends State<LightDetectorScreen>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  StreamSubscription<int>? _lightSubscription;

  int _currentLux = 0;
  String _status = "Checking...";
  Color _statusColor = AppColors.audioPrimary;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_LightLevel> _levels = [
    _LightLevel(
      name: "अंधेरा",
      english: "Dark",
      threshold: 0,
      color: const Color(0xFF1E1E2E),
      icon: Icons.nightlight_round,
    ),
    _LightLevel(
      name: "धुंधला",
      english: "Dim",
      threshold: 20,
      color: const Color(0xFF4A4A6A),
      icon: Icons.brightness_low,
    ),
    _LightLevel(
      name: "सामान्य",
      english: "Normal",
      threshold: 100,
      color: const Color(0xFFFFB300),
      icon: Icons.brightness_medium,
    ),
    _LightLevel(
      name: "उजाला",
      english: "Bright",
      threshold: 500,
      color: const Color(0xFFFFD54F),
      icon: Icons.brightness_high,
    ),
    _LightLevel(
      name: "बहुत तेज़!",
      english: "Very Bright",
      threshold: 1000,
      color: const Color(0xFFFFFFFF),
      icon: Icons.wb_sunny,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initTTS();
    _startListening();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts
        .speak("Light Detector chalu. Tap karein status sunne ke liye.");
  }

  void _startListening() {
    // Create local instance instead of using Provider to avoid dependency issues
    final hardwareService = HardwareService();
    _lightSubscription = hardwareService.lightLevel.listen((lux) {
      if (!mounted) return;

      setState(() {
        _currentLux = lux;
        _updateStatus(lux);
      });
    });
  }

  void _updateStatus(int lux) {
    _LightLevel current = _levels.first;

    for (final level in _levels) {
      if (lux >= level.threshold) {
        current = level;
      }
    }

    _status = "${current.name} (${current.english})";
    _statusColor = current.color;
  }

  Future<void> _announceStatus() async {
    HapticFeedback.mediumImpact();
    await _flutterTts.speak("$_status. $_currentLux lux.");
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lightSubscription?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate background opacity based on light level
    final backgroundOpacity = (_currentLux / 1000).clamp(0.1, 1.0);

    return Scaffold(
      backgroundColor: AppColors.audioBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _announceStatus,
        child: Stack(
          children: [
            // Animated background
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    _statusColor.withAlpha((backgroundOpacity * 255).toInt()),
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
                  Expanded(child: _buildCentralIndicator()),
                  _buildLevelIndicator(),
                  _buildBottomInfo(),
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
          Semantics(
            label: "Go back",
            button: true,
            child: GestureDetector(
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
                  "Light Detector",
                  style: TextStyle(
                    color: AppColors.audioText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Real-time light level",
                  style: TextStyle(
                    color: AppColors.audioTextMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Lux reading
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor.withAlpha(50),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor.withAlpha(100)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, color: _statusColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  "$_currentLux lux",
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralIndicator() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _statusColor,
                    _statusColor.withAlpha(100),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _statusColor.withAlpha(150),
                    blurRadius: 50,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getLevelIcon(),
                    size: 64,
                    color: _currentLux > 500
                        ? AppColors.audioBackground
                        : AppColors.audioText,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _currentLux > 500
                          ? AppColors.audioBackground
                          : AppColors.audioText,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getLevelIcon() {
    for (final level in _levels.reversed) {
      if (_currentLux >= level.threshold) {
        return level.icon;
      }
    }
    return _levels.first.icon;
  }

  Widget _buildLevelIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.audioSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Light Scale",
            style: TextStyle(
              color: AppColors.audioTextMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          // Level bar
          Stack(
            children: [
              // Background gradient
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: _levels.map((l) => l.color).toList(),
                  ),
                ),
              ),
              // Current position indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                left: ((_currentLux / 1500) *
                        (MediaQuery.of(context).size.width - 88))
                    .clamp(0, MediaQuery.of(context).size.width - 88),
                child: Container(
                  width: 16,
                  height: 16,
                  transform: Matrix4.translationValues(-8, -2, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _statusColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withAlpha(150),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Level labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _levels
                .map((level) => Text(
                      level.english,
                      style: TextStyle(
                        color: level.color,
                        fontSize: 10,
                        fontWeight: _status.contains(level.english)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.audioSurface,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_rounded,
                color: AppColors.audioPrimary, size: 20),
            const SizedBox(width: 8),
            const Text(
              "Tap anywhere to hear light level",
              style: TextStyle(color: AppColors.audioTextMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightLevel {
  final String name;
  final String english;
  final int threshold;
  final Color color;
  final IconData icon;

  _LightLevel({
    required this.name,
    required this.english,
    required this.threshold,
    required this.color,
    required this.icon,
  });
}
