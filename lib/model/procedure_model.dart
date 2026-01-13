class ProcedureModel {
  final int id;
  final String code;
  final String name; // display_name hoặc name
  final String description;
  final String? decisionNumber;
  final String? implementationResult;
  final String? requirementsForImplementation;
  final dynamic implementationLevelId; // có thể bool hoặc int
  final bool isProcedureLookup;
  final bool isPublished;
  final dynamic procedureTypeId; // có thể false or int
  final dynamic receivingAddress; // có thể false or string
  final List<int> componentIds;
  final List<int> implementationAgencyIds;
  final List<int> submissionTypeIds;
  final String? procedureFieldName;
  final String? companyName;
  final String? authorizedAgencyName;
  final String? competentAgencyName;
  final DateTime? createDate;
  final DateTime? writeDate;

  // giữ raw JSON nếu cần debug
  final Map<String, dynamic>? raw;

  ProcedureModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    this.decisionNumber,
    this.implementationResult,
    this.requirementsForImplementation,
    this.implementationLevelId,
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
    String getPairName(dynamic maybePair) {
      // nếu là [id, "Tên"] -> trả về phần tử thứ 1
      try {
        if (maybePair is List && maybePair.length > 1) {
          return maybePair[1]?.toString() ?? '';
        }
        if (maybePair == null) return '';
        return maybePair.toString();
      } catch (e) {
        return '';
      }
    }

    List<int> toIntList(dynamic val) {
      if (val is List) {
        return val
            .map<int>((e) {
              if (e is int) return e;
              if (e is String) return int.tryParse(e) ?? 0;
              return 0;
            })
            .where((i) => i != 0)
            .toList();
      }
      return <int>[];
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return ProcedureModel(
      id: (json['id'] is int)
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString() ?? '',
      name: (json['display_name'] ?? json['name'])?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      decisionNumber: json['decision_number']?.toString(),
      implementationResult: json['implementation_result']?.toString(),
      requirementsForImplementation: json['requirements_for_implementation']
          ?.toString(),
      implementationLevelId:
          json['implementation_level_id'], // giữ dynamic (bool|int|null)
      isProcedureLookup: (json['is_procedure_lookup'] is bool)
          ? json['is_procedure_lookup'] as bool
          : (json['is_procedure_lookup']?.toString().toLowerCase() == 'true'),
      isPublished: (json['is_published'] is bool)
          ? json['is_published'] as bool
          : (json['is_published']?.toString().toLowerCase() == 'true'),
      procedureTypeId: json['procedure_type_id'],
      receivingAddress: json['receiving_address'],
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
