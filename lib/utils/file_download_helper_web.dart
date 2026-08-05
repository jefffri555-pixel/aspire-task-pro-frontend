import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveBytesToDevice({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  if (bytes.isEmpty) {
    throw Exception('Downloaded file is empty');
  }

  final blob = html.Blob(
    [bytes],
    mimeType,
  );

  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);

  anchor.click();

  anchor.remove();

  await Future<void>.delayed(
    const Duration(milliseconds: 200),
  );

  html.Url.revokeObjectUrl(url);
}
