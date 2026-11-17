
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    // Check whether location services are enabled.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable GPS.',
      );
    }

    // Check permission.
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. '
        'Please enable it from app settings.',
      );
    }

    // Get current GPS position.
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  double calculateDistance({
    required double latitude,
    required double longitude,
    required double officeLatitude,
    required double officeLongitude,
  }) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      officeLatitude,
      officeLongitude,
    );
  }

  bool isWithinOfficeRadius({
    required double latitude,
    required double longitude,
    required double officeLatitude,
    required double officeLongitude,
    double radiusInMeters = 200,
  }) {
    final distance = calculateDistance(
      latitude: latitude,
      longitude: longitude,
      officeLatitude: officeLatitude,
      officeLongitude: officeLongitude,
    );

    return distance <= radiusInMeters;
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
