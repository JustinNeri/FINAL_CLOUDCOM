import 'package:flutter/material.dart';

import 'api.dart';
import 'caught_monsters.dart';
import 'theme.dart';
import 'widgets.dart';

class EditMonsterScreen extends StatefulWidget {
  const EditMonsterScreen({super.key, required this.playerId});

  final String playerId;

  @override
  State<EditMonsterScreen> createState() => _EditMonsterScreenState();
}

class _EditMonsterScreenState extends State<EditMonsterScreen> {
  bool loadingList = false;
  String loadError = '';
  List<CaughtMonster> caughtMonsters = [];

  @override
  void initState() {
    super.initState();
    _loadCaughtMonsters();
  }

  Future<void> _loadCaughtMonsters() async {
    setState(() {
      loadingList = true;
      loadError = '';
    });

    try {
      final monsters = await fetchCaughtMonsters(widget.playerId);
      if (mounted) setState(() => caughtMonsters = monsters);
    } catch (e) {
      if (mounted) setState(() => loadError = errorText(e));
    } finally {
      if (mounted) setState(() => loadingList = false);
    }
  }

  /// Sends the edit; returns an error message, or null on success.
  Future<String?> _editMonster(CaughtMonster monster, String newName, String newType) async {
    try {
      final resp = await apiPost('edit_monster_api.php', {
        'catch_id': monster.catchId,
        'monster_id': monster.monsterId,
        if (newName.isNotEmpty) 'name': newName,
        if (newType.isNotEmpty) 'type': newType,
      });
      if (resp.statusCode != 200) return 'Server error: ${resp.statusCode}\n${shortBody(resp.body)}';
      final serverError = responseError(resp.body);
      if (serverError != null) return serverError;

      if (mounted) {
        setState(() {
          caughtMonsters = [
            for (final m in caughtMonsters)
              m.catchId == monster.catchId
                  ? m.copyWith(name: newName.isEmpty ? null : newName, type: newType.isEmpty ? null : newType)
                  : m,
          ];
        });
      }
      return null;
    } catch (e) {
      return requestErrorMessage(e);
    }
  }

  Future<void> _openEditSheet(CaughtMonster monster) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditMonsterSheet(
        monster: monster,
        onSave: (name, type) => _editMonster(monster, name, type),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monster updated.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Monsters'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadingList ? null : _loadCaughtMonsters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: CaughtMonsterListView(
          loading: loadingList,
          error: loadError,
          monsters: caughtMonsters,
          onRefresh: _loadCaughtMonsters,
          intro: 'Tap a monster to change its name or type.',
          itemBuilder: (m) => CaughtMonsterTile(
            monster: m,
            onTap: () => _openEditSheet(m),
            trailing: IconButton(
              tooltip: 'Edit ${m.displayName}',
              onPressed: () => _openEditSheet(m),
              icon: const Icon(Icons.edit_outlined, color: ThemeColors.pokeBlue),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet form for renaming a monster. Pops with true once saved.
class _EditMonsterSheet extends StatefulWidget {
  const _EditMonsterSheet({required this.monster, required this.onSave});

  final CaughtMonster monster;
  final Future<String?> Function(String name, String type) onSave;

  @override
  State<_EditMonsterSheet> createState() => _EditMonsterSheetState();
}

class _EditMonsterSheetState extends State<_EditMonsterSheet> {
  late final TextEditingController _nameCtrl = TextEditingController(text: widget.monster.name ?? '');
  late final TextEditingController _typeCtrl = TextEditingController(text: widget.monster.type ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final type = _typeCtrl.text.trim();
    if (name.isEmpty && type.isEmpty) {
      setState(() => _error = 'Enter a new name or type.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(name, type);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: ContentWidth(
        maxWidth: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit ${widget.monster.displayName}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text('Monster #${widget.monster.monsterId}', style: const TextStyle(color: ThemeColors.textMuted)),
            const SizedBox(height: 18),
            AppTextField(label: 'Monster Name', controller: _nameCtrl, icon: Icons.pets, textInputAction: TextInputAction.next),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Monster Type',
              controller: _typeCtrl,
              icon: Icons.category_outlined,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saving ? null : _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              MessageBanner(message: _error!),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const ButtonSpinner() : const Icon(Icons.save_outlined),
              label: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
