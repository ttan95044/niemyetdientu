import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:niemyetdientu/model/category_model.dart';
import 'package:niemyetdientu/service/base.dart';

class CategoryService {
  static final String apiUrl = "${BaseService.apiUrl}/fields";

  static Future<List<CategoryModel>> fetchCategories() async {
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
    switch (id) {
      case 1:
        return "0xFF9C27B0";
      case 2:
        return "0xFF00BCD4";
      case 3:
        return "0xFFE91E63";
      case 4:
        return "0xFF4CAF50";
      case 5:
        return "0xFFFF9800";
      case 6:
        return "0xFF795548";
      case 7:
        return "0xFF3F51B5";
      case 8:
        return "0xFF009688";
      case 9:
        return "0xFF673AB7";
      case 10:
        return "0xFFF44336";
      default:
        return "0xFF9E9E9E";
    }
  }
}
