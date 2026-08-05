import '../config/constants.dart';

String? resolveBackendMediaUrl(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }

  final url = value.trim();

  if (url.startsWith('http://') ||
      url.startsWith('https://') ||
      url.startsWith('blob:')) {
    return url;
  }

  final backendOrigin = AppConstants.apiBaseUrl.replaceAll('/api', '');

  if (url.startsWith('/')) {
    return '$backendOrigin$url';
  }

  return '$backendOrigin/$url';
}
