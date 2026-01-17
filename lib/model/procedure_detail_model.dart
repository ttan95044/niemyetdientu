import 'package:niemyetdientu/model/procedure_component_model.dart';

class ProcedureDetail {
  final int id;
  final String code;
  final String name;
  final String displayName;

  final String? description;
  final String? requirementsForImplementation;
  final String? implementationResult;
  final String? implementationSequence;
  final String? decisionNumber;
  final String? createDate;
  final String? writeDate;

  final bool isPublished;
  final bool isProcedureLookup;

  final String? keywords;
  final String? receivingAddress;

  final List<int>? componentIds;
  final List<int>? submissionTypeIds;
  final List<int>? implementationAgencyIds;
  final List<int>? implementationObjectIds;
  final List<int>? legalGroundIds;

  final List<ProcedureComponent>? components;

  final dynamic authorizedAgencyId;
  final dynamic competentAgencyId;
  final dynamic companyId;
  final dynamic procedureFieldId;
  final dynamic writeUid;
  final int? templateId;

  final dynamic createUid;
  final dynamic implementationLevelId;
  final dynamic procedureTypeId;

  final List<dynamic>? coordinatingAgencyId;

  ProcedureDetail({
    required this.id,
    required this.code,
    required this.name,
    required this.displayName,
    this.description,
    this.requirementsForImplementation,
    this.implementationResult,
    this.implementationSequence,
    this.decisionNumber,
    this.createDate,
    this.writeDate,
    this.isPublished = false,
    this.isProcedureLookup = false,
    this.keywords,
    this.receivingAddress,
    this.componentIds,
    this.submissionTypeIds,
    this.implementationAgencyIds,
    this.implementationObjectIds,
    this.legalGroundIds,
    this.components,
    this.authorizedAgencyId,
    this.competentAgencyId,
    this.companyId,
    this.procedureFieldId,
    this.writeUid,
    this.templateId,
    this.createUid,
    this.implementationLevelId,
    this.procedureTypeId,
    this.coordinatingAgencyId,
  });

  factory ProcedureDetail.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) => v is String ? v : null;
    int? parseMany2One(dynamic v) {
      if (v is List && v.isNotEmpty && v[0] is int) {
        return v[0];
      }
      return null; // false | null | rác → null
    }

    return ProcedureDetail(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',

      description: str(json['description']),
      requirementsForImplementation: str(
        json['requirements_for_implementation'],
      ),
      implementationResult: str(json['implementation_result']),
      implementationSequence: str(json['implementation_sequence']),
      decisionNumber: str(json['decision_number']),
      createDate: str(json['create_date']),
      writeDate: str(json['write_date']),

      isPublished: json['is_published'] ?? false,
      isProcedureLookup: json['is_procedure_lookup'] ?? false,

      keywords: str(json['keywords']),
      receivingAddress: str(json['receiving_address']),

      componentIds: (json['component_ids'] as List?)?.cast<int>(),
      submissionTypeIds: (json['submission_type_ids'] as List?)?.cast<int>(),
      implementationAgencyIds: (json['implementation_agency_ids'] as List?)
          ?.cast<int>(),
      implementationObjectIds: (json['implementation_object_ids'] as List?)
          ?.cast<int>(),
      legalGroundIds: (json['legal_ground_ids'] as List?)?.cast<int>(),

      components: (json['components'] as List?)
          ?.map((e) => ProcedureComponent.fromJson(e))
          .toList(),

      coordinatingAgencyId: json['coordinating_agency_id'],
      authorizedAgencyId: json['authorized_agency_id'],
      competentAgencyId: json['competent_agency_id'],
      companyId: json['company_id'],
      procedureFieldId: json['procedure_field_id'],
      writeUid: json['write_uid'],
      templateId: parseMany2One(json['template_id']),
      createUid: json['create_uid'],
      implementationLevelId: json['implementation_level_id'],
      procedureTypeId: json['procedure_type_id'],
    );
  }
}
