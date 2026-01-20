import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:niemyetdientu/model/template_model.dart';
import 'package:niemyetdientu/service/base.dart';

class TemplateService {
  static const String _baseUrl = BaseService.apiUrl;

  /// 📦 Header dùng chung
  static const Map<String, String> _headers = {
    'X-API-KEY': BaseService.apiKey,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// 📄 Lấy template (PDF base64) theo template_id
  static Future<TemplateModel> fetchTemplateById(int templateId) async {
    debugPrint('🟣 [API] fetchTemplateById called with id = $templateId');
    debugPrint('🟣 [API] id runtimeType = ${templateId.runtimeType}');

    final url = Uri.parse('$_baseUrl/template/$templateId');
    debugPrint('🟣 [API] GET $url');

    final response = await http.get(url, headers: _headers);

    debugPrint('🟣 [API] statusCode = ${response.statusCode}');
    debugPrint('🟣 [API] body = ${response.body.substring(0, 200)}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return TemplateModel.fromJson(json);
    } else {
      throw Exception(
        'Không tải được template $templateId: '
        '${response.statusCode} - ${response.body}',
      );
    }
  }
}
