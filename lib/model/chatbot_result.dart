class ChatbotResult {
  final String name;
  final String decision;
  final String typeName;
  final String fieldName;
  final bool isPublished;

  ChatbotResult({
    required this.name,
    required this.decision,
    required this.typeName,
    required this.fieldName,
    required this.isPublished,
  });

  factory ChatbotResult.fromJson(Map<String, dynamic> json) {
    return ChatbotResult(
      name: json['name'] ?? '',
      decision: json['decision_number'] ?? '',
      typeName: json['type_name'] ?? '',
      fieldName: json['field_name'] ?? '',
      isPublished: json['is_published'] ?? false,
    );
  }
}
