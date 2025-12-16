import 'dart:async';
import 'package:flutter/material.dart';
import 'package:senseplay/theme/app_theme.dart';

/// Dynamic Theme Provider
/// Provides context-aware, time-adaptive color schemes with smooth transitions
class DynamicThemeProvider extends ChangeNotifier {
  // Current color values
  Color _primaryAccent = AppColors.audioPrimary;
  Color _secondaryAccent = AppColors.audioSecondary;
  double _backgroundIntensity = 0.3;

  // Animation state
  Timer? _colorCycleTimer;
  bool _isAnimating = false;

  // Time-based theme adjustments
  static const Map<int, Map<String, Color>> _timeBasedColors = {
    6: {
      'primary': Color(0xFFFFB74D),
      'secondary': Color(0xFFFF8A65)
    }, // Morning
    12: {
      'primary': Color(0xFF00D4AA),
      'secondary': Color(0xFF00A3FF)
    }, // Afternoon
    18: {
      'primary': Color(0xFF7C4DFF),
      'secondary': Color(0xFFE040FB)
    }, // Evening
    22: {'primary': Color(0xFF3D5AFE), 'secondary': Color(0xFF536DFE)}, // Night
  };

  // Getters
  Color get primaryAccent => _primaryAccent;
  Color get secondaryAccent => _secondaryAccent;
  double get backgroundIntensity => _backgroundIntensity;

  LinearGradient get currentGradient => LinearGradient(
        colors: [_primaryAccent, _secondaryAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  RadialGradient get backgroundGradient => RadialGradient(
        center: Alignment.center,
        radius: 1.5,
        colors: [
          _primaryAccent.withOpacity(_backgroundIntensity),
          AppColors.audioBackground,
        ],
      );

  DynamicThemeProvider() {
    _updateTimeBasedTheme();
    // Update theme every hour
    Timer.periodic(const Duration(hours: 1), (_) => _updateTimeBasedTheme());
  }

  /// Update colors based on time of day
  void _updateTimeBasedTheme() {
    final hour = DateTime.now().hour;

    Color primary;
    Color secondary;

    if (hour >= 6 && hour < 12) {
      // Morning - warm sunrise colors
      primary = const Color(0xFFFFB74D);
      secondary = const Color(0xFFFF8A65);
    } else if (hour >= 12 && hour < 18) {
      // Afternoon - vibrant teal
      primary = const Color(0xFF00D4AA);
      secondary = const Color(0xFF00A3FF);
    } else if (hour >= 18 && hour < 22) {
      // Evening - purple hues
      primary = const Color(0xFF7C4DFF);
      secondary = const Color(0xFFE040FB);
    } else {
      // Night - deep blue
      primary = const Color(0xFF3D5AFE);
      secondary = const Color(0xFF536DFE);
    }

    _animateToColors(primary, secondary);
  }

  /// Animate color transition
  void _animateToColors(Color primary, Color secondary) {
    _primaryAccent = primary;
    _secondaryAccent = secondary;
    notifyListeners();
  }

  /// Set colors for a specific context (e.g., feature highlight)
  void setContextColors(Color primary, Color secondary) {
    _primaryAccent = primary;
    _secondaryAccent = secondary;
    notifyListeners();
  }

  /// Set background intensity for breathing effect
  void setBackgroundIntensity(double intensity) {
    _backgroundIntensity = intensity.clamp(0.1, 0.8);
    notifyListeners();
  }

  /// Start color cycling animation (for idle state)
  void startColorCycle() {
    if (_isAnimating) return;
    _isAnimating = true;

    final colors = [
      [AppColors.audioPrimary, const Color(0xFF00A3FF)],
      [const Color(0xFF7C4DFF), const Color(0xFFE040FB)],
      [const Color(0xFFFF6B6B), const Color(0xFFFFB800)],
      [const Color(0xFF00D4AA), const Color(0xFF43B7A8)],
    ];

    int index = 0;
    _colorCycleTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      index = (index + 1) % colors.length;
      _animateToColors(colors[index][0], colors[index][1]);
    });
  }

  /// Stop color cycling
  void stopColorCycle() {
    _isAnimating = false;
    _colorCycleTimer?.cancel();
    _colorCycleTimer = null;
    _updateTimeBasedTheme();
  }

  /// Get greeting based on time
  String getTimeGreeting({bool hindi = false}) {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return hindi ? 'सुप्रभात' : 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return hindi ? 'नमस्कार' : 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return hindi ? 'शुभ संध्या' : 'Good Evening';
    } else {
      return hindi ? 'शुभ रात्रि' : 'Good Night';
    }
  }

  @override
  void dispose() {
    _colorCycleTimer?.cancel();
    super.dispose();
  }
}

/// Extension for easy theme access
extension DynamicThemeContext on BuildContext {
  DynamicThemeProvider get dynamicTheme =>
      DynamicThemeProvider(); // Should be accessed via Provider
}
