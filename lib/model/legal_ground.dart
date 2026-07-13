class LegalGround {
  final int id;
  final String issueDate;
  final String issuingAgency;
  final String referenceNumber;
  final String summary;

  LegalGround({
    required this.id,
    required this.issueDate,
    required this.issuingAgency,
    required this.referenceNumber,
    required this.summary,
  });

  factory LegalGround.fromJson(Map<String, dynamic> json) {
    return LegalGround(
      id: json["id"] ?? 0,
      issueDate: json["issue_date"] ?? "",
      issuingAgency: json["issuing_agency"] == false
          ? ""
          : json["issuing_agency"] ?? "",
      referenceNumber: json["reference_number"] ?? "",
      summary: json["summary"] ?? "",
    );
  }
}
