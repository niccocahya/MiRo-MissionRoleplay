import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class GroqService {
  // API Key milikmu sudah terpasang!
  static const String _apiKey =
      'REDACTED_ROTATED_GROQ_KEY';
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> sendMessage({
    required List<Map<String, String>> chatHistory,
    required String systemPrompt,
  }) async {
    try {
      // Susun pesan: Masukkan System Prompt di urutan paling atas agar AI patuh
      final List<Map<String, String>> messages = [
        {'role': 'system', 'content': systemPrompt},
        ...chatHistory,
      ];

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama3-70b-8192", // Model paling canggih Llama-3 di Groq
          "messages": messages,
          "temperature":
              0.7, // Kreativitas AI (0.0 = Kaku, 1.0 = Sangat Kreatif)
          "max_tokens": 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint("Groq Error: ${response.body}");
        return "Waduh, Pinguin lagi pusing nih. Coba tanya lagi ya, Bunda! 🐧💦";
      }
    } catch (e) {
      debugPrint("Groq Exception: $e");
      return "Maaf, koneksi internet Pinguin sepertinya terputus. 📶🐧";
    }
  }
}
