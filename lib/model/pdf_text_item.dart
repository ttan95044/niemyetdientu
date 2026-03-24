/// Mô hình dữ liệu cho text item được thêm vào PDF
class PdfTextItem {
  final String id; // ID duy nhất
  final String text; // Nội dung text
  final double x; // Vị trí X (từ trái)
  final double y; // Vị trí Y (từ trên)
  final double fontSize;
  final String fontColor;

  PdfTextItem({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 16,
    this.fontColor = '000000',
  });

  /// Clone với những thay đổi nhất định
  PdfTextItem copyWith({
    String? text,
    double? x,
    double? y,
    double? fontSize,
    String? fontColor,
  }) {
    return PdfTextItem(
      id: id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
    );
  }
}
