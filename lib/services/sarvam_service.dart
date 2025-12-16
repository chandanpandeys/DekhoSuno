import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SarvamService {
  final String _baseUrl =
      'https://api.sarvam.ai/speech-to-text'; // Hypothetical URL
  final String? _apiKey;

  SarvamService() : _apiKey = dotenv.env['SARVAM_API_KEY'];

  Future<String> transcribeAudio(File audioFile) async {
    if (_apiKey == null) {
      return "API Key missing.";
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'multipart/form-data',
      });
      request.files
          .add(await http.MultipartFile.fromPath('file', audioFile.path));
      request.fields['language_code'] = 'hi-IN'; // Hinglish/Hindi
      request.fields['model'] = 'saaras:v1'; // Hypothetical model name

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transcript'] ?? "";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Transcription failed.";
    }
  }
}
