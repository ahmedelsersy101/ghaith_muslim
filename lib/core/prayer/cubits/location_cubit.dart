import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart' hide LocationServiceDisabledException;
import 'package:ghaith/core/prayer/services/location_service.dart';

/// Cubit for managing location state
class LocationCubit extends Cubit<LocationState> {
  final LocationService _locationService;

  LocationCubit(this._locationService) : super(LocationInitial());

  /// Request and load location.
  /// Emits [LocationNeedsDisclosure] if the Prominent Disclosure has not been
  /// shown to the user yet.
  Future<void> loadLocation() async {
    try {
      emit(LocationLoading());

      // ── Google Play Prominent Disclosure compliance ──────────────────────
      // Do NOT request location before showing the custom disclosure dialog.
      if (!_locationService.hasSeenDisclosure()) {
        emit(LocationNeedsDisclosure());
        return;
      }
      // ────────────────────────────────────────────────────────────────────

      final locationInfo = await _locationService.getLocationInfo();
      emit(LocationLoaded(locationInfo: locationInfo));
    } on LocationServiceDisabledException catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.serviceDisabled));
    } on LocationPermissionDeniedException catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.permissionDenied));
    } on LocationPermissionDeniedForeverException catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.permissionDeniedForever));
    } catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.unknown));
    }
  }

  /// Called after the user taps "Agree" on the Prominent Disclosure sheet.
  /// Marks the disclosure as seen, then requests foreground location permission,
  /// and on success emits [LocationNeedsBackgroundPermission] so the UI can
  /// show the secondary background-location sheet.
  Future<void> requestPermissionAfterDisclosure() async {
    try {
      emit(LocationLoading());

      // Persist the "seen" flag so the disclosure never appears again
      await _locationService.markDisclosureSeen();

      // Request foreground permission (fine + coarse)
      final permission = await _locationService.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(LocationPermissionDenied());
        return;
      }

      // Foreground granted – check background permission
      final backgroundPermission = await Geolocator.checkPermission();
      if (backgroundPermission != LocationPermission.always &&
          !_locationService.hasSkippedBackgroundLocation()) {
        // Emit state so UI can show the background location sheet
        emit(LocationNeedsBackgroundPermission());
        return;
      }

      // All permissions granted – load location
      await loadLocationAfterPermission();
    } catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.unknown));
    }
  }

  /// Load location directly (called after all permissions are confirmed).
  Future<void> loadLocationAfterPermission() async {
    try {
      emit(LocationLoading());
      final locationInfo = await _locationService.getLocationInfo();
      emit(LocationLoaded(locationInfo: locationInfo));
    } on LocationServiceDisabledException catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.serviceDisabled));
    } on LocationPermissionDeniedException catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.permissionDenied));
    } on LocationPermissionDeniedForeverException catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.permissionDeniedForever));
    } catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.unknown));
    }
  }

  /// Set manual location
  Future<void> setManualLocation(double latitude, double longitude) async {
    try {
      emit(LocationLoading());

      final locationInfo = await _locationService.setManualLocation(
        latitude,
        longitude,
      );

      emit(LocationLoaded(locationInfo: locationInfo));
    } catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.unknown));
    }
  }

  /// Request location permission (legacy – kept for backward compatibility)
  Future<void> requestPermission() async {
    try {
      final permission = await _locationService.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(LocationPermissionDenied());
      } else {
        await loadLocationAfterPermission();
      }
    } catch (e) {
      emit(LocationError(e.toString(), LocationErrorType.unknown));
    }
  }

  /// Load cached location if available
  void loadCachedLocation() {
    final cachedLocation = _locationService.getCachedLocation();
    if (cachedLocation != null) {
      emit(LocationLoaded(locationInfo: cachedLocation));
    } else {
      emit(LocationInitial());
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// States
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Base state for location
abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LocationInitial extends LocationState {}

/// Loading state
class LocationLoading extends LocationState {}

/// The Prominent Disclosure has not been shown yet.
/// UI should show the custom disclosure sheet before requesting permission.
class LocationNeedsDisclosure extends LocationState {}

/// Foreground permission granted; background "Always" access is still needed.
/// UI should show the background location secondary sheet.
class LocationNeedsBackgroundPermission extends LocationState {}

/// Foreground permission denied
class LocationPermissionDenied extends LocationState {}

/// Loaded state
class LocationLoaded extends LocationState {
  final LocationInfo locationInfo;

  const LocationLoaded({required this.locationInfo});

  @override
  List<Object?> get props => [locationInfo];
}

/// Error state
class LocationError extends LocationState {
  final String message;
  final LocationErrorType errorType;

  const LocationError(this.message, this.errorType);

  @override
  List<Object?> get props => [message, errorType];
}

/// Types of location errors
enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}
