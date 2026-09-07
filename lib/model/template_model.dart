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

  /// Extension của file
  String get extension {
    if (printFilename.isEmpty) return '';

    final index = printFilename.lastIndexOf('.');
    if (index == -1) return '';

    return printFilename.substring(index + 1).toLowerCase();
  }

  bool get isPdf => extension == 'pdf';
  bool get isDoc => extension == 'doc';
  bool get isDocx => extension == 'docx';
  bool get isExcel => extension == 'xls' || extension == 'xlsx';
  bool get isPowerPoint => extension == 'ppt' || extension == 'pptx';
}
