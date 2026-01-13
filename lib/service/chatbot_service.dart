import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  // static const String _baseUrl = 'http://pat-tuannm-pc:5000/api/chatbot';
  static const String _baseUrl = 'http://42.1.111.50:4040/api/chatbot';

  /// Gửi prompt đến server Flask và nhận phản hồi
  static Future<String> sendPrompt(String prompt) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi server');
    }

    final json = jsonDecode(response.body);

    if (json['status'] == true &&
        json['data'] != null &&
        json['data']['answer'] != null) {
      return json['data']['answer'];
    }

    return 'Chatbot không có phản hồi.';
  }
}
