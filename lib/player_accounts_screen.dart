import 'dart:convert';

import 'package:flutter/material.dart';

import 'api.dart';
import 'auth_models.dart';
import 'login_screen.dart' show validateUsername, validateNewPassword;
import 'theme.dart';
import 'widgets.dart';

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
  late PlayerProfile _profile = widget.currentPlayer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Refreshes the profile from the server. The backend only offers a list of
  /// all players, so this picks the signed-in player out of it.
  Future<void> _loadProfile() async {
    setState(() {
      loading = true;
      error = '';
    });

    const endpoints = ['list_players_api.php', 'list_player_api.php'];

    try {
      String? body;
      var lastStatus = 0;
      for (final endpoint in endpoints) {
        final resp = await apiGet(endpoint);
        if (resp.statusCode == 200) {
          body = resp.body;
          break;
        }
        lastStatus = resp.statusCode;
      }
      if (!mounted) return;

      if (body == null) {
        setState(() => error = 'Could not refresh your profile ($lastStatus).');
        return;
      }

      final players = (decodeList(body) ?? []).map(PlayerProfile.fromMap);
      final match = players.where((p) => p.id == widget.currentPlayer.id);
      if (match.isNotEmpty) setState(() => _profile = match.first);
    } catch (e) {
      if (mounted) setState(() => error = requestErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Saves the profile; returns an error message, or null on success.
  Future<String?> _updatePlayer({
    required String username,
    required String playerName,
    required String password,
  }) async {
    try {
      final newPassword = password.trim();
      final resp = await apiPost('update_player_api.php', {
        'player_id': _profile.id,
        'username': username,
        'player_name': playerName,
        // Support multiple backend parameter names for password updates.
        if (newPassword.isNotEmpty) 'password': newPassword,
        if (newPassword.isNotEmpty) 'new_password': newPassword,
        if (newPassword.isNotEmpty) 'player_password': newPassword,
      });

      if (resp.statusCode != 200) return 'Update failed (${resp.statusCode}).';
      final serverError = responseError(resp.body);
      if (serverError != null) return serverError;

      int? affectedRows;
      try {
        final data = json.decode(resp.body);
        if (data is Map<String, dynamic>) {
          affectedRows = int.tryParse(data['affected_rows']?.toString() ?? '');
        }
      } on FormatException {
        // Keep legacy behavior when response is not JSON.
      }
      if (newPassword.isNotEmpty && affectedRows == 0) {
        return 'The server did not change the password. Check update_player_api.php.';
      }

      final updated = PlayerProfile(id: _profile.id, username: username, name: playerName);
      widget.onProfileUpdated(updated);
      if (mounted) setState(() => _profile = updated);
      return null;
    } catch (e) {
      return requestErrorMessage(e);
    }
  }

  Future<void> _openEditDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditPlayerDialog(
        profile: _profile,
        onSave: (username, playerName, password) => _updatePlayer(
          username: username,
          playerName: playerName,
          password: password,
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = _profile.displayName.isNotEmpty ? _profile.displayName[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ContentWidth(
            maxWidth: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: ThemeColors.pokeYellow,
                          child: Text(
                            initial,
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: ThemeColors.deepNavy),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(_profile.displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('@${_profile.username}', style: const TextStyle(color: ThemeColors.textMuted)),
                        if (loading) ...[
                          const SizedBox(height: 14),
                          const LinearProgressIndicator(minHeight: 3),
                        ],
                      ],
                    ),
                  ),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  MessageBanner(message: error, onRetry: _loadProfile),
                ],
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Player name'),
                        subtitle: Text(_profile.name?.isNotEmpty == true ? _profile.name! : 'Not set'),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.alternate_email),
                        title: const Text('Username'),
                        subtitle: Text(_profile.username),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.tag),
                        title: const Text('Trainer ID'),
                        subtitle: Text(_profile.id),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _openEditDialog,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profile or password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog for changing username, player name and (optionally) password.
/// Pops with true once saved.
class _EditPlayerDialog extends StatefulWidget {
  const _EditPlayerDialog({required this.profile, required this.onSave});

  final PlayerProfile profile;
  final Future<String?> Function(String username, String playerName, String password) onSave;

  @override
  State<_EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends State<_EditPlayerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl = TextEditingController(text: widget.profile.username);
  late final TextEditingController _nameCtrl = TextEditingController(text: widget.profile.name ?? '');
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(_usernameCtrl.text.trim(), _nameCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Username',
                  controller: _usernameCtrl,
                  icon: Icons.alternate_email,
                  // Existing usernames predate the rules, so only check changed ones.
                  validator: (v) => v?.trim() == widget.profile.username ? null : validateUsername(v),
                ),
                const SizedBox(height: 12),
                AppTextField(label: 'Player Name', controller: _nameCtrl, icon: Icons.badge_outlined),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Change password (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'New Password',
                  controller: _passwordCtrl,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) => (v ?? '').isEmpty ? null : validateNewPassword(v),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Confirm New Password',
                  controller: _confirmCtrl,
                  icon: Icons.lock_reset,
                  obscureText: true,
                  validator: (v) => v != _passwordCtrl.text ? 'Passwords do not match.' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  MessageBanner(message: _error!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const ButtonSpinner() : const Text('Save'),
        ),
      ],
    );
  }
}
