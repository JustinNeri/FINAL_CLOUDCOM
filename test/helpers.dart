import 'dart:convert';

import 'package:cloudcom_final/api.dart';
import 'package:cloudcom_final/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

typedef Handler = http.Response Function(http.Request request);

/// Routes every API call to [routes], keyed by the last path segment
/// (e.g. `login_player_api.php`). Unknown paths answer 404. Returns the list
/// of requests made, for assertions.
List<http.Request> useFakeServer(Map<String, Handler> routes) {
  final requests = <http.Request>[];
  apiClient = MockClient((request) async {
    requests.add(request);
    final handler = routes[request.url.pathSegments.last];
    return handler?.call(request) ?? http.Response('Not found', 404);
  });
  return requests;
}

/// A JSON response with status 200.
http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// Shows [screen] inside a themed app.
Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: screen));
  await settle(tester);
}

/// Any Material button (including `.icon` variants) labelled [label].
Finder findButton(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );

/// Scrolls [finder] into view, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

/// Lets fake requests finish and the UI rebuild. Unlike pumpAndSettle this
/// does not hang on spinners that animate forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
