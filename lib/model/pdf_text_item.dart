/// Mô hình dữ liệu cho text item được thêm vào PDF
class PdfTextItem {
  final String id; // ID duy nhất
  final String text; // Nội dung text
  final double x; // Vị trí X (từ trái, trong page)
  final double y; // Vị trí Y (từ trên, trong page)
  final double fontSize;
  final String fontColor;
  final String fontFamily; // Font chữ (mặc định: Times New Roman)
  final int pageIndex; // Page index (0-based) nếu PDF nhiều pages

  PdfTextItem({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 16,
    this.fontColor = '000000',
    this.fontFamily = 'times', // Times New Roman
    this.pageIndex = 0,
  });

  /// Clone với những thay đổi nhất định
  PdfTextItem copyWith({
    String? text,
    double? x,
    double? y,
    double? fontSize,
    String? fontColor,
    String? fontFamily,
    int? pageIndex,
  }) {
    return PdfTextItem(
      id: id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      fontFamily: fontFamily ?? this.fontFamily,
      pageIndex: pageIndex ?? this.pageIndex,
    );
  }
}
