import 'package:niemyetdientu/model/category_model.dart';

String normalize(String text) {
  return text
      .toLowerCase()
      .replaceAll('-', '')
      .replaceAll(' ', '')
      .trim();
}

CategoryModel? findCategoryByField(
  String field,
  List<CategoryModel> categories,
) {
  try {
    return categories.firstWhere(
      (c) => normalize(c.title) == normalize(field),
    );
  } catch (e) {
    return null;
  }
}