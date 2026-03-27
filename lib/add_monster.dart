import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'theme.dart';
class AddMonsterScreen extends StatefulWidget {
  const AddMonsterScreen({super.key});

  @override
  State<AddMonsterScreen> createState() => _AddMonsterScreenState();
}

class _AddMonsterScreenState extends State<AddMonsterScreen> {
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');
  final MapController _mapController = MapController();

  LatLng _selected = const LatLng(15.1636563, 120.5860201);
  double _radiusMeters = 100;

  @override
  void initState() {
    super.initState();
    _setDefaultToCurrentLocation();
  }

  Future<void> _saveMonster() async {
    final name = _nameController.text.trim();
    final type = _typeController.text.trim();
    final lat = _selected.latitude;
    final lon = _selected.longitude;
    final radius = _radiusMeters;

    if (name.isEmpty || type.isEmpty) {
      _showStub("Please fill all fields");
      return;
    }

    final url = Uri.parse(
      "http://100.69.77.17/add_monster_api.php"
      "?name=$name&type=$type&lat=$lat&lon=$lon&radius=$radius",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        _showStub(response.body);
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        _showStub("Failed to save monster");
      }
    } catch (e) {
      _showStub("Error: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() => _selected = latLng);
    _mapController.move(latLng, _mapController.camera.zoom);
  }

  void _onRadiusChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() => _radiusMeters = parsed);
    }
  }

  void _showStub(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _setDefaultToCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final next = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      setState(() => _selected = next);
      _mapController.move(next, _mapController.camera.zoom);
    } catch (_) {
      // Keep existing fallback location if GPS is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    const baseGreen = ThemeColors.deepNavy;
    const border = Color(0xFFCBD8C9);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text('Add Monster', style: TextStyle(color: ThemeColors.deepNavy)),
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
              child: const Icon(Icons.add, color: Colors.white),
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
              _LabeledField(
                label: 'Monster Name',
                controller: _nameController,
                hint: 'Monster Name',
              ),
              const SizedBox(height: 10),
              _LabeledField(
                label: 'Monster Type',
                controller: _typeController,
                hint: 'Monster Type',
              ),
              const SizedBox(height: 10),
              _LabeledField(
                label: 'Spawn Radius (meters)',
                controller: _radiusController,
                hint: '100',
                keyboardType: TextInputType.number,
                onChanged: _onRadiusChanged,
              ),
              const SizedBox(height: 12),
              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: ThemeColors.cardNavy,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeColors.borderNavy, width: 6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selected,
                      initialZoom: 17,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.cloudcom_final',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _selected,
                            color: ThemeColors.deepNavy.withOpacity(0.18),
                            borderStrokeWidth: 2,
                            borderColor: ThemeColors.deepNavy.withOpacity(0.5),
                            useRadiusInMeter: true,
                            radius: _radiusMeters,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selected,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: const Icon(
                              Icons.location_on,
                              color: ThemeColors.pokeRed,
                              size: 38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tap on the map to set the monster spawn point',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Latitude: ${_selected.latitude.toStringAsFixed(6)}'),
                    Text('Longitude: ${_selected.longitude.toStringAsFixed(6)}'),
                    Text('Radius: ${_radiusMeters.toStringAsFixed(1)} meters'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ActionButton(
                label: 'Save Monster',
                icon: Icons.save_outlined,
                onPressed: _saveMonster,
                filled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;

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
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: ThemeColors.pokeYellow),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const baseGreen = ThemeColors.deepNavy;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? ThemeColors.pokeYellow : Colors.white,
          foregroundColor: filled ? Colors.black : ThemeColors.pokeBlue,
          side: const BorderSide(color: ThemeColors.pokeBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: filled ? 2 : 0,
        ),
      ),
    );
  }
}
