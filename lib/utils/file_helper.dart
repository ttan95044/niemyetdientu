import 'dart:convert';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class FileHelper {
  static Future<File> saveBase64File({
    required String base64,
    required String filename,
  }) async {
    final bytes = base64Decode(base64);

    final dir = await getTemporaryDirectory();

    final file = File('${dir.path}/$filename');

    await file.writeAsBytes(bytes);

    return file;
  }

  static Future<void> openFile({
    required String base64,
    required String filename,
  }) async {
    final file = await saveBase64File(base64: base64, filename: filename);

    await OpenFilex.open(file.path);
  }
}
