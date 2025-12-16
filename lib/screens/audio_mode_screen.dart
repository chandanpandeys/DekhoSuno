import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:senseplay/services/ml_service.dart';
import 'package:senseplay/services/preferences_service.dart';
import 'package:senseplay/screens/settings_screen.dart';
import 'package:senseplay/widgets/activity_log.dart';
import 'package:senseplay/widgets/keyboard_shortcuts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AudioModeScreen extends StatefulWidget {
  const AudioModeScreen({super.key});

  @override
  State<AudioModeScreen> createState() => _AudioModeScreenState();
}

class _AudioModeScreenState extends State<AudioModeScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final MLService _mlService = MLService();
  final PreferencesService _prefs = PreferencesService();

  CameraController? _cameraController;
  bool _isProcessing = false;
  final bool _isListening = false;
  String _currentLang = 'en';

  final List<String> _menuItems = [
    "Read Text",
    "Describe Scene",
    "Find Object",
    "Settings"
  ];
  int _currentIndex = 0;

  final List<ActivityLogEntry> _activityLog = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _addLog(String icon, String source, String message,
      {Duration? duration}) {
    if (!mounted) return;
    setState(() {
      _activityLog.add(ActivityLogEntry(
        timestamp: DateTime.now(),
        icon: icon,
        source: source,
        message: message,
        duration: duration,
      ));
      if (_activityLog.length > 50) {
        _activityLog.removeAt(0);
      }
    });
  }

  Future<void> _initializeServices() async {
    _addLog('🚀', 'System', 'Initializing...');
    await _initializePreferences();
    await _initializeTTS();
    await _initializeCamera();
    _addLog('✅', 'Ready', 'Press 1-4 or click menu');
  }

  Future<void> _initializePreferences() async {
    _currentLang = await _prefs.getLanguage();
  }

  Future<void> _initializeTTS() async {
    double speed = await _prefs.getVoiceSpeed();
    await _flutterTts.setLanguage(_currentLang == 'hi' ? 'hi-IN' : 'en-US');
    await _flutterTts.setSpeechRate(speed);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          _cameraController = CameraController(
            cameras.first,
            ResolutionPreset.medium,
            enableAudio: false,
          );
          await _cameraController!.initialize();
          if (mounted) {
            setState(() {});
            _addLog('📷', 'Camera', 'Ready');
          }
        }
      }
    } catch (e) {
      _addLog('❌', 'Camera', 'Failed: $e');
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _selectMenuItem(int index) {
    setState(() => _currentIndex = index);
    final item = _menuItems[index];
    _addLog('👆', 'Menu', item);

    if (item == "Settings") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
    } else if (item == "Describe Scene") {
      _processTask("describe");
    } else if (item == "Read Text") {
      _processTask("read");
    } else if (item == "Find Object") {
      _addLog('🔍', 'Find', 'Feature coming soon!');
      _speak("Find object feature coming soon");
    }
  }

  Future<void> _processTask(String task) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _addLog('⚠️', 'Error', 'Camera not ready');
      return;
    }

    if (_isProcessing) {
      _addLog('⚠️', 'Busy', 'Already processing');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final startTime = DateTime.now();
      final image = await _cameraController!.takePicture();

      if (task == "describe") {
        _addLog('🤖', 'Gemini', 'Analyzing...');
        final response = await _mlService.describeScene(File(image.path));
        final duration = DateTime.now().difference(startTime);
        _addLog('✅', 'Scene', response, duration: duration);
        _speak(response);
      } else if (task == "read") {
        _addLog('🤖', 'Gemini', 'Reading...');
        final response = await _mlService.readText(File(image.path));
        final duration = DateTime.now().difference(startTime);
        _addLog('📝', 'Text', response, duration: duration);
        _speak(response);
      }
    } catch (e) {
      _addLog('❌', 'Error', '$e');
      _speak("Sorry, an error occurred");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _cameraController?.dispose();
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('🎤 Audio Mode'),
        backgroundColor: Colors.black,
        actions: [
          GeminiStatusBadge(
            isProcessing: _isProcessing,
            statusText: _isProcessing ? '🤖 Processing...' : null,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Press 1-4 for menu items',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keyboard Shortcuts'),
                  content: const Text(
                    '1 or R - Read Text\n'
                    '2 or D - Describe Scene\n'
                    '3 or F - Find Object\n'
                    '4 or S - Settings',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: KeyboardShortcuts(
        onReadText: () => _selectMenuItem(0),
        onDescribeScene: () => _selectMenuItem(1),
        onFindObject: () => _selectMenuItem(2),
        onSettings: () => _selectMenuItem(3),
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Menu Sidebar
        Container(
          width: 250,
          color: Colors.black,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Quick Menu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _menuItems.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return ListTile(
                      leading: Icon(
                        _getIconForMenuItem(_menuItems[index]),
                        color: isSelected ? Colors.tealAccent : Colors.white54,
                      ),
                      title: Text(
                        '[${index + 1}] ${_menuItems[index]}',
                        style: TextStyle(
                          color:
                              isSelected ? Colors.tealAccent : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: Colors.teal.withOpacity(0.2),
                      onTap: () => _selectMenuItem(index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Camera View
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black87,
            child: _cameraController != null &&
                    _cameraController!.value.isInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      CameraPreview(_cameraController!),
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.tealAccent,
                              strokeWidth: 4,
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),

        // Activity Log
        Container(
          width: 350,
          color: const Color(0xFF0A0A0A),
          padding: const EdgeInsets.all(16),
          child: ActivityLogWidget(entries: _activityLog),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: Text(
        'Please use desktop/web for full experience',
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
    );
  }

  IconData _getIconForMenuItem(String item) {
    switch (item) {
      case "Read Text":
        return Icons.text_fields_rounded;
      case "Describe Scene":
        return Icons.image_search_rounded;
      case "Find Object":
        return Icons.search_rounded;
      case "Settings":
        return Icons.settings_rounded;
      default:
        return Icons.circle;
    }
  }
}
