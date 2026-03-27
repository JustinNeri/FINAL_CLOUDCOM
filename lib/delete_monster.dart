import 'dart:convert';

import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:http/http.dart' as http;

class DeleteMonsterScreen extends StatefulWidget {
  const DeleteMonsterScreen({
    super.key,
    required this.playerId,
  });

  final String playerId;

  @override
  State<DeleteMonsterScreen> createState() => _DeleteMonsterScreenState();
}

class _DeleteMonsterScreenState extends State<DeleteMonsterScreen> {
  late final TextEditingController _playerController;

  bool deleting = false;
  bool loadingList = false;
  String loadError = '';
  List<_Monster> caughtMonsters = [];

  final String apiBase = 'http://15.224.51.87';
  String get listEndpoint => '$apiBase/get_caught_monsters_api.php';

  @override
  void initState() {
    super.initState();
    _playerController = TextEditingController(text: widget.playerId);
    _loadCaughtMonsters();
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _loadCaughtMonsters() async {
    final playerId = _playerController.text.trim().isEmpty
        ? '1'
        : _playerController.text.trim();

    setState(() {
      loadingList = true;
      loadError = '';
    });

    final url = Uri.parse('$listEndpoint?player_id=$playerId');

    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final parsed = _parseList(resp.body);
        final serverMsg = _extractServerMessage(resp.body);
        if (parsed.isEmpty && serverMsg != null && serverMsg.isNotEmpty) {
          setState(() => loadError = 'Server message: $serverMsg');
          return;
        }
        setState(() {
          caughtMonsters = parsed;
        });
      } else {
        setState(() => loadError = 'Server error: ${resp.statusCode}\n${_shortBody(resp.body)}');
      }
    } catch (e) {
      setState(() => loadError = 'Request failed: $e');
    } finally {
      if (mounted) {
        setState(() => loadingList = false);
      }
    }
  }

  Future<void> _deleteMonster(_Monster monster) async {
    if (monster.catchId.isEmpty) {
      _show('Catch ID missing.');
      return;
    }

    setState(() => deleting = true);

    final url = Uri.parse('$apiBase/delete_monster_api.php');
    final body = {
      'catch_id': monster.catchId,
      'monster_id': monster.monsterId,
    };

    try {
      final resp = await http.post(url, body: body).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        _show('Delete Successfully');
        setState(() {
          caughtMonsters.removeWhere((m) => m.catchId == monster.catchId);
        });
      } else {
        _show('Server error: ${resp.statusCode}\n${_shortBody(resp.body)}');
      }
    } catch (e) {
      _show('Request failed: $e');
    } finally {
      if (mounted) {
        setState(() => deleting = false);
      }
    }
  }

  Future<void> _confirmDelete(_Monster monster) async {
    if (deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Monster'),
        content: Text('Delete ${monster.name ?? 'Monster'} (#${monster.monsterId})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteMonster(monster);
    }
  }

  void _show(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    const baseGreen = ThemeColors.deepNavy;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text('Delete Monsters', style: TextStyle(color: ThemeColors.deepNavy)),
        iconTheme: const IconThemeData(color: ThemeColors.deepNavy),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: CircleAvatar(
              backgroundColor: ThemeColors.pokeYellow,
              child: const Icon(Icons.arrow_back, color: ThemeColors.deepNavy),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.deepOrange,
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Caught monsters for this player. Tap delete to remove a monster.'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _Field(
                      label: 'Player ID',
                      controller: _playerController,
                      keyboard: TextInputType.number,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: loadingList ? null : _loadCaughtMonsters,
                    icon: loadingList
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.refresh, color: Colors.black),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.pokeYellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(120, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (loadError.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(loadError),
                ),
              if (loadingList)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!loadingList && loadError.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Caught Monsters (${caughtMonsters.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (caughtMonsters.isEmpty)
                      const Text('No caught monsters yet.'),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: caughtMonsters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final m = caughtMonsters[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.name ?? 'Monster ${m.monsterId}',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(m.type ?? 'Unknown type', style: const TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: deleting ? null : () => _confirmDelete(m),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Delete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: baseGreen,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
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

String? _extractServerMessage(String body) {
  try {
    final data = json.decode(body);
    if (data is Map<String, dynamic>) {
      final err = data['error']?.toString();
      if (err != null && err.trim().isNotEmpty) return err;
      final msg = data['message']?.toString();
      if (msg != null && msg.trim().isNotEmpty) return msg;
    }
  } catch (_) {
    // Ignore parse errors and fallback to generic handling.
  }
  return null;
}

class _Monster {
  _Monster({
    required this.catchId,
    required this.monsterId,
    this.name,
    this.type,
  });

  final String catchId;
  final String monsterId;
  final String? name;
  final String? type;

  factory _Monster.fromMap(Map<String, dynamic> map) {
    return _Monster(
      catchId: map['catch_id']?.toString() ?? '',
      monsterId: map['monster_id']?.toString() ?? '',
      name: map['monster_name']?.toString(),
      type: map['monster_type']?.toString(),
    );
  }
}

List<_Monster> _parseList(String body) {
  try {
    final data = json.decode(body);
    List list;
    if (data is List) {
      list = data;
    } else if (data is Map && data['data'] is List) {
      list = data['data'];
    } else {
      return [];
    }
    return list
        .whereType<Map>()
        .map((m) => _Monster.fromMap(Map<String, dynamic>.from(m)))
      .where((m) => m.catchId.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboard,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFCBD8C9);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: ThemeColors.deepNavy),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}