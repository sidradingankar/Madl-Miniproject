// ============================================================
// location_service.dart — GPS location + permission handling
//   Now includes a real-time position stream via Geolocator
// ============================================================

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;
  final bool permissionDenied;

  const LocationResult({
    this.latitude,
    this.longitude,
    this.error,
    this.permissionDenied = false,
  });

  bool get hasLocation => latitude != null && longitude != null;

  /// Google Maps URL for this position
  String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  /// Formatted coordinate string
  String get coordString =>
      '${latitude?.toStringAsFixed(6)}, ${longitude?.toStringAsFixed(6)}';
}

class LocationService {
  // ─── Permission Handling ────────────────────────────────────

  /// Check if location services are enabled and permission is granted.
  /// Returns a human-readable status string.
  Future<String> getPermissionStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return 'Location services disabled';

    final permission = await Geolocator.checkPermission();
    switch (permission) {
      case LocationPermission.denied:
        return 'Permission denied';
      case LocationPermission.deniedForever:
        return 'Permission permanently denied';
      case LocationPermission.whileInUse:
        return 'Granted (while in use)';
      case LocationPermission.always:
        return 'Granted (always)';
      default:
        return 'Unknown';
    }
  }

  /// Request location permission from the user.
  /// Returns true if permission is granted.
  Future<bool> requestPermission() async {
    // Check if location service is on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ─── Get Current Position ───────────────────────────────────

  /// Get the current GPS location.
  /// Returns a [LocationResult] — always safe (never throws).
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Make sure location services are available
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          error: 'Location services are disabled on your device.\n'
              'Please enable GPS in Settings.',
        );
      }

      // Check/request permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult(
            error: 'Location permission was denied.\n'
                'Please allow location access to use this feature.',
            permissionDenied: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          error: 'Location permission is permanently denied.\n'
              'Please enable it in your device Settings > App Permissions.',
          permissionDenied: true,
        );
      }

      // Get position with a reasonable timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationServiceDisabledException {
      return const LocationResult(
        error: 'Location services are disabled. Please turn on GPS.',
      );
    } catch (e) {
      return LocationResult(
        error: 'Unable to get location: ${e.toString()}\n'
            'Make sure GPS is enabled and try again.',
      );
    }
  }

  /// Open device location settings (mobile only)
  Future<void> openLocationSettings() async {
    if (!kIsWeb) await Geolocator.openLocationSettings();
  }

  /// Open app settings for permanently denied permission (mobile only)
  Future<void> openAppSettings() async {
    if (!kIsWeb) await Geolocator.openAppSettings();
  }

  // ─── Real-Time Location Stream ──────────────────────────────

  /// Returns a live stream of [Position] updates.
  /// [intervalMs] controls how often the GPS polls (default 5 000 ms).
  /// The stream never throws — errors are silently swallowed.
  ///
  /// Callers MUST cancel the [StreamSubscription] in their dispose().
  Stream<LocationResult> getLocationStream({int intervalMs = 5000}) async* {
    // Check permission first — yield an error result if not granted
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      yield const LocationResult(
          error: 'Location services are disabled. Please enable GPS.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      yield const LocationResult(
          error: 'Location permission denied.',
          permissionDenied: true);
      return;
    }

    final settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: Duration(milliseconds: intervalMs),
      forceLocationManager: false,
    );

    await for (final position in Geolocator.getPositionStream(
        locationSettings: settings)) {
      yield LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  }
}
