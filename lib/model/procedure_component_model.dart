class ProcedureComponent {
  final int id;
  final String name;
  final String displayName;
  final int numberOfCopies;
  final int numberOfOriginals;
  final String? createDate;
  final String? writeDate;

  final List<dynamic>? companyId;
  final List<dynamic>? createUid;
  final List<dynamic>? writeUid;
  final List<dynamic>? procedureDefinitionId;

  final dynamic templateId;

  ProcedureComponent({
    required this.id,
    required this.name,
    required this.displayName,
    required this.numberOfCopies,
    required this.numberOfOriginals,
    this.createDate,
    this.writeDate,
    this.companyId,
    this.createUid,
    this.writeUid,
    this.procedureDefinitionId,
    this.templateId,
  });

  factory ProcedureComponent.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) => v is String ? v : null;

    return ProcedureComponent(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      numberOfCopies: json['number_of_copies'] ?? 0,
      numberOfOriginals: json['number_of_originals'] ?? 0,
      createDate: str(json['create_date']),
      writeDate: str(json['write_date']),
      companyId: json['company_id'],
      createUid: json['create_uid'],
      writeUid: json['write_uid'],
      procedureDefinitionId: json['procedure_definition_id'],
      templateId: json['template_id'],
    );
  }
}
