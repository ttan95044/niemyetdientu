import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:niemyetdientu/model/procedure_model.dart';
import 'package:niemyetdientu/model/procedure_detail_model.dart';

class ProcedureService {
  /// 🌐 Base API
  static const String _baseUrl = 'http://42.1.111.50:8065/api';

  /// 🔐 API KEY (nên đưa sang .env khi build production)
  static const String _apiKey =
      '8c38f8c9cc90ca3fed786e537bd952bd18a82d1771d7774f7dbdbd3c35982bf2';

  /// 📦 Header dùng chung
  static const Map<String, String> _headers = {
    'X-API-KEY': _apiKey,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// 🧠 Lấy danh sách **thủ tục con** theo field_code
  static Future<List<ProcedureModel>> fetchProceduresByFieldCode(
    String fieldCode,
  ) async {
    final url = Uri.parse('$_baseUrl/procedures/$fieldCode');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => ProcedureModel.fromJson(e)).toList();
      } else {
        throw Exception('Lỗi tải danh sách thủ tục (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API procedures/$fieldCode: $e');
    }
  }

  /// 📄 Lấy **chi tiết một thủ tục** theo code
  static Future<ProcedureDetail?> fetchProcedureDetail(String code) async {
    final url = Uri.parse('$_baseUrl/procedure/$code');

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ProcedureDetail.fromJson(data);
      } else {
        throw Exception('Lỗi tải chi tiết thủ tục (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API procedure/$code: $e');
    }
  }
}
