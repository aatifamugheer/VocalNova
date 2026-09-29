import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/speech_result.dart';

class SpeechApiService {
  /// Base URL of Member 2's Speech AI FastAPI server.
  ///
  /// For Android emulator, use 10.0.2.2 instead of 127.0.0.1.
  /// For a physical Android phone, replace this with the PC's
  /// local network IP address.
  final String baseUrl;

  SpeechApiService({
    String? baseUrl,
 }) : baseUrl = baseUrl ?? 'http://127.0.0.1:8000';

  /// Sends an audio recording to Member 2's Speech AI API.
  Future<SpeechResult> analyzeSpeech({
    required String targetWord,
    required String attemptId,
    required File audioFile,
    String language = 'en-US',
  }) async {
    final uri = Uri.parse('$baseUrl/analyze-speech');

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['targetWord'] = targetWord;
    request.fields['attemptId'] = attemptId;
    request.fields['language'] = language;

    request.files.add(
      await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
      ),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Speech AI returned an invalid response.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage =
          data['error']?.toString() ??
          'Speech analysis failed with status ${response.statusCode}.';

      throw Exception(errorMessage);
    }

    return SpeechResult.fromMap(data);
  }

  /// Checks whether Member 2's Speech AI server is running.
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      return data is Map<String, dynamic> &&
          data['status'] == 'healthy';
    } catch (_) {
      return false;
    }
  }
}