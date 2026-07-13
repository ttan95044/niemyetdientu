class SubmissionTypeInfo {
  final int id;
  final String name;

  SubmissionTypeInfo({required this.id, required this.name});

  factory SubmissionTypeInfo.fromJson(Map<String, dynamic> json) {
    return SubmissionTypeInfo(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}
