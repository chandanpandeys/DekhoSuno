import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:senseplay/providers/settings_provider.dart';
import 'package:senseplay/screens/audio/smart_camera_screen.dart';
import 'package:senseplay/screens/audio/currency_reader_screen.dart';
import 'package:senseplay/screens/audio/guided_walking_screen.dart';
import 'package:senseplay/screens/audio/light_detector_screen.dart';
import 'package:senseplay/screens/audio/reader_screen.dart';
import 'package:senseplay/screens/landing_screen.dart';
import 'package:senseplay/screens/settings_screen.dart';
import 'package:senseplay/services/hardware_service.dart';
import 'package:senseplay/services/voice_command_service.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:senseplay/screens/assistant_screen.dart';
import 'package:vibration/vibration.dart';

/// Premium Audio Mode Home Screen
/// Gesture-based and voice-controlled navigation for visually impaired users
class AudioHomeScreen extends StatefulWidget {
  const AudioHomeScreen({super.key});

  @override
  State<AudioHomeScreen> createState() => _AudioHomeScreenState();
}

class _AudioHomeScreenState extends State<AudioHomeScreen>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  final HardwareService _hardwareService = HardwareService();
  StreamSubscription<bool>? _shakeSubscription;

  late AnimationController _pulseController;
  late AnimationController _breatheController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _breatheAnimation;

  String _currentHint = "Double Tap: Smart Camera";
  DateTime? _lastGestureTime;

  // Voice command state
  bool _isVoiceListening = false;
  bool _isVoiceAwake = false;

  final List<_FeatureInfo> _features = [
    _FeatureInfo(
      name: "Smart Camera",
      icon: Icons.camera_enhance_rounded,
      color: AppColors.audioPrimary,
      gesture: "Double Tap",
      hindiDescription: "Camera se dekhein aur sunein",
      voiceCommand: 'smart_camera',
    ),
    _FeatureInfo(
      name: "Currency Reader",
      icon: Icons.currency_rupee_rounded,
      color: AppColors.audioSecondary,
      gesture: "Long Press",
      hindiDescription: "Note ki pehchaan",
      voiceCommand: 'currency_reader',
    ),
    _FeatureInfo(
      name: "Light Detector",
      icon: Icons.lightbulb_rounded,
      color: const Color(0xFFFF9800),
      gesture: "Swipe Up",
      hindiDescription: "Roshni ki jaankari",
      voiceCommand: 'light_detector',
    ),
    _FeatureInfo(
      name: "Text Reader",
      icon: Icons.document_scanner_rounded,
      color: const Color(0xFF4CAF50),
      gesture: "Swipe Down",
      hindiDescription: "Likha hua padhein",
      voiceCommand: 'text_reader',
    ),
    _FeatureInfo(
      name: "Guided Walking",
      icon: Icons.directions_walk_rounded,
      color: const Color(0xFF9C27B0),
      gesture: "Swipe Left",
      hindiDescription: "Chalne mein madad",
      voiceCommand: 'guided_walking',
    ),
    _FeatureInfo(
      name: "AI Assistant",
      icon: Icons.assistant_rounded,
      color: const Color(0xFF00BCD4),
      gesture: "Swipe Right",
      hindiDescription: "Apna personal assistant",
      voiceCommand: 'assistant',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupShakeDetection();
    _setupVoiceCommands();
    _initTTS();
    _announceMode();
  }

  void _setupShakeDetection() {
    _shakeSubscription = _hardwareService.onShake.listen((_) {
      _triggerSOS(); // Shake triggers SOS emergency
    });
  }

  void _setupVoiceCommands() {
    final voiceService = context.read<VoiceCommandService>();

    voiceService.onCommand = (command) async {
      switch (command) {
        case 'smart_camera':
          await _flutterTts.speak("Camera khol raha hoon");
          _openSmartCamera();
          break;
        case 'currency_reader':
          await _flutterTts.speak("Currency reader khol raha hoon");
          _openCurrencyReader();
          break;
        case 'light_detector':
          await _flutterTts.speak("Light detector khol raha hoon");
          _openLightDetector();
          break;
        case 'text_reader':
          await _flutterTts.speak("Text reader khol raha hoon");
          _openTextReader();
          break;
        case 'guided_walking':
          await _flutterTts.speak("Guided walking khol raha hoon");
          _openGuidedWalking();
          break;
        case 'assistant':
          await _flutterTts.speak("Assistant khol raha hoon");
          _openAssistant();
          break;
        case 'go_back':
        case 'go_home':
          _goToLanding();
          break;
      }
    };

    voiceService.onListeningStateChange = (isListening) {
      if (mounted) {
        setState(() => _isVoiceListening = isListening);
      }
    };

    voiceService.onWakeStateChange = (isAwake) {
      if (mounted) {
        setState(() => _isVoiceAwake = isAwake);
        if (isAwake) {
          Vibration.vibrate(duration: 100);
          _flutterTts.speak("Suniye, kya karna hai?");
        }
      }
    };

    // Start listening for voice commands
    voiceService.startListening(waitForWakeWord: true);
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _announceMode() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await Vibration.vibrate(pattern: [0, 100, 50, 100]);

    // Time-based greeting
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = "Suprabhat";
    } else if (hour < 17) {
      greeting = "Namaskar";
    } else {
      greeting = "Shubh Sandhya";
    }

    await _flutterTts.speak(
      "$greeting! Audio Mode chalu hai. "
      "Double tap se camera, Long press se currency reader, "
      "Upar swipe se light detector, Neeche swipe se text reader. "
      "Ya bolein 'Dekho Suno' aur phir feature ka naam.",
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breatheController.dispose();
    _shakeSubscription?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  void _handleTap() {
    // Single tap - just provide haptic feedback
    HapticFeedback.lightImpact();
  }

  void _triggerSOS() async {
    // Strong SOS vibration pattern (SOS in morse: ... --- ...)
    await Vibration.vibrate(pattern: [
      0, 100, 100, 100, 100, 100, // S: ...
      200, 300, 100, 300, 100, 300, // O: ---
      200, 100, 100, 100, 100, 100, // S: ...
    ]);

    await _flutterTts
        .speak("SOS! Emergency mode activated. Double tap to call for help.");

    if (!mounted) return;

    // Show emergency dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.audioSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.emergency, color: AppColors.audioAccent, size: 32),
            SizedBox(width: 12),
            Text(
              "SOS Emergency",
              style: TextStyle(
                  color: AppColors.audioText, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "आपातकालीन मदद चाहिए?",
              style: TextStyle(color: AppColors.audioText, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "Do you need emergency help?",
              style: TextStyle(color: AppColors.audioTextMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _flutterTts.speak("Cancelled");
            },
            child: Text("Cancel",
                style: TextStyle(color: AppColors.audioTextMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.audioAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await Vibration.vibrate(duration: 500);
              await _flutterTts.speak("Calling emergency services");
              // Call emergency number (112 is India's emergency number)
              // In production, use url_launcher: launchUrl(Uri.parse('tel:112'))
            },
            icon: const Icon(Icons.call),
            label: const Text("Call 112"),
          ),
        ],
      ),
    );
  }

  void _openSmartCamera() {
    _hapticAndSpeak("Smart Camera", "Camera khul raha hai");
    Navigator.of(context).push(
      _createRoute(const SmartCameraScreen()),
    );
  }

  void _openCurrencyReader() {
    _hapticAndSpeak("Currency Reader", "Currency reader khul raha hai");
    Navigator.of(context).push(
      _createRoute(const CurrencyReaderScreen()),
    );
  }

  void _openLightDetector() {
    _hapticAndSpeak("Light Detector", "Light detector khul raha hai");
    Navigator.of(context).push(
      _createRoute(const LightDetectorScreen()),
    );
  }

  void _openTextReader() {
    _hapticAndSpeak("Text Reader", "Text reader khul raha hai");
    Navigator.of(context).push(
      _createRoute(const ReaderScreen()),
    );
  }

  void _openGuidedWalking() {
    _hapticAndSpeak("Guided Walking", "Guided walking khul raha hai");
    Navigator.of(context).push(
      _createRoute(const GuidedWalkingScreen()),
    );
  }

  void _openAssistant() {
    _hapticAndSpeak("AI Assistant", "Assistant khul raha hai");
    Navigator.of(context).push(
      _createRoute(const AssistantScreen()),
    );
  }

  Future<void> _hapticAndSpeak(String feature, String message) async {
    await Vibration.vibrate(duration: 100);
    await _flutterTts.speak(message);
  }

  PageRouteBuilder _createRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: AppAnimations.fast,
    );
  }

  void _updateHint(int index) {
    if (index >= 0 && index < _features.length) {
      setState(() {
        _currentHint = "${_features[index].gesture}: ${_features[index].name}";
      });
    }
  }

  void _goToLanding() async {
    await Vibration.vibrate(pattern: [0, 50, 50, 50]);
    await _flutterTts.speak("Mode selection screen par ja rahe hain");

    if (!mounted) return;
    context.read<SettingsProvider>().clearPreferences();
    Navigator.of(context).pushReplacement(
      _createRoute(const LandingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goToLanding();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.audioBackground,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          onDoubleTap: _openSmartCamera,
          onLongPress: _openCurrencyReader,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -200) {
              _openLightDetector();
            } else if (details.primaryVelocity! > 200) {
              _openTextReader();
            }
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -200) {
              // Swipe left for Guided Walking
              _openGuidedWalking();
            } else if (details.primaryVelocity! > 200) {
              // Swipe right for AI Assistant
              _openAssistant();
            }
          },
          child: Stack(
            children: [
              // Animated background
              _buildAnimatedBackground(),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Top bar with settings
                    _buildTopBar(),

                    // Central pulsing indicator
                    Expanded(
                      child: Center(
                        child: _buildCentralIndicator(),
                      ),
                    ),

                    // Feature hints
                    _buildFeatureHints(),

                    // Bottom gesture guide
                    _buildGestureGuide(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _breatheAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                AppColors.audioPrimary.withOpacity(_breatheAnimation.value),
                AppColors.audioBackground,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.audioPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.audioPrimary.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.audioPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Audio Mode",
                  style: TextStyle(
                    color: AppColors.audioPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Settings and Mode switch buttons
          Row(
            children: [
              // Settings button
              Semantics(
                label: "Settings. Tap to open settings.",
                button: true,
                child: GestureDetector(
                  onTap: () async {
                    await Vibration.vibrate(duration: 50);
                    await _flutterTts.speak("Settings");
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.audioSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.audioText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mode switch button
              Semantics(
                label: "Switch mode. Tap to change mode.",
                button: true,
                child: GestureDetector(
                  onTap: _goToLanding,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.audioSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.audioText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCentralIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.audioPrimary,
                  AppColors.audioPrimary.withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.audioPrimary.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hearing_rounded,
                  size: 64,
                  color: AppColors.audioBackground,
                ),
                SizedBox(height: 8),
                Text(
                  "सुनो",
                  style: TextStyle(
                    fontFamily: 'Noto Sans Devanagari',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.audioBackground,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureHints() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.audioSurface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: Column(
        children: _features
            .map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: feature.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          feature.icon,
                          color: feature.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feature.name,
                              style: const TextStyle(
                                color: AppColors.audioText,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              feature.hindiDescription,
                              style: const TextStyle(
                                color: AppColors.audioTextMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: feature.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          feature.gesture,
                          style: TextStyle(
                            color: feature.color,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildGestureGuide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.vibration_rounded,
            color: AppColors.audioAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            "Shake phone for SOS",
            style: TextStyle(
              color: AppColors.audioAccent.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String gesture;
  final String hindiDescription;
  final String voiceCommand;

  _FeatureInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.gesture,
    required this.hindiDescription,
    required this.voiceCommand,
  });
}
