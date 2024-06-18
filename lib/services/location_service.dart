import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Checks location permission and requests if necessary.
  static Future<void> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied.';
      }
    } else if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied.';
    }
  }

  /// Checks if location services are enabled.
  static Future<void> checkLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }
  }

  /// Fetches the current location.
  static Future<Position> getCurrentLocation() async {
    try {
      await checkLocationPermission();
      await checkLocationService();
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      throw 'Error fetching location.';
    }
  }
}
