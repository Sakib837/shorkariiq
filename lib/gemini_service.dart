
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  /// targetLang: 'en' or 'bn' (Bangla)
  static Future<String> chatWithGemini(String prompt, {String targetLang = 'en'}) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) {
      return 'API key missing. Pass GEMINI_API_KEY with --dart-define.';
    }

    final langInstruction = targetLang == 'bn'
        ? 'Respond in Bengali (Bangla) using clear, simple language.'
        : 'Respond in English.';
    final finalPrompt = '$langInstruction\n\n$prompt';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": finalPrompt}
          ]
        }
      ]
    };

    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (resp.statusCode != 200) {
        return 'Sorry, I could not get a response right now (HTTP ${resp.statusCode}).';
      }
      final data = json.decode(resp.body);
      // Typical shape: candidates[0].content.parts[0].text
      final candidates = data['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        if (content is Map && content['parts'] is List && content['parts'].isNotEmpty) {
          final text = content['parts'][0]['text'];
          if (text is String) return text.trim();
        }
      }
      // fallback
      return data.toString();
    } catch (e) {
      return 'Request failed: $e';
    }
  }
}
