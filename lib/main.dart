import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:senseplay/providers/settings_provider.dart';
import 'package:senseplay/providers/dynamic_theme_provider.dart';
import 'package:senseplay/services/gemini_service.dart';
import 'package:senseplay/services/sarvam_service.dart';
import 'package:senseplay/services/hardware_service.dart';
import 'package:senseplay/services/voice_command_service.dart';
import 'package:senseplay/services/wake_word_service.dart';
import 'package:senseplay/services/wake_word_task_handler.dart';
import 'package:senseplay/screens/landing_screen.dart';
import 'package:senseplay/screens/visual/home_screen.dart';
import 'package:senseplay/screens/audio/home_screen.dart';
import 'package:senseplay/theme/app_theme.dart';
import 'package:flutter_tts/flutter_tts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Gemini features may not work.");
  }

  // Initialize foreground task for wake word detection
  initForegroundTask();

  // Initialize voice command service
  final voiceService = VoiceCommandService();
  await voiceService.initialize();

  // Initialize wake word service
  final wakeWordService = WakeWordService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DynamicThemeProvider()),
        ChangeNotifierProvider.value(value: voiceService),
        ChangeNotifierProvider.value(value: wakeWordService),
        Provider(create: (_) => GeminiService()),
        Provider(create: (_) => SarvamService()),
        Provider(create: (_) => HardwareService()),
      ],
      child: const SensePlayApp(),
    ),
  );
}

class SensePlayApp extends StatefulWidget {
  const SensePlayApp({super.key});

  @override
  State<SensePlayApp> createState() => _SensePlayAppState();
}

class _SensePlayAppState extends State<SensePlayApp>
    with WidgetsBindingObserver {
  final FlutterTts _flutterTts = FlutterTts();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToShake();
      _setupWakeWordDetection();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flutterTts.stop();
    super.dispose();
  }

  void _listenToShake() {
    final hardwareService = context.read<HardwareService>();
    final settingsProvider = context.read<SettingsProvider>();

    hardwareService.onShake.listen((_) {
      debugPrint("Shake detected! Resetting app mode.");
      settingsProvider.clearPreferences();
    });
  }

  /// Setup wake word detection with callbacks
  void _setupWakeWordDetection() async {
    final wakeWordService = context.read<WakeWordService>();
    final settingsProvider = context.read<SettingsProvider>();

    // Set up wake word callback - single wake word: "Help DekhoSuno"
    wakeWordService.onWakeWordDetected = () async {
      debugPrint('Main: Wake word detected - activating app');
      await _flutterTts.speak("DekhoSuno activated!");
      // Show landing screen for mode selection
      settingsProvider.clearPreferences();
    };

    // Initialize and start wake word detection
    final success = await wakeWordService.initialize();
    if (success) {
      await wakeWordService.startListening();
      debugPrint('Main: Wake word detection started');

      // Also start background foreground service
      await startWakeWordService();
    } else {
      debugPrint(
          'Main: Failed to initialize wake word service: ${wakeWordService.errorMessage}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          // Dynamically switch theme based on app mode
          final theme = switch (settings.appMode) {
            AppMode.visual => AppTheme.visualTheme,
            AppMode.audio => AppTheme.audioTheme,
            AppMode.notSet => AppTheme.visualTheme, // Default to visual theme
          };

          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'DekhoSuno',
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: _buildHomeScreen(settings.appMode),
          );
        },
      ),
    );
  }

  Widget _buildHomeScreen(AppMode mode) {
    return AnimatedSwitcher(
      duration: AppAnimations.normal,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: switch (mode) {
        AppMode.visual => const VisualHomeScreen(key: ValueKey('visual')),
        AppMode.audio => const AudioHomeScreen(key: ValueKey('audio')),
        AppMode.notSet => const LandingScreen(key: ValueKey('landing')),
      },
    );
  }
}
