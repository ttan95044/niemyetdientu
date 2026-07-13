class TemplateInfo {
  final int id;
  final String name;

  TemplateInfo({required this.id, required this.name});

  factory TemplateInfo.fromJson(Map<String, dynamic> json) {
    return TemplateInfo(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}
