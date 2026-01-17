import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

Future<File> createPdfFromBase64(String base64Str) async {
  final bytes = base64Decode(base64Str);
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/template_${DateTime.now().millisecondsSinceEpoch}.pdf',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file;
}
