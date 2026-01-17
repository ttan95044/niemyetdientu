class ProcedureModel {
  final int id;
  final String code;
  final String name;

  final String? description;
  final String? implementationLevelName;
  final String? decisionNumber;
  final String? implementationResult;
  final String? requirementsForImplementation;

  final dynamic implementationLevelId;
  final bool isProcedureLookup;
  final bool isPublished;

  final dynamic procedureTypeId;
  final String? receivingAddress;

  final List<int> componentIds;
  final List<int> implementationAgencyIds;
  final List<int> submissionTypeIds;

  final String? procedureFieldName;
  final String? companyName;
  final String? authorizedAgencyName;
  final String? competentAgencyName;

  final DateTime? createDate;
  final DateTime? writeDate;

  final Map<String, dynamic>? raw;

  ProcedureModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.decisionNumber,
    this.implementationResult,
    this.requirementsForImplementation,
    this.implementationLevelId,
    this.implementationLevelName,
    this.isProcedureLookup = false,
    this.isPublished = false,
    this.procedureTypeId,
    this.receivingAddress,
    this.componentIds = const [],
    this.implementationAgencyIds = const [],
    this.submissionTypeIds = const [],
    this.procedureFieldName,
    this.companyName,
    this.authorizedAgencyName,
    this.competentAgencyName,
    this.createDate,
    this.writeDate,
    this.raw,
  });

  factory ProcedureModel.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) => v is String ? v : null;

    String getPairName(dynamic maybePair) {
      if (maybePair is List && maybePair.length > 1) {
        return maybePair[1]?.toString() ?? '';
      }
      return '';
    }

    List<int> toIntList(dynamic val) {
      if (val is List) {
        return val.whereType<int>().toList();
      }
      return <int>[];
    }

    DateTime? parseDate(dynamic v) {
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return null;
    }

    return ProcedureModel(
      id: json['id'] ?? 0,
      code: json['code']?.toString() ?? '',
      name: (json['display_name'] ?? json['name'])?.toString() ?? '',

      description: str(json['description']),
      decisionNumber: str(json['decision_number']),
      implementationResult: str(json['implementation_result']),
      requirementsForImplementation: str(
        json['requirements_for_implementation'],
      ),

      implementationLevelId: json['implementation_level_id'],
      implementationLevelName: getPairName(json['implementation_level_id']),

      isProcedureLookup: json['is_procedure_lookup'] == true,
      isPublished: json['is_published'] == true,

      procedureTypeId: json['procedure_type_id'],
      receivingAddress: str(json['receiving_address']),

      componentIds: toIntList(json['component_ids']),
      implementationAgencyIds: toIntList(json['implementation_agency_ids']),
      submissionTypeIds: toIntList(json['submission_type_ids']),

      procedureFieldName: getPairName(json['procedure_field_id']),
      companyName: getPairName(json['company_id']),
      authorizedAgencyName: getPairName(json['authorized_agency_id']),
      competentAgencyName: getPairName(json['competent_agency_id']),

      createDate: parseDate(json['create_date']),
      writeDate: parseDate(json['write_date']),

      raw: Map<String, dynamic>.from(json),
    );
  }
}
