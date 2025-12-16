// Basic Flutter widget test for DekhoSuno app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:senseplay/main.dart';
import 'package:senseplay/providers/settings_provider.dart';
import 'package:senseplay/services/gemini_service.dart';
import 'package:senseplay/services/sarvam_service.dart';
import 'package:senseplay/services/hardware_service.dart';

void main() {
  testWidgets('App loads landing screen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          Provider(create: (_) => GeminiService()),
          Provider(create: (_) => SarvamService()),
          Provider(create: (_) => HardwareService()),
        ],
        child: const SensePlayApp(),
      ),
    );

    // Wait for animations and async operations
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify we're on the landing screen with mode options
    expect(find.text('देखो'), findsOneWidget);
    expect(find.text('सुनो'), findsOneWidget);
  });
}
