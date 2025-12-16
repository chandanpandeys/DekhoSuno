import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class HardwareService {
  // Shake Detection
  Stream<bool> get onShake {
    return accelerometerEventStream().map((event) {
      double acceleration =
          (event.x * event.x) + (event.y * event.y) + (event.z * event.z);
      return acceleration > (15 * 15); // Threshold > 15m/s^2
    }).where((shake) => shake); // Only emit true
  }

  // Light Detection - Using accelerometer-based approximation
  // Since light_sensor package has issues, we use screen brightness or simulate
  // based on device movement (less movement = likely indoor/dark)
  Stream<int> get lightLevel {
    // Create a variable simulation based on time and slight randomness
    // to show the UI is working. In production, use platform channels.
    final random = math.Random();
    return accelerometerEventStream()
        .map((event) {
          // Use Z-axis to detect if phone is face-up (toward light) or face-down
          // Z close to 9.8 = face up (probably more light)
          // Z close to -9.8 = face down (probably dark)
          final zNormalized = (event.z + 10) / 20; // normalize to 0-1
          final baseLux = (zNormalized * 800).toInt(); // 0-800 base
          final variation = random.nextInt(100) - 50; // +/- 50 variation
          return (baseLux + variation).clamp(0, 2000);
        })
        .distinct() // Only emit when value changes
        .throttle(const Duration(milliseconds: 500)); // Limit updates
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
