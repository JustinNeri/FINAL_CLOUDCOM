import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'auth_models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoginSuccess});

  final void Function(PlayerProfile profile) onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final String apiBase = 'http://15.224.51.87';

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

    final url = Uri.parse('$apiBase/login_player_api.php');

    try {
      final resp = await http.post(url, body: {
        'username': username,
        'password': password,
      }).timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) {
        final serverError = _extractError(resp.body);
        setState(() => error = serverError ?? _shortBody(resp.body));
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
      setState(() => error = 'Request failed: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _openCreateAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePlayerAccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const baseGreen = Color(0xFF3F6F4F);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: baseGreen,
        title: const Text('Player Login', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3ECE1), Color(0xFFF3F8F2)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: baseGreen.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 120,
                left: -45,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: baseGreen.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD6E2D4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 44,
                                width: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3F6F4F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.shield_moon, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Monster Control Center',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sign in to continue your hunt operations.',
                            style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 16),
                          _Field(label: 'Username', controller: _usernameController),
                          const SizedBox(height: 10),
                          _Field(
                            label: 'Password',
                            controller: _passwordController,
                            obscureText: true,
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
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(error)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: loading ? null : _login,
                              icon: loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.login),
                              label: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 13),
                                child: Text('Login'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: baseGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: loading ? null : _openCreateAccount,
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 13),
                                child: Text('Create Player Account'),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: baseGreen,
                                side: const BorderSide(color: Color(0xFFC5D8C1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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

String? _extractError(String body) {
  try {
    final data = json.decode(body);
    if (data is Map<String, dynamic>) {
      final err = data['error']?.toString();
      if (err != null && err.trim().isNotEmpty) return err;
      final msg = data['message']?.toString();
      if (msg != null && msg.trim().isNotEmpty) return msg;
    }
  } catch (_) {
    // Ignore parse errors.
  }
  return null;
}

class CreatePlayerAccountScreen extends StatefulWidget {
  const CreatePlayerAccountScreen({super.key});

  @override
  State<CreatePlayerAccountScreen> createState() => _CreatePlayerAccountScreenState();
}

class _CreatePlayerAccountScreenState extends State<CreatePlayerAccountScreen> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  final String apiBase = 'http://15.224.51.87';

  bool saving = false;
  String error = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final username = _usernameController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => error = 'Username and password are required.');
      return;
    }

    setState(() {
      saving = true;
      error = '';
    });

    final url = Uri.parse('$apiBase/create_player_api.php');

    try {
      final resp = await http.post(url, body: {
        'username': username,
        'player_name': name,
        'password': password,
      }).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() => error = 'Create failed: ${resp.statusCode}\n${resp.body}');
      }
    } catch (e) {
      setState(() => error = 'Request failed: $e');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseGreen = Color(0xFF3F6F4F);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: baseGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Create Player Account', style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3ECE1), Color(0xFFF3F8F2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD6E2D4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create a new player account',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enter details below to register your hunter profile.',
                        style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 16),
                      _Field(label: 'Username', controller: _usernameController),
                      const SizedBox(height: 10),
                      _Field(label: 'Player Name', controller: _nameController),
                      const SizedBox(height: 10),
                      _Field(label: 'Password', controller: _passwordController, obscureText: true),
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
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(child: Text(error)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: saving ? null : _createAccount,
                          icon: saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 13),
                            child: Text('Create Account'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: baseGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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

class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late bool _isObscured;

  IconData _leadingIconFor(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('password')) return Icons.lock_outline;
    if (normalized.contains('username')) return Icons.alternate_email;
    if (normalized.contains('name')) return Icons.person_outline;
    return Icons.text_fields;
  }

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFCBD8C9);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: widget.controller,
          obscureText: _isObscured,
          enableSuggestions: !widget.obscureText,
          autocorrect: !widget.obscureText,
          decoration: InputDecoration(
            hintText: widget.label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(_leadingIconFor(widget.label), size: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3F6F4F)),
            ),
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
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
