import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:senseplay/screens/visual_mode_screen.dart';
import 'package:senseplay/screens/audio_mode_screen.dart';
import 'package:senseplay/utils/semantics_helper.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _navigateToVisualMode(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VisualModeScreen()),
    );
  }

  void _navigateToAudioMode(BuildContext context) {
    HapticFeedback.heavyImpact();
    SemanticsHelper.announce("Entering Audio Mode");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AudioModeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          "Welcome to\nSensePlay",
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Choose your mode to get started",
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 40),

                        // Visual Mode Card
                        Expanded(
                          child: _ModeCard(
                            title: "Visual Mode",
                            subtitle: "For Hearing Impaired",
                            icon: Icons.visibility_rounded,
                            color: Colors.teal,
                            onTap: () => _navigateToVisualMode(context),
                            semanticsLabel:
                                "Visual Mode for Hearing Impaired. Tap to enter.",
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Audio Mode Card
                        Expanded(
                          child: _ModeCard(
                            title: "Audio Mode",
                            subtitle: "For Visually Impaired",
                            icon: Icons.hearing_rounded,
                            color: Colors.deepPurple,
                            onTap: () => _navigateToAudioMode(context),
                            onDoubleTap: () => _navigateToAudioMode(context),
                            semanticsLabel:
                                "Audio Mode for Visually Impaired. Double tap to enter.",
                            isAudioMode: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final String semanticsLabel;
  final bool isAudioMode;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.onDoubleTap,
    required this.semanticsLabel,
    this.isAudioMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 32, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    if (isAudioMode) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app,
                                size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Double Tap",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
