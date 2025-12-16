import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:senseplay/models/walking_detection.dart';
import 'package:senseplay/services/gemini_service.dart';
import 'package:senseplay/services/guided_walking_service.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:vibration/vibration.dart';

/// Guided Walking Screen
/// Real-time AI-powered navigation assistance for visually impaired users
class GuidedWalkingScreen extends StatefulWidget {
  const GuidedWalkingScreen({super.key});

  @override
  State<GuidedWalkingScreen> createState() => _GuidedWalkingScreenState();
}

class _GuidedWalkingScreenState extends State<GuidedWalkingScreen>
    with TickerProviderStateMixin {
  late GuidedWalkingService _walkingService;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _statusController;
  late Animation<Color?> _statusColorAnimation;

  bool _isInitialized = false;
  String _statusText = "Initializing...";

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeService();
  }

  void _setupAnimations() {
    // Pulse animation for active state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Status color animation
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _statusColorAnimation = ColorTween(
      begin: AppColors.audioPrimary,
      end: AppColors.audioSecondary,
    ).animate(_statusController);
  }

  Future<void> _initializeService() async {
    final geminiService = context.read<GeminiService>();
    _walkingService = GuidedWalkingService(geminiService);

    _walkingService.onDetection = _handleDetection;
    _walkingService.onError = _handleError;
    _walkingService.addListener(_updateUI);

    final success = await _walkingService.initialize();

    if (!mounted) return;

    setState(() {
      _isInitialized = success;
      _statusText = success
          ? "Ready! Double tap to start walking guidance"
          : "Failed to initialize camera";
    });
  }

  void _handleDetection(WalkingDetection detection) {
    if (!mounted) return;

    setState(() {
      switch (detection.pathStatus) {
        case 'clear':
          _statusText = "Path clear";
          _statusController.reverse();
          break;
        case 'caution':
          _statusText = "Obstacles detected";
          _statusController.forward();
          break;
        case 'blocked':
          _statusText = "Path blocked!";
          _statusController.forward();
          break;
        default:
          _statusText = "Analyzing...";
      }
    });
  }

  void _handleError(String error) {
    if (!mounted) return;
    setState(() {
      _statusText = error;
    });
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  Future<void> _startWalking() async {
    await Vibration.vibrate(duration: 100);
    await _walkingService.start();
  }

  Future<void> _stopWalking() async {
    await _walkingService.stop();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusController.dispose();
    _walkingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.audioBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: () {
          if (!_walkingService.isActive) {
            _startWalking();
          } else {
            _walkingService.repeatLastAnnouncement();
          }
        },
        onLongPress: () {
          if (_walkingService.isActive) {
            _walkingService.togglePause();
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            // Swipe down - stop
            _stopWalking();
          }
        },
        onTap: () {
          // Triple tap detection for scene description
          Vibration.vibrate(duration: 30);
        },
        child: Stack(
          children: [
            // Camera preview (dimmed)
            if (_isInitialized && _walkingService.cameraController != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.2,
                  child: CameraPreview(_walkingService.cameraController!),
                ),
              ),

            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.audioBackground.withOpacity(0.7),
                    AppColors.audioBackground.withOpacity(0.9),
                    AppColors.audioBackground,
                  ],
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildCentralContent()),
                  _buildObstacleZones(),
                  _buildBottomSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          Semantics(
            label: "Stop and go back",
            button: true,
            child: GestureDetector(
              onTap: _stopWalking,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.audioSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.audioText,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Guided Walking",
                  style: TextStyle(
                    color: AppColors.audioText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "AI-powered navigation",
                  style: TextStyle(
                    color: AppColors.audioTextMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Status indicator
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final isActive = _walkingService.isActive;
    final isPaused = _walkingService.isPaused;
    final isAnalyzing = _walkingService.isAnalyzing;

    Color statusColor;
    String statusLabel;

    if (!isActive) {
      statusColor = AppColors.audioTextMuted;
      statusLabel = "Ready";
    } else if (isPaused) {
      statusColor = AppColors.audioSecondary;
      statusLabel = "Paused";
    } else if (isAnalyzing) {
      statusColor = AppColors.audioPrimary;
      statusLabel = "Scanning";
    } else {
      statusColor = AppColors.success;
      statusLabel = "Active";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAnalyzing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.audioPrimary,
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralContent() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Center(
          child: Transform.scale(
            scale: _walkingService.isActive && !_walkingService.isPaused
                ? _pulseAnimation.value
                : 1.0,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _getStatusColor().withOpacity(0.3),
                    _getStatusColor().withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: _getStatusColor().withOpacity(0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor().withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 56,
                    color: _getStatusColor(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.audioText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor() {
    final detection = _walkingService.lastDetection;
    if (detection == null) return AppColors.audioTextMuted;

    switch (detection.pathStatus) {
      case 'clear':
        return AppColors.success;
      case 'caution':
        return AppColors.audioSecondary;
      case 'blocked':
        return AppColors.audioAccent;
      default:
        return AppColors.audioPrimary;
    }
  }

  IconData _getStatusIcon() {
    if (!_walkingService.isActive) {
      return Icons.directions_walk_rounded;
    }
    if (_walkingService.isPaused) {
      return Icons.pause_circle_outline_rounded;
    }

    final detection = _walkingService.lastDetection;
    if (detection == null) return Icons.radar_rounded;

    switch (detection.pathStatus) {
      case 'clear':
        return Icons.check_circle_outline_rounded;
      case 'caution':
        return Icons.warning_amber_rounded;
      case 'blocked':
        return Icons.block_rounded;
      default:
        return Icons.radar_rounded;
    }
  }

  Widget _buildObstacleZones() {
    final detection = _walkingService.lastDetection;

    bool leftHasObstacle = false;
    bool centerHasObstacle = false;
    bool rightHasObstacle = false;

    if (detection != null) {
      for (var obstacle in detection.obstacles) {
        switch (obstacle.position) {
          case 'left':
            leftHasObstacle = true;
            break;
          case 'center':
            centerHasObstacle = true;
            break;
          case 'right':
            rightHasObstacle = true;
            break;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildZoneIndicator("LEFT", leftHasObstacle),
          _buildZoneIndicator("CENTER", centerHasObstacle),
          _buildZoneIndicator("RIGHT", rightHasObstacle),
        ],
      ),
    );
  }

  Widget _buildZoneIndicator(String label, bool hasObstacle) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: hasObstacle
              ? AppColors.audioAccent.withOpacity(0.2)
              : AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasObstacle
                ? AppColors.audioAccent.withOpacity(0.5)
                : AppColors.success.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasObstacle ? Icons.warning_rounded : Icons.check_rounded,
              color: hasObstacle ? AppColors.audioAccent : AppColors.success,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: hasObstacle ? AppColors.audioAccent : AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    final detection = _walkingService.lastDetection;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.audioSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last announcement
          if (detection != null && detection.obstacles.isNotEmpty) ...[
            const Text(
              "Detected obstacles:",
              style: TextStyle(
                color: AppColors.audioTextMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ...detection.sortedByPriority.take(3).map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: o.urgency == 'critical' || o.urgency == 'high'
                              ? AppColors.audioAccent
                              : AppColors.audioSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          o.announcement,
                          style: const TextStyle(
                            color: AppColors.audioText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const Divider(color: AppColors.glassBorder, height: 20),
          ],

          // Gesture hints
          Row(
            children: [
              _buildGestureHint(
                icon: Icons.touch_app_rounded,
                label: _walkingService.isActive ? "Double tap" : "Double tap",
                action: _walkingService.isActive ? "Repeat" : "Start",
              ),
              const SizedBox(width: 12),
              _buildGestureHint(
                icon: Icons.pan_tool_rounded,
                label: "Long press",
                action: _walkingService.isPaused ? "Resume" : "Pause",
              ),
              const SizedBox(width: 12),
              _buildGestureHint(
                icon: Icons.swipe_down_rounded,
                label: "Swipe down",
                action: "Stop",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGestureHint({
    required IconData icon,
    required String label,
    required String action,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.audioPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.audioPrimary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.audioTextMuted,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              action,
              style: const TextStyle(
                color: AppColors.audioPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
