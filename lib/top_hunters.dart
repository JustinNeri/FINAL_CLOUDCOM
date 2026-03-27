import 'dart:convert';

import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:http/http.dart' as http;

class TopHuntersScreen extends StatefulWidget {
  const TopHuntersScreen({super.key});

  @override
  State<TopHuntersScreen> createState() => _TopHuntersScreenState();
}

class _TopHuntersScreenState extends State<TopHuntersScreen> {
  final String apiBase = 'http://15.224.51.87';

  bool loading = false;
  String error = '';
  List<_HunterStat> hunters = [];

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

    final endpoints = [
      '$apiBase/view_top_hunters_api.php',
    ];

    http.Response? successResp;
    final failures = <String>[];

    for (final endpoint in endpoints) {
      try {
        final resp = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          successResp = resp;
          break;
        }
        failures.add('$endpoint -> ${resp.statusCode}');
      } catch (e) {
        failures.add('$endpoint -> $e');
      }
    }

    if (successResp == null) {
      setState(() {
        loading = false;
        error = failures.isEmpty
            ? 'No response from leaderboard API.'
            : 'Failed endpoints:\n${failures.join('\n')}';
      });
      return;
    }

    try {
      final parsed = _parseHunterStats(successResp.body);
      setState(() {
        hunters = parsed;
      });
    } catch (e) {
      setState(() => error = 'Parse error: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseGreen = ThemeColors.deepNavy;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text('View Top Monster Hunters', style: TextStyle(color: ThemeColors.deepNavy)),
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
              backgroundColor: ThemeColors.pokeYellow,
              child: const Icon(Icons.emoji_events_outlined, color: ThemeColors.deepNavy),
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
              const Text('Leaderboard of players by total monster catches.'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: loading ? null : _loadTopHunters,
                    icon: loading
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
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!loading && error.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top Hunters (${hunters.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    if (hunters.isEmpty)
                      const Text('No catches found yet.'),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: hunters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final h = hunters[index];
                        final rank = index + 1;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                                  if (rank == 1)
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(colors: [ThemeColors.pokeYellow, ThemeColors.pokeBlue]),
                                        boxShadow: [BoxShadow(color: ThemeColors.pokeYellow.withOpacity(0.2), blurRadius: 6)],
                                      ),
                                      child: const Center(child: Icon(Icons.emoji_events, color: Colors.white)),
                                    )
                                  else if (rank == 2)
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: ThemeColors.pokeBlue.withOpacity(0.9)),
                                      child: const Center(child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                                    )
                                  else if (rank == 3)
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: ThemeColors.pokeRed.withOpacity(0.9)),
                                      child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                                    )
                                  else
                                    SizedBox(
                                      width: 46,
                                      child: Text(
                                        '$rank',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: ThemeColors.deepNavy,
                                        ),
                                      ),
                                    ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h.playerName ?? 'Player ${h.playerId}',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Player ID: ${h.playerId}'),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: ThemeColors.deepNavy.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${h.totalCatches} catches',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: ThemeColors.deepNavy,
                                  ),
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

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFC49102);
    if (rank == 2) return const Color(0xFF6D7881);
    if (rank == 3) return const Color(0xFFA56A43);
    return ThemeColors.deepNavy;
  }
}

class _HunterStat {
  _HunterStat({
    required this.playerId,
    required this.totalCatches,
    this.playerName,
  });

  final String playerId;
  final int totalCatches;
  final String? playerName;
}

List<_HunterStat> _parseHunterStats(String body) {
  final decoded = json.decode(body);
  final list = _extractList(decoded);
  final byPlayer = <String, _HunterStat>{};

  for (final raw in list) {
    final map = Map<String, dynamic>.from(raw);
    final id = (map['player_id'] ?? map['id'] ?? map['playerId'])?.toString() ?? '';
    if (id.isEmpty) continue;

    final total = int.tryParse((map['total_catches'] ?? map['count'] ?? map['catch_count'] ?? '').toString());
    final name = map['player_name']?.toString();

    if (total != null) {
      byPlayer[id] = _HunterStat(playerId: id, totalCatches: total, playerName: name);
    } else {
      // Fallback: if API returns raw catch rows, aggregate by player_id.
      final existing = byPlayer[id];
      byPlayer[id] = _HunterStat(
        playerId: id,
        totalCatches: (existing?.totalCatches ?? 0) + 1,
        playerName: existing?.playerName ?? name,
      );
    }
  }

  final result = byPlayer.values.toList()
    ..sort((a, b) => b.totalCatches.compareTo(a.totalCatches));
  return result;
}

List<Map<String, dynamic>> _extractList(dynamic data) {
  if (data is List) {
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (data is Map && data['data'] is List) {
    return (data['data'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (data is Map) {
    return [Map<String, dynamic>.from(data)];
  }
  return [];
}