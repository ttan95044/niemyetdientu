import 'dart:convert';
import 'dart:io';

// ignore: unused_import
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'package:niemyetdientu/model/chatbot_result.dart';
import 'package:niemyetdientu/service/base.dart';

class ChatbotService {
  static const String _baseUrl =
      '${BaseService.apiUrlChatbot}/webhook/${BaseService.apiKeyChatbot}';

  static Future<List<ChatbotResult>> sendPrompt(String prompt) async {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;

    final client = IOClient(httpClient);

    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'chatInput': prompt}),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi server: ${response.statusCode}\n${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data
        .map((e) => ChatbotResult.fromJson(e))
        .take(5) // lấy tối đa 5 kết quả
        .toList();
  }
}
