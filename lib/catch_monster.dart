import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:torch_light/torch_light.dart';

import 'api.dart';
import 'location.dart';
import 'theme.dart';
import 'widgets.dart';

class CatchMonsterScreen extends StatefulWidget {
  const CatchMonsterScreen({
    super.key,
    required this.playerId,
    this.enableAlerts = true,
  });

  final String playerId;

  /// Flashlight, sound and vibration on detection. Off in tests.
  final bool enableAlerts;

  @override
  State<CatchMonsterScreen> createState() => _CatchMonsterScreenState();
}

class _CatchMonsterScreenState extends State<CatchMonsterScreen> {
  LatLng? _position;
  bool _locating = false;
  String? _locationError;

  String detectMessage = "";
  String catchMessage = "";
  String error = "";
  List<Map<String, dynamic>> nearby = [];
  final Set<int> caughtIds = {};
  bool detecting = false;
  bool catching = false;
  bool _alertInProgress = false;
  // SystemSoundType.alert is silent on Android and web, so the alarm plays an asset.
  AudioPlayer? _alertPlayer;

  int? detectedMonsterId;
  String? detectedMonsterName;

  @override
  void initState() {
    super.initState();
    if (widget.enableAlerts) _alertPlayer = AudioPlayer();
    _locate();
    _syncCaughtIdsFromServer();
  }

  @override
  void dispose() {
    if (widget.enableAlerts) unawaited(_turnOffTorchSafely());
    unawaited(_alertPlayer?.dispose());
    super.dispose();
  }

  String _detectedLabel(Map<String, dynamic> monster) {
    final name = monster["monster_name"]?.toString() ?? "monster";
    final type = monster["monster_type"]?.toString();
    final distance = monster["distance"]?.toString() ?? "";
    return "Detected: $name"
        "${type != null ? " ($type)" : ""}"
        "${distance.isNotEmpty ? " - $distance m away" : ""}";
  }

  Future<void> _turnOffTorchSafely() async {
    try {
      await TorchLight.disableTorch();
    } catch (_) {
      // Ignore torch disable failures when hardware is unavailable.
    }
  }

