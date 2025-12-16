import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saved place for navigation
class SavedPlace {
  final String id;
  final String name;
  final String hindiName;
  final LatLng location;
  final IconData icon;
  final DateTime? lastVisited;

  SavedPlace({
    required this.id,
    required this.name,
    required this.hindiName,
    required this.location,
    this.icon = Icons.place,
    this.lastVisited,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hindiName': hindiName,
        'lat': location.latitude,
        'lng': location.longitude,
        'icon': icon.codePoint,
        'lastVisited': lastVisited?.toIso8601String(),
      };

  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(
        id: json['id'],
        name: json['name'],
        hindiName: json['hindiName'],
        location: LatLng(json['lat'], json['lng']),
        icon: IconData(json['icon'] ?? Icons.place.codePoint,
            fontFamily: 'MaterialIcons'),
        lastVisited: json['lastVisited'] != null
            ? DateTime.parse(json['lastVisited'])
            : null,
      );
}

/// Navigation direction step
class NavigationStep {
  final String instruction;
  final String hindiInstruction;
  final double distanceMeters;
  final String direction; // 'straight', 'left', 'right', 'arrived'

  NavigationStep({
    required this.instruction,
    required this.hindiInstruction,
    required this.distanceMeters,
    required this.direction,
  });
}

/// Navigation Service for voice-guided walking to saved places
class NavigationService extends ChangeNotifier {
  Position? _currentPosition;
  SavedPlace? _destination;
  bool _isNavigating = false;
  bool _isInitialized = false;
  String? _lastError;

  final List<SavedPlace> _savedPlaces = [];

  // Callbacks
  Function(String message)? onSpeak;
  Function(NavigationStep step)? onNavigationUpdate;

  // Getters
  Position? get currentPosition => _currentPosition;
  SavedPlace? get destination => _destination;
  bool get isNavigating => _isNavigating;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  List<SavedPlace> get savedPlaces => List.unmodifiable(_savedPlaces);

  /// Initialize the service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied) {
          _lastError = 'Location permission denied';
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _lastError = 'Location permission permanently denied';
        return false;
      }

      // Load saved places
      await _loadSavedPlaces();

      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('NavigationService: Error initializing: $_lastError');
      return false;
    }
  }

  /// Add current location as saved place
  Future<void> saveCurrentLocation(
      String name, String hindiName, IconData icon) async {
    if (_currentPosition == null) {
      await _updateCurrentPosition();
    }

    if (_currentPosition == null) return;

    final place = SavedPlace(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      hindiName: hindiName,
      location: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      icon: icon,
    );

    _savedPlaces.add(place);
    await _savePlaces();
    notifyListeners();
  }

  /// Add a place with specific coordinates
  Future<void> addPlace(SavedPlace place) async {
    _savedPlaces.add(place);
    await _savePlaces();
    notifyListeners();
  }

  /// Remove a saved place
  Future<void> removePlace(String id) async {
    _savedPlaces.removeWhere((p) => p.id == id);
    await _savePlaces();
    notifyListeners();
  }

  /// Start navigation to a saved place
  Future<void> startNavigation(SavedPlace destination) async {
    if (!_isInitialized) {
      await initialize();
    }

    _destination = destination;
    _isNavigating = true;
    notifyListeners();

    // Announce start
    final distance = _getDistance();
    onSpeak?.call(
        "${destination.hindiName} ki taraf chal rahe hain. Distance hai ${_formatDistance(distance)}.");

    // Start position updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    ).listen((position) {
      if (!_isNavigating) return;

      _currentPosition = position;
      _updateNavigation();
      notifyListeners();
    });
  }

  /// Stop navigation
  void stopNavigation() {
    _isNavigating = false;
    _destination = null;
    onSpeak?.call("Navigation ruk gaya.");
    notifyListeners();
  }

  /// Update current position
  Future<void> _updateCurrentPosition() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error getting position: $e');
    }
  }

  /// Update navigation with current position
  void _updateNavigation() {
    if (_destination == null || _currentPosition == null) return;

    final distance = _getDistance();
    final bearing = _getBearing();

    // Check if arrived
    if (distance < 20) {
      onSpeak?.call("Aap ${_destination!.hindiName} pahunch gaye!");
      onNavigationUpdate?.call(NavigationStep(
        instruction: "You have arrived!",
        hindiInstruction: "Aap pahunch gaye!",
        distanceMeters: distance,
        direction: 'arrived',
      ));
      stopNavigation();
      return;
    }

    // Determine direction
    String direction = 'straight';
    String hindiDirection = 'Seedha chalein';

    if (bearing > 30 && bearing < 150) {
      direction = 'right';
      hindiDirection = 'Daayein murein';
    } else if (bearing > 210 && bearing < 330) {
      direction = 'left';
      hindiDirection = 'Baayein murein';
    }

    final step = NavigationStep(
      instruction: "${_formatDistance(distance)} to ${_destination!.name}",
      hindiInstruction:
          "$hindiDirection. ${_formatDistanceHindi(distance)} aur chalna hai.",
      distanceMeters: distance,
      direction: direction,
    );

    onNavigationUpdate?.call(step);

    // Announce at intervals
    if (distance % 50 < 5) {
      onSpeak?.call(step.hindiInstruction);
    }
  }

  /// Get distance to destination in meters
  double _getDistance() {
    if (_currentPosition == null || _destination == null) return 0;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destination!.location.latitude,
      _destination!.location.longitude,
    );
  }

  /// Get bearing to destination
  double _getBearing() {
    if (_currentPosition == null || _destination == null) return 0;

    final bearing = Geolocator.bearingBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destination!.location.latitude,
      _destination!.location.longitude,
    );

    // Adjust for current heading
    final heading = _currentPosition!.heading;
    var relative = bearing - heading;
    if (relative < 0) relative += 360;
    return relative;
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDistanceHindi(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} kilometer';
    }
    return '${meters.round()} meter';
  }

  /// Load saved places from storage
  Future<void> _loadSavedPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('saved_places');
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        _savedPlaces.addAll(decoded.map((j) => SavedPlace.fromJson(j)));
      }

      // Add default places if empty
      if (_savedPlaces.isEmpty) {
        _addDefaultPlaces();
      }
    } catch (e) {
      debugPrint('Error loading places: $e');
      _addDefaultPlaces();
    }
  }

  void _addDefaultPlaces() {
    // These are placeholder coords - user will save real locations
    _savedPlaces.addAll([
      SavedPlace(
        id: 'home',
        name: 'Home',
        hindiName: 'घर',
        location: LatLng(28.6139, 77.2090), // Delhi placeholder
        icon: Icons.home,
      ),
      SavedPlace(
        id: 'school',
        name: 'School',
        hindiName: 'स्कूल',
        location: LatLng(28.6145, 77.2095),
        icon: Icons.school,
      ),
    ]);
  }

  /// Save places to storage
  Future<void> _savePlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_places',
          jsonEncode(_savedPlaces.map((p) => p.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving places: $e');
    }
  }

  /// Get distance from current position to a place
  double? getDistanceTo(SavedPlace place) {
    if (_currentPosition == null) return null;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      place.location.latitude,
      place.location.longitude,
    );
  }
}
