import 'dart:convert';

import 'package:flutter/material.dart';
import 'api.dart';
import 'theme.dart';
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
      if (mounted) setState(() => error = 'Request failed: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _openEditDialog(PlayerProfile profile) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditPlayerDialog(
        profile: profile,
        onSave: (username, playerName, password) => _updatePlayer(
          playerId: profile.id,
          username: username,
          playerName: playerName,
          password: password,
        ),
      ),
    );
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
        final serverError = responseError(resp.body);
        if (serverError != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: $serverError')),
            );
          }
          return false;
        }

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
    const baseGreen = ThemeColors.deepNavy;
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: loading ? null : _loadPlayers,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh, color: Colors.black),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.pokeYellow,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(120, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

class _EditPlayerDialog extends StatefulWidget {
  const _EditPlayerDialog({required this.profile, required this.onSave});

  final PlayerProfile profile;
  final Future<bool> Function(String username, String playerName, String password) onSave;

  @override
  State<_EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends State<_EditPlayerDialog> {
  late final TextEditingController _usernameCtrl =
      TextEditingController(text: widget.profile.username);
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.profile.name ?? '');
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Username cannot be empty.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await widget.onSave(username, _nameCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Player'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogField(label: 'Username', controller: _usernameCtrl),
            _DialogField(label: 'Player Name', controller: _nameCtrl),
            _DialogField(
              label: 'New Password (optional)',
              controller: _passwordCtrl,
              obscureText: true,
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
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
