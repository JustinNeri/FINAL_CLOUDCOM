import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// OpenStreetMap tiles, requested the way the OSM tile usage policy asks:
/// a single host (no a/b/c subdomains) and an identifying user agent.
/// For heavy traffic, switch [urlTemplate] to a commercial or self-hosted provider.
TileLayer osmTileLayer() {
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.example.cloudcom_final',
    maxNativeZoom: 19,
  );
}

/// The "© OpenStreetMap contributors" credit OSM requires on every map.
Widget osmAttribution() {
  return const SimpleAttributionWidget(
    source: Text('OpenStreetMap contributors'),
    backgroundColor: Color(0xCCFFFFFF),
  );
}
