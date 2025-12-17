import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:senseplay/services/notification_service.dart';

/// Message in conversation history
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'],
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

/// Note stored by the assistant
class Note {
  final String id;
  final String content;
  final DateTime createdAt;
  final String? category;

  Note({
    required this.id,
    required this.content,
    required this.createdAt,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'category': category,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
        category: json['category'],
      );
}

/// Reminder stored by the assistant
class Reminder {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime? dueTime;
  bool isCompleted;

  Reminder({
    required this.id,
    required this.content,
    required this.createdAt,
    this.dueTime,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'dueTime': dueTime?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
        dueTime:
            json['dueTime'] != null ? DateTime.parse(json['dueTime']) : null,
        isCompleted: json['isCompleted'] ?? false,
      );
}

/// Command parsed from user input
class AssistantCommand {
  final String
      type; // 'note', 'reminder', 'open_feature', 'chat', 'list_notes', 'list_reminders'
  final String? content;
  final String? featureName;

  AssistantCommand({
    required this.type,
    this.content,
    this.featureName,
  });
}

/// Personalized AI Assistant Service
/// Provides conversational AI with memory, notes, reminders, and app control
class AssistantService extends ChangeNotifier {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  final List<ChatMessage> _conversationHistory = [];
  final List<Note> _notes = [];
  final List<Reminder> _reminders = [];

  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _lastError;

  // Callbacks for app control
  Function(String featureName)? onOpenFeature;
  Function(String message)? onSpeak;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  String? get lastError => _lastError;
  List<ChatMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);
  List<Note> get notes => List.unmodifiable(_notes);
  List<Reminder> get reminders => List.unmodifiable(_reminders);
  List<Reminder> get pendingReminders =>
      _reminders.where((r) => !r.isCompleted).toList();

  /// Initialize the assistant
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        _lastError = 'Gemini API key not found';
        return false;
      }

