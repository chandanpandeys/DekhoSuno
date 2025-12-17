import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Swipe Gesture Wrapper with Animations and Haptic Feedback
/// Provides a more tactile, realistic swipe experience for accessibility features
class SwipeGestureWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final bool enableHaptics;
  final double swipeThreshold;

  const SwipeGestureWrapper({
    super.key,
    required this.child,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.enableHaptics = true,
    this.swipeThreshold = 100.0,
  });

  @override
  State<SwipeGestureWrapper> createState() => _SwipeGestureWrapperState();
}

class _SwipeGestureWrapperState extends State<SwipeGestureWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _feedbackAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _dragOffset = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final dx = _dragOffset.dx.abs();
    final dy = _dragOffset.dy.abs();

    // Check if swipe meets threshold
    if (dx > widget.swipeThreshold ||
        dy > widget.swipeThreshold ||
        velocity.distance > 500) {
      if (dx > dy) {
        // Horizontal swipe
        if (_dragOffset.dx > 0 && widget.onSwipeRight != null) {
          _triggerSwipe(widget.onSwipeRight!);
        } else if (_dragOffset.dx < 0 && widget.onSwipeLeft != null) {
          _triggerSwipe(widget.onSwipeLeft!);
        }
      } else {
        // Vertical swipe
        if (_dragOffset.dy > 0 && widget.onSwipeDown != null) {
          _triggerSwipe(widget.onSwipeDown!);
        } else if (_dragOffset.dy < 0 && widget.onSwipeUp != null) {
          _triggerSwipe(widget.onSwipeUp!);
        }
      }
    }

    // Reset animation
    _feedbackController.forward().then((_) {
      _feedbackController.reset();
    });

    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  Future<void> _triggerSwipe(VoidCallback callback) async {
    if (widget.enableHaptics) {
      // Progressive haptic feedback pattern
      await Vibration.vibrate(duration: 30);
      await Future.delayed(const Duration(milliseconds: 50));
      await Vibration.vibrate(duration: 50);
      HapticFeedback.mediumImpact();
    }

    callback();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _feedbackAnimation,
        builder: (context, child) {
          // Apply slight visual feedback during swipe
          double offsetX = _dragOffset.dx * 0.1;
          double offsetY = _dragOffset.dy * 0.1;

          // Limit offset
          offsetX = offsetX.clamp(-20.0, 20.0);
          offsetY = offsetY.clamp(-20.0, 20.0);

          return Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Direction indicator overlay for visual feedback
class SwipeDirectionIndicator extends StatelessWidget {
  final String direction;
  final Color color;

  const SwipeDirectionIndicator({
    super.key,
    required this.direction,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (direction) {
      case 'up':
        icon = Icons.keyboard_arrow_up_rounded;
        break;
      case 'down':
        icon = Icons.keyboard_arrow_down_rounded;
        break;
      case 'left':
        icon = Icons.keyboard_arrow_left_rounded;
        break;
      case 'right':
        icon = Icons.keyboard_arrow_right_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 48),
    );
  }
}
