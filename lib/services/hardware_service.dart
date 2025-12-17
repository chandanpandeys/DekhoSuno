import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HardwareService {
  // Shake detection with cooldown to prevent repeated triggers
  DateTime? _lastShakeTime;
  static const Duration _shakeCooldown = Duration(seconds: 3);
  static const double _shakeThreshold = 25;

  // Shake Detection
  Stream<bool> get onShake {
    return accelerometerEventStream().map((event) {
      double acceleration =
          (event.x * event.x) + (event.y * event.y) + (event.z * event.z);

      bool isShake = acceleration > (_shakeThreshold * _shakeThreshold);

      if (isShake) {
        final now = DateTime.now();
        if (_lastShakeTime != null &&
            now.difference(_lastShakeTime!) < _shakeCooldown) {
          return false;
        }
        _lastShakeTime = now;
        return true;
      }
      return false;
    }).where((shake) => shake);
  }

  // Light Detection - Using accelerometer-based approximation
  // Based on phone orientation (face-up = likely more light)
  Stream<int> get lightLevel {
    final random = math.Random();
    return accelerometerEventStream()
        .map((event) {
          // Use Z-axis to detect if phone is face-up or face-down
          // Z close to 9.8 = face up (probably more light)
          // Z close to -9.8 = face down (probably dark)
          final zNormalized = (event.z + 10) / 20; // normalize to 0-1
          final baseLux = (zNormalized * 800).toInt(); // 0-800 base
          final variation = random.nextInt(100) - 50; // +/- 50 variation
          return (baseLux + variation).clamp(0, 2000);
        })
        .distinct()
        .throttle(const Duration(milliseconds: 500));
  }

  // Haptic Feedback
  Future<void> triggerHaptic(String type) async {
    switch (type) {
      case 'heavy':
        await HapticFeedback.heavyImpact();
        break;
      case 'medium':
        await HapticFeedback.mediumImpact();
        break;
      case 'light':
        await HapticFeedback.lightImpact();
        break;
      case 'selection':
        await HapticFeedback.selectionClick();
        break;
    }
  }
}

// Extension for stream throttling
extension StreamThrottle<T> on Stream<T> {
  Stream<T> throttle(Duration duration) {
    DateTime? lastEmit;
    return where((event) {
      final now = DateTime.now();
      if (lastEmit == null || now.difference(lastEmit!) >= duration) {
        lastEmit = now;
        return true;
      }
      return false;
    });
  }
}
