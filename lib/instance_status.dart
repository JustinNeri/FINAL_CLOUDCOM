import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api.dart';
import 'theme.dart';

/// State of the backend EC2 instance, as shown to the player.
enum InstanceState {
  unknown('Unknown', 'Status not checked yet.', Icons.help_outline, ThemeColors.accentMuted),
  starting('Starting…', 'The server is booting. This usually takes about a minute.', Icons.hourglass_top, ThemeColors.pokeBlue),
  running('Online', 'All systems nominal. Catching and detection are available.', Icons.bolt, ThemeColors.success),
  stopping('Stopping…', 'The server is shutting down.', Icons.hourglass_bottom, Colors.orange),
  stopped('Offline', 'Paused. Start the instance to catch and detect monsters.', Icons.power_settings_new, ThemeColors.pokeRed);

  const InstanceState(this.label, this.description, this.icon, this.color);

  final String label;
  final String description;
  final IconData icon;
  final Color color;

  bool get isTransitioning => this == starting || this == stopping;

  /// Catching only makes sense when the server is not known to be down.
  bool get allowsCatching => this == running || this == unknown;
}

/// Reads the instance state from a status response. Accepts JSON with a
/// `state`/`status` field or free text, and falls back to [unknown].
InstanceState parseInstanceState(String body) {
  var text = body.toLowerCase();
  try {
    final data = json.decode(body);
    if (data is Map) {
      final field = data['state'] ?? data['status'] ?? data['instance_state'];
      if (field != null) text = field.toString().toLowerCase();
    }
  } on FormatException {
    // Plain text body: match on the whole text.
  }

  // Order matters: "stopping" must win over "running" in text like
  // "was running, now stopping".
  if (text.contains('stopping') || text.contains('shutting')) return InstanceState.stopping;
  if (text.contains('pending') || text.contains('starting')) return InstanceState.starting;
  if (text.contains('stopped') || text.contains('offline')) return InstanceState.stopped;
  if (text.contains('running') || text.contains('online') || text.contains('started')) {
    return InstanceState.running;
  }
  return InstanceState.unknown;
}

/// Sends `status`, `start` or `stop` to the instance API. Tries POST first and
/// falls back to GET, since the Lambda may be wired either way.
Future<http.Response> callInstanceApi(String action) async {
  final uri = Uri.parse(instanceApi).replace(queryParameters: {'action': action});
  http.Response? postResponse;

  try {
    final resp = await apiClient
        .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'action': action}))
        .timeout(apiTimeout);
    if (resp.statusCode == 200) return resp;
    postResponse = resp;
  } catch (_) {
    // Fall through to GET.
  }

  final getResponse = await apiClient.get(uri).timeout(apiTimeout);
  if (getResponse.statusCode == 200) return getResponse;

  throw Exception(postResponse != null
      ? 'POST failed: ${postResponse.statusCode} | GET failed: ${getResponse.statusCode} ${shortBody(getResponse.body)}'
      : 'GET failed: ${getResponse.statusCode} ${shortBody(getResponse.body)}');
}
