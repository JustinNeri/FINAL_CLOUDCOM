import 'dart:convert';

import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';
import 'widgets.dart';

class TopHuntersScreen extends StatefulWidget {
  const TopHuntersScreen({super.key, this.currentPlayerId});

  final String? currentPlayerId;

  @override
  State<TopHuntersScreen> createState() => _TopHuntersScreenState();
}

class _TopHuntersScreenState extends State<TopHuntersScreen> {
  bool loading = false;
  String error = '';
  List<HunterStat> hunters = [];

  @override
  void initState() {
    super.initState();
    _loadTopHunters();
  }

  Future<void> _loadTopHunters() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final resp = await apiGet('view_top_hunters_api.php');
      if (!mounted) return;
      if (resp.statusCode != 200) {
        setState(() => error = 'Could not load the leaderboard (${resp.statusCode}).');
        return;
      }
      setState(() => hunters = parseHunterStats(resp.body));
    } on FormatException catch (e) {
      if (mounted) setState(() => error = 'Parse error: ${e.message}');
    } catch (e) {
      if (mounted) setState(() => error = requestErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = widget.currentPlayerId?.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Hunters'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : _loadTopHunters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTopHunters,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Players ranked by total monster catches.',
                      style: TextStyle(color: ThemeColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    if (loading && hunters.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (error.isNotEmpty)
                      MessageBanner(message: error, onRetry: _loadTopHunters)
                    else if (hunters.isEmpty)
                      const EmptyState(
                        icon: Icons.emoji_events_outlined,
                        title: 'No catches found yet',
                        message: 'Be the first hunter on the board!',
                      )
                    else
                      for (var i = 0; i < hunters.length; i++) ...[
                        _HunterRow(
                          hunter: hunters[i],
                          rank: i + 1,
                          isOwner: ownerId != null && ownerId.isNotEmpty && ownerId == hunters[i].playerId.trim(),
                        ),
                        const SizedBox(height: 8),
                      ],
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

class _HunterRow extends StatelessWidget {
  const _HunterRow({required this.hunter, required this.rank, required this.isOwner});

  final HunterStat hunter;
  final int rank;
  final bool isOwner;

  static const _medals = {
    1: Color(0xFFE2A400),
    2: Color(0xFF8A96A3),
    3: Color(0xFFB0703F),
  };

  @override
  Widget build(BuildContext context) {
    final medal = _medals[rank];

    return Semantics(
      label: 'Rank $rank, ${hunter.playerName ?? 'Player ${hunter.playerId}'}, ${hunter.totalCatches} catches${isOwner ? ', you' : ''}',
      excludeSemantics: true,
      child: Material(
        color: isOwner ? ThemeColors.pokeYellow.withValues(alpha: 0.18) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: BorderSide(color: isOwner ? ThemeColors.pokeYellow : ThemeColors.outline, width: isOwner ? 2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: medal ?? ThemeColors.background,
                ),
                child: rank == 1
                    ? const Icon(Icons.emoji_events, color: Colors.white)
                    : Text(
                        '$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: medal != null ? Colors.white : ThemeColors.deepNavy,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            hunter.playerName ?? 'Player ${hunter.playerId}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 8),
                          const Pill(label: 'You', color: ThemeColors.deepNavy),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Trainer ID #${hunter.playerId}', style: const TextStyle(color: ThemeColors.textMuted, fontSize: 12.5)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${hunter.totalCatches}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: ThemeColors.deepNavy),
                  ),
                  const Text('catches', style: TextStyle(color: ThemeColors.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HunterStat {
  HunterStat({
    required this.playerId,
    required this.totalCatches,
    this.playerName,
  });

  final String playerId;
  final int totalCatches;
  final String? playerName;
}

/// Builds the leaderboard from either per-player totals or raw catch rows,
/// sorted by catches, most first.
List<HunterStat> parseHunterStats(String body) {
  final decoded = json.decode(body);
  final list = decodeList(body) ?? (decoded is Map ? [Map<String, dynamic>.from(decoded)] : <Map<String, dynamic>>[]);
  final byPlayer = <String, HunterStat>{};

  for (final map in list) {
    final id = (map['player_id'] ?? map['id'] ?? map['playerId'])?.toString() ?? '';
    if (id.isEmpty) continue;

    final total = int.tryParse((map['total_catches'] ?? map['count'] ?? map['catch_count'] ?? '').toString());
    final name = map['player_name']?.toString();

    if (total != null) {
      byPlayer[id] = HunterStat(playerId: id, totalCatches: total, playerName: name);
    } else {
      // Fallback: if API returns raw catch rows, aggregate by player_id.
      final existing = byPlayer[id];
      byPlayer[id] = HunterStat(
        playerId: id,
        totalCatches: (existing?.totalCatches ?? 0) + 1,
        playerName: existing?.playerName ?? name,
      );
    }
  }

  return byPlayer.values.toList()..sort((a, b) => b.totalCatches.compareTo(a.totalCatches));
}
