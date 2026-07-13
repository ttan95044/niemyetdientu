import 'package:niemyetdientu/model/submission_type_info.dart';

class SubmissionType {
  final int id;

  final String description;
  final String fee;

  final int processingTime;

  final SubmissionTypeInfo submissionType;

  SubmissionType({
    required this.id,
    required this.description,
    required this.fee,
    required this.processingTime,
    required this.submissionType,
  });

  factory SubmissionType.fromJson(Map<String, dynamic> json) {
    return SubmissionType(
      id: json["id"] ?? 0,
      description: json["description"] ?? "",
      fee: json["fee"] ?? "",
      processingTime: json["processing_time"] ?? 0,
      submissionType: SubmissionTypeInfo.fromJson(json["submission_type"]),
    );
  }
}
