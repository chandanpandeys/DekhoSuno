import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _visionModel;
  late final GenerativeModel _textModel;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }

    // Use Gemini 2.5 Flash for all models for speed and multimodal capabilities
    _visionModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );

    _textModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  Future<String> describeScene(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
              "You are a guide for a blind child. Describe this image in simple Hinglish (Hindi + English mix). Keep it under 2 sentences."),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      return response.text ?? "Kuch saaf dikh nahi raha.";
    } catch (e) {
      return "Maaf kijiye, main dekh nahi pa raha.";
    }
  }

  Future<String> identifyCurrency(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
              "Identify the Indian Currency denomination value. Return ONLY the number. If no currency, say '0'."),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      return response.text?.trim() ?? "0";
    } catch (e) {
      return "0";
    }
  }

  Future<String> chatWithImage(String prompt, File? imageFile) async {
    try {
      List<Part> parts = [TextPart(prompt)];
      if (imageFile != null) {
        final imageBytes = await imageFile.readAsBytes();
        parts.add(DataPart('image/jpeg', imageBytes));
      }

      final content = [Content.multi(parts)];
      final response = await _visionModel.generateContent(content);
      return response.text ?? "Samajh nahi aaya.";
    } catch (e) {
      return "Koi gadbad ho gayi.";
    }
  }

  /// Analyze walking path for obstacles and hazards
  /// Returns structured response for guided walking feature
  Future<String> analyzeWalkingPath(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(
              '''You are a navigation assistant helping a blind person walk safely.
Analyze this forward-facing camera view for obstacles and hazards in the walking path.

For EACH obstacle or object that could affect walking:
1. Identify what it is (use common names: chair, table, person, wall, stairs, etc.)
2. Estimate distance from camera (use visual cues like size, perspective, ground position)
3. Indicate position: left, center, or right of the walking path
4. Rate urgency: critical (<1m), high (1-2m), medium (2-4m), low (>4m)

RESPOND IN THIS EXACT FORMAT:
PATH_STATUS: [clear/caution/blocked]
OBSTACLES:
- [name]|[distance in meters]|[left/center/right]|[critical/high/medium/low]
GUIDANCE: [One short sentence navigation instruction in Hinglish]

EXAMPLE if obstacles found:
PATH_STATUS: caution
OBSTACLES:
- chair|2.5|left|medium
- table|1.0|center|critical
GUIDANCE: Ruko! Table seedha aage hai, thoda left jao.

EXAMPLE if path is clear:
PATH_STATUS: clear
OBSTACLES: none
GUIDANCE: Raasta saaf hai, aage badho.

IMPORTANT: Be concise. Max 4 obstacles. Focus on what's in the walking path.'''),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _visionModel.generateContent(content);
      return response.text ??
          "PATH_STATUS: unknown\nOBSTACLES: none\nGUIDANCE: Analysis failed.";
    } catch (e) {
      return "PATH_STATUS: unknown\nOBSTACLES: none\nGUIDANCE: Kuch gadbad ho gayi.";
    }
  }
}
