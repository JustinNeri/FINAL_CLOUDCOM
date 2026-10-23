import 'dart:convert';

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