  Future<void> _triggerDetectionAlert() async {
    if (!widget.enableAlerts || _alertInProgress) return;
    _alertInProgress = true;

    final endAt = DateTime.now().add(const Duration(seconds: 5));
    try {
      try {
        await TorchLight.enableTorch();
      } catch (_) {
        // Continue alarm sound even if torch is unavailable.
      }

      // Stop early if the player leaves the screen.
      while (mounted && DateTime.now().isBefore(endAt)) {
        try {
          await _alertPlayer?.play(AssetSource('sounds/detect_alert.wav'));
        } catch (_) {
          // Keep vibrating even if audio playback is unavailable.
        }
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 700));
      }
    } finally {
      await _turnOffTorchSafely();
      _alertInProgress = false;
    }
  }

  Future<void> _playCatchSuccessCue() async {
    if (!widget.enableAlerts) return;
    // Play a short ascending cue to mimic a classic capture success sound.
    try {
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 120));
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Ignore sound/haptic failures on unsupported devices.
    }
  }

  Future<void> _syncCaughtIdsFromServer() async {
    try {
      final response = await apiGet("get_caught_monsters_api.php", {"player_id": widget.playerId});
      if (response.statusCode != 200 || response.body.isEmpty) return;
      final list = decodeList(response.body);
      if (list == null || !mounted) return;

      setState(() {
        caughtIds
          ..clear()
          ..addAll(list.map((m) => int.tryParse(m["monster_id"].toString())).whereType<int>());
      });
    } catch (_) {
      // Ignore sync failures and continue with local caughtIds cache.
    }
  }

  /// Refreshes [_position]; returns false and sets [_locationError] on failure.
  Future<bool> _locate() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final position = await currentLocation();
      if (!mounted) return false;
      setState(() => _position = position);
      return true;
    } catch (e) {
      if (mounted) setState(() => _locationError = e.toString());
      return false;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> detectMonster() async {
    setState(() {
      detecting = true;
      catchMessage = "";
      detectMessage = "";
      error = "";
    });

    try {
      if (!await _locate()) return;
      await _syncCaughtIdsFromServer();
      if (!mounted) return;

      setState(() {
        detectedMonsterId = null;
        detectedMonsterName = null;
        nearby = [];
      });

      final response = await apiGet("detect_monsters_api.php", {
        "lat": _position!.latitude.toString(),
        "lon": _position!.longitude.toString(),
      });
      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() => error = "Server error: ${response.statusCode}");
        return;
      }
      if (response.body.trim().isEmpty) {
        setState(() => detectMessage = "No monster found nearby.");
        return;
      }

      List<Map<String, dynamic>> items;
      try {
        final data = json.decode(response.body);
        items = data is List
            ? data.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
            : data is Map<String, dynamic>
                ? [data]
                : [];
      } on FormatException {
        setState(() => detectMessage = response.body);
        return;
      }

      final serverError = responseError(response.body);
      if (serverError != null) {
        setState(() => error = serverError);
        return;
      }

      // Filter out already-caught monsters client-side
      items = items.where((m) {
        final id = int.tryParse(m["monster_id"].toString());
        return id == null || !caughtIds.contains(id);
      }).toList();

      if (items.isEmpty) {
        setState(() => detectMessage = "No monster found nearby.");
        return;
      }

      final first = items.first;
      setState(() {
        nearby = items;
        detectedMonsterId = int.tryParse(first["monster_id"].toString());
        detectedMonsterName = first["monster_name"]?.toString();
        detectMessage = _detectedLabel(first);
      });
      unawaited(_triggerDetectionAlert());
    } catch (e) {
      if (mounted) setState(() => error = requestErrorMessage(e));
    } finally {
      if (mounted) setState(() => detecting = false);
    }
  }

  Future<void> catchMonster() async {
    if (detectedMonsterId == null) {
      setState(() => catchMessage = "Detect first, then catch.");
      return;
    }

    setState(() {
      catching = true;
      catchMessage = "";
      error = "";
    });

    try {
      if (!await _locate()) return;

      final response = await apiPost("catch_monster_api.php", {
        "player_id": widget.playerId,
        "monster_id": detectedMonsterId.toString(),
        "lat": _position!.latitude.toString(),
        "lon": _position!.longitude.toString(),
      });
      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() => error = "Catch failed: ${response.statusCode}");
        return;
      }
      final serverError = responseError(response.body);
      if (serverError != null) {
        setState(() => error = "Catch failed: $serverError");
        return;
      }

      final caughtName = detectedMonsterName ?? "Monster";
      setState(() {
        catchMessage = response.body.trim().isEmpty ? "You caught $caughtName!" : response.body;

        nearby.removeWhere((m) => int.tryParse(m["monster_id"].toString()) == detectedMonsterId);
        caughtIds.add(detectedMonsterId!);

        // Select the next available monster, or clear if none
        if (nearby.isNotEmpty) {
          final first = nearby.first;
          detectedMonsterId = int.tryParse(first["monster_id"].toString());
          detectedMonsterName = first["monster_name"]?.toString();
          detectMessage = _detectedLabel(first);
        } else {
          detectedMonsterId = null;
          detectedMonsterName = null;
          detectMessage = "";
        }
      });
      unawaited(_playCatchSuccessCue());
    } catch (e) {
      if (mounted) setState(() => error = requestErrorMessage(e));
    } finally {
      if (mounted) setState(() => catching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = detecting || catching;

    return Scaffold(
      appBar: AppBar(title: const Text('Catch Monsters')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LocationCard(
                  position: _position,
                  locating: _locating,
                  error: _locationError,
                  onRetry: busy || _locating ? null : _locate,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: busy ? null : detectMonster,
                  style: FilledButton.styleFrom(
                    backgroundColor: ThemeColors.pokeYellow,
                    foregroundColor: ThemeColors.deepNavy,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  icon: detecting
                      ? const ButtonSpinner(color: ThemeColors.deepNavy)
                      : const Icon(Icons.radar),
                  label: Text(detecting ? "Scanning…" : "Detect Monsters"),
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  MessageBanner(message: error),
                ],
                if (catchMessage.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  MessageBanner(
                    message: catchMessage,
                    kind: detectedMonsterId == null && nearby.isEmpty && catchMessage.startsWith("Detect")
                        ? MessageKind.info
                        : MessageKind.success,
                  ),
                ],
                if (detectMessage.isNotEmpty && nearby.isEmpty) ...[
                  const SizedBox(height: 14),
                  MessageBanner(message: detectMessage, kind: MessageKind.info),
                ],
                if (nearby.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  SectionTitle(
                    "Nearby Monsters (${nearby.length})",
                    trailing: const Text("Tap to select", style: TextStyle(color: ThemeColors.textMuted, fontSize: 12)),
                  ),
                  for (final m in nearby) ...[
                    _NearbyMonsterCard(
                      monster: m,
                      selected: detectedMonsterId != null &&
                          int.tryParse(m["monster_id"].toString()) == detectedMonsterId,
                      onTap: busy
                          ? null
                          : () => setState(() {
                                detectedMonsterId = int.tryParse(m["monster_id"].toString());
                                detectedMonsterName = m["monster_name"]?.toString() ?? "Monster";
                                detectMessage = _detectedLabel(m);
                                catchMessage = "";
                                error = "";
                              }),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: busy || detectedMonsterId == null ? null : catchMonster,
                    style: FilledButton.styleFrom(
                      backgroundColor: ThemeColors.pokeRed,
                      minimumSize: const Size.fromHeight(56),
                    ),
                    icon: catching ? const ButtonSpinner() : const Icon(Icons.catching_pokemon),
                    label: Text(catching
                        ? "Catching…"
                        : "Catch ${detectedMonsterName ?? "Monster"}"),
                  ),
                ],
                if (nearby.isEmpty && detectMessage.isEmpty && error.isEmpty && catchMessage.isEmpty && !detecting)
                  const EmptyState(
                    icon: Icons.radar,
                    title: "Ready to hunt",
                    message: "Press Detect Monsters to scan the area around you.",
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.position,
    required this.locating,
    required this.error,
    required this.onRetry,
  });

  final LatLng? position;
  final bool locating;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final String status;
    final Color color;
    if (error != null) {
      status = "Location unavailable";
      color = Theme.of(context).colorScheme.error;
    } else if (position == null) {
      status = "Finding your location…";
      color = ThemeColors.pokeBlue;
    } else {
      status = "${position!.latitude.toStringAsFixed(6)}, ${position!.longitude.toStringAsFixed(6)}";
      color = ThemeColors.success;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon: error != null ? Icons.location_off_outlined : Icons.my_location, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Your location", style: TextStyle(color: ThemeColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(status, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
                if (locating)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: ButtonSpinner(color: ThemeColors.pokeBlue),
                  )
                else
                  IconButton(
                    tooltip: "Update location",
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: const TextStyle(color: ThemeColors.textMuted, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _NearbyMonsterCard extends StatelessWidget {
  const _NearbyMonsterCard({required this.monster, required this.selected, required this.onTap});

  final Map<String, dynamic> monster;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = monster["monster_name"]?.toString() ?? "Monster";
    final type = monster["monster_type"]?.toString() ?? "Unknown";
    final distance = monster["distance"]?.toString();

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? ThemeColors.pokeYellow.withValues(alpha: 0.16) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          side: BorderSide(color: selected ? ThemeColors.pokeYellow : ThemeColors.outline, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const IconBadge(icon: Icons.pets, color: ThemeColors.pokeRed),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Pill(label: type, color: ThemeColors.pokeBlue),
                          if (distance != null)
                            Pill(label: "$distance m away", color: ThemeColors.textMuted, icon: Icons.near_me_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? ThemeColors.pokeYellow : ThemeColors.accentMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
