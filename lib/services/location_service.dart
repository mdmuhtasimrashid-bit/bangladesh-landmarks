// lib/services/location_service.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Bangladesh center coordinates (approx)
  static const double bangladeshLatitude = 23.6850;
  static const double bangladeshLongitude = 90.3563;

  // Request location permission (when in use)
  static Future<bool> requestLocationPermission() async {
    // On web, permission_handler doesn't work - browser handles it directly
    if (kIsWeb) {
      return true; // Geolocator will handle web permissions
    }

    PermissionStatus permission = await Permission.locationWhenInUse.status;

    if (permission.isDenied) {
      permission = await Permission.locationWhenInUse.request();
    }

    if (permission.isPermanentlyDenied) {
      // Open app settings so user can enable permission manually
      await openAppSettings();
      return false;
    }

    return permission.isGranted;
  }

  // Get current device location
  static Future<Position?> getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && !kIsWeb) {
        throw Exception('Location services are disabled.');
      }

      // On web, skip permission check - let Geolocator handle it
      if (!kIsWeb) {
        final bool hasPermission = await requestLocationPermission();
        if (!hasPermission) {
          throw Exception('Location permission denied.');
        }
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      return position;
    } catch (e) {
      // Log if needed and return null so caller can fallback
      return null;
    }
  }

  // Get location, with fallback to Bangladesh center when null
  static Future<Position> getCurrentLocationWithFallback() async {
    final Position? pos = await getCurrentLocation();
    if (pos != null) return pos;

    return Position(
      latitude: bangladeshLatitude,
      longitude: bangladeshLongitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  // Calculate distance between two coordinates (meters)
  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Check if coordinates are approximately inside Bangladesh bounds
  static bool isInBangladesh(double latitude, double longitude) {
    return latitude >= 20.0 &&
        latitude <= 27.0 &&
        longitude >= 88.0 &&
        longitude <= 93.0;
  }

  // Format coordinates to readable string
  static String formatCoordinates(double latitude, double longitude) {
    final String latDir = latitude >= 0 ? 'N' : 'S';
    final String lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}°$latDir, ${longitude.abs().toStringAsFixed(4)}°$lonDir';
  }
}
