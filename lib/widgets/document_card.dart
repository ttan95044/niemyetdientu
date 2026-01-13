import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// --- Widget hiển thị 1 tài liệu có QR ---
class DocumentCard extends StatelessWidget {
  final String name;
  final String link;

  const DocumentCard({super.key, required this.name, required this.link});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            QrImageView(data: link, size: 90, backgroundColor: Colors.white),
          ],
        ),
      ),
    );
  }
}
