import 'package:niemyetdientu/model/id_name.dart';
import 'package:niemyetdientu/model/legal_ground.dart';
import 'package:niemyetdientu/model/procedure_component.dart';
import 'package:niemyetdientu/model/submission_type.dart';

class ProcedureDetail {
  final int id;
  final String code;
  final String displayCode;
  final String name;

  final bool isPublished;

  final String? description;
  final String? implementationSequence;
  final String? implementationResult;
  final String? requirementsForImplementation;
  final String? receivingAddress;
  final String? keywords;
  final String? decisionNumber;

  final IdName? procedureField;
  final IdName? procedureType;
  final IdName? implementationLevel;

  final IdName? authorizedAgency;
  final IdName? competentAgency;

  final List<IdName> implementationAgencies;
  final List<IdName> implementationObjects;
  final List<IdName> coordinatingAgencies;

  final List<ProcedureComponent> components;
  final List<LegalGround> legalGrounds;
  final List<SubmissionType> submissionTypes;

  ProcedureDetail({
    required this.id,
    required this.code,
    required this.displayCode,
    required this.name,
    required this.isPublished,
    this.description,
    this.implementationSequence,
    this.implementationResult,
    this.requirementsForImplementation,
    this.receivingAddress,
    this.keywords,
    this.decisionNumber,
    this.procedureField,
    this.procedureType,
    this.implementationLevel,
    this.authorizedAgency,
    this.competentAgency,
    required this.implementationAgencies,
    required this.implementationObjects,
    required this.coordinatingAgencies,
    required this.components,
    required this.legalGrounds,
    required this.submissionTypes,
  });

  factory ProcedureDetail.fromJson(Map<String, dynamic> json) {
    return ProcedureDetail(
      id: json["id"] ?? 0,
      code: json["code"] ?? "",
      displayCode: json["display_code"] ?? "",
      name: json["name"] ?? "",
      isPublished: json["is_published"] ?? false,

      description: json["description"] == false ? null : json["description"],
      implementationSequence: json["implementation_sequence"] == false
          ? null
          : json["implementation_sequence"],
      implementationResult: json["implementation_result"] == false
          ? null
          : json["implementation_result"],
      requirementsForImplementation:
          json["requirements_for_implementation"] == false
          ? null
          : json["requirements_for_implementation"],
      receivingAddress: json["receiving_address"] == false
          ? null
          : json["receiving_address"],
      keywords: json["keywords"] == false ? null : json["keywords"],
      decisionNumber: json["decision_number"],

      procedureField: json["procedure_field"] is Map
          ? IdName.fromJson(json["procedure_field"])
          : null,

      procedureType: json["procedure_type"] is Map
          ? IdName.fromJson(json["procedure_type"])
          : null,

      implementationLevel: json["implementation_level"] is Map
          ? IdName.fromJson(json["implementation_level"])
          : null,

      authorizedAgency: json["authorized_agency"] is Map
          ? IdName.fromJson(json["authorized_agency"])
          : null,

      competentAgency: json["competent_agency"] is Map
          ? IdName.fromJson(json["competent_agency"])
          : null,

      implementationAgencies: (json["implementation_agencies"] as List? ?? [])
          .map((e) => IdName.fromJson(e))
          .toList(),

      implementationObjects: (json["implementation_objects"] as List? ?? [])
          .map((e) => IdName.fromJson(e))
          .toList(),

      coordinatingAgencies: (json["coordinating_agencies"] as List? ?? [])
          .map((e) => IdName.fromJson(e))
          .toList(),

      components: (json["components"] as List? ?? [])
          .map((e) => ProcedureComponent.fromJson(e))
          .toList(),

      legalGrounds: (json["legal_grounds"] as List? ?? [])
          .map((e) => LegalGround.fromJson(e))
          .toList(),

      submissionTypes: (json["submission_types"] as List? ?? [])
          .map((e) => SubmissionType.fromJson(e))
          .toList(),
    );
  }
}
