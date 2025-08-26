// lib/core/api_logger.dart
import 'package:flutter/foundation.dart';

class ApiLogger {
  static void request(String method, Uri uri, {Map<String, String>? headers, dynamic body}) {
    if (!kDebugMode) return;
    debugPrint('--- API REQUEST [$method] ---');
    debugPrint('URL: $uri');
    if (headers != null && headers.isNotEmpty) {
      final redacted = Map<String, String>.from(headers);
      final authKey = redacted.keys.firstWhere(
            (k) => k.toLowerCase() == 'authorization',
        orElse: () => '',
      );
      if (authKey.isNotEmpty) redacted[authKey] = '***';
      debugPrint('Headers: $redacted');
    }
    if (body != null) debugPrint('Body: $body');
  }

  static void success(String method, Uri uri, int status, dynamic response) {
    if (!kDebugMode) return;
    debugPrint('--- API SUCCESS [$method] ---');
    debugPrint('URL: $uri');
    debugPrint('Status: $status');
    debugPrint('Response: $response');
  }

  static void error(String method, Uri uri, int status, dynamic response) {
    if (!kDebugMode) return;
    debugPrint('--- API ERROR [$method] ---');
    debugPrint('URL: $uri');
    debugPrint('Status: $status');
    debugPrint('Error: $response');
  }

  static void exception(String method, Uri uri, Object e) {
    if (!kDebugMode) return;
    debugPrint('--- API EXCEPTION [$method] ---');
    debugPrint('URL: $uri');
    debugPrint('Exception: $e');
  }
}