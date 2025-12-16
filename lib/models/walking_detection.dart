/// Walking Detection Models for Guided Walking Feature
/// Represents detected obstacles and navigation state for visually impaired users

/// Represents a single detected obstacle in the walking path
class DetectedObstacle {
  final String name;
  final String position; // left, center, right
  final String estimatedDistance; // e.g., "2-3 meters", "about 1 meter"
  final double distanceMeters; // Numeric estimate for calculations
  final String urgency; // low, medium, high, critical

  const DetectedObstacle({
    required this.name,
    required this.position,
    required this.estimatedDistance,
    required this.distanceMeters,
    required this.urgency,
  });

  /// Get haptic pattern based on distance
  List<int> get hapticPattern {
    if (distanceMeters < 1) {
      return [200, 50, 200, 50, 200]; // Critical: urgent triple pulse
    } else if (distanceMeters < 2) {
      return [100, 100, 100]; // High: double buzz
    } else if (distanceMeters < 4) {
      return [50]; // Medium: single pulse
    }
    return []; // Low: no haptic
  }

  /// Get announcement priority (lower = higher priority)
  int get priority {
    switch (urgency) {
      case 'critical':
        return 0;
      case 'high':
        return 1;
      case 'medium':
        return 2;
      case 'low':
      default:
        return 3;
    }
  }

  /// Format for voice announcement
  String get announcement {
    final positionText =
        position == 'center' ? 'directly ahead' : 'on your $position';
    return '$name $positionText, $estimatedDistance';
  }

  @override
  String toString() =>
      'DetectedObstacle($name, $position, $estimatedDistance, $urgency)';
}

/// Complete walking detection result from a single analysis
class WalkingDetection {
  final List<DetectedObstacle> obstacles;
  final String pathStatus; // clear, caution, blocked
  final String navigationGuidance;
  final DateTime timestamp;

  const WalkingDetection({
    required this.obstacles,
    required this.pathStatus,
    required this.navigationGuidance,
    required this.timestamp,
  });

  /// Check if path is safe to continue
  bool get isSafe => pathStatus == 'clear';

  /// Check if there are critical obstacles
  bool get hasCriticalObstacles =>
      obstacles.any((o) => o.urgency == 'critical');

  /// Get the most urgent obstacle
  DetectedObstacle? get mostUrgent {
    if (obstacles.isEmpty) return null;
    return obstacles.reduce((a, b) => a.priority < b.priority ? a : b);
  }

  /// Get obstacles sorted by priority
  List<DetectedObstacle> get sortedByPriority {
    final sorted = List<DetectedObstacle>.from(obstacles);
    sorted.sort((a, b) => a.priority.compareTo(b.priority));
    return sorted;
  }

  /// Get full announcement for all obstacles
  String get fullAnnouncement {
    if (obstacles.isEmpty) {
      return navigationGuidance;
    }

    final sortedObstacles = sortedByPriority.take(3); // Max 3 obstacles
    final obstacleAnnouncements =
        sortedObstacles.map((o) => o.announcement).join('. ');
    return '$obstacleAnnouncements. $navigationGuidance';
  }

  /// Create empty/clear detection
  factory WalkingDetection.clear() {
    return WalkingDetection(
      obstacles: [],
      pathStatus: 'clear',
      navigationGuidance: 'Path is clear ahead. Continue walking safely.',
      timestamp: DateTime.now(),
    );
  }

  /// Create error/unknown detection
  factory WalkingDetection.unknown() {
    return WalkingDetection(
      obstacles: [],
      pathStatus: 'unknown',
      navigationGuidance: 'Unable to analyze path. Please be cautious.',
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'WalkingDetection($pathStatus, ${obstacles.length} obstacles)';
}

/// Walking sensitivity levels
enum WalkingSensitivity {
  low, // Only report obstacles < 2m
  medium, // Report obstacles < 4m (default)
  high, // Report all visible obstacles
}

extension WalkingSensitivityExtension on WalkingSensitivity {
  double get maxDistance {
    switch (this) {
      case WalkingSensitivity.low:
        return 2.0;
      case WalkingSensitivity.medium:
        return 4.0;
      case WalkingSensitivity.high:
        return 10.0;
    }
  }

  String get displayName {
    switch (this) {
      case WalkingSensitivity.low:
        return 'Low (close obstacles only)';
      case WalkingSensitivity.medium:
        return 'Medium (recommended)';
      case WalkingSensitivity.high:
        return 'High (all obstacles)';
    }
  }
}
