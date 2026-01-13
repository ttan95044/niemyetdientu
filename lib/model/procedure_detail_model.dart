class ProcedureDetail {
  final int id;
  final String code;
  final String name;
  final String displayName;
  final String? description;
  final String? requirementsForImplementation;
  final String? implementationResult;
  final String? decisionNumber;
  final String? createDate;
  final String? writeDate;
  final bool isPublished;
  final bool isProcedureLookup;
  final bool implementationSequence;
  final bool keywords;
  final bool receivingAddress;
  final List<int>? componentIds;
  final List<int>? coordinatingAgencyId;
  final List<int>? submissionTypeIds;
  final List<int>? implementationAgencyIds;
  final List<int>? implementationObjectIds;
  final List<int>? legalGroundIds;

  final List<dynamic>? authorizedAgencyId;
  final List<dynamic>? competentAgencyId;
  final List<dynamic>? companyId;
  final List<dynamic>? procedureFieldId;
  final List<dynamic>? writeUid;
  final List<dynamic>? createUid;

  final dynamic implementationLevelId;
  final dynamic procedureTypeId;

  ProcedureDetail({
    required this.id,
    required this.code,
    required this.name,
    required this.displayName,
    this.description,
    this.requirementsForImplementation,
    this.implementationResult,
    this.decisionNumber,
    this.createDate,
    this.writeDate,
    this.isPublished = false,
    this.isProcedureLookup = false,
    this.implementationSequence = false,
    this.keywords = false,
    this.receivingAddress = false,
    this.componentIds,
    this.coordinatingAgencyId,
    this.submissionTypeIds,
    this.implementationAgencyIds,
    this.implementationObjectIds,
    this.legalGroundIds,
    this.authorizedAgencyId,
    this.competentAgencyId,
    this.companyId,
    this.procedureFieldId,
    this.writeUid,
    this.createUid,
    this.implementationLevelId,
    this.procedureTypeId,
  });

  factory ProcedureDetail.fromJson(Map<String, dynamic> json) {
    return ProcedureDetail(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      description: json['description'],
      requirementsForImplementation: json['requirements_for_implementation'],
      implementationResult: json['implementation_result'],
      decisionNumber: json['decision_number'],
      createDate: json['create_date'],
      writeDate: json['write_date'],
      isPublished: json['is_published'] ?? false,
      isProcedureLookup: json['is_procedure_lookup'] ?? false,
      implementationSequence: json['implementation_sequence'] ?? false,
      keywords: json['keywords'] ?? false,
      receivingAddress: json['receiving_address'] ?? false,
      componentIds: (json['component_ids'] as List?)?.cast<int>(),
      coordinatingAgencyId: (json['coordinating_agency_id'] as List?)
          ?.cast<int>(),
      submissionTypeIds: (json['submission_type_ids'] as List?)?.cast<int>(),
      implementationAgencyIds: (json['implementation_agency_ids'] as List?)
          ?.cast<int>(),
      implementationObjectIds: (json['implementation_object_ids'] as List?)
          ?.cast<int>(),
      legalGroundIds: (json['legal_ground_ids'] as List?)?.cast<int>(),
      authorizedAgencyId: json['authorized_agency_id'],
      competentAgencyId: json['competent_agency_id'],
      companyId: json['company_id'],
      procedureFieldId: json['procedure_field_id'],
      writeUid: json['write_uid'],
      createUid: json['create_uid'],
      implementationLevelId: json['implementation_level_id'],
      procedureTypeId: json['procedure_type_id'],
    );
  }
}
