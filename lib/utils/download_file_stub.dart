import 'dart:typed_data';

Future<String?> downloadAndSaveFile(
    Uint8List bytes, String filename, String mimeType) async {
  throw UnsupportedError('Cannot download file on this platform');
}
