import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:niemyetdientu/service/base.dart';

class ChatbotService {
  // static const String _baseUrl = 'http://pat-tuannm-pc:5000/api/chatbot';
  static const String _baseUrl = '${BaseService.apiUrlChatbot}/mistral';

  /// Gửi prompt đến server Flask và nhận phản hồi
  static Future<String> sendPrompt(String prompt) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': prompt}),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi server');
    }

    final json = jsonDecode(response.body);

    // API returns: { "status": true, "message": [ {...} ] }
    if (json['status'] == true && json['message'] != null) {
      final message = json['message'];
      if (message is List) {
        final sb = StringBuffer();
        // If multiple results, show header
        if (message.length > 1) {
          sb.writeln('Tìm thấy ${message.length} thông tin liên quan\n');
        }
        for (var i = 0; i < message.length; i++) {
          final item = message[i];
          if (item is Map) {
            final code = item['code'] ?? '';
            final decision = item['decision_number'] ?? '';
            final name = item['name'] ?? '';
            final typeName = item['type_name'] ?? '';
            final field = item['field_name'] ?? '';
            final isPublished = item['is_published'] == true ? 'Có' : 'Không';

            if (message.length > 1) {
              sb.writeln('### ${i + 1}. ${name.toString()}');
            } else if (name.toString().isNotEmpty) {
              sb.writeln('### ${name.toString()}');
            }

            if (code.toString().isNotEmpty) {
              sb.writeln('- **Mã:** ${code.toString()}');
            }
            if (decision.toString().isNotEmpty) {
              sb.writeln('- **Số quyết định:** ${decision.toString()}');
            }
            if (typeName.toString().isNotEmpty) {
              sb.writeln('- **Loại:** ${typeName.toString()}');
            }
            if (field.toString().isNotEmpty) {
              sb.writeln('- **Lĩnh vực:** ${field.toString()}');
            }
            sb.writeln('- **Đã phát hành:** $isPublished\n');
          } else {
            sb.writeln('- ${item.toString()}\n');
          }
        }
        return sb.toString();
      }
      return message.toString();
    }

    return 'Chatbot không có phản hồi.';
  }
}
