import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:adhan/adhan.dart';

/// Service for managing location-related functionality for prayer times
/// Handles GPS coordinates, permissions, and geocoding
class LocationService {
  /// Check if location services are enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission from user
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current GPS position
  /// Throws exception if permission denied or service disabled.
  /// NOTE: This method no longer requests permission inline.
  /// Permission must be requested via [requestPermission()] from the UI layer
  /// after showing the Prominent Disclosure dialog.
  Future<Position> getCurrentPosition() async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    // Check permission – do NOT request automatically here
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      throw LocationPermissionDeniedException();
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedForeverException();
    }

    // Get position with high accuracy
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Prominent Disclosure tracking (Google Play policy compliance)
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true if the user has already seen the Prominent Disclosure dialog.
  bool hasSeenDisclosure() => getValue('locationDisclosureSeen') == true;

  /// Persists that the disclosure has been shown so it is never shown again.
  Future<void> markDisclosureSeen() async {
    await updateValue('locationDisclosureSeen', true);
  }

  /// Returns true if the user has chosen to skip the background location prompt
  bool hasSkippedBackgroundLocation() => getValue('backgroundLocationSkipped') == true;

  /// Persists that the background location prompt was skipped
  Future<void> markBackgroundLocationSkipped() async {
    await updateValue('backgroundLocationSkipped', true);
  }

  /// Get location information including city and country names
  Future<LocationInfo> getLocationInfo() async {
    try {
      // Try to get current position
      final position = await getCurrentPosition();

      // Get city and country from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String city = 'Unknown';
      String country = 'Unknown';

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        city = place.locality ?? place.subAdministrativeArea ?? 'Unknown';
        country = place.country ?? 'Unknown';
      }

      final locationInfo = LocationInfo(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
        isManual: false,
      );

      // Cache location for offline use
      await _cacheLocation(locationInfo);

      return locationInfo;
    } catch (e) {
      // Try to get cached location
      final cachedLocation = getCachedLocation();
      if (cachedLocation != null) {
        return cachedLocation;
      }
      rethrow;
    }
  }

  /// Get coordinates as Adhan library Coordinates object
  Future<Coordinates> getCoordinates() async {
    final locationInfo = await getLocationInfo();
    return Coordinates(locationInfo.latitude, locationInfo.longitude);
  }

  /// Cache location information for offline access
  Future<void> _cacheLocation(LocationInfo locationInfo) async {
    await updateValue('cachedLocation', {
      'latitude': locationInfo.latitude,
      'longitude': locationInfo.longitude,
      'city': locationInfo.city,
      'country': locationInfo.country,
      'isManual': locationInfo.isManual,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get cached location from storage
  LocationInfo? getCachedLocation() {
    final cached = getValue('cachedLocation');
    if (cached == null) return null;

    return LocationInfo(
      latitude: cached['latitude'] as double,
      longitude: cached['longitude'] as double,
      city: cached['city'] as String,
      country: cached['country'] as String,
      isManual: cached['isManual'] as bool? ?? false,
    );
  }

  /// Set manual location (for when GPS is not available)
  Future<LocationInfo> setManualLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      // Try to get city/country from coordinates
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      String city = 'Manual Location';
      String country = '';

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        city = place.locality ?? place.subAdministrativeArea ?? 'Manual Location';
        country = place.country ?? '';
      }

      final locationInfo = LocationInfo(
        latitude: latitude,
        longitude: longitude,
        city: city,
        country: country,
        isManual: true,
      );

      await _cacheLocation(locationInfo);
      return locationInfo;
    } catch (e) {
      // If geocoding fails, still save the coordinates
      final locationInfo = LocationInfo(
        latitude: latitude,
        longitude: longitude,
        city: 'Manual Location',
        country: '',
        isManual: true,
      );

      await _cacheLocation(locationInfo);
      return locationInfo;
    }
  }

  /// Clear cached location
  Future<void> clearCachedLocation() async {
    await updateValue('cachedLocation', null);
  }

  /// Check if we have a valid cached location
  bool hasCachedLocation() {
    return getCachedLocation() != null;
  }
}

/// Model for location information
class LocationInfo {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final bool isManual;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    this.isManual = false,
  });

  /// Get formatted location string
  String get formattedLocation {
    if (country.isEmpty) {
      return city;
    }
    return '$city, $country';
  }

  /// Get Adhan library Coordinates object
  Coordinates get coordinates {
    return Coordinates(latitude, longitude);
  }

  @override
  String toString() {
    return 'LocationInfo(lat: $latitude, lon: $longitude, city: $city, country: $country, manual: $isManual)';
  }
}

/// Exception thrown when location services are disabled
class LocationServiceDisabledException implements Exception {
  @override
  String toString() => 'Location services are disabled. Please enable them in settings.';
}

/// Exception thrown when location permission is denied
class LocationPermissionDeniedException implements Exception {
  @override
  String toString() => 'Location permission denied. Please grant permission to use this feature.';
}

/// Exception thrown when location permission is permanently denied
class LocationPermissionDeniedForeverException implements Exception {
  @override
  String toString() => 'Location permission permanently denied. Please enable it in app settings.';
}
