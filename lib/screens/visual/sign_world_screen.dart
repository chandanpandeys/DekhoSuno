import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:senseplay/data/sign_language_content.dart';
import 'package:senseplay/services/ml_service.dart';
import 'package:senseplay/theme/app_theme.dart';

/// Enhanced Sign World Screen
/// Learn sign language through browsing or camera-based object recognition
class SignWorldScreen extends StatefulWidget {
  const SignWorldScreen({super.key});

  @override
  State<SignWorldScreen> createState() => _SignWorldScreenState();
}

class _SignWorldScreenState extends State<SignWorldScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  final MLService _mlService = MLService();
  Timer? _detectionTimer;

  bool _isCameraMode = false; // Start in learning mode, not camera
  bool _isCameraReady = false;
  bool _isDetecting = false;

  int _selectedCategoryIndex = 0;
  SignInfo? _selectedSign;
  String _searchQuery = '';

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _tabController = TabController(
      length: SignLanguageContent.categories.length,
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() => _selectedCategoryIndex = _tabController.index);
    });
  }

  void _setupAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    if (_controller != null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() => _isCameraReady = true);
      _startRealDetection();
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _disposeCamera() {
    _detectionTimer?.cancel();
    _controller?.dispose();
    _controller = null;
    _isCameraReady = false;
  }

  void _toggleCameraMode() {
    setState(() {
      _isCameraMode = !_isCameraMode;
    });

    if (_isCameraMode) {
      _initializeCamera();
    } else {
      _disposeCamera();
    }

    HapticFeedback.mediumImpact();
  }

  void _startRealDetection() {
    _detectionTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted ||
          _controller == null ||
          !_controller!.value.isInitialized ||
          _isDetecting) {
        return;
      }

      setState(() => _isDetecting = true);

      try {
        final image = await _controller!.takePicture();
        final labels = await _mlService.detectObjects(File(image.path));

        if (!mounted) return;

        // Find matching sign in content
        for (final label in labels) {
          final results = SignLanguageContent.search(label);
          if (results.isNotEmpty) {
            HapticFeedback.mediumImpact();
            setState(() => _selectedSign = results.first);
            break;
          }
        }
      } catch (e) {
        debugPrint('Detection error: $e');
      } finally {
        if (mounted) setState(() => _isDetecting = false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bounceController.dispose();
    _detectionTimer?.cancel();
    _controller?.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.visualBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_isCameraMode) _buildCategoryTabs(),
            Expanded(
              child: _isCameraMode ? _buildCameraView() : _buildLearningView(),
            ),
            if (_selectedSign != null) _buildSignInfoCard(),
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
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.visualSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.small,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.visualText,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sign World",
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.visualText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${SignLanguageContent.totalSigns} signs to learn",
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.visualTextMuted,
                  ),
                ),
              ],
            ),
          ),

          // Camera toggle button
          GestureDetector(
            onTap: _toggleCameraMode,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isCameraMode
                    ? AppColors.visualPrimary
                    : AppColors.visualSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.small,
              ),
              child: Icon(
                _isCameraMode ? Icons.camera_alt : Icons.camera_alt_outlined,
                color: _isCameraMode ? Colors.white : AppColors.visualText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppColors.visualPrimary,
        labelColor: AppColors.visualPrimary,
        unselectedLabelColor: AppColors.visualTextMuted,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: SignLanguageContent.categories
            .map((cat) => Tab(
                  child: Row(
                    children: [
                      Text(cat.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(cat.name),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildLearningView() {
    final category = SignLanguageContent.categories[_selectedCategoryIndex];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: category.signs.length,
      itemBuilder: (context, index) {
        final sign = category.signs[index];
        final isSelected = _selectedSign == sign;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedSign = sign);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.visualPrimary.withOpacity(0.15)
                  : AppColors.visualSurface,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: AppColors.visualPrimary, width: 2)
                  : null,
              boxShadow: AppShadows.small,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sign.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  sign.name,
                  style: TextStyle(
                    color: AppColors.visualText,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sign.hindiName,
                  style: TextStyle(
                    color: AppColors.visualPrimary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera preview
        if (_isCameraReady && _controller != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: CameraPreview(_controller!),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.visualSurface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.visualPrimary),
            ),
          ),

        // Detection overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.visualSurface.withAlpha(240),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.medium,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isDetecting
                        ? AppColors.visualPrimary.withAlpha(30)
                        : AppColors.success.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isDetecting
                        ? Icons.search_rounded
                        : Icons.check_circle_rounded,
                    color: _isDetecting
                        ? AppColors.visualPrimary
                        : AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isDetecting ? "Scanning..." : "Point camera at objects",
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.visualText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInfoCard() {
    final sign = _selectedSign!;

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.visualSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.visualPrimaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(sign.emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sign.name,
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.visualText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          sign.hindiName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.visualPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppColors.visualTextMuted,
                    onPressed: () => setState(() => _selectedSign = null),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.visualBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gesture_rounded,
                      color: AppColors.visualSecondary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sign.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.visualText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
