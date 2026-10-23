import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base URL of the PHP backend. Override at build time with
/// `--dart-define=API_BASE=https://your-domain`.
const String apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://100.69.77.17',
);

/// AWS endpoint that starts, stops and reports the backend instance.
const String instanceApi = String.fromEnvironment(
  'INSTANCE_API',
  defaultValue: 'https://xfnttovxp5.execute-api.eu-west-3.amazonaws.com/default/STOP_AND_START',
);

const Duration apiTimeout = Duration(seconds: 10);

/// HTTP client used for every request. Tests swap in a `MockClient`.
http.Client apiClient = http.Client();

/// GET `$apiBase/$path` with optional query parameters.
Future<http.Response> apiGet(String path, [Map<String, String>? query]) {
  final uri = Uri.parse('$apiBase/$path').replace(queryParameters: query);
  return apiClient.get(uri).timeout(apiTimeout);
}

/// POST form fields to `$apiBase/$path`.
Future<http.Response> apiPost(String path, Map<String, String> body) {
  return apiClient.post(Uri.parse('$apiBase/$path'), body: body).timeout(apiTimeout);
}

/// Returns the failure message from a response body, or null when the body
/// does not report a failure. The backend can answer HTTP 200 with
/// `{"ok": false, "error": "..."}`, so a 200 status alone is not success.
String? responseError(String body) {
  final trimmed = body.trim();
  try {
    final data = json.decode(trimmed);
    if (data is Map) {
      final err = data['error']?.toString();
      if (err != null && err.trim().isNotEmpty) return err;
      final failed = data['ok'] == false ||
          data['success'] == false ||
          data['status']?.toString().toLowerCase() == 'error';
      if (failed) {
        final msg = data['message']?.toString();
        return msg != null && msg.trim().isNotEmpty
            ? msg
            : 'The server rejected the request.';
      }
    }
    return null;
  } on FormatException {
    // Plain-text responses: treat ones that open with an error word as failures.
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('error') || lower.startsWith('failed') || lower.startsWith('fatal')) {
      return trimmed;
    }
    return null;
  }
}

/// The `error` or `message` field of a JSON object body, if any.
String? serverMessage(String body) {
  try {
    final data = json.decode(body);
    if (data is Map) {
      for (final key in ['error', 'message']) {
        final value = data[key]?.toString();
        if (value != null && value.trim().isNotEmpty) return value;
      }
    }
  } on FormatException {
    // Not JSON.
  }
  return null;
}

/// Decodes a body that is either a JSON list or `{"data": [...]}` into its
/// object rows. Returns null when the body has neither shape.
List<Map<String, dynamic>>? decodeList(String body) {
  try {
    final data = json.decode(body);
    final list = data is List
        ? data
        : data is Map && data['data'] is List
            ? data['data'] as List
            : null;
    return list?.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  } on FormatException {
    return null;
  }
}

/// A response body trimmed to a length that fits in an error message.
String shortBody(String body) {
  final clean = body.trim();
  if (clean.isEmpty) return '(empty response body)';
  if (clean.length <= 240) return clean;
  return '${clean.substring(0, 240)}...';
}

/// Turns an exception from a request into a message a player can act on.
String requestErrorMessage(Object error) {
  final text = error.toString();
  if (text.contains('TimeoutException')) {
    return 'The server took too long to answer. Check your connection and try again.';
  }
  if (text.contains('XMLHttpRequest') || text.contains('ClientException') || text.contains('SocketException')) {
    return 'Could not reach the server. It may be offline or blocked by your network.';
  }
  return 'Request failed: $text';
}
