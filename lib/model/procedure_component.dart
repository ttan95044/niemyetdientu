import 'package:niemyetdientu/model/template_info.dart';

class ProcedureComponent {
  final int id;
  final String name;

  final int numberOfCopies;
  final int numberOfOriginals;

  final TemplateInfo? template;

  ProcedureComponent({
    required this.id,
    required this.name,
    required this.numberOfCopies,
    required this.numberOfOriginals,
    this.template,
  });

  factory ProcedureComponent.fromJson(Map<String, dynamic> json) {
    return ProcedureComponent(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      numberOfCopies: json["number_of_copies"] ?? 0,
      numberOfOriginals: json["number_of_originals"] ?? 0,
      template: json["template"] is Map
          ? TemplateInfo.fromJson(json["template"])
          : null,
    );
  }
}
