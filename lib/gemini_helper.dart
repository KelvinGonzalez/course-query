import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String apiKey = String.fromEnvironment("GEMINI_KEY");

Future<List<double>> generateEmbedding(String text) async {
  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=$apiKey');
  final headers = {'Content-Type': 'application/json'};
  final payload = jsonEncode({
    "model": "models/text-embedding-004",
    "content": {
      "parts": [
        {"text": text}
      ]
    },
  });

  final response = await http.post(url, headers: headers, body: payload);
  final data = jsonDecode(response.body);
  return List<double>.from(data['embedding']['values']);
}

Future<String> fetchGeminiResponse(String text) async {
  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
  final headers = {'Content-Type': 'application/json'};
  final payload = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": text}
        ]
      }
    ]
  });

  final response = await http.post(url, headers: headers, body: payload);
  final data = jsonDecode(response.body);
  return data['candidates'][0]['content']['parts'][0]['text'];
}

Future<Map<String, dynamic>> getQueryData(String text) async {
  final query = (await rootBundle.loadString('assets/gemini_query.txt'))
      .replaceAll('{prompt}', text);
  final response = await fetchGeminiResponse(query);
  final data = jsonDecode(response.replaceAll(RegExp(r"```(json)?"), "").trim())
      as Map<String, dynamic>;
  for (var entry in data.entries) {
    if (entry.value != null &&
        ["course_info", "professor_name"].contains(entry.key)) {
      data[entry.key] = await generateEmbedding(entry.value);
    }
  }
  return data;
}
