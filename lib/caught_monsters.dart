import 'package:flutter/material.dart';

import 'api.dart';
import 'theme.dart';
import 'widgets.dart';

/// A monster a player has caught, as returned by get_caught_monsters_api.php.
class CaughtMonster {
  const CaughtMonster({
    required this.catchId,
    required this.monsterId,
    this.playerId = '',
    this.name,
    this.type,
    this.spawnLat,
    this.spawnLon,
    this.catchLat,
    this.catchLon,
    this.caughtAt,
  });

  final String catchId;
  final String monsterId;
  final String playerId;
  final String? name;
  final String? type;
  final double? spawnLat;
  final double? spawnLon;
  final double? catchLat;
  final double? catchLon;
  final String? caughtAt;

  String get displayName => name?.isNotEmpty == true ? name! : 'Monster $monsterId';
  String get displayType => type?.isNotEmpty == true ? type! : 'Unknown type';

  bool get hasSpawn => spawnLat != null && spawnLon != null;
  bool get hasCatch => catchLat != null && catchLon != null;

  /// Where to pin the monster on a map: its spawn point, else where it was caught.
  double? get mapLat => hasSpawn ? spawnLat : catchLat;
  double? get mapLon => hasSpawn ? spawnLon : catchLon;
  String get coordinateSource => hasSpawn ? 'Spawn' : (hasCatch ? 'Caught location' : 'Unknown');

  CaughtMonster copyWith({String? name, String? type}) {
    return CaughtMonster(
      catchId: catchId,
      monsterId: monsterId,
      playerId: playerId,
      name: name ?? this.name,
      type: type ?? this.type,
      spawnLat: spawnLat,
      spawnLon: spawnLon,
      catchLat: catchLat,
      catchLon: catchLon,
      caughtAt: caughtAt,
    );
  }

  factory CaughtMonster.fromMap(Map<String, dynamic> map) {
    double? number(dynamic value) => value == null ? null : double.tryParse(value.toString());

    return CaughtMonster(
      catchId: map['catch_id']?.toString() ?? '',
      monsterId: map['monster_id']?.toString() ?? '',
      playerId: map['player_id']?.toString() ?? '',
      name: map['monster_name']?.toString(),
      type: map['monster_type']?.toString(),
      spawnLat: number(map['spawn_latitude'] ?? map['monster_latitude']),
      spawnLon: number(map['spawn_longitude'] ?? map['monster_longitude']),
      catchLat: number(map['latitude'] ?? map['catch_latitude'] ?? map['lat']),
      catchLon: number(map['longitude'] ?? map['catch_longitude'] ?? map['lon']),
      caughtAt: map['caught_at']?.toString(),
    );
  }
}

/// Loads a player's caught monsters. Throws an [Exception] whose message can
/// be shown to the player.
Future<List<CaughtMonster>> fetchCaughtMonsters(String playerId) async {
  final resp = await apiGet('get_caught_monsters_api.php', {'player_id': playerId});
  if (resp.statusCode != 200) {
    throw Exception('Server error: ${resp.statusCode}\n${shortBody(resp.body)}');
  }

  final monsters = (decodeList(resp.body) ?? [])
      .map(CaughtMonster.fromMap)
      .where((m) => m.catchId.isNotEmpty)
      .toList();

  final message = serverMessage(resp.body);
  if (monsters.isEmpty && message != null) throw Exception(message);
  return monsters;
}

/// Exception text without the "Exception: " prefix Dart adds.
String errorText(Object error) {
  final text = error.toString();
  if (text.startsWith('Exception: ')) return text.substring(11);
  return requestErrorMessage(error);
}

/// One caught monster in a list, with an action on the right.
class CaughtMonsterTile extends StatelessWidget {
  const CaughtMonsterTile({super.key, required this.monster, this.trailing, this.onTap});

  final CaughtMonster monster;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          child: Row(
            children: [
              const IconBadge(icon: Icons.pets, color: ThemeColors.pokeRed),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(monster.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Pill(label: monster.displayType, color: ThemeColors.pokeBlue),
                        Pill(label: '#${monster.monsterId}', color: ThemeColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared body for screens listing caught monsters: loading, error, empty and
/// list states with pull-to-refresh.
class CaughtMonsterListView extends StatelessWidget {
  const CaughtMonsterListView({
    super.key,
    required this.loading,
    required this.error,
    required this.monsters,
    required this.onRefresh,
    required this.intro,
    required this.itemBuilder,
  });

  final bool loading;
  final String error;
  final List<CaughtMonster> monsters;
  final Future<void> Function() onRefresh;
  final String intro;
  final Widget Function(CaughtMonster monster) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(intro, style: const TextStyle(color: ThemeColors.textMuted)),
                const SizedBox(height: 14),
                if (loading && monsters.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (error.isNotEmpty)
                  MessageBanner(message: error, onRetry: onRefresh)
                else if (monsters.isEmpty)
                  const EmptyState(
                    icon: Icons.catching_pokemon,
                    title: 'No caught monsters yet',
                    message: 'Monsters you catch will show up here.',
                  )
                else ...[
                  SectionTitle('Caught Monsters (${monsters.length})'),
                  for (final monster in monsters) ...[
                    itemBuilder(monster),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
