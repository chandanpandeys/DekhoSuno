import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        model: 'gemini-2.5-flash',
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
    return '''You are an AGENT assistant for DekhoSuno, an accessibility app. You can control the app and help users navigate features.

IMPORTANT RULES:
1. Respond in Hinglish (Hindi + English mix) - be friendly and accessible
2. Keep responses SHORT (max 2-3 sentences)  
3. You CAN open any app feature when user asks
4. You can take notes and set reminders
5. Be proactive - if user asks about a task, suggest opening the right feature

AVAILABLE FEATURES TO OPEN:
AUDIO MODE (for visually impaired):
- smart_camera: "Open camera", "kya dikh raha hai", "describe scene"
- currency_reader: "Check currency", "note pehchano", "rupees"
- light_detector: "Check light", "brightness", "roshni"
- text_reader: "Read text", "document", "OCR"
- guided_walking: "Help me walk", "navigation", "obstacles"
- mini_map: "Open map", "navigate somewhere", "directions"
- road_crossing: "Cross road", "traffic check", "road safe"

VISUAL MODE (for hearing impaired):
- live_subtitles: "Show subtitles", "caption", "speech to text"  
- sound_watch: "Sound alerts", "listen for sounds", "audio monitor"
- call_assistant: "Help with call", "phone call captions"
- sign_world: "Sign language", "learn signs", "ASL"

COMMANDS:
- [OPEN_FEATURE: feature_name] - Opens a feature
- [TAKE_NOTE: content] - Saves a note
- [SET_REMINDER: content] - Creates reminder
- [LIST_NOTES] - Shows saved notes
- [LIST_REMINDERS] - Shows reminders

EXAMPLES:
User: "I want to cross the road"
Response: [OPEN_FEATURE: road_crossing] Abhi road crossing assistant kholta hoon. Yeh feature traffic check karega.

User: "Help me read this document"  
Response: [OPEN_FEATURE: text_reader] Text reader khol raha hoon. Document camera ke saamne rakho.

User: "Note down my wifi password is 12345"
Response: [TAKE_NOTE: wifi password is 12345] Theek hai, password save kar diya.

Be helpful and proactive. If unsure which feature, ask the user.''';
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

  /// Add a reminder
  Future<void> addReminder(String content, {DateTime? dueTime}) async {
    final reminder = Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
      dueTime: dueTime,
    );
    _reminders.add(reminder);
    await _saveData();
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
