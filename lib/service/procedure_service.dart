import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:niemyetdientu/model/procedure_model.dart';
import 'package:niemyetdientu/model/procedure_detail_model.dart';

class ProcedureService {
  static const String _baseUrl = 'http://42.1.111.50:8065/api';

  /// 🧠 Lấy danh sách **thủ tục con** theo field_code
  static Future<List<ProcedureModel>> fetchProceduresByFieldCode(
    String fieldCode,
  ) async {
    final url = Uri.parse('$_baseUrl/procedures/$fieldCode');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => ProcedureModel.fromJson(e)).toList();
      } else {
        throw Exception('Lỗi tải dữ liệu thủ tục: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API procedures/$fieldCode: $e');
    }
  }

  /// 📄 Lấy **chi tiết một thủ tục** theo ID
  static Future<ProcedureDetail?> fetchProcedureDetail(String code) async {
    final url = Uri.parse('$_baseUrl/procedure/$code');
    print(url);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ProcedureDetail.fromJson(data);
      } else {
        throw Exception('Lỗi tải chi tiết thủ tục: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối API procedure/$code: $e');
    }
  }
}
