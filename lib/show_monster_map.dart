import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

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
  late final TextEditingController _playerController;
  final String apiBase = 'http://100.69.77.17';
  final MapController _mapController = MapController();

  bool loading = false;
  String loadError = '';
  List<_CaughtMonster> monsters = [];
  _CaughtMonster? selectedMonster;

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
    final playerId = widget.playerId;

    setState(() {
      loading = true;
      loadError = '';
      selectedMonster = null;
    });

    final url = Uri.parse('$listEndpoint?player_id=$playerId');

    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final parsed = _parseCaught(resp.body, expectedPlayerId: playerId);
        final serverMsg = _extractServerMessage(resp.body);
        if (parsed.isEmpty && serverMsg != null && serverMsg.isNotEmpty) {
          setState(() => loadError = 'Server message: $serverMsg');
          return;
        }

        setState(() {
          monsters = parsed;
          selectedMonster = parsed.isNotEmpty ? parsed.first : null;
        });

        if (parsed.isNotEmpty) {
          final first = parsed.first;
          _mapController.move(LatLng(first.lat, first.lon), 16);
        }
      } else {
        setState(() => loadError = 'Server error: ${resp.statusCode}\n${_shortBody(resp.body)}');
      }
    } catch (e) {
      setState(() => loadError = 'Request failed: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseGreen = ThemeColors.deepNavy;
    final positionedMonsters = _spreadOverlappingMonsters(monsters);
    final initialCenter = monsters.isNotEmpty
        ? LatLng(monsters.first.lat, monsters.first.lon)
        : const LatLng(15.2234, 120.5835);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text('Show Monster Map', style: TextStyle(color: ThemeColors.deepNavy)),
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
              backgroundColor: ThemeColors.pokeRed,
              child: const Icon(Icons.map_outlined, color: Colors.white),
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
              const Text('Map of monsters caught by this player.'),
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
                    onPressed: loading ? null : _loadCaughtMonsters,
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
              const SizedBox(height: 12),
              Container(
                height: 340,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1626),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF22344A), width: 6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: monsters.isNotEmpty ? 16 : 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.cloudcom_final',
                      ),
                      MarkerLayer(
                        markers: positionedMonsters
                            .map(
                              (m) => Marker(
                                point: LatLng(m.pointLat, m.pointLon),
                                width: 46,
                                height: 46,
                                alignment: Alignment.topCenter,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => selectedMonster = m.monster);
                                  },
                                  child: Tooltip(
                                    message: 'Catch ID: ${m.monster.catchId}\n${m.monster.name}\nType: ${m.monster.type}\nCaught: ${m.monster.caughtAt ?? '-'}',
                                    child: Icon(
                                      Icons.location_on,
                                      color: selectedMonster?.catchId == m.monster.catchId
                                          ? ThemeColors.pokeYellow
                                          : ThemeColors.pokeRed,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Markers: ${monsters.length}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (selectedMonster != null) _buildMonsterSummaryTable(selectedMonster!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonsterSummaryTable(_CaughtMonster monster) {
    final borderColor = Colors.grey[300]!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Monster Summary',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _summaryRow('Catch ID', monster.catchId),
              _summaryRow('Monster ID', monster.monsterId),
              _summaryRow('Name', monster.name),
              _summaryRow('Monster Type', monster.type),
              _summaryRow('Latitude', monster.lat.toStringAsFixed(7)),
              _summaryRow('Longitude', monster.lon.toStringAsFixed(7)),
              _summaryRow('Coordinate Source', monster.coordinateSource),
              _summaryRow('Caught Date', monster.caughtAt ?? '-'),
            ],
          ),
        ],
      ),
    );
  }
}

TableRow _summaryRow(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(value),
      ),
    ],
  );
}

class _MarkerPoint {
  _MarkerPoint({
    required this.monster,
    required this.pointLat,
    required this.pointLon,
  });

  final _CaughtMonster monster;
  final double pointLat;
  final double pointLon;
}

