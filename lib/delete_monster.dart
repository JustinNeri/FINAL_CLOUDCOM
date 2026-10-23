import 'package:flutter/material.dart';

import 'api.dart';
import 'caught_monsters.dart';
import 'theme.dart';

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
  bool loadingList = false;
  String loadError = '';
  List<CaughtMonster> caughtMonsters = [];

  /// Catch currently being deleted, so only its button shows progress.
  String? deletingCatchId;

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

  Future<void> _deleteMonster(CaughtMonster monster) async {
    setState(() => deletingCatchId = monster.catchId);

    try {
      final resp = await apiPost('delete_monster_api.php', {
        'catch_id': monster.catchId,
        'monster_id': monster.monsterId,
      });
      if (!mounted) return;

      if (resp.statusCode != 200) {
        _show('Server error: ${resp.statusCode}\n${shortBody(resp.body)}');
        return;
      }
      final serverError = responseError(resp.body);
      if (serverError != null) {
        _show('Delete failed: $serverError');
        return;
      }
      setState(() => caughtMonsters.removeWhere((m) => m.catchId == monster.catchId));
      _show('${monster.displayName} was released.');
    } catch (e) {
      if (mounted) _show(requestErrorMessage(e));
    } finally {
      if (mounted) setState(() => deletingCatchId = null);
    }
  }

  Future<void> _confirmDelete(CaughtMonster monster) async {
    if (deletingCatchId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_outline, color: ThemeColors.pokeRed, size: 32),
        title: Text('Delete ${monster.displayName}?'),
        content: const Text('This removes the catch from your collection. It cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ThemeColors.pokeRed),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Monsters'),
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
          intro: 'Release monsters you no longer want in your collection.',
          itemBuilder: (m) => CaughtMonsterTile(
            monster: m,
            trailing: deletingCatchId == m.catchId
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
                  )
                : IconButton(
                    tooltip: 'Delete ${m.displayName}',
                    onPressed: deletingCatchId != null ? null : () => _confirmDelete(m),
                    icon: const Icon(Icons.delete_outline, color: ThemeColors.pokeRed),
                  ),
          ),
        ),
      ),
    );
  }
}
