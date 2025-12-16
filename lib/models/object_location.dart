class ObjectLocation {
  final bool found;
  final String objectName;
  final String direction; // left, right, center, up, down, not_found
  final String distance; // close, medium, far, not_found
  final String
      sizeInFrame; // small, medium, large, not_found (indicator of distance)
  final String guidanceText;

  ObjectLocation({
    required this.found,
    required this.objectName,
    required this.direction,
    required this.distance,
    required this.sizeInFrame,
    required this.guidanceText,
  });

  bool get isCentered => direction == 'center';
  bool get isClose => distance == 'close' || sizeInFrame == 'large';

  String get proximityIndicator {
    if (distance == 'close') return 'very close';
    if (distance == 'medium') return 'nearby';
    if (distance == 'far') return 'in the distance';
    return '';
  }
}
