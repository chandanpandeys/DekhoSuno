import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_error.dart';

/// Foreground task handler for background wake word detection
///
/// This runs as an Android foreground service to detect wake words
/// even when the app is closed or in background.
@pragma('vm:entry-point')
class WakeWordTaskHandler extends TaskHandler {
  PorcupineManager? _porcupineManager;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('WakeWordTaskHandler: Starting background service');
    await _initializePorcupine();
  }

  Future<void> _initializePorcupine() async {
    try {
      // Load environment variables
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint('WakeWordTaskHandler: Could not load .env: $e');
      }

      final accessKey = dotenv.env['PICOVOICE_ACCESS_KEY'] ?? '';

      if (accessKey.isEmpty) {
        debugPrint('WakeWordTaskHandler: No access key found');
        return;
      }

      // Initialize with custom "help decko sueno" wake word
      const keywordAsset = 'assets/help-decko-sueno_en_android_v4_0_0.ppn';

      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        accessKey,
        [keywordAsset],
        _onWakeWordDetected,
        sensitivities: [0.7],
        errorCallback: _onPorcupineError,
      );

      await _porcupineManager?.start();
      debugPrint(
          'WakeWordTaskHandler: Started with "help decko sueno" wake word');
    } on PorcupineException catch (e) {
      debugPrint('WakeWordTaskHandler: Porcupine error: ${e.message}');
    } catch (e) {
      debugPrint('WakeWordTaskHandler: Error initializing: $e');
    }
  }

  void _onWakeWordDetected(int keywordIndex) {
    debugPrint('WakeWordTaskHandler: Wake word detected!');

    // Update notification
    FlutterForegroundTask.updateService(
      notificationTitle: 'DekhoSuno Active',
      notificationText: 'Wake word detected!',
    );

    // Launch the app to foreground
    FlutterForegroundTask.launchApp();
  }

  void _onPorcupineError(PorcupineException error) {
    debugPrint('WakeWordTaskHandler: Porcupine error: ${error.message}');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Not needed for wake word detection
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('WakeWordTaskHandler: Destroying background service');
    await _porcupineManager?.stop();
    await _porcupineManager?.delete();
    _porcupineManager = null;
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final String? command = data['command'];
      if (command == 'stop') {
        _porcupineManager?.stop();
      } else if (command == 'start') {
        _porcupineManager?.start();
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stopButton') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {
    debugPrint('WakeWordTaskHandler: Notification dismissed');
  }
}

/// Initialize foreground task service
void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'dekhosuno_wake_word',
      channelName: 'DekhoSuno Wake Word',
      channelDescription: 'Listening for "Help DekhoSuno" wake word',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );
}

/// Start the wake word foreground service
Future<ServiceRequestResult> startWakeWordService() async {
  if (await FlutterForegroundTask.isRunningService) {
    return FlutterForegroundTask.restartService();
  } else {
    return FlutterForegroundTask.startService(
      notificationTitle: 'DekhoSuno Listening',
      notificationText: 'Say "Help DekhoSuno" to activate',
      callback: startCallback,
    );
  }
}

/// Stop the wake word foreground service
Future<ServiceRequestResult> stopWakeWordService() {
  return FlutterForegroundTask.stopService();
}

/// Check if wake word service is running
Future<bool> isWakeWordServiceRunning() {
  return FlutterForegroundTask.isRunningService;
}

/// Callback entry point for the foreground task
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(WakeWordTaskHandler());
}
