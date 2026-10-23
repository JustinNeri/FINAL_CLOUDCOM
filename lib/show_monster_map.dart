import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'caught_monsters.dart';
import 'map_tiles.dart';
import 'theme.dart';
import 'widgets.dart';

class ShowMonsterMapScreen extends StatefulWidget {
  const ShowMonsterMapScreen({
    super.key,
    required this.playerId,
  });

  final String playerId;

  @override
  State<ShowMonsterMapScreen> createState() => _ShowMonsterMapScreenState();
}

class _ShowMonsterMapScreenState extends State<ShowMonsterMapScreen> {
  static const _fallbackCenter = LatLng(15.2234, 120.5835);

  final MapController _mapController = MapController();

  bool loading = false;
  bool _mapReady = false;
  String loadError = '';
  List<CaughtMonster> monsters = [];
  CaughtMonster? selectedMonster;

  @override
  void initState() {
    super.initState();
    _loadCaughtMonsters();
  }

  Future<void> _loadCaughtMonsters() async {
    setState(() {
      loading = true;
      loadError = '';
      selectedMonster = null;
    });

    try {
      final all = await fetchCaughtMonsters(widget.playerId);
      if (!mounted) return;
      final mappable = all
          .where((m) =>
              m.mapLat != null &&
              m.mapLon != null &&
              m.mapLat != 0 &&
              m.mapLon != 0 &&
              (m.playerId.isEmpty || m.playerId == widget.playerId))
          .toList();
      setState(() {
        monsters = mappable;
        selectedMonster = mappable.isNotEmpty ? mappable.first : null;
      });
      _fitToMonsters();
    } catch (e) {
      if (mounted) setState(() => loadError = errorText(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Zooms the map so every marker is visible.
  void _fitToMonsters() {
    if (!_mapReady || monsters.isEmpty) return;
    final points = monsters.map((m) => LatLng(m.mapLat!, m.mapLon!)).toList();
    if (points.length == 1) {
      _mapController.move(points.first, 16);
    } else {
      _mapController.fitCamera(
        CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(56), maxZoom: 17),
      );
    }
  }

  void _select(CaughtMonster monster) {
    setState(() => selectedMonster = monster);
    if (_mapReady) {
      _mapController.move(LatLng(monster.mapLat!, monster.mapLon!), math.max(_mapController.camera.zoom, 16));
    }
  }

  @override
  Widget build(BuildContext context) {
    final positionedMonsters = _spreadOverlappingMonsters(monsters);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monster Map'),
        actions: [
          if (monsters.length > 1)
            IconButton(
              tooltip: 'Show all monsters',
              onPressed: _fitToMonsters,
              icon: const Icon(Icons.zoom_out_map),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : _loadCaughtMonsters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (loadError.isNotEmpty) ...[
                  MessageBanner(message: loadError, onRetry: _loadCaughtMonsters),
                  const SizedBox(height: 14),
                ],
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 380,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _fallbackCenter,
                            initialZoom: 13,
                            onMapReady: () {
                              _mapReady = true;
                              _fitToMonsters();
                            },
                          ),
                          children: [
                            osmTileLayer(),
                            MarkerLayer(
                              markers: [
                                for (final m in positionedMonsters)
                                  Marker(
                                    point: LatLng(m.pointLat, m.pointLon),
                                    width: 46,
                                    height: 46,
                                    alignment: Alignment.topCenter,
                                    child: GestureDetector(
                                      onTap: () => setState(() => selectedMonster = m.monster),
                                      child: Tooltip(
                                        message: '${m.monster.displayName} · ${m.monster.displayType}',
                                        child: Icon(
                                          Icons.location_on,
                                          color: selectedMonster?.catchId == m.monster.catchId
                                              ? ThemeColors.pokeYellow
                                              : ThemeColors.pokeRed,
                                          size: 40,
                                          shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            osmAttribution(),
                          ],
                        ),
                        if (loading)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(minHeight: 3),
                          ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Material(
                            color: Colors.white,
                            elevation: 2,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Text(
                                '${monsters.length} ${monsters.length == 1 ? 'catch' : 'catches'}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (selectedMonster != null) ...[
                  _MonsterSummary(monster: selectedMonster!),
                  const SizedBox(height: 20),
                ],
                if (!loading && loadError.isEmpty && monsters.isEmpty)
                  const EmptyState(
                    icon: Icons.map_outlined,
                    title: 'No catches on the map yet',
                    message: 'Catch a monster and it will be pinned here.',
                  ),
                if (monsters.length > 1) ...[
                  const SectionTitle('All catches'),
                  for (final m in monsters) ...[
                    CaughtMonsterTile(
                      monster: m,
                      onTap: () => _select(m),
                      trailing: Icon(
                        selectedMonster?.catchId == m.catchId ? Icons.location_on : Icons.chevron_right,
                        color: selectedMonster?.catchId == m.catchId ? ThemeColors.pokeYellow : ThemeColors.accentMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonsterSummary extends StatelessWidget {
  const _MonsterSummary({required this.monster});

  final CaughtMonster monster;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Catch ID', monster.catchId),
      ('Monster ID', monster.monsterId),
      ('Type', monster.displayType),
      ('Latitude', monster.mapLat!.toStringAsFixed(7)),
      ('Longitude', monster.mapLon!.toStringAsFixed(7)),
      ('Pinned at', monster.coordinateSource),
      ('Caught', monster.caughtAt ?? '-'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBadge(icon: Icons.pets, color: ThemeColors.pokeYellow),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(monster.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 6),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(label, style: const TextStyle(color: ThemeColors.textMuted)),
                    ),
                    Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarkerPoint {
  _MarkerPoint({
    required this.monster,
    required this.pointLat,
    required this.pointLon,
  });

  final CaughtMonster monster;
  final double pointLat;
  final double pointLon;
}

List<_MarkerPoint> _spreadOverlappingMonsters(List<CaughtMonster> source) {
  final groups = <String, List<CaughtMonster>>{};

  for (final monster in source) {
    final key = '${monster.mapLat!.toStringAsFixed(7)}:${monster.mapLon!.toStringAsFixed(7)}';
    groups.putIfAbsent(key, () => <CaughtMonster>[]).add(monster);
  }

  final positioned = <_MarkerPoint>[];
  for (final group in groups.values) {
    if (group.length == 1) {
      positioned.add(_MarkerPoint(monster: group.first, pointLat: group.first.mapLat!, pointLon: group.first.mapLon!));
      continue;
    }

    // Spread same-point catches in a small circle so each catch gets a visible marker.
    const spreadMeters = 8.0;
    for (var i = 0; i < group.length; i++) {
      final angle = (2 * math.pi * i) / group.length;
      final base = group[i];
      final latOffset = spreadMeters * math.cos(angle) / 111320.0;
      final lonOffset = spreadMeters * math.sin(angle) /
          (111320.0 * math.cos(base.mapLat! * math.pi / 180).abs().clamp(0.2, 1));

      positioned.add(_MarkerPoint(
        monster: base,
        pointLat: base.mapLat! + latOffset,
        pointLon: base.mapLon! + lonOffset,
      ));
    }
  }

  return positioned;
}
