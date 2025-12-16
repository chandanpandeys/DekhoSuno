import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:senseplay/services/gemini_service.dart';
import 'package:senseplay/models/object_location.dart';

class MLService {
  final GeminiService _geminiService = GeminiService();

  // ML Kit instances (lazy loaded to avoid issues on unsupported platforms)
  ImageLabeler? _imageLabeler;
  ObjectDetector? _objectDetector;
  OnDeviceTranslator? _translator;
  TextRecognizer? _textRecognizer;

  bool get _useOnDeviceML =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<String> describeScene(File imageFile) async {
    // Always use Gemini for detailed scene description as it's smarter
    return await _geminiService.describeScene(imageFile);
  }

  Future<List<String>> detectObjects(File imageFile) async {
    if (_useOnDeviceML) {
      try {
        _imageLabeler ??= ImageLabeler(
            options: ImageLabelerOptions(confidenceThreshold: 0.7));
        final inputImage = InputImage.fromFile(imageFile);
        final labels = await _imageLabeler!.processImage(inputImage);
        return labels.map((l) => l.label).toList();
      } catch (e) {
        debugPrint("ML Kit Error: $e");
        // Fallback to Gemini
      }
    }

    // Fallback or non-mobile platform
    final description = await _geminiService.chatWithImage(
        "List the main objects in this image, separated by commas.", imageFile);
    return description.split(',').map((e) => e.trim()).toList();
  }

  Future<String> translateText(String text, String targetLangCode) async {
    if (_useOnDeviceML) {
      try {
        // Map language codes if necessary. Assuming targetLangCode is BCP-47 tag.
        // ML Kit uses TranslateLanguage enum.
        const sourceLang = TranslateLanguage.english;
        final targetLang = targetLangCode == 'hi'
            ? TranslateLanguage.hindi
            : TranslateLanguage.spanish; // Default/Example

        _translator = OnDeviceTranslator(
            sourceLanguage: sourceLang, targetLanguage: targetLang);
        return await _translator!.translateText(text);
      } catch (e) {
        debugPrint("Translation Error: $e");
      }
    }

    // Fallback to Gemini
    return await _geminiService.chatWithImage(
        "Translate this to $targetLangCode: $text", null);
  }

  Future<String> readText(File imageFile) async {
    if (_useOnDeviceML) {
      try {
        _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
        final inputImage = InputImage.fromFile(imageFile);
        final recognizedText = await _textRecognizer!.processImage(inputImage);

        if (recognizedText.text.isNotEmpty) {
          return recognizedText.text;
        }
      } catch (e) {
        debugPrint("Text Recognition Error: $e");
      }
    }

    // Fallback to Gemini for better handwriting/complex text support
    return await _geminiService.chatWithImage(
        "Read the text in this image exactly as it appears.", imageFile);
  }

  Future<ObjectLocation> findObjectInScene(
      File imageFile, String targetObject) async {
    // Use Gemini Vision for advanced object finding and spatial reasoning
    final response = await _geminiService.chatWithImage(
        """Analyze this image for a $targetObject. Respond in this exact format:
        
FOUND: yes/no
DIRECTION: left/right/center/up/down/not_found
DISTANCE: close/medium/far/not_found
SIZE_IN_FRAME: small/medium/large/not_found
GUIDANCE: Brief 1-sentence guidance on how to reach it
        
Example response if found:
FOUND: yes
DIRECTION: left
DISTANCE: medium
SIZE_IN_FRAME: medium
GUIDANCE: Move the camera left and slightly up, the $targetObject is at chest height.
        
Example response if not found:
FOUND: no
DIRECTION: not_found
DISTANCE: not_found
SIZE_IN_FRAME: not_found
GUIDANCE: I don't see a $targetObject in this view. Try scanning left or right.""",
        imageFile);

    return _parseObjectLocation(response, targetObject);
  }

  ObjectLocation _parseObjectLocation(String response, String objectName) {
    final lines = response.split('\n');
    bool found = false;
    String direction = 'not_found';
    String distance = 'not_found';
    String sizeInFrame = 'not_found';
    String guidance = 'I don\'t see a $objectName';

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('FOUND:')) {
        found = line.toLowerCase().contains('yes');
      } else if (line.startsWith('DIRECTION:')) {
        direction = line.split(':')[1].trim().toLowerCase();
      } else if (line.startsWith('DISTANCE:')) {
        distance = line.split(':')[1].trim().toLowerCase();
      } else if (line.startsWith('SIZE_IN_FRAME:')) {
        sizeInFrame = line.split(':')[1].trim().toLowerCase();
      } else if (line.startsWith('GUIDANCE:')) {
        guidance = line.substring(line.indexOf(':') + 1).trim();
      }
    }

    return ObjectLocation(
      found: found,
      objectName: objectName,
      direction: direction,
      distance: distance,
      sizeInFrame: sizeInFrame,
      guidanceText: guidance,
    );
  }

  void dispose() {
    _imageLabeler?.close();
    _objectDetector?.close();
    _translator?.close();
    _textRecognizer?.close();
  }
}
