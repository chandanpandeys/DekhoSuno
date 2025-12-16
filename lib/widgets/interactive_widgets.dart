import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:senseplay/theme/app_theme.dart';

/// ============================================================================
/// PULSE BUTTON - Animated press effect with glow
/// ============================================================================
class PulseButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color glowColor;
  final double size;
  final bool isActive;

  const PulseButton({
    super.key,
    required this.child,
    required this.onTap,
    this.glowColor = AppColors.audioPrimary,
    this.size = 64,
    this.isActive = false,
  });

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isActive ? _scaleAnimation.value : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: widget.glowColor
                              .withOpacity(_glowAnimation.value),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================================
/// RIPPLE CARD - Touch ripple with scale animation
/// ============================================================================
class RippleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color rippleColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const RippleCard({
    super.key,
    required this.child,
    required this.onTap,
    this.rippleColor = AppColors.visualPrimary,
    this.borderRadius,
    this.padding,
  });

  @override
  State<RippleCard> createState() => _RippleCardState();
}

class _RippleCardState extends State<RippleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      setState(() => _isPressed = false);
    });
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse().then((_) {
      setState(() => _isPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: widget.rippleColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================================
/// VOICE INDICATOR - Visual feedback for voice listening state
/// ============================================================================
class VoiceIndicator extends StatefulWidget {
  final bool isListening;
  final bool isAwake;
  final Color primaryColor;
  final double size;

  const VoiceIndicator({
    super.key,
    required this.isListening,
    required this.isAwake,
    this.primaryColor = AppColors.audioPrimary,
    this.size = 80,
  });

  @override
  State<VoiceIndicator> createState() => _VoiceIndicatorState();
}

class _VoiceIndicatorState extends State<VoiceIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoiceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    } else {
      _pulseController.stop();
      _waveController.stop();
      _pulseController.reset();
      _waveController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isAwake ? AppColors.success : widget.primaryColor;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          if (widget.isListening)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Wave rings
          if (widget.isListening)
            ...List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  final delay = index * 0.3;
                  final progress = (_waveController.value + delay) % 1.0;
                  return Transform.scale(
                    scale: 0.5 + progress * 0.8,
                    child: Opacity(
                      opacity: (1.0 - progress) * 0.5,
                      child: Container(
                        width: widget.size * 0.6,
                        height: widget.size * 0.6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

          // Center icon
          Container(
            width: widget.size * 0.5,
            height: widget.size * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color,
                  color.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              widget.isAwake ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: widget.size * 0.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// BREATHING ICON - Idle animation for icons
/// ============================================================================
class BreathingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final Duration duration;

  const BreathingIcon({
    super.key,
    required this.icon,
    this.color = AppColors.audioPrimary,
    this.size = 48,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<BreathingIcon> createState() => _BreathingIconState();
}

class _BreathingIconState extends State<BreathingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(
              widget.icon,
              color: widget.color,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

/// ============================================================================
/// INTERACTIVE FEATURE CARD - Enhanced card with animations
/// ============================================================================
class InteractiveFeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isHighlighted;

  const InteractiveFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  State<InteractiveFeatureCard> createState() => _InteractiveFeatureCardState();
}

class _InteractiveFeatureCardState extends State<InteractiveFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    Future.delayed(const Duration(milliseconds: 100), () {
      _controller.reverse().then((_) {
        if (mounted) setState(() => _isPressed = false);
      });
    });
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _isPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.title}. ${widget.subtitle}. Tap to open.',
      button: true,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.visualSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    if (_isPressed || widget.isHighlighted)
                      BoxShadow(
                        color: widget.accentColor
                            .withOpacity(0.3 + (_glowAnimation.value * 0.2)),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                  border: widget.isHighlighted
                      ? Border.all(
                          color: widget.accentColor.withOpacity(0.5),
                          width: 2,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Background gradient accent
                    Positioned(
                      top: -20,
                      right: -20,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isPressed ? 120 : 100,
                        height: _isPressed ? 120 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: widget.gradient,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accentColor
                                  .withOpacity(_isPressed ? 0.5 : 0.3),
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
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(_isPressed ? 14 : 12),
                            decoration: BoxDecoration(
                              gradient: widget.gradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.accentColor
                                      .withOpacity(_isPressed ? 0.6 : 0.4),
                                  blurRadius: _isPressed ? 16 : 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          const Spacer(),

                          // Title
                          Text(
                            widget.title,
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.visualText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Subtitle
                          Text(
                            widget.subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.visualTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow indicator with animation
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(_isPressed ? 10 : 8),
                        decoration: BoxDecoration(
                          color: widget.accentColor
                              .withOpacity(_isPressed ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: widget.accentColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ============================================================================
/// FLOATING ACTION INDICATOR - For showing voice command hints
/// ============================================================================
class FloatingActionIndicator extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const FloatingActionIndicator({
    super.key,
    required this.text,
    required this.icon,
    this.color = AppColors.audioPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
