import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:torch_light/torch_light.dart';
import 'api.dart';
import 'theme.dart';

class CatchMonsterScreen extends StatefulWidget {
  const CatchMonsterScreen({
    super.key,
    required this.playerId,
  });

  final String playerId;

  @override
  State<CatchMonsterScreen> createState() => _CatchMonsterScreenState();
}

class _CatchMonsterScreenState extends State<CatchMonsterScreen> {
  String latitude = "";
  String longitude = "";
  String detectMessage = "";
  String catchMessage = "";
  String error = "";
  List<Map<String, dynamic>> nearby = [];
  final Set<int> caughtIds = {};
  bool detecting = false;
  bool catching = false;
  bool _alertInProgress = false;
  // SystemSoundType.alert is silent on Android and web, so the alarm plays an asset.
  final AudioPlayer _alertPlayer = AudioPlayer();

  int? detectedMonsterId;
  String? detectedMonsterName;

  @override
  void initState() {
    super.initState();
    getLocation();
    _syncCaughtIdsFromServer();
  }

  @override
  void dispose() {
    unawaited(_turnOffTorchSafely());
    unawaited(_alertPlayer.dispose());
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
    if (_alertInProgress) return;
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
          await _alertPlayer.play(AssetSource('sounds/detect_alert.wav'));
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
    // Play a short ascending cue to mimic a classic capture success sound.
    try {
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 120));
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 140));
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Ignore sound/haptic failures on unsupported devices.
    }
  }

  Future<void> _syncCaughtIdsFromServer() async {
    final url = Uri.parse(
        "$apiBase/get_caught_monsters_api.php?player_id=${widget.playerId}");
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.body.isEmpty) return;

      final decoded = json.decode(response.body);
      List list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        list = decoded['data'];
      } else {
        return;
      }

      final synced = <int>{};
      for (final item in list) {
        if (item is Map) {
          final id = int.tryParse(item["monster_id"].toString());
          if (id != null) synced.add(id);
        }
      }

      if (!mounted) return;
      setState(() {
        caughtIds
          ..clear()
          ..addAll(synced);
      });
    } catch (_) {
      // Ignore sync failures and continue with local caughtIds cache.
    }
  }

  /// Updates [latitude]/[longitude]; returns false and sets [error] on failure.
  Future<bool> getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => error = "Location services are disabled. Enable GPS.");
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) setState(() => error = "Location permission denied.");
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (!mounted) return false;
      setState(() {
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
        error = "";
      });
      return true;
    } catch (e) {
      if (mounted) setState(() => error = "Could not get your location: $e");
      return false;
    }
  }

  Future<void> detectMonster() async {
    if (!await getLocation()) return;
    await _syncCaughtIdsFromServer();
    if (!mounted) return;

    setState(() {
      detecting = true;
      catchMessage = "";
      detectMessage = "";
      error = "";
      detectedMonsterId = null;
      detectedMonsterName = null;
      nearby = [];
    });

    final url = Uri.parse(
      "$apiBase/detect_monsters_api.php?lat=$latitude&lon=$longitude",
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          setState(() => detectMessage = "No monster found nearby.");
        } else {
          try {
            final data = json.decode(response.body);
            List<Map<String, dynamic>> items = [];
            if (data is List) {
              for (final item in data) {
                if (item is Map) {
                  items.add(Map<String, dynamic>.from(item));
                }
              }
            } else if (data is Map<String, dynamic>) {
              items.add(data);
            }

            // Filter out already-caught monsters client-side
            items = items.where((m) {
              final id = int.tryParse(m["monster_id"].toString());
              return id == null || !caughtIds.contains(id);
            }).toList();

            if (items.isNotEmpty) {
              nearby = items;
              final first = items.first;
              detectedMonsterId = int.tryParse(first["monster_id"].toString());
              detectedMonsterName = first["monster_name"]?.toString();
              setState(() => detectMessage = _detectedLabel(first));
              unawaited(_triggerDetectionAlert());
            } else {
              setState(() => detectMessage = "No monster found nearby.");
            }
          } catch (_) {
            setState(() => detectMessage = response.body.isEmpty
                ? "No monster found nearby."
                : response.body);
          }
        }
      } else {
        setState(() => error = "Server error: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => error = "Request failed: $e");
    } finally {
      if (mounted) setState(() => detecting = false);
    }
  }

  Future<void> catchMonster() async {
    if (detectedMonsterId == null) {
      setState(() => catchMessage = "Detect first, then catch.");
      return;
    }
    if (!await getLocation()) return;

    setState(() {
      catching = true;
      catchMessage = "";
      error = "";
    });

    // Adjust player_id/location_id fields to match your API contract.
    final url = Uri.parse("$apiBase/catch_monster_api.php");
    final body = {
      "player_id": widget.playerId,
      "monster_id": detectedMonsterId.toString(),
      "lat": latitude,
      "lon": longitude,
    };

    try {
      final response =
          await http.post(url, body: body).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final serverError = responseError(response.body);
        if (serverError != null) {
          setState(() => error = "Catch failed: $serverError");
          return;
        }
        setState(() {
          catchMessage =
              response.body.isEmpty ? "Catch recorded." : response.body;

          // Remove the caught monster from the nearby list
          nearby.removeWhere((m) =>
              int.tryParse(m["monster_id"].toString()) == detectedMonsterId);

          if (detectedMonsterId != null) {
            caughtIds.add(detectedMonsterId!);
          }

          // Reset selection to next available, or clear if none
          if (nearby.isNotEmpty) {
            final first = nearby.first;
            detectedMonsterId = int.tryParse(first["monster_id"].toString());
            detectedMonsterName = first["monster_name"]?.toString();
            detectMessage = _detectedLabel(first);
          } else {
            detectedMonsterId = null;
            detectedMonsterName = null;
            detectMessage = "No monster selected";
          }
        });
        unawaited(_playCatchSuccessCue());
      } else {
        setState(() => error = "Catch failed: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) setState(() => error = "Request failed: $e");
    } finally {
      if (mounted) setState(() => catching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text('Catch Monsters',
            style: TextStyle(color: ThemeColors.deepNavy)),
        iconTheme: const IconThemeData(color: ThemeColors.deepNavy),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
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
              backgroundColor: ThemeColors.pokeBlue,
              child: const Icon(Icons.catching_pokemon, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                buildField("Your Latitude", latitude),
                buildField("Your Longitude", longitude),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: detecting ? null : detectMonster,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.pokeYellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: detecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Detect Monsters"),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: catching ? null : catchMonster,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.pokeYellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: catching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Catch Monster"),
                ),
                const SizedBox(height: 20),
                if (error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(error, textAlign: TextAlign.center),
                  ),
                if (detectMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      detectMessage,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (catchMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      catchMessage,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (nearby.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Nearby Monsters (${nearby.length})",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: nearby.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final m = nearby[index];
                      final name = m["monster_name"]?.toString() ?? "Monster";
                      final type = m["monster_type"]?.toString();
                      final distance = m["distance"]?.toString();
                      final id = int.tryParse(m["monster_id"].toString());
                      final selected =
                          detectedMonsterId != null && id == detectedMonsterId;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            detectedMonsterId = id;
                            detectedMonsterName = name;
                            detectMessage = _detectedLabel(m);
                            catchMessage = "";
                            error = "";
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected
                                ? ThemeColors.pokeYellow.withValues(alpha: 0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? ThemeColors.pokeYellow
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${type ?? "Unknown"} - ${distance ?? "?"} m",
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selected)
                                Icon(Icons.check_circle,
                                    color: ThemeColors.pokeYellow),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value.isEmpty ? "Loading..." : value),
        ),
      ],
    );
  }
}
