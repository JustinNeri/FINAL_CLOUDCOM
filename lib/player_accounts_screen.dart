import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_models.dart';

class PlayerAccountsScreen extends StatefulWidget {
  const PlayerAccountsScreen({
    super.key,
    required this.currentPlayer,
    required this.onProfileUpdated,
  });

  final PlayerProfile currentPlayer;
  final ValueChanged<PlayerProfile> onProfileUpdated;

  @override
  State<PlayerAccountsScreen> createState() => _PlayerAccountsScreenState();
}

class _PlayerAccountsScreenState extends State<PlayerAccountsScreen> {
  final String apiBase = 'http://15.224.51.87';

  bool loading = false;
  String error = '';
  List<PlayerProfile> players = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      loading = true;
      error = '';
    });

    final endpoints = [
      '$apiBase/list_players_api.php',
      '$apiBase/list_player_api.php',
    ];

    http.Response? resp;

    try {
      for (final endpoint in endpoints) {
        final candidate = await http
            .get(Uri.parse(endpoint))
            .timeout(const Duration(seconds: 10));

        if (candidate.statusCode == 200) {
          resp = candidate;
          break;
        }
      }

      if (resp == null) {
        final lastEndpoint = endpoints.last;
        final lastResp = await http
            .get(Uri.parse(lastEndpoint))
            .timeout(const Duration(seconds: 10));
        setState(() =>
            error = 'Load failed: ${lastResp.statusCode}\nEndpoint: $lastEndpoint\n${_shortBody(lastResp.body)}');
        return;
      }

      final decoded = json.decode(resp.body);
      List list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        list = decoded['data'];
      } else {
        list = [];
      }

      setState(() {
        players = list
            .whereType<Map>()
            .map((e) => PlayerProfile.fromMap(Map<String, dynamic>.from(e)))
            .where((p) => p.id.isNotEmpty || p.username.isNotEmpty)
            .toList();
        error = '';
      });
    } catch (e) {
      setState(() => error = 'Request failed: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _openEditDialog(PlayerProfile profile) async {
    final usernameCtrl = TextEditingController(text: profile.username);
    final nameCtrl = TextEditingController(text: profile.name ?? '');
    final passwordCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update Player'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(label: 'Username', controller: usernameCtrl),
                _DialogField(label: 'Player Name', controller: nameCtrl),
                _DialogField(
                  label: 'New Password (optional)',
                  controller: passwordCtrl,
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ok = await _updatePlayer(
                  playerId: profile.id,
                  username: usernameCtrl.text.trim(),
                  playerName: nameCtrl.text.trim(),
                  password: passwordCtrl.text,
                );
                if (!mounted) return;
                if (ok) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    usernameCtrl.dispose();
    nameCtrl.dispose();
    passwordCtrl.dispose();
  }

  Future<bool> _updatePlayer({
    required String playerId,
    required String username,
    required String playerName,
    required String password,
  }) async {
    try {
      final newPassword = password.trim();
      final body = {
        'player_id': playerId,
        'username': username,
        'player_name': playerName,
        // Support multiple backend parameter names for password updates.
        if (newPassword.isNotEmpty) 'password': newPassword,
        if (newPassword.isNotEmpty) 'new_password': newPassword,
        if (newPassword.isNotEmpty) 'player_password': newPassword,
      };

      final resp = await http.post(
        Uri.parse('$apiBase/update_player_api.php'),
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        int? affectedRows;
        try {
          final data = json.decode(resp.body);
          if (data is Map<String, dynamic>) {
            affectedRows = int.tryParse(data['affected_rows']?.toString() ?? '');
          }
        } catch (_) {
          // Keep legacy behavior when response is not JSON.
        }

        final passwordWasRequested = newPassword.isNotEmpty;
        if (passwordWasRequested && affectedRows == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password was not updated by the server. Please update update_player_api.php backend logic.'),
              ),
            );
          }
          return false;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Player updated.')),
          );
        }

        final updatedProfile = PlayerProfile(
          id: playerId,
          username: username,
          name: playerName,
        );
        widget.onProfileUpdated(updatedProfile);

        await _loadPlayers();
        return true;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${resp.statusCode}')),
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request failed: $e')),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseGreen = Color(0xFF3F6F4F);
    final currentPlayer = players.where((p) => p.id == widget.currentPlayer.id).isNotEmpty
        ? players.firstWhere((p) => p.id == widget.currentPlayer.id)
        : widget.currentPlayer;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: baseGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Account', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: loading ? null : _loadPlayers,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: baseGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (error.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(error),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentPlayer.username,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Player ID: ${currentPlayer.id}'),
                                      if ((currentPlayer.name ?? '').isNotEmpty)
                                        Text('Name: ${currentPlayer.name}'),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _openEditDialog(currentPlayer),
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Update',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatefulWidget {
  const _DialogField({
    required this.label,
    required this.controller,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;

  @override
  State<_DialogField> createState() => _DialogFieldState();
}

class _DialogFieldState extends State<_DialogField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: widget.controller,
        obscureText: _isObscured,
        enableSuggestions: !widget.obscureText,
        autocorrect: !widget.obscureText,
        decoration: InputDecoration(
          labelText: widget.label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: widget.obscureText
              ? IconButton(
                  onPressed: () {
                    setState(() => _isObscured = !_isObscured);
                  },
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                )
              : null,
          isDense: true,
        ),
      ),
    );
  }
}

String _shortBody(String body) {
  final clean = body.trim();
  if (clean.isEmpty) return '(empty response body)';
  if (clean.length <= 240) return clean;
  return '${clean.substring(0, 240)}...';
}
