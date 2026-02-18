import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';
import 'package:ghaith/core/prayer/services/location_service.dart';
import 'package:geolocator/geolocator.dart' hide LocationServiceDisabledException;

/// Cubit for managing location state
class LocationCubit extends Cubit<LocationState> {
  final LocationService _locationService;

  LocationCubit(this._locationService) : super(LocationInitial());

  /// Request and load location
  Future<void> loadLocation() async {
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

  /// Request location permission
  Future<void> requestPermission() async {
    try {
      final permission = await _locationService.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(LocationPermissionDenied());
      } else {
        // Permission granted, load location
        await loadLocation();
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

/// Permission denied state
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
