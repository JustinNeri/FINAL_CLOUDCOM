import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'api.dart';
import 'location.dart';
import 'map_tiles.dart';
import 'theme.dart';
import 'widgets.dart';

class AddMonsterScreen extends StatefulWidget {
  const AddMonsterScreen({super.key});

  @override
  State<AddMonsterScreen> createState() => _AddMonsterScreenState();
}

class _AddMonsterScreenState extends State<AddMonsterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');
  final MapController _mapController = MapController();

  LatLng _selected = const LatLng(15.1636563, 120.5860201);
  double _radiusMeters = 100;
  bool _saving = false;
  bool _locating = false;
  bool _mapReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _useCurrentLocation(quiet: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _saveMonster() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final response = await apiGet('add_monster_api.php', {
        'name': name,
        'type': _typeController.text.trim(),
        'lat': _selected.latitude.toString(),
        'lon': _selected.longitude.toString(),
        'radius': _radiusMeters.toString(),
      });
      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() => _error = 'Failed to save monster (${response.statusCode}).');
        return;
      }
      final serverError = responseError(response.body);
      if (serverError != null) {
        setState(() => _error = serverError);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.body.trim().isEmpty ? '$name added to the map.' : response.body)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = requestErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _moveTo(LatLng point) {
    setState(() => _selected = point);
    // Before the map is ready, onMapReady centers it on _selected instead.
    if (_mapReady) _mapController.move(point, _mapController.camera.zoom);
  }

  /// Moves the spawn point to the device location. [quiet] skips the error
  /// message, for the automatic attempt when the screen opens.
  Future<void> _useCurrentLocation({bool quiet = false}) async {
    setState(() => _locating = true);
    try {
      final position = await currentLocation();
      if (mounted) _moveTo(position);
    } catch (e) {
      if (mounted && !quiet) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onRadiusChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() => _radiusMeters = parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Monster')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ContentWidth(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('Monster details'),
                  AppTextField(
                    label: 'Monster Name',
                    controller: _nameController,
                    icon: Icons.pets,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name.' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Monster Type',
                    hint: 'e.g. Fire, Water, Grass',
                    controller: _typeController,
                    icon: Icons.category_outlined,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a type.' : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Spawn Radius (meters)',
                    controller: _radiusController,
                    icon: Icons.radio_button_checked,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _onRadiusChanged,
                    validator: (v) {
                      final radius = double.tryParse((v ?? '').trim());
                      return radius == null || radius <= 0 ? 'Enter a number greater than 0.' : null;
                    },
                  ),
                  const SizedBox(height: 22),
                  SectionTitle(
                    'Spawn point',
                    trailing: TextButton.icon(
                      onPressed: _locating ? null : _useCurrentLocation,
                      icon: _locating
                          ? const ButtonSpinner(color: ThemeColors.pokeBlue)
                          : const Icon(Icons.my_location, size: 18),
                      label: const Text('Use my location'),
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _selected,
                              initialZoom: 17,
                              onTap: (_, point) => _moveTo(point),
                              onMapReady: () {
                                _mapReady = true;
                                _mapController.move(_selected, _mapController.camera.zoom);
                              },
                            ),
                            children: [
                              osmTileLayer(),
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: _selected,
                                    color: ThemeColors.pokeRed.withValues(alpha: 0.15),
                                    borderStrokeWidth: 2,
                                    borderColor: ThemeColors.pokeRed.withValues(alpha: 0.6),
                                    useRadiusInMeter: true,
                                    radius: _radiusMeters,
                                  ),
                                ],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selected,
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.topCenter,
                                    child: const Icon(Icons.location_on, color: ThemeColors.pokeRed, size: 42),
                                  ),
                                ],
                              ),
                              osmAttribution(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const Icon(Icons.touch_app_outlined, color: ThemeColors.textMuted, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tap the map to move the spawn point.\n'
                                  '${_selected.latitude.toStringAsFixed(6)}, ${_selected.longitude.toStringAsFixed(6)} · '
                                  '${_radiusMeters.toStringAsFixed(0)} m radius',
                                  style: const TextStyle(color: ThemeColors.textMuted, fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    MessageBanner(message: _error!),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveMonster,
                    icon: _saving ? const ButtonSpinner() : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save Monster'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
