import 'package:flutter_test/flutter_test.dart';

import 'package:cloudcom_final/api.dart';

void main() {
  group('responseError', () {
    test('returns the error field from a JSON body', () {
      expect(responseError('{"ok": false, "error": "Username taken"}'), 'Username taken');
    });

    test('uses message when ok or success is false', () {
      expect(responseError('{"success": false, "message": "Too far away"}'), 'Too far away');
      expect(responseError('{"ok": false}'), 'The server rejected the request.');
    });

    test('treats status "error" as a failure', () {
      expect(responseError('{"status": "error", "message": "Bad input"}'), 'Bad input');
    });

    test('accepts successful JSON bodies', () {
      expect(responseError('{"ok": true, "message": "Saved"}'), isNull);
      expect(responseError('{"error": ""}'), isNull);
      expect(responseError('[{"monster_id": 1}]'), isNull);
    });

    test('handles plain-text bodies', () {
      expect(responseError('Error: duplicate entry'), 'Error: duplicate entry');
      expect(responseError('Failed to insert'), 'Failed to insert');
      expect(responseError('Monster added successfully'), isNull);
      expect(responseError(''), isNull);
    });
  });
}
