import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:senseplay/providers/settings_provider.dart';
import 'package:senseplay/providers/dynamic_theme_provider.dart';
import 'package:senseplay/screens/audio/home_screen.dart';
import 'package:senseplay/screens/visual/home_screen.dart';
import 'package:senseplay/services/voice_command_service.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:senseplay/widgets/interactive_widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

/// Premium Landing Screen - "The Switch"
/// An immersive, accessible mode selection experience with voice commands
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();

  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _voiceGlowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _voiceGlowAnimation;

  bool _hasSpoken = false;
  bool _isVoiceListening = false;
  bool _isVoiceAwake = false;
  String _voiceHint = 'Say "Dekho Suno" to activate voice';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _speakIntro();
    _setupVoiceCommands();
  }

  void _setupAnimations() {
    // Pulsing animation for icons
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Floating animation for the divider
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Voice glow animation
    _voiceGlowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _voiceGlowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _voiceGlowController, curve: Curves.easeInOut),
    );
  }

  void _setupVoiceCommands() {
    final voiceService = context.read<VoiceCommandService>();

    // Set up mode selection callback
    voiceService.onModeSelect = (mode) {
      if (mode == 'visual_mode') {
        _selectVisualMode();
      } else if (mode == 'audio_mode') {
        _selectAudioMode();
      }
    };

    // Set up listening state callback
    voiceService.onListeningStateChange = (isListening) {
      if (mounted) {
        setState(() {
          _isVoiceListening = isListening;
          if (isListening) {
            _voiceGlowController.repeat(reverse: true);
          } else {
            _voiceGlowController.stop();
            _voiceGlowController.reset();
          }
        });
      }
    };

    // Set up wake state callback
    voiceService.onWakeStateChange = (isAwake) {
      if (mounted) {
        setState(() {
          _isVoiceAwake = isAwake;
          if (isAwake) {
            _voiceHint = 'Say "Dekho" or "Suno"';
            HapticFeedback.mediumImpact();
          } else {
            _voiceHint = 'Say "Dekho Suno" to activate voice';
          }
        });
      }
    };

    // Start listening for wake word
    voiceService.startListening(waitForWakeWord: true);
  }

  Future<void> _speakIntro() async {
    if (_hasSpoken) return;
    _hasSpoken = true;

    await Future.delayed(const Duration(milliseconds: 500));
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(
      "Namaste! DekhoSuno mein aapka swagat hai. "
      "Agar aap dekh kar app use karna chahte hain, toh upar waale hisse ko dabayein, "
      "ya bolein 'Dekho'. "
      "Agar aap sun kar app use karna chahte hain, toh neeche waale hisse ko dabayein, "
      "ya bolein 'Suno'.",
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _voiceGlowController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _selectVisualMode() {
    HapticFeedback.lightImpact();
    _flutterTts.stop();
    _flutterTts.speak("Visual Mode selected!");

    // Stop voice listening when navigating
    context.read<VoiceCommandService>().stopListening();

    context.read<SettingsProvider>().setAppMode(AppMode.visual);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const VisualHomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: AppAnimations.normal,
      ),
    );
  }

  void _selectAudioMode() async {
    // Strong haptic pattern for audio mode
    await Vibration.vibrate(pattern: [0, 100, 50, 100]);
    _flutterTts.stop();
    await _flutterTts.speak("Audio Mode chalu ho raha hai!");

    // Stop voice listening when navigating
    if (mounted) {
      context.read<VoiceCommandService>().stopListening();
    }

    if (!mounted) return;
    context.read<SettingsProvider>().setAppMode(AppMode.audio);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AudioHomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: AppAnimations.normal,
      ),
    );
  }

  void _toggleVoiceListening() async {
    final voiceService = context.read<VoiceCommandService>();

    if (_isVoiceListening) {
      await voiceService.stopListening();
    } else {
      await voiceService.startListening(waitForWakeWord: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Visual Mode (Top Half) - Light Theme
              Expanded(
                child: _buildModeSection(
                  onTap: _selectVisualMode,
                  gradient: AppColors.landingTopGradient,
                  icon: Icons.visibility_rounded,
                  iconColor: AppColors.visualPrimary,
                  hindiTitle: "देखो",
                  englishSubtitle: "Visual Mode",
                  description: "For hearing impaired",
                  voiceCommand: '"Dekho"',
                  isTop: true,
                ),
              ),

              // Animated Divider with Voice Indicator
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.visualPrimary.withOpacity(0.5),
                            AppColors.audioPrimary.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.audioPrimary.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Audio Mode (Bottom Half) - Dark Theme
              Expanded(
                child: _buildModeSection(
                  onTap: _selectAudioMode,
                  gradient: AppColors.landingBottomGradient,
                  icon: Icons.hearing_rounded,
                  iconColor: AppColors.audioPrimary,
                  hindiTitle: "सुनो",
                  englishSubtitle: "Audio Mode",
                  description: "For visually impaired",
                  voiceCommand: '"Suno"',
                  isTop: false,
                ),
              ),
            ],
          ),

          // Voice Command Floating Indicator
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _toggleVoiceListening,
                child: AnimatedBuilder(
                  animation: _voiceGlowAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _isVoiceAwake
                            ? AppColors.success.withOpacity(0.9)
                            : _isVoiceListening
                                ? AppColors.audioPrimary.withOpacity(0.9)
                                : AppColors.audioSurface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: _isVoiceListening
                            ? [
                                BoxShadow(
                                  color: (_isVoiceAwake
                                          ? AppColors.success
                                          : AppColors.audioPrimary)
                                      .withOpacity(_voiceGlowAnimation.value),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                        border: Border.all(
                          color: _isVoiceAwake
                              ? AppColors.success
                              : _isVoiceListening
                                  ? AppColors.audioPrimary
                                  : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _isVoiceAwake
                                  ? Icons.check_circle
                                  : _isVoiceListening
                                      ? Icons.mic
                                      : Icons.mic_none,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _voiceHint,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSection({
    required VoidCallback onTap,
    required LinearGradient gradient,
    required IconData icon,
    required Color iconColor,
    required String hindiTitle,
    required String englishSubtitle,
    required String description,
    required String voiceCommand,
    required bool isTop,
  }) {
    final isDark = !isTop;

    return Semantics(
      label:
          '$englishSubtitle. $description. Tap or say $voiceCommand to select.',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: iconColor.withOpacity(0.2),
          highlightColor: iconColor.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(gradient: gradient),
            child: Stack(
              children: [
                // Decorative circles
                ..._buildDecorativeCircles(iconColor, isDark),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Icon
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    iconColor.withOpacity(0.2),
                                    iconColor.withOpacity(0.05),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: iconColor.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                size: 72,
                                color: iconColor,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Hindi Title
                      Text(
                        hindiTitle,
                        style: TextStyle(
                          fontFamily: 'Noto Sans Devanagari',
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.visualText,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // English Subtitle
                      Text(
                        englishSubtitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: iconColor,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Description
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white54
                              : AppColors.visualTextMuted,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tap and Voice hint
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tap hint
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: iconColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 16,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Tap",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: iconColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            "or",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.visualTextMuted,
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Voice hint
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: iconColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mic_rounded,
                                  size: 16,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  voiceCommand,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: iconColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDecorativeCircles(Color color, bool isDark) {
    return [
      // Top-left circle
      Positioned(
        top: -50,
        left: -50,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(isDark ? 0.1 : 0.05),
          ),
        ),
      ),
      // Bottom-right circle
      Positioned(
        bottom: -30,
        right: -30,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(isDark ? 0.08 : 0.04),
          ),
        ),
      ),
    ];
  }
}
