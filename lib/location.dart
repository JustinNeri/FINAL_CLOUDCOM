import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// A location problem with a message that can be shown to the player.
class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Returns the device's current position. Tests replace this.
Future<LatLng> Function() currentLocation = _deviceLocation;

Future<LatLng> _deviceLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationException('Location services are turned off. Turn on GPS and try again.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw const LocationException('Location permission was denied. Allow it to find monsters near you.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationException('Location permission is blocked. Enable it in your device or browser settings.');
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  } catch (e) {
    throw LocationException('Could not get your location ($e).');
  }
}
