import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:senseplay/services/navigation_service.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:vibration/vibration.dart';

/// Mini Map Screen for voice-guided navigation to saved places
class MiniMapScreen extends StatefulWidget {
  const MiniMapScreen({super.key});

  @override
  State<MiniMapScreen> createState() => _MiniMapScreenState();
}

class _MiniMapScreenState extends State<MiniMapScreen> {
  final NavigationService _navService = NavigationService();
  final FlutterTts _tts = FlutterTts();
  final MapController _mapController = MapController();

  String _currentInstruction = "Select a destination";
  bool _isAddingPlace = false;
  final TextEditingController _placeNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _tts.setLanguage("hi-IN");
    await _tts.setSpeechRate(0.5);

    _navService.onSpeak = (message) async {
      await Vibration.vibrate(duration: 50);
      await _tts.speak(message);
    };

    _navService.onNavigationUpdate = (step) {
      setState(() {
        _currentInstruction = step.hindiInstruction;
      });

      // Haptic feedback for direction
      if (step.direction == 'left') {
        Vibration.vibrate(pattern: [0, 100, 50, 100]); // Left pattern
      } else if (step.direction == 'right') {
        Vibration.vibrate(
            pattern: [0, 100, 100, 100, 100, 100]); // Right pattern
      } else if (step.direction == 'arrived') {
        Vibration.vibrate(pattern: [0, 300, 100, 300]); // Arrival pattern
      }
    };

    final success = await _navService.initialize();
    if (success) {
      await _tts.speak("Mini Map khul gaya. Aap kahan jaana chahte hain?");
    } else {
      await _tts.speak("Location permission chahiye.");
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _navService.stopNavigation();
    _tts.stop();
    _placeNameController.dispose();
    super.dispose();
  }

  void _startNavigationTo(SavedPlace place) {
    _navService.startNavigation(place);

    // Center map on route
    if (_navService.currentPosition != null) {
      _mapController.move(
        LatLng(
          _navService.currentPosition!.latitude,
          _navService.currentPosition!.longitude,
        ),
        15,
      );
    }

    setState(() {
      _currentInstruction = "${place.hindiName} ki taraf ja rahe hain...";
    });
  }

  void _showAddPlaceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.audioSurface,
        title: const Text("Add Current Location",
            style: TextStyle(color: AppColors.audioText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _placeNameController,
              style: const TextStyle(color: AppColors.audioText),
              decoration: const InputDecoration(
                hintText: "Place name (e.g., Home)",
                hintStyle: TextStyle(color: AppColors.audioTextMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.audioPrimary,
            ),
            onPressed: () async {
              final name = _placeNameController.text.trim();
              if (name.isNotEmpty) {
                await _navService.saveCurrentLocation(
                  name,
                  name, // Hindi name same for now
                  Icons.place,
                );
                _placeNameController.clear();
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  await _tts.speak("$name save ho gaya.");
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.audioBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                  _buildMap(),
                  _buildNavigationOverlay(),
                ],
              ),
            ),
            _buildPlacesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.audioSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.audioText),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mini Map",
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.audioText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${_navService.savedPlaces.length} saved places",
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.audioTextMuted),
                ),
              ],
            ),
          ),
          // Add place button
          GestureDetector(
            onTap: _showAddPlaceDialog,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.audioPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final currentPos = _navService.currentPosition;
    final center = currentPos != null
        ? LatLng(currentPos.latitude, currentPos.longitude)
        : const LatLng(28.6139, 77.2090); // Delhi default

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.senseplay',
        ),
        // Current location marker
        if (currentPos != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(currentPos.latitude, currentPos.longitude),
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.audioPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.audioPrimary.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.my_location,
                      color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        // Saved places markers
        MarkerLayer(
          markers: _navService.savedPlaces
              .map((place) => Marker(
                    point: place.location,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _startNavigationTo(place),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _navService.destination?.id == place.id
                                  ? Colors.green
                                  : AppColors.audioSecondary,
                              shape: BoxShape.circle,
                            ),
                            child:
                                Icon(place.icon, color: Colors.white, size: 18),
                          ),
                          Text(
                            place.name,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
        // Navigation line
        if (_navService.isNavigating &&
            currentPos != null &&
            _navService.destination != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  LatLng(currentPos.latitude, currentPos.longitude),
                  _navService.destination!.location,
                ],
                strokeWidth: 4,
                color: AppColors.audioPrimary,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildNavigationOverlay() {
    if (!_navService.isNavigating) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.audioSurface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.medium,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.audioPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.navigation, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _navService.destination!.name,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.audioText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _currentInstruction,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.audioTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.audioTextMuted),
              onPressed: () {
                _navService.stopNavigation();
                setState(() {
                  _currentInstruction = "Navigation stopped";
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlacesList() {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.audioSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Saved Places",
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.audioTextMuted),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navService.savedPlaces.length,
              itemBuilder: (context, index) {
                final place = _navService.savedPlaces[index];
                final distance = _navService.getDistanceTo(place);
                final isActive = _navService.destination?.id == place.id;

                return GestureDetector(
                  onTap: () => _startNavigationTo(place),
                  onLongPress: () => _showPlaceOptions(place),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.audioPrimary.withOpacity(0.2)
                          : AppColors.audioBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: isActive
                          ? Border.all(color: AppColors.audioPrimary, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(place.icon,
                            color: AppColors.audioPrimary, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          place.name,
                          style: TextStyle(
                            color: AppColors.audioText,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (distance != null)
                          Text(
                            _formatDistance(distance),
                            style: TextStyle(
                              color: AppColors.audioTextMuted,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceOptions(SavedPlace place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.audioSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(place.icon, color: AppColors.audioPrimary, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    place.name,
                    style: AppTypography.titleLarge
                        .copyWith(color: AppColors.audioText),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              leading:
                  const Icon(Icons.navigation, color: AppColors.audioPrimary),
              title: const Text("Navigate Here",
                  style: TextStyle(color: AppColors.audioText)),
              onTap: () {
                Navigator.pop(context);
                _startNavigationTo(place);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete Place",
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _navService.removePlace(place.id);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}
