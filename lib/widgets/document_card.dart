import 'package:flutter/material.dart';

/// --- Widget hiển thị 1 tài liệu / biểu mẫu ---
class DocumentCard extends StatelessWidget {
  final String name;
  final int originals;
  final int copies;

  /// 👉 Bấm vào CARD để xem biểu mẫu
  final VoidCallback onView;

  /// 👉 Bấm icon in để in biểu mẫu
  final VoidCallback onPrint;

  const DocumentCard({
    super.key,
    required this.name,
    required this.originals,
    required this.copies,
    required this.onView,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onView, // 👈 bấm card để xem PDF
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 📄 Tên giấy tờ
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 8),

              /// 📊 Bản gốc / bản sao + in
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gốc: $originals  •  Sao: $copies',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),

                  /// 🖨️ Icon in
                  IconButton(
                    icon: const Icon(Icons.print, size: 22),
                    tooltip: 'In biểu mẫu',
                    onPressed: onPrint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
