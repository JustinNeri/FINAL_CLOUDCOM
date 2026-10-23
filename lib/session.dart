import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_models.dart';

/// Keeps the signed-in player on the device so a page refresh or app restart
/// does not log them out. Only the public profile is stored, never the password.
class Session {
  static const _key = 'signed_in_player';

  static Future<PlayerProfile?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final profile = PlayerProfile.fromMap(Map<String, dynamic>.from(json.decode(raw) as Map));
      return profile.id.isEmpty ? null : profile;
    } catch (_) {
      // Storage unavailable (private browsing) or corrupt: start signed out.
      return null;
    }
  }

  static Future<void> save(PlayerProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(profile.toMap()));
    } catch (_) {
      // Not remembering the login is acceptable; the player stays signed in for now.
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Nothing stored to clear.
    }
  }
}
