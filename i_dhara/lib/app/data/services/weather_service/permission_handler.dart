import 'package:geolocator/geolocator.dart';

class PermissionService {
  static Future<bool> requestLocationPermission() async {
    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // If permission is denied, request it (this will show native Android/iOS dialog)
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Return true if permission is granted (either whileInUse or always)
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
