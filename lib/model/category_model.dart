class CategoryModel {
  final int id;
  final String code;
  final String title;
  final bool note;
  final String icon;
  final String color;
  final List<String> children;

  CategoryModel({
    required this.id,
    required this.code,
    required this.title,
    required this.note,
    required this.icon,
    required this.color,
    required this.children,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json["id"] ?? 0,
      code: json["code"] ?? "",
      title: json["name"] ?? "",
      note: json["note"] ?? false,
      icon: "",
      color: "",
      children: const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "code": code,
      "name": title,
      "note": note,
      "icon": icon,
      "color": color,
      "children": children,
    };
  }

  CategoryModel copyWith({
    int? id,
    String? code,
    String? title,
    bool? note,
    String? icon,
    String? color,
    List<String>? children,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      note: note ?? this.note,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      children: children ?? this.children,
    );
  }
}
