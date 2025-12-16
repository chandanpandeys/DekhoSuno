import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:senseplay/theme/app_theme.dart';

/// Premium accessible widgets for DekhoSuno app

// ============================================================================
// GLASSMORPHIC CARD
// ============================================================================

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool isDark;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
    this.isDark = false,
    this.borderRadius = AppRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.glassBlack,
                  AppColors.glassBlack.withOpacity(0.2),
                ]
              : [
                  AppColors.glassWhite,
                  AppColors.glassWhite.withOpacity(0.1),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? AppColors.glassBorder
              : AppColors.glassBorder.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: AppShadows.medium,
      ),
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    if (onTap != null) {
      return Semantics(
        label: semanticLabel,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap!();
            },
            borderRadius: BorderRadius.circular(borderRadius),
            child: card,
          ),
        ),
      );
    }

    return Semantics(
      label: semanticLabel,
      child: card,
    );
  }
}

// ============================================================================
// FEATURE CARD (For home screens)
// ============================================================================

class FeatureCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDark;

  const FeatureCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isDark = false,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
    return Semantics(
      label: '${widget.title}. ${widget.subtitle ?? ''}',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark
                  ? AppColors.audioSurface
                  : AppColors.visualSurface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppShadows.medium,
              border: Border.all(
                color: widget.iconColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.iconColor.withOpacity(0.2),
                        widget.iconColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 40,
                    color: widget.iconColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge.copyWith(
                    color: widget.isDark
                        ? AppColors.audioText
                        : AppColors.visualText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: widget.isDark
                          ? AppColors.audioTextMuted
                          : AppColors.visualTextMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// VOICE BUTTON (Announces itself on tap)
// ============================================================================

class VoiceButton extends StatefulWidget {
  final String label;
  final String? voiceLabel;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isDark;

  const VoiceButton({
    super.key,
    required this.label,
    this.voiceLabel,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isDark = true,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('hi-IN');
  }

  Future<void> _handleTap() async {
    HapticFeedback.mediumImpact();
    await _tts.speak(widget.voiceLabel ?? widget.label);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isPrimary
        ? (widget.isDark ? AppColors.audioPrimary : AppColors.visualPrimary)
        : (widget.isDark ? AppColors.audioSurface : AppColors.visualSurface);

    final foregroundColor = widget.isPrimary
        ? (widget.isDark ? AppColors.audioBackground : Colors.white)
        : (widget.isDark ? AppColors.audioText : AppColors.visualText);

    return Semantics(
      label: widget.voiceLabel ?? widget.label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: widget.isPrimary ? AppShadows.medium : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: foregroundColor, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  widget.label,
                  style: AppTypography.labelLarge.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PULSING INDICATOR
// ============================================================================

class PulsingIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final IconData? icon;

  const PulsingIndicator({
    super.key,
    this.color = AppColors.audioPrimary,
    this.size = 100,
    this.icon,
  });

  @override
  State<PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(0.8),
                widget.color.withOpacity(0.3),
              ],
            ),
            boxShadow: AppShadows.glow(widget.color),
          ),
          child: widget.icon != null
              ? Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.size * 0.4,
                )
              : null,
        );
      },
    );
  }
}

// ============================================================================
// GESTURE HINT OVERLAY
// ============================================================================

class GestureHintOverlay extends StatelessWidget {
  final List<GestureHint> hints;
  final bool isDark;

  const GestureHintOverlay({
    super.key,
    required this.hints,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.audioSurface.withOpacity(0.95)
            : AppColors.visualSurface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: hints
            .map((hint) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: hint.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(hint.icon, color: hint.color, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hint.gesture,
                              style: AppTypography.labelLarge.copyWith(
                                color: isDark
                                    ? AppColors.audioText
                                    : AppColors.visualText,
                              ),
                            ),
                            Text(
                              hint.action,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.audioTextMuted
                                    : AppColors.visualTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class GestureHint {
  final IconData icon;
  final String gesture;
  final String action;
  final Color color;

  const GestureHint({
    required this.icon,
    required this.gesture,
    required this.action,
    this.color = AppColors.audioPrimary,
  });
}

// ============================================================================
// ANIMATED GRADIENT BACKGROUND
// ============================================================================

class AnimatedGradientBackground extends StatefulWidget {
  final List<Color> colors;
  final Widget child;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.colors,
    required this.child,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _topAlignment;
  late Animation<Alignment> _bottomAlignment;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _topAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 1,
      ),
    ]).animate(_controller);

    _bottomAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 1,
      ),
    ]).animate(_controller);
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
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.colors,
              begin: _topAlignment.value,
              end: _bottomAlignment.value,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ============================================================================
// STATUS CHIP
// ============================================================================

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isActive;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: isActive ? color : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isActive ? color : Colors.grey,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isActive ? color : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
