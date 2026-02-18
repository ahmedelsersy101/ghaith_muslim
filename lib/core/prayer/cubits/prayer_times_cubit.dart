import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';
import 'package:ghaith/core/prayer/services/prayer_times_service.dart';
import 'package:ghaith/core/prayer/services/location_service.dart';
import 'package:ghaith/core/prayer/services/notification_service_prayer.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:adhan/adhan.dart';

/// Cubit for managing prayer times state
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  final PrayerTimesService _prayerTimesService;
  final LocationService _locationService;
  final PrayerNotificationService _notificationService;

  Timer? _countdownTimer;
  PrayerTimes? _currentPrayerTimes;

  PrayerTimesCubit({
    required PrayerTimesService prayerTimesService,
    required LocationService locationService,
    required PrayerNotificationService notificationService,
  })  : _prayerTimesService = prayerTimesService,
        _locationService = locationService,
        _notificationService = notificationService,
        super(PrayerTimesInitial());

  /// Load prayer times for current location
  Future<void> loadPrayerTimes() async {
    try {
      emit(PrayerTimesLoading());

      // Get location
      final locationInfo = await _locationService.getLocationInfo();

      // Get calculation method from settings
      final methodName = getValue('prayerCalculationMethod') ?? 'muslim_world_league';
      final method = _prayerTimesService.getCalculationMethodByName(methodName);

      // Calculate prayer times
      final coordinates = locationInfo.coordinates;
      final now = DateTime.now();
      _currentPrayerTimes = _prayerTimesService.calculatePrayerTimes(
        coordinates,
        now,
        method: method,
      );

      // Get all prayer times
      final allPrayers = _prayerTimesService.getAllPrayerTimes(_currentPrayerTimes!);

      // Get next prayer
      final nextPrayer = _prayerTimesService.getNextPrayer(_currentPrayerTimes!);

      // Cache prayer times for the month
      await _prayerTimesService.cachePrayerTimesForMonth(
        coordinates,
        now,
        method: method,
      );

      // Schedule notifications
      await _scheduleNotifications(allPrayers);

      // Start countdown timer
      _startCountdownTimer();

      emit(PrayerTimesLoaded(
        fajr: allPrayers.fajr,
        sunrise: allPrayers.sunrise,
        dhuhr: allPrayers.dhuhr,
        asr: allPrayers.asr,
        maghrib: allPrayers.maghrib,
        isha: allPrayers.isha,
        nextPrayer: nextPrayer.name,
        nextPrayerArabic: nextPrayer.nameArabic,
        nextPrayerTime: nextPrayer.time,
        countdown: nextPrayer.countdown,
        location: locationInfo.formattedLocation,
        locationInfo: locationInfo,
      ));
    } on LocationPermissionDeniedForeverException catch (e) {
      emit(PrayerTimesPermissionDeniedForever(e.toString()));
    } on LocationPermissionDeniedException catch (e) {
      emit(PrayerTimesPermissionDenied(e.toString()));
    } on LocationServiceDisabledException catch (e) {
      emit(PrayerTimesLocationServiceDisabled(e.toString()));
    } catch (e) {
      emit(PrayerTimesError(e.toString()));
    }
  }

  /// Refresh prayer times (force reload)
  Future<void> refreshPrayerTimes() async {
    await loadPrayerTimes();
  }

  /// Update countdown every second
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is PrayerTimesLoaded) {
        final currentState = state as PrayerTimesLoaded;
        final now = DateTime.now();

        // Check if we've passed the next prayer time
        if (now.isAfter(currentState.nextPrayerTime)) {
          // Reload prayer times to get new next prayer
          loadPrayerTimes();
          return;
        }

        // Update countdown
        final newCountdown = currentState.nextPrayerTime.difference(now);

        emit(currentState.copyWith(countdown: newCountdown));
      }
    });
  }

  /// Schedule notifications for all prayers
  Future<void> _scheduleNotifications(AllPrayerTimes prayers) async {
    final prayerTimes = {
      'fajr': prayers.fajr,
      'dhuhr': prayers.dhuhr,
      'asr': prayers.asr,
      'maghrib': prayers.maghrib,
      'isha': prayers.isha,
    };

    await _notificationService.scheduleAllPrayersForDay(prayerTimes);
  }

  /// Get time format preference
  bool _use24HourFormat() {
    return getValue('use24HourFormat') ?? false;
  }

  /// Format prayer time based on user preference
  String formatTime(DateTime time) {
    return _prayerTimesService.formatPrayerTime(
      time,
      use24Hour: _use24HourFormat(),
    );
  }

  /// Get countdown string (e.g., "2h 15m")
  String getCountdownString(Duration countdown) {
    final hours = countdown.inHours;
    final minutes = countdown.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}

/// Base state for prayer times
abstract class PrayerTimesState extends Equatable {
  const PrayerTimesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PrayerTimesInitial extends PrayerTimesState {}

/// Loading state
class PrayerTimesLoading extends PrayerTimesState {}

/// Loaded state with all prayer data
class PrayerTimesLoaded extends PrayerTimesState {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String nextPrayer;
  final String nextPrayerArabic;
  final DateTime nextPrayerTime;
  final Duration countdown;
  final String location;
  final LocationInfo locationInfo;

  const PrayerTimesLoaded({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.nextPrayer,
    required this.nextPrayerArabic,
    required this.nextPrayerTime,
    required this.countdown,
    required this.location,
    required this.locationInfo,
  });

  PrayerTimesLoaded copyWith({
    DateTime? fajr,
    DateTime? sunrise,
    DateTime? dhuhr,
    DateTime? asr,
    DateTime? maghrib,
    DateTime? isha,
    String? nextPrayer,
    String? nextPrayerArabic,
    DateTime? nextPrayerTime,
    Duration? countdown,
    String? location,
    LocationInfo? locationInfo,
  }) {
    return PrayerTimesLoaded(
      fajr: fajr ?? this.fajr,
      sunrise: sunrise ?? this.sunrise,
      dhuhr: dhuhr ?? this.dhuhr,
      asr: asr ?? this.asr,
      maghrib: maghrib ?? this.maghrib,
      isha: isha ?? this.isha,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      nextPrayerArabic: nextPrayerArabic ?? this.nextPrayerArabic,
      nextPrayerTime: nextPrayerTime ?? this.nextPrayerTime,
      countdown: countdown ?? this.countdown,
      location: location ?? this.location,
      locationInfo: locationInfo ?? this.locationInfo,
    );
  }

  @override
  List<Object?> get props => [
        fajr,
        sunrise,
        dhuhr,
        asr,
        maghrib,
        isha,
        nextPrayer,
        nextPrayerArabic,
        nextPrayerTime,
        countdown,
        location,
        locationInfo,
      ];
}

/// Error state
class PrayerTimesError extends PrayerTimesState {
  final String message;

  const PrayerTimesError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Permission denied state (can request again)
class PrayerTimesPermissionDenied extends PrayerTimesState {
  final String message;

  const PrayerTimesPermissionDenied(this.message);

  @override
  List<Object?> get props => [message];
}

/// Permission denied forever state (need to open settings)
class PrayerTimesPermissionDeniedForever extends PrayerTimesState {
  final String message;

  const PrayerTimesPermissionDeniedForever(this.message);

  @override
  List<Object?> get props => [message];
}

/// Location service disabled state
class PrayerTimesLocationServiceDisabled extends PrayerTimesState {
  final String message;

  const PrayerTimesLocationServiceDisabled(this.message);

  @override
  List<Object?> get props => [message];
}
