import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Premium Call Assistant Screen
/// Caption overlay for phone calls (for hearing impaired users)
/// Note: Full overlay functionality requires native platform integration
class CallAssistantScreen extends StatefulWidget {
  const CallAssistantScreen({super.key});

  @override
  State<CallAssistantScreen> createState() => _CallAssistantScreenState();
}

class _CallAssistantScreenState extends State<CallAssistantScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isAssistantActive = false;
  bool _speechAvailable = false;
  String _currentCaption = "";
  List<String> _captionHistory = [];
  final TextEditingController _phoneController = TextEditingController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' && _isAssistantActive) {
          _startListening();
        }
      },
      onError: (error) => debugPrint('Call Assistant STT Error: $error'),
    );
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startListening() {
    if (!_speechAvailable || !_isAssistantActive) return;

    _speech.listen(
      onResult: (result) {
        setState(() {
          _currentCaption = result.recognizedWords;
          if (result.finalResult && _currentCaption.isNotEmpty) {
            _captionHistory.insert(0, _currentCaption);
            if (_captionHistory.length > 20) _captionHistory.removeLast();
          }
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      listenMode: ListenMode.dictation,
    );
  }

  void _toggleAssistant() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAssistantActive = !_isAssistantActive;

      if (_isAssistantActive) {
        _pulseController.repeat(reverse: true);
        _currentCaption = "Listening for speech...";
        _startListening();
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _speech.stop();
        _currentCaption = "";
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _phoneController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.visualBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMainContent()),
            _buildCaptionPreview(),
            _buildPhoneDialer(),
            _buildControlButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneDialer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.visualSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.visualText, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                hintStyle: TextStyle(color: AppColors.visualTextMuted),
                prefixIcon:
                    const Icon(Icons.phone, color: AppColors.visualPrimary),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: "Make call",
            button: true,
            child: GestureDetector(
              onTap: () {
                final phone = _phoneController.text.trim();
                if (phone.isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  _makePhoneCall(phone);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.success, Color(0xFF16A34A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Semantics(
            label: "Go back",
            button: true,
            child: GestureDetector(
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Call Assistant",
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.visualText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Real-time call captions",
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.visualTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isAssistantActive
                  ? AppColors.success.withAlpha(30)
                  : AppColors.visualTextMuted.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isAssistantActive
                    ? AppColors.success.withAlpha(80)
                    : AppColors.visualTextMuted.withAlpha(80),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isAssistantActive
                        ? AppColors.success
                        : AppColors.visualTextMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isAssistantActive ? "Active" : "Inactive",
                  style: TextStyle(
                    color: _isAssistantActive
                        ? AppColors.success
                        : AppColors.visualTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isAssistantActive ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (_isAssistantActive
                                ? AppColors.success
                                : AppColors.visualPrimary)
                            .withAlpha(80),
                        (_isAssistantActive
                                ? AppColors.success
                                : AppColors.visualPrimary)
                            .withAlpha(30),
                      ],
                    ),
                    boxShadow: _isAssistantActive
                        ? [
                            BoxShadow(
                              color: AppColors.success.withAlpha(80),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isAssistantActive
                        ? Icons.hearing_rounded
                        : Icons.phone_in_talk_rounded,
                    size: 64,
                    color: _isAssistantActive
                        ? AppColors.success
                        : AppColors.visualPrimary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            _isAssistantActive
                ? "Listening to your call..."
                : "Start the assistant to\ncaption your calls",
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.visualText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAssistantActive
                ? "Captions will appear below"
                : "Tap the button below to begin",
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.visualTextMuted,
            ),
          ),
          const SizedBox(height: 16),
          // Speakerphone requirement notice
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.volume_up, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "⚠️ SPEAKERPHONE REQUIRED\nPut your call on speaker so the mic can hear the other person.",
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionPreview() {
    if (!_isAssistantActive) return const SizedBox(height: 120);

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.visualSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.medium,
        border: Border.all(
          color: AppColors.success.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Live Caption",
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              _currentCaption.isEmpty
                  ? "Waiting for speech..."
                  : _currentCaption,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.visualText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Semantics(
        label: _isAssistantActive ? "Stop assistant" : "Start assistant",
        button: true,
        child: GestureDetector(
          onTap: _toggleAssistant,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: _isAssistantActive
                  ? const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    )
                  : const LinearGradient(
                      colors: [AppColors.success, Color(0xFF16A34A)],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_isAssistantActive
                          ? const Color(0xFFEF4444)
                          : AppColors.success)
                      .withAlpha(100),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isAssistantActive
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  _isAssistantActive ? "Stop Assistant" : "Start Assistant",
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