      _model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
      );

      // Start chat with system prompt as first message
      _chatSession = _model.startChat(history: [
        Content.text(_getSystemPrompt()),
      ]);

      // Load saved data
      await _loadData();

      _isInitialized = true;
      _lastError = null;
      debugPrint('AssistantService: Initialized successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to initialize: $e';
      debugPrint('AssistantService: $_lastError');
      return false;
    }
  }

  String _getSystemPrompt() {
    return '''You are a friendly, warm AI assistant named DekhoSuno Assistant for an accessibility app.

PERSONALITY & CONVERSATION STYLE:
- Be warm, friendly, and conversational like a helpful friend
- Respond naturally to greetings, questions, jokes, and casual chat
- Use Hinglish (Hindi + English mix) for relatability
- Keep responses SHORT (1-3 sentences max)
- Show empathy and understanding

WHEN TO USE COMMANDS:
- ONLY use [OPEN_FEATURE:] when user EXPLICITLY asks to open something
- For general questions, just answer naturally WITHOUT commands
- For "I want to..." or "Can you help me..." - suggest the feature first, don't auto-open

CAPABILITIES:
1. Natural conversation - greetings, questions, jokes, casual chat
2. App navigation - open features when explicitly requested
3. Notes & reminders - save user information when asked
4. Helpful suggestions - recommend features based on user needs

AVAILABLE FEATURES (use only when explicitly requested):
AUDIO MODE (for visually impaired):
- smart_camera: Camera/scene description
- currency_reader: Currency/note identification  
- light_detector: Light/brightness check
- text_reader: Read text/documents/OCR
- guided_walking: Walking navigation/obstacles
- mini_map: Map/directions/navigation
- road_crossing: Road crossing/traffic safety

VISUAL MODE (for hearing impaired):
- live_subtitles: Live captions/speech-to-text
- sound_watch: Sound/audio alerts
- call_assistant: Call transcription
- sign_world: Sign language learning

COMMANDS (use sparingly):
- [OPEN_FEATURE: feature_name] - Opens a feature
- [TAKE_NOTE: content] - Saves a note
- [SET_REMINDER: content] - Creates reminder
- [LIST_NOTES] - Shows saved notes
- [LIST_REMINDERS] - Shows reminders

CONVERSATION EXAMPLES:
User: "Hi, how are you?"
Response: Namaste! Main bilkul theek hoon, aap kaise ho? Batao, aaj kya madad kar sakta hoon?

User: "What can you do?"
Response: Main bahut kuch kar sakta hoon! Camera se cheezein describe kar sakta hoon, text padh sakta hoon, currency identify kar sakta hoon, aur aapke notes bhi save kar sakta hoon. Kya try karna chahoge?

User: "Tell me a joke"
Response: Ek joke sunao? Teacher ne pucha - Beta, tum late kyun aaye? Student bola - Raasta pooch raha tha, maine bata diya! 😄

User: "I need to read something"
Response: Kya padhna hai? Agar document ya text hai toh main Text Reader khol sakta hoon - camera ke saamne rakho aur main padh dunga.

User: "Open camera please"
Response: [OPEN_FEATURE: smart_camera] Camera khol raha hoon!

User: "Save this - my ATM pin is 1234"
Response: [TAKE_NOTE: ATM pin is 1234] Done! ATM pin save kar diya safely.

IMPORTANT: Be a helpful friend first, assistant second. If uncertain, ASK rather than assume.''';
  }

  /// Send a message to the assistant
  Future<String> sendMessage(String userMessage) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return 'Assistant not available. $lastError';
    }

    _isProcessing = true;
    notifyListeners();

    try {
      // Add user message to history
      _conversationHistory.add(ChatMessage(role: 'user', content: userMessage));

      // Build context with notes/reminders summary
      final context = _buildContextSummary();
      final fullPrompt =
          context.isNotEmpty ? '$context\n\nUser: $userMessage' : userMessage;

      // Get response from Gemini
      final response = await _chatSession.sendMessage(Content.text(fullPrompt));
      final responseText = response.text ?? 'Samajh nahi aaya.';

      // Parse and execute any commands
      final processedResponse = await _processResponse(responseText);

      // Add assistant response to history
      _conversationHistory
          .add(ChatMessage(role: 'assistant', content: processedResponse));

      // Save data periodically
      await _saveData();

      _isProcessing = false;
      notifyListeners();
      return processedResponse;
    } catch (e) {
      _isProcessing = false;
      _lastError = e.toString();
      notifyListeners();
      return 'Maaf kijiye, kuch gadbad ho gayi.';
    }
  }

  String _buildContextSummary() {
    final parts = <String>[];

    if (_notes.isNotEmpty) {
      parts.add('User has ${_notes.length} saved notes.');
    }

    final pending = pendingReminders;
    if (pending.isNotEmpty) {
      parts.add('User has ${pending.length} pending reminders.');
    }

    return parts.join(' ');
  }

  Future<String> _processResponse(String response) async {
    // Extract and process commands
    if (response.contains('[TAKE_NOTE:')) {
      final match = RegExp(r'\[TAKE_NOTE:\s*(.+?)\]').firstMatch(response);
      if (match != null) {
        final noteContent = match.group(1)!.trim();
        await addNote(noteContent);
        // Remove command from display response
        response = response.replaceAll(match.group(0)!, '').trim();
      }
    }

    if (response.contains('[SET_REMINDER:')) {
      final match = RegExp(r'\[SET_REMINDER:\s*(.+?)\]').firstMatch(response);
      if (match != null) {
        final reminderContent = match.group(1)!.trim();
        await addReminder(reminderContent);
        response = response.replaceAll(match.group(0)!, '').trim();
      }
    }

    if (response.contains('[OPEN_FEATURE:')) {
      final match = RegExp(r'\[OPEN_FEATURE:\s*(.+?)\]').firstMatch(response);
      if (match != null) {
        final featureName = match.group(1)!.trim().toLowerCase();
        onOpenFeature?.call(featureName);
        response = response.replaceAll(match.group(0)!, '').trim();
      }
    }

    if (response.contains('[LIST_NOTES]')) {
      final notesList = _notes.isEmpty
          ? 'Koi note nahi hai abhi.'
          : _notes.take(5).map((n) => '• ${n.content}').join('\n');
      response = response.replaceAll('[LIST_NOTES]', notesList).trim();
    }

    if (response.contains('[LIST_REMINDERS]')) {
      final remindersList = pendingReminders.isEmpty
          ? 'Koi pending reminder nahi hai.'
          : pendingReminders.take(5).map((r) => '• ${r.content}').join('\n');
      response = response.replaceAll('[LIST_REMINDERS]', remindersList).trim();
    }

    return response.isEmpty ? 'Done!' : response;
  }

  /// Add a note
  Future<void> addNote(String content) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
    );
    _notes.add(note);
    await _saveData();
    notifyListeners();
  }

  /// Add a reminder with optional time scheduling
  Future<void> addReminder(String content, {DateTime? dueTime}) async {
    // Try to parse time from content if not provided
    dueTime ??= NotificationService.parseTimeExpression(content);
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final reminder = Reminder(
      id: id,
      content: content,
      createdAt: DateTime.now(),
      dueTime: dueTime,
    );
    _reminders.add(reminder);
    await _saveData();
    
    // Schedule notification if time is set
    if (dueTime != null && dueTime.isAfter(DateTime.now())) {
      final notificationService = NotificationService();
      await notificationService.scheduleReminder(
        id: int.tryParse(id) ?? id.hashCode,
        title: 'DekhoSuno Reminder',
        body: content,
        scheduledTime: dueTime,
      );
    }
    
    notifyListeners();
  }

  /// Complete a reminder
  Future<void> completeReminder(String id) async {
    final reminder = _reminders.firstWhere((r) => r.id == id,
        orElse: () => throw Exception('Not found'));
    reminder.isCompleted = true;
    await _saveData();
    notifyListeners();
  }

  /// Delete a note
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveData();
    notifyListeners();
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _saveData();
    notifyListeners();
  }

  /// Clear conversation history
  Future<void> clearHistory() async {
    _conversationHistory.clear();
    await _saveData();
    notifyListeners();
  }

  /// Load saved data from SharedPreferences
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load conversation history (keep only last 20 messages)
      final historyJson = prefs.getString('assistant_history');
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _conversationHistory
            .addAll(decoded.map((j) => ChatMessage.fromJson(j)).toList());
        // Keep only last 20
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 20);
        }
      }

      // Load notes
      final notesJson = prefs.getString('assistant_notes');
      if (notesJson != null) {
        final List<dynamic> decoded = jsonDecode(notesJson);
        _notes.addAll(decoded.map((j) => Note.fromJson(j)).toList());
      }

      // Load reminders
      final remindersJson = prefs.getString('assistant_reminders');
      if (remindersJson != null) {
        final List<dynamic> decoded = jsonDecode(remindersJson);
        _reminders.addAll(decoded.map((j) => Reminder.fromJson(j)).toList());
      }

      debugPrint(
          'AssistantService: Loaded ${_conversationHistory.length} messages, ${_notes.length} notes, ${_reminders.length} reminders');
    } catch (e) {
      debugPrint('AssistantService: Error loading data: $e');
    }
  }

  /// Save data to SharedPreferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save only last 20 messages
      final historyToSave = _conversationHistory.length > 20
          ? _conversationHistory.sublist(_conversationHistory.length - 20)
          : _conversationHistory;
      await prefs.setString('assistant_history',
          jsonEncode(historyToSave.map((m) => m.toJson()).toList()));

      await prefs.setString('assistant_notes',
          jsonEncode(_notes.map((n) => n.toJson()).toList()));

      await prefs.setString('assistant_reminders',
          jsonEncode(_reminders.map((r) => r.toJson()).toList()));
    } catch (e) {
      debugPrint('AssistantService: Error saving data: $e');
    }
  }
}
