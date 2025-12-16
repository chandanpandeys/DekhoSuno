import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:vibration/vibration.dart';

/// Premium Sound Watch Screen
/// Beautiful visualization of ambient sounds for hearing impaired users
class SoundWatchScreen extends StatefulWidget {
  const SoundWatchScreen({super.key});

  @override
  State<SoundWatchScreen> createState() => _SoundWatchScreenState();
}

class _SoundWatchScreenState extends State<SoundWatchScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  double _soundLevel = 0.0;
  String _detectedSound = "Quiet";
  Color _currentColor = AppColors.success;
  List<String> _soundHistory = [];

  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<_SoundLevel> _levels = [
    _SoundLevel(name: "Quiet", threshold: 0, color: AppColors.success),
    _SoundLevel(name: "Background", threshold: 3, color: Color(0xFF22D3EE)),
    _SoundLevel(name: "Talking", threshold: 5, color: AppColors.warning),
    _SoundLevel(name: "Loud", threshold: 8, color: Color(0xFFF97316)),
    _SoundLevel(name: "VERY LOUD!", threshold: 12, color: AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initSpeech();
  }

  void _setupAnimations() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Status: $status'),
      onError: (error) => debugPrint('Error: $error'),
    );

    if (available) {
      setState(() {
        _isListening = true;
      });
      _startListening();
    }
  }

  void _startListening() {
    if (!mounted) return;

    _speech.listen(
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() {
          _soundLevel = level.clamp(0, 20);
        });
        _classifySound(level);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      listenMode: ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );

    // Auto-restart listening when it stops
    _speech.statusListener = (status) {
      if (status == 'done' || status == 'notListening') {
        if (mounted && _isListening) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _startListening();
          });
        }
      }
    };
  }

  void _classifySound(double level) {
    String newSound = _levels.first.name;
    Color newColor = _levels.first.color;

    for (final soundLevel in _levels) {
      if (level >= soundLevel.threshold) {
        newSound = soundLevel.name;
        newColor = soundLevel.color;
      }
    }

    if (newSound != _detectedSound) {
      setState(() {
        _detectedSound = newSound;
        _currentColor = newColor;

        // Add to history
        final timestamp = DateTime.now();
        final timeStr =
            "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}";
        _soundHistory.insert(0, "$timeStr - $newSound");
        if (_soundHistory.length > 10) {
          _soundHistory.removeLast();
        }
      });

      // Haptic feedback for loud sounds
      if (level > 8) {
        Vibration.vibrate(duration: 200);
        _pulseController.forward().then((_) => _pulseController.reverse());
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _pulseController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.visualBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Main visualization
            Expanded(
              child: _buildVisualization(),
            ),

            // Sound level indicators
            _buildLevelIndicators(),

            // History
            _buildHistory(),
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
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.visualSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.small,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.visualText,
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
                Text(
                  "Sound Watch",
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.visualText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Visualize sounds around you",
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.visualTextMuted,
                  ),
                ),
              ],
            ),
          ),

          // Listening status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isListening
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isListening
                    ? AppColors.success.withOpacity(0.3)
                    : AppColors.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isListening ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isListening ? "Listening" : "Off",
                  style: TextStyle(
                    color: _isListening ? AppColors.success : AppColors.error,
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

  Widget _buildVisualization() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated wave rings
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                final delay = index * 0.3;
                final progress = (_waveController.value + delay) % 1.0;
                final size = 100 + (progress * (100 + _soundLevel * 5));
                final opacity = (1 - progress) * 0.3;

                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _currentColor.withOpacity(opacity),
                      width: 2,
                    ),
                  ),
                );
              },
            );
          }),

          // Main circle
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 150 + _soundLevel * 5,
                  height: 150 + _soundLevel * 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _currentColor.withOpacity(0.8),
                        _currentColor.withOpacity(0.4),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _currentColor.withOpacity(0.4),
                        blurRadius: 30 + _soundLevel * 2,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.graphic_eq_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _detectedSound,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLevelIndicators() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.visualSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sound Level",
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.visualText,
            ),
          ),
          const SizedBox(height: 12),

          // Level bar
          Stack(
            children: [
              // Background
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors:
                        _levels.map((l) => l.color.withOpacity(0.3)).toList(),
                  ),
                ),
              ),

              // Active level
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: 12,
                width: ((_soundLevel / 15) * MediaQuery.of(context).size.width -
                        64)
                    .clamp(0, MediaQuery.of(context).size.width - 64),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _currentColor,
                  boxShadow: [
                    BoxShadow(
                      color: _currentColor.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Level labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _levels
                .map((level) => Text(
                      level.name,
                      style: TextStyle(
                        color: level.color,
                        fontSize: 10,
                        fontWeight: level.name == _detectedSound
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

  Widget _buildHistory() {
    return Container(
      height: 140,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.visualSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Sounds",
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.visualText,
                ),
              ),
              Icon(
                Icons.history_rounded,
                color: AppColors.visualTextMuted,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _soundHistory.isEmpty
                ? Center(
                    child: Text(
                      "Sound events will appear here",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.visualTextMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _soundHistory.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _soundHistory[index],
                          style: TextStyle(
                            color: index == 0
                                ? AppColors.visualText
                                : AppColors.visualTextMuted,
                            fontSize: 12,
                            fontWeight: index == 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SoundLevel {
  final String name;
  final double threshold;
  final Color color;

  _SoundLevel({
    required this.name,
    required this.threshold,
    required this.color,
  });
}
