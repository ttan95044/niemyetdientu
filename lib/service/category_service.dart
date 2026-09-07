import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:niemyetdientu/model/category_model.dart';
import 'package:niemyetdientu/service/base.dart';

class CategoryService {
  static Future<List<CategoryModel>> fetchCategories({
    int companyId = 1,
  }) async {
    final String apiUrl = "${BaseService.apiUrl}/fields?company_id=$companyId";

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {'X-API-KEY': BaseService.apiKey, 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      return data.map((item) {
        final id = item['id'] as int;
        final model = CategoryModel.fromJson(item);

        return model.copyWith(icon: _getIconById(id), color: _getColorById(id));
      }).toList();
    } else {
      throw Exception('Lỗi tải danh mục: ${response.statusCode}');
    }
  }

  static String _getIconById(int id) {
    switch (id) {
      case 1:
        return "assets/icons/tuphap.svg";
      case 2:
        return "assets/icons/card.svg";
      case 3:
        return "assets/icons/xaydung.svg";
      case 4:
        return "assets/icons/laodong.svg";
      case 5:
        return "assets/icons/yte.svg";
      case 6:
        return "assets/icons/nongnghiep.svg";
      case 7:
        return "assets/icons/vanhoa.svg";
      case 8:
        return "assets/icons/thuongmai.svg";
      case 9:
        return "assets/icons/tochuc.svg";
      case 10:
        return "assets/icons/anninh.svg";
      default:
        return "assets/icons/default.svg";
    }
  }

  static String _getColorById(int id) {
    if (id <= 0) return "0xFF9C27B0";

    const int baseColorInt = 0xFF9C27B0;

    final Color baseColor = Color(baseColorInt);
    final HSLColor baseHsl = HSLColor.fromColor(baseColor);

    const double goldenAngle = 137.5;

    final double hue = (baseHsl.hue + (id - 1) * goldenAngle) % 360;

    final HSLColor newHsl = baseHsl.withHue(hue);

    final Color newColor = newHsl.toColor();

    final String hex = newColor.value
        .toRadixString(16)
        .padLeft(8, '0')
        .toUpperCase();

    return '0x$hex';
  }
}
