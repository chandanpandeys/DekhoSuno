import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:senseplay/services/assistant_service.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

/// AI Assistant Popup Widget
/// A floating, glassmorphism-styled chat interface accessible from any screen
class AIAssistantPopup extends StatefulWidget {
  final bool isAudioMode;

  const AIAssistantPopup({super.key, this.isAudioMode = false});

  /// Show the AI Assistant as a modal bottom sheet popup
  static void show(BuildContext context, {bool isAudioMode = false}) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => AIAssistantPopup(isAudioMode: isAudioMode),
    );
  }

  @override
  State<AIAssistantPopup> createState() => _AIAssistantPopupState();
}

class _AIAssistantPopupState extends State<AIAssistantPopup>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  late AssistantService _assistantService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isListening = false;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _autoListenEnabled = true;

  @override
  void initState() {
    super.initState();
    _assistantService = AssistantService();
    _setupAnimations();
    _initializeAssistant();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeAssistant() async {
    await _tts.setLanguage("hi-IN");
    await _tts.setSpeechRate(0.5);
    await _speechToText.initialize();

    final success = await _assistantService.initialize();
    if (success && mounted) {
      setState(() => _isInitialized = true);

      // Welcome message
      await Future.delayed(const Duration(milliseconds: 300));
      await _speak("Haan boliye, kya madad chahiye?");
    }
  }

  Future<void> _speak(String text) async {
    await Vibration.vibrate(duration: 50);
    _isSpeaking = true;

    // Set up completion handler for auto-listen in audio mode
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (widget.isAudioMode &&
          _autoListenEnabled &&
          mounted &&
          !_isListening) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && !_isSpeaking && !_isListening) {
            _startVoiceInput();
          }
        });
      }
    });

    await _tts.speak(text);
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _textController.clear();
    setState(() {});
    _scrollToBottom();

    final response = await _assistantService.sendMessage(message);
    await _speak(response);

    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startVoiceInput() async {
    if (_isListening) return;

    setState(() => _isListening = true);
    _pulseController.repeat(reverse: true);
    await Vibration.vibrate(duration: 100);

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          setState(() => _isListening = false);
          _pulseController.stop();
          _pulseController.reset();
          _speechToText.stop();
          _sendMessage(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_IN',
    );

    // Timeout after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (_isListening && mounted) {
        setState(() => _isListening = false);
        _pulseController.stop();
        _pulseController.reset();
        _speechToText.stop();
      }
    });
  }

  void _stopVoiceInput() {
    if (_isListening) {
      _speechToText.stop();
      _pulseController.stop();
      _pulseController.reset();
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _tts.stop();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        gradient: widget.isAudioMode
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A28), Color(0xFF0A0A0F)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8F9FC), Color(0xFFFFFFFF)],
              ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: widget.isAudioMode
              ? AppColors.audioPrimary.withOpacity(0.3)
              : AppColors.visualPrimary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isAudioMode
                    ? AppColors.audioPrimary
                    : AppColors.visualPrimary)
                .withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildChatArea()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final primaryColor =
        widget.isAudioMode ? AppColors.audioPrimary : AppColors.visualPrimary;
    final textColor =
        widget.isAudioMode ? AppColors.audioText : AppColors.visualText;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              // AI Avatar with glow effect
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: widget.isAudioMode
                      ? AppColors.audioPrimaryGradient
                      : AppColors.visualPrimaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Assistant",
                      style: AppTypography.titleLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isListening ? "Listening..." : "Online",
                          style: AppTypography.bodySmall.copyWith(
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Close button
              Semantics(
                label: "Close AI assistant",
                button: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: textColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    final messages = _assistantService.conversationHistory;
    final textColor =
        widget.isAudioMode ? AppColors.audioText : AppColors.visualText;
    final mutedColor = widget.isAudioMode
        ? AppColors.audioTextMuted
        : AppColors.visualTextMuted;
    final primaryColor =
        widget.isAudioMode ? AppColors.audioPrimary : AppColors.visualPrimary;

    if (messages.isEmpty && !_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Initializing...",
              style: TextStyle(color: mutedColor),
            ),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "Mujhse kuch bhi poochiye!",
              style: AppTypography.bodyLarge.copyWith(
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Notes, reminders, ya koi bhi sawaal",
              style: AppTypography.bodySmall.copyWith(
                color: mutedColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (_assistantService.isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _assistantService.isProcessing) {
          return _buildLoadingBubble();
        }
        return _buildMessageBubble(messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    final primaryColor =
        widget.isAudioMode ? AppColors.audioPrimary : AppColors.visualPrimary;
    final surfaceColor =
        widget.isAudioMode ? AppColors.audioSurface : AppColors.visualSurface;
    final textColor =
        widget.isAudioMode ? AppColors.audioText : AppColors.visualText;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? primaryColor : surfaceColor,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: (isUser ? primaryColor : Colors.black).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : textColor,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    final surfaceColor =
        widget.isAudioMode ? AppColors.audioSurface : AppColors.visualSurface;
    final primaryColor =
        widget.isAudioMode ? AppColors.audioPrimary : AppColors.visualPrimary;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: SizedBox(
          width: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                List.generate(3, (i) => _buildTypingDot(primaryColor, i * 150)),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDot(Color color, int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    final primaryColor =
        widget.isAudioMode ? AppColors.audioPrimary : AppColors.visualPrimary;
    final surfaceColor =
        widget.isAudioMode ? AppColors.audioSurface : AppColors.visualSurface;
    final textColor =
        widget.isAudioMode ? AppColors.audioText : AppColors.visualText;
    final mutedColor = widget.isAudioMode
        ? AppColors.audioTextMuted
        : AppColors.visualTextMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: "Type or tap mic...",
                    hintStyle: TextStyle(color: mutedColor),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Voice button with pulse animation
            Semantics(
              label: _isListening ? "Stop voice input" : "Start voice input",
              button: true,
              child: GestureDetector(
                onTap: _isListening ? _stopVoiceInput : _startVoiceInput,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _isListening
                              ? const LinearGradient(colors: [
                                  Color(0xFFFF6B6B),
                                  Color(0xFFEE5A5A)
                                ])
                              : (widget.isAudioMode
                                  ? AppColors.audioPrimaryGradient
                                  : AppColors.visualPrimaryGradient),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? Colors.red : primaryColor)
                                  .withOpacity(0.4),
                              blurRadius: _isListening ? 16 : 8,
                              spreadRadius: _isListening ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
