import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:senseplay/providers/settings_provider.dart';
import 'package:senseplay/screens/landing_screen.dart';
import 'package:senseplay/screens/settings_screen.dart';
import 'package:senseplay/screens/visual/call_assistant_screen.dart';
import 'package:senseplay/screens/visual/live_subtitles_screen.dart';
import 'package:senseplay/screens/visual/sign_world_screen.dart';
import 'package:senseplay/screens/visual/sound_watch_screen.dart';
import 'package:senseplay/screens/assistant_screen.dart';
import 'package:senseplay/services/hardware_service.dart';
import 'package:senseplay/services/voice_command_service.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:senseplay/widgets/interactive_widgets.dart';

/// Premium Visual Mode Home Screen
/// Modern dashboard for hearing impaired users with voice commands
class VisualHomeScreen extends StatefulWidget {
  const VisualHomeScreen({super.key});

  @override
  State<VisualHomeScreen> createState() => _VisualHomeScreenState();
}

class _VisualHomeScreenState extends State<VisualHomeScreen>
    with TickerProviderStateMixin {
  final HardwareService _hardwareService = HardwareService();
  StreamSubscription<bool>? _shakeSubscription;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late List<Animation<double>> _cardAnimations;

  bool _isVoiceListening = false;
  int _highlightedFeature = -1;

  final List<_FeatureItem> _features = [
    _FeatureItem(
      title: "Live Subtitles",
      subtitle: "Real-time speech to text",
      icon: Icons.subtitles_rounded,
      color: AppColors.visualPrimary,
      gradient: const LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      voiceCommand: 'live_subtitles',
    ),
    _FeatureItem(
      title: "Sound Watch",
      subtitle: "Visualize ambient sounds",
      icon: Icons.graphic_eq_rounded,
      color: AppColors.visualSecondary,
      gradient: const LinearGradient(
        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      voiceCommand: 'sound_watch',
    ),
    _FeatureItem(
      title: "Call Assistant",
      subtitle: "Caption your calls",
      icon: Icons.phone_in_talk_rounded,
      color: AppColors.visualAccent,
      gradient: const LinearGradient(
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      voiceCommand: 'call_assistant',
    ),
    _FeatureItem(
      title: "Sign World",
      subtitle: "Learn sign language",
      icon: Icons.sign_language_rounded,
      color: const Color(0xFF8B5CF6),
      gradient: const LinearGradient(
        colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      voiceCommand: 'sign_world',
    ),
    _FeatureItem(
      title: "AI Assistant",
      subtitle: "Your personal helper",
      icon: Icons.assistant_rounded,
      color: const Color(0xFF00BCD4),
      gradient: const LinearGradient(
        colors: [Color(0xFF00BCD4), Color(0xFF26A69A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      voiceCommand: 'assistant',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupShakeDetection();
    _setupVoiceCommands();
  }

  void _setupShakeDetection() {
    _shakeSubscription = _hardwareService.onShake.listen((_) {
      _goToLanding();
    });
  }

  void _setupVoiceCommands() {
    final voiceService = context.read<VoiceCommandService>();

    voiceService.onCommand = (command) {
      switch (command) {
        case 'live_subtitles':
          _highlightAndNavigate(0);
          break;
        case 'sound_watch':
          _highlightAndNavigate(1);
          break;
        case 'call_assistant':
          _highlightAndNavigate(2);
          break;
        case 'sign_world':
          _highlightAndNavigate(3);
          break;
        case 'assistant':
          _highlightAndNavigate(4);
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

    // Start listening
    voiceService.startListening(waitForWakeWord: true);
  }

  void _highlightAndNavigate(int index) {
    setState(() => _highlightedFeature = index);
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _highlightedFeature = -1);
        _navigateToFeature(index);
      }
    });
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimations = List.generate(
      _features.length,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _slideController,
          curve: Interval(
            index * 0.15,
            0.4 + index * 0.15,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _shakeSubscription?.cancel();
    super.dispose();
  }

  void _navigateToFeature(int index) {
    HapticFeedback.mediumImpact();

    Widget screen;
    switch (index) {
      case 0: // Live Subtitles
        screen = const LiveSubtitlesScreen();
        break;
      case 1: // Sound Watch
        screen = const SoundWatchScreen();
        break;
      case 2: // Call Assistant
        screen = const CallAssistantScreen();
        break;
      case 3: // Sign World
        screen = const SignWorldScreen();
        break;
      case 4: // AI Assistant
        screen = const AssistantScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
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

  void _goToLanding() {
    HapticFeedback.selectionClick();
    context.read<SettingsProvider>().clearPreferences();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
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
        backgroundColor: AppColors.visualBackground,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),

                // Welcome message
                _buildWelcomeSection(),

                // Feature grid
                Expanded(
                  child: _buildFeatureGrid(),
                ),

                // Bottom info
                _buildBottomInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and mode indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.visualPrimaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.small,
                ),
                child: const Icon(
                  Icons.visibility_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "DekhoSuno",
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.visualText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.visualPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Visual Mode",
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.visualPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Action buttons
          Row(
            children: [
              _buildIconButton(
                icon: Icons.swap_horiz_rounded,
                onTap: _goToLanding,
                tooltip: "Switch Mode",
              ),
              const SizedBox(width: 8),
              _buildIconButton(
                icon: Icons.settings_rounded,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                tooltip: "Settings",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.visualSurface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.small,
            ),
            child: Icon(
              icon,
              color: AppColors.visualTextMuted,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = "Good Morning";
    } else if (hour < 17) {
      greeting = "Good Afternoon";
    } else {
      greeting = "Good Evening";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.visualText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Ready to assist you today",
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.visualTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.95,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _features.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _cardAnimations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _cardAnimations[index].value)),
                child: Opacity(
                  opacity: _cardAnimations[index].value,
                  child: child,
                ),
              );
            },
            child: _buildFeatureCard(index),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(int index) {
    final feature = _features[index];

    return Semantics(
      label: '${feature.title}. ${feature.subtitle}. Tap to open.',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToFeature(index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.visualSurface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.medium,
            ),
            child: Stack(
              children: [
                // Background gradient accent
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: feature.gradient,
                      boxShadow: [
                        BoxShadow(
                          color: feature.color.withOpacity(0.3),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Icon container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: feature.gradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: feature.color.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          feature.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                      const Spacer(),

                      // Title
                      Text(
                        feature.title,
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.visualText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        feature.subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.visualTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow indicator - positioned higher to avoid overlap
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: feature.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: feature.color,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.visualPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.visualPrimary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.visualPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.visualPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Quick Tip",
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.visualPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Shake your phone anytime to return to mode selection",
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.visualTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final String voiceCommand;

  _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.voiceCommand,
  });
}
