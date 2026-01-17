class TemplateModel {
  final int id;
  final String displayName;
  final String printFilename;
  final String printFileBase64;

  TemplateModel({
    required this.id,
    required this.displayName,
    required this.printFilename,
    required this.printFileBase64,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'] is int ? json['id'] : 0,

      displayName: json['display_name'] is String ? json['display_name'] : '',

      printFilename: json['print_filename'] is String
          ? json['print_filename']
          : '',

      printFileBase64: json['print_file'] is String ? json['print_file'] : '',
    );
  }
}
