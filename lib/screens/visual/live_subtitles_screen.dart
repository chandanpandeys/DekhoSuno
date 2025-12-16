import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:vibration/vibration.dart';

/// Premium Live Subtitles Screen
/// Real-time speech-to-text display for hearing impaired users
class LiveSubtitlesScreen extends StatefulWidget {
  const LiveSubtitlesScreen({super.key});

  @override
  State<LiveSubtitlesScreen> createState() => _LiveSubtitlesScreenState();
}

class _LiveSubtitlesScreenState extends State<LiveSubtitlesScreen>
    with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _currentText = "";
  List<_SubtitleEntry> _subtitleHistory = [];
  double _soundLevel = 0.0;
  String _selectedLanguage = "en-IN";

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> _languages = [
    {"code": "en-IN", "name": "English"},
    {"code": "hi-IN", "name": "हिंदी"},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initSpeech();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          // Restart listening when it stops
          _startListening();
        }
      },
      onError: (error) => debugPrint('Speech Error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _startListening();
    }
  }

  void _startListening() {
    if (!_speech.isListening) {
      _speech.listen(
        onResult: (result) {
          setState(() {
            _currentText = result.recognizedWords;

            if (result.finalResult && _currentText.isNotEmpty) {
              _addToHistory(_currentText);
              _currentText = "";
            }
          });
        },
        onSoundLevelChange: (level) {
          setState(() => _soundLevel = level.clamp(0, 10));
        },
        localeId: _selectedLanguage,
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        listenFor: const Duration(seconds: 30),
      );
    }
  }

  void _addToHistory(String text) {
    final entry = _SubtitleEntry(
      text: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      _subtitleHistory.insert(0, entry);
      if (_subtitleHistory.length > 50) {
        _subtitleHistory.removeLast();
      }
    });
    Vibration.vibrate(duration: 30);
  }

  void _toggleListening() {
    HapticFeedback.mediumImpact();
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _startListening();
    }
  }

  void _changeLanguage(String code) {
    setState(() => _selectedLanguage = code);
    if (_isListening) {
      _speech.stop();
      Future.delayed(const Duration(milliseconds: 300), _startListening);
    }
  }

  void _clearHistory() {
    HapticFeedback.lightImpact();
    setState(() {
      _subtitleHistory.clear();
      _currentText = "";
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.stop();
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
            _buildCurrentSubtitle(),
            Expanded(child: _buildHistory()),
            _buildControls(),
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
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Live Subtitles",
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.visualText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Real-time speech to text",
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.visualTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Language selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.visualSurface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.small,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLanguage,
                isDense: true,
                dropdownColor: AppColors.visualSurface,
                icon: const Icon(Icons.language, size: 18),
                items: _languages.map((lang) {
                  return DropdownMenuItem(
                    value: lang["code"],
                    child: Text(
                      lang["name"]!,
                      style: TextStyle(color: AppColors.visualText),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) _changeLanguage(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSubtitle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.visualPrimaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.visualPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Listening indicator
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.white : Colors.white54,
                        shape: BoxShape.circle,
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                _isListening ? "Listening..." : "Paused",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Sound level indicator
              SizedBox(
                width: 60,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _soundLevel / 10,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentText.isEmpty ? "Start speaking..." : _currentText,
            style: TextStyle(
              color: _currentText.isEmpty ? Colors.white54 : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_subtitleHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.subtitles_rounded,
              size: 64,
              color: AppColors.visualTextMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "Subtitles will appear here",
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.visualTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subtitleHistory.length,
      itemBuilder: (context, index) {
        final entry = _subtitleHistory[index];
        final timeStr =
            "${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}";

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.visualSurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: index == 0 ? AppShadows.small : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  color: AppColors.visualPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.text,
                  style: TextStyle(
                    color: index == 0
                        ? AppColors.visualText
                        : AppColors.visualTextMuted,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Clear button
          Expanded(
            child: GestureDetector(
              onTap: _clearHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.visualSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.small,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.clear_all, color: AppColors.visualTextMuted),
                    const SizedBox(width: 8),
                    Text(
                      "Clear",
                      style: TextStyle(
                        color: AppColors.visualTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Toggle button
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _toggleListening,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _isListening
                      ? const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        )
                      : AppColors.visualPrimaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening
                              ? const Color(0xFFEF4444)
                              : AppColors.visualPrimary)
                          .withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isListening ? "Stop" : "Start Listening",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtitleEntry {
  final String text;
  final DateTime timestamp;

  _SubtitleEntry({required this.text, required this.timestamp});
}