class _CaughtMonster {
  _CaughtMonster({
    required this.catchId,
    required this.monsterId,
    required this.playerId,
    required this.name,
    required this.type,
    required this.lat,
    required this.lon,
    required this.coordinateSource,
    this.caughtAt,
  });

  final String catchId;
  final String monsterId;
  final String playerId;
  final String name;
  final String type;
  final double lat;
  final double lon;
  final String coordinateSource;
  final String? caughtAt;

  factory _CaughtMonster.fromMap(Map<String, dynamic> map) {
    final spawnLat = _toDouble(map['spawn_latitude'] ?? map['monster_latitude']);
    final spawnLon = _toDouble(map['spawn_longitude'] ?? map['monster_longitude']);
    final catchLat = _toDouble(map['latitude'] ?? map['catch_latitude'] ?? map['lat']);
    final catchLon = _toDouble(map['longitude'] ?? map['catch_longitude'] ?? map['lon']);

    final hasSpawn = spawnLat != null && spawnLon != null;
    final hasCatch = catchLat != null && catchLon != null;

    return _CaughtMonster(
      catchId: map['catch_id']?.toString() ?? '',
      monsterId: map['monster_id']?.toString() ?? '',
      playerId: map['player_id']?.toString() ?? '',
      name: map['monster_name']?.toString() ?? 'Monster',
      type: map['monster_type']?.toString() ?? 'Unknown',
      lat: hasSpawn ? spawnLat! : (hasCatch ? catchLat! : 0),
      lon: hasSpawn ? spawnLon! : (hasCatch ? catchLon! : 0),
      coordinateSource: hasSpawn
          ? 'Spawn'
          : (hasCatch ? 'Caught location' : 'Unknown'),
      caughtAt: map['caught_at']?.toString(),
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  return double.tryParse(value.toString());
}

List<_CaughtMonster> _parseCaught(String body, {required String expectedPlayerId}) {
  try {
    final decoded = json.decode(body);
    List list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map && decoded['data'] is List) {
      list = decoded['data'];
    } else {
      return [];
    }

    return list
        .whereType<Map>()
        .map((e) => _CaughtMonster.fromMap(Map<String, dynamic>.from(e)))
      .where((m) =>
          m.catchId.isNotEmpty &&
          m.lat != 0 &&
          m.lon != 0 &&
          (m.playerId.isEmpty || m.playerId == expectedPlayerId))
        .toList();
  } catch (_) {
    return [];
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
    // Ignore parse errors and fallback.
  }
  return null;
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

List<_MarkerPoint> _spreadOverlappingMonsters(List<_CaughtMonster> source) {
  final groups = <String, List<_CaughtMonster>>{};

  for (final monster in source) {
    final key =
        '${monster.lat.toStringAsFixed(7)}:${monster.lon.toStringAsFixed(7)}';
    groups.putIfAbsent(key, () => <_CaughtMonster>[]).add(monster);
  }

  final positioned = <_MarkerPoint>[];
  for (final entry in groups.entries) {
    final group = entry.value;
    if (group.length == 1) {
      positioned.add(
        _MarkerPoint(
          monster: group.first,
          pointLat: group.first.lat,
          pointLon: group.first.lon,
        ),
      );
      continue;
    }

    // Spread same-point catches in a small circle so each catch gets a visible marker.
    const spreadMeters = 8.0;
    for (var i = 0; i < group.length; i++) {
      final angle = (2 * math.pi * i) / group.length;
      final latMeters = spreadMeters * math.cos(angle);
      final lonMeters = spreadMeters * math.sin(angle);

      final base = group[i];
      final latOffset = latMeters / 111320.0;
      final lonOffset = lonMeters /
          (111320.0 * math.cos(base.lat * math.pi / 180).abs().clamp(0.2, 1));

      positioned.add(
        _MarkerPoint(
          monster: base,
          pointLat: base.lat + latOffset,
          pointLon: base.lon + lonOffset,
        ),
      );
    }
  }

  return positioned;
}
