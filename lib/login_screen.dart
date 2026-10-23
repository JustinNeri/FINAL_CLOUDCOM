import 'dart:convert';

import 'package:flutter/material.dart';

import 'api.dart';
import 'auth_models.dart';
import 'theme.dart';
import 'widgets.dart';

const int minUsernameLength = 3;
const int minPasswordLength = 6;

String? validateUsername(String? value) {
  final username = value?.trim() ?? '';
  if (username.isEmpty) return 'Enter a username.';
  if (username.length < minUsernameLength) return 'Use at least $minUsernameLength characters.';
  if (username.contains(' ')) return 'Usernames cannot contain spaces.';
  return null;
}

String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Enter a password.';
  if (password.length < minPasswordLength) return 'Use at least $minPasswordLength characters.';
  return null;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoginSuccess});

  final void Function(PlayerProfile profile) onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool loading = false;
  String error = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => error = 'Please enter username and password.');
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final resp = await apiPost('login_player_api.php', {
        'username': username,
        'password': password,
      });
      if (!mounted) return;

      if (resp.statusCode != 200) {
        setState(() => error = serverMessage(resp.body) ?? shortBody(resp.body));
        return;
      }

      final data = json.decode(resp.body);
      if (data is Map<String, dynamic>) {
        final ok = data['ok'] == true || data['success'] == true;
        if (!ok && data.containsKey('error')) {
          setState(() => error = data['error'].toString());
          return;
        }

        final profileMap = data['player'] is Map
            ? Map<String, dynamic>.from(data['player'])
            : data;

        final profile = PlayerProfile.fromMap(profileMap);
        if (profile.id.isEmpty && profile.username.isEmpty) {
          setState(() => error = 'Invalid login response.');
          return;
        }
        widget.onLoginSuccess(profile);
        return;
      }

      setState(() => error = 'Unexpected server response.');
    } catch (e) {
      if (mounted) setState(() => error = requestErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openCreateAccount() async {
    final created = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CreatePlayerAccountScreen()),
    );
    if (created != null && mounted) {
      _usernameController.text = created;
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Sign in with your new password.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ThemeColors.deepNavy, ThemeColors.cardNavy, Color(0xFF2A3466)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ContentWidth(
                maxWidth: 420,
                child: AutofillGroup(
                  child: Column(
                    children: [
                      const AppLogo(size: 88),
                      const SizedBox(height: 16),
                      const Text(
                        'Monster Control Center',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to continue your hunt.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(height: 28),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Player Login',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 18),
                              AppTextField(
                                label: 'Username',
                                controller: _usernameController,
                                icon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                label: 'Password',
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onSubmitted: (_) => loading ? null : _login(),
                              ),
                              if (error.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                MessageBanner(message: error),
                              ],
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                onPressed: loading ? null : _login,
                                icon: loading ? const ButtonSpinner() : const Icon(Icons.login),
                                label: const Text('Login'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('New trainer?', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
                          TextButton(
                            onPressed: loading ? null : _openCreateAccount,
                            style: TextButton.styleFrom(foregroundColor: ThemeColors.pokeYellow),
                            child: const Text('Create Player Account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Registers a new player. Pops with the new username on success.
class CreatePlayerAccountScreen extends StatefulWidget {
  const CreatePlayerAccountScreen({super.key});

  @override
  State<CreatePlayerAccountScreen> createState() => _CreatePlayerAccountScreenState();
}

class _CreatePlayerAccountScreenState extends State<CreatePlayerAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool saving = false;
  String error = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    setState(() {
      saving = true;
      error = '';
    });

    try {
      final resp = await apiPost('create_player_api.php', {
        'username': username,
        'player_name': _nameController.text.trim(),
        'password': _passwordController.text,
      });
      if (!mounted) return;

      if (resp.statusCode == 200) {
        final serverError = responseError(resp.body);
        if (serverError != null) {
          setState(() => error = serverError);
          return;
        }
        Navigator.of(context).pop(username);
      } else {
        setState(() => error = 'Create failed (${resp.statusCode}): ${serverMessage(resp.body) ?? shortBody(resp.body)}');
      }
    } catch (e) {
      if (mounted) setState(() => error = requestErrorMessage(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ContentWidth(
            maxWidth: 460,
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Become a trainer',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create your hunter profile to start catching monsters.',
                      style: TextStyle(color: ThemeColors.textMuted),
                    ),
                    const SizedBox(height: 22),
                    AppTextField(
                      label: 'Username',
                      controller: _usernameController,
                      icon: Icons.alternate_email,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newUsername],
                      validator: validateUsername,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Player Name (optional)',
                      controller: _nameController,
                      icon: Icons.badge_outlined,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.nickname],
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Password',
                      hint: 'At least $minPasswordLength characters',
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: validateNewPassword,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Confirm Password',
                      controller: _confirmController,
                      icon: Icons.lock_reset,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => saving ? null : _createAccount(),
                      validator: (value) =>
                          value != _passwordController.text ? 'Passwords do not match.' : null,
                    ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      MessageBanner(message: error),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: saving ? null : _createAccount,
                      icon: saving ? const ButtonSpinner() : const Icon(Icons.check_circle_outline),
                      label: const Text('Create Account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
