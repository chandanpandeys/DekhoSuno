import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:senseplay/services/assistant_service.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';

/// AI Assistant Screen
/// Conversational AI with notes, reminders, and app control
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  late AssistantService _assistantService;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _assistantService = AssistantService();
    _initializeAssistant();
  }

  Future<void> _initializeAssistant() async {
    await _tts.setLanguage("hi-IN");
    await _tts.setSpeechRate(0.5);
    await _speechToText.initialize();

    final success = await _assistantService.initialize();
    if (success) {
      _assistantService.onOpenFeature = _handleOpenFeature;

      // Welcome message
      await Future.delayed(const Duration(milliseconds: 500));
      await _speak(
          "Namaste! Main aapka assistant hoon. Aap mujhse kuch bhi pooch sakte hain, ya bolein 'note down' ya 'remind me'.");
    }

    if (mounted) setState(() {});
  }

  void _handleOpenFeature(String featureName) {
    // Navigate to the feature
    Navigator.of(context).pop(); // Close assistant first
    // The parent screen should handle the actual navigation
  }

  Future<void> _speak(String text) async {
    await Vibration.vibrate(duration: 50);
    await _tts.speak(text);
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _textController.clear();
    setState(() {});

    // Scroll to bottom
    _scrollToBottom();

    final response = await _assistantService.sendMessage(message);

    // Speak the response
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
    await Vibration.vibrate(duration: 100);
    await _speak("Boliye...");

    // Wait for TTS to finish
    await Future.delayed(const Duration(milliseconds: 800));

    // Start listening with speech_to_text
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          setState(() => _isListening = false);
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
        _speechToText.stop();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.audioBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildChatArea()),
            _buildInputArea(),
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
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.audioText,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Assistant",
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.audioText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${_assistantService.notes.length} notes • ${_assistantService.pendingReminders.length} reminders",
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.audioTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Notes/Reminders button
          GestureDetector(
            onTap: () => _showNotesReminders(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.audioSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notes_rounded,
                color: AppColors.audioPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    final messages = _assistantService.conversationHistory;

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.audioPrimaryGradient,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.assistant_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Aapka Personal Assistant",
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.audioText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Notes le sakta hoon, reminders set kar sakta hoon,\naur app features khol sakta hoon",
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.audioTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip("Note down my password"),
                _buildSuggestionChip("Remind me to call doctor"),
                _buildSuggestionChip("Open smart camera"),
                _buildSuggestionChip("Meri notes dikhao"),
              ],
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

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.audioPrimary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.audioPrimary.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.audioPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.audioPrimary : AppColors.audioSurface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.audioText,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.audioSurface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: const SizedBox(
          width: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TypingDot(delay: 0),
              _TypingDot(delay: 150),
              _TypingDot(delay: 300),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.audioSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          // Text input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.audioBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: AppColors.audioText),
                decoration: const InputDecoration(
                  hintText: "Type or tap mic to speak...",
                  hintStyle: TextStyle(color: AppColors.audioTextMuted),
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Voice button
          GestureDetector(
            onTap: _isListening ? null : _startVoiceInput,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: _isListening
                    ? const LinearGradient(
                        colors: [Colors.red, Colors.redAccent])
                    : AppColors.audioPrimaryGradient,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                _isListening ? Icons.hearing : Icons.mic_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotesReminders() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.audioSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DefaultTabController(
        length: 2,
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.audioTextMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TabBar(
                indicatorColor: AppColors.audioPrimary,
                labelColor: AppColors.audioPrimary,
                unselectedLabelColor: AppColors.audioTextMuted,
                tabs: [
                  Tab(text: "Notes (${_assistantService.notes.length})"),
                  Tab(
                      text:
                          "Reminders (${_assistantService.pendingReminders.length})"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildNotesList(),
                    _buildRemindersList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesList() {
    final notes = _assistantService.notes;
    if (notes.isEmpty) {
      return const Center(
        child: Text("No notes yet",
            style: TextStyle(color: AppColors.audioTextMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.audioBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  note.content,
                  style: const TextStyle(color: AppColors.audioText),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.audioTextMuted),
                onPressed: () => _assistantService.deleteNote(note.id),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRemindersList() {
    final reminders = _assistantService.pendingReminders;
    if (reminders.isEmpty) {
      return const Center(
        child: Text("No reminders",
            style: TextStyle(color: AppColors.audioTextMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.audioBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Checkbox(
                value: reminder.isCompleted,
                onChanged: (_) =>
                    _assistantService.completeReminder(reminder.id),
                activeColor: AppColors.audioPrimary,
              ),
              Expanded(
                child: Text(
                  reminder.content,
                  style: const TextStyle(color: AppColors.audioText),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.audioTextMuted),
                onPressed: () => _assistantService.deleteReminder(reminder.id),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Typing indicator dot
class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.audioPrimary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
