import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';
import 'package:ghaith/helpers/hive_helper.dart';

/// Cubit for managing prayer settings and preferences
class PrayerSettingsCubit extends Cubit<PrayerSettingsState> {
  PrayerSettingsCubit() : super(PrayerSettingsState.initial());

  /// Load settings from storage
  Future<void> loadSettings() async {
    final calculationMethod = getValue('prayerCalculationMethod') ?? 'muslim_world_league';
    final use24HourFormat = getValue('use24HourFormat') ?? false;
    final reminderMinutes = getValue('prayerReminderMinutes') ?? 0;
    final selectedAdhanSound = getValue('selectedAdhanSound') ?? 'silence.ogg';
    final locationMode = getValue('locationMode') ?? 'automatic';
    final persistentNotification = getValue('persistentPrayerNotification') ?? false;

    // Load individual prayer notification settings
    final fajrEnabled = getValue('prayerNotificationEnabled_fajr') ?? true;
    final dhuhrEnabled = getValue('prayerNotificationEnabled_dhuhr') ?? true;
    final asrEnabled = getValue('prayerNotificationEnabled_asr') ?? true;
    final maghribEnabled = getValue('prayerNotificationEnabled_maghrib') ?? true;
    final ishaEnabled = getValue('prayerNotificationEnabled_isha') ?? true;

    emit(PrayerSettingsState(
      calculationMethod: calculationMethod,
      use24HourFormat: use24HourFormat,
      reminderMinutes: reminderMinutes,
      selectedAdhanSound: selectedAdhanSound,
      persistentNotification: persistentNotification,
      fajrNotificationEnabled: fajrEnabled,
      dhuhrNotificationEnabled: dhuhrEnabled,
      asrNotificationEnabled: asrEnabled,
      maghribNotificationEnabled: maghribEnabled,
      ishaNotificationEnabled: ishaEnabled,
      locationMode: locationMode,
    ));
  }

  /// Update calculation method
  Future<void> setCalculationMethod(String method) async {
    await updateValue('prayerCalculationMethod', method);
    emit(state.copyWith(calculationMethod: method));
  }

  /// Toggle 24-hour format
  Future<void> setUse24HourFormat(bool use24Hour) async {
    await updateValue('use24HourFormat', use24Hour);
    emit(state.copyWith(use24HourFormat: use24Hour));
  }

  /// Set reminder minutes before prayer
  Future<void> setReminderMinutes(int minutes) async {
    await updateValue('prayerReminderMinutes', minutes);
    emit(state.copyWith(reminderMinutes: minutes));
  }

  /// Set Adhan sound
  Future<void> setAdhanSound(String soundPath) async {
    await updateValue('selectedAdhanSound', soundPath);
    emit(state.copyWith(selectedAdhanSound: soundPath));
  }

  /// Toggle persistent notification
  Future<void> setPersistentNotification(bool enabled) async {
    await updateValue('persistentPrayerNotification', enabled);
    emit(state.copyWith(persistentNotification: enabled));
  }

  /// Toggle notification for specific prayer
  Future<void> setPrayerNotificationEnabled(String prayer, bool enabled) async {
    final key = 'prayerNotificationEnabled_${prayer.toLowerCase()}';
    await updateValue(key, enabled);

    switch (prayer.toLowerCase()) {
      case 'fajr':
        emit(state.copyWith(fajrNotificationEnabled: enabled));
        break;
      case 'dhuhr':
        emit(state.copyWith(dhuhrNotificationEnabled: enabled));
        break;
      case 'asr':
        emit(state.copyWith(asrNotificationEnabled: enabled));
        break;
      case 'maghrib':
        emit(state.copyWith(maghribNotificationEnabled: enabled));
        break;
      case 'isha':
        emit(state.copyWith(ishaNotificationEnabled: enabled));
        break;
    }
  }

  /// Set location mode (automatic or manual)
  Future<void> setLocationMode(String mode) async {
    await updateValue('locationMode', mode);
    emit(state.copyWith(locationMode: mode));
  }

  /// Get available calculation methods
  List<CalculationMethodOption> getCalculationMethods() {
    return [
      CalculationMethodOption(
        value: 'muslim_world_league',
        displayName: 'Muslim World League',
        displayNameArabic: 'رابطة العالم الإسلامي',
      ),
      CalculationMethodOption(
        value: 'egyptian',
        displayName: 'Egyptian General Authority',
        displayNameArabic: 'الهيئة المصرية العامة',
      ),
      CalculationMethodOption(
        value: 'karachi',
        displayName: 'University of Islamic Sciences, Karachi',
        displayNameArabic: 'جامعة العلوم الإسلامية، كراتشي',
      ),
      CalculationMethodOption(
        value: 'umm_al_qura',
        displayName: 'Umm Al-Qura University, Makkah',
        displayNameArabic: 'جامعة أم القرى، مكة',
      ),
      CalculationMethodOption(
        value: 'dubai',
        displayName: 'Dubai',
        displayNameArabic: 'دبي',
      ),
      CalculationMethodOption(
        value: 'moon_sighting_committee',
        displayName: 'Moonsighting Committee Worldwide',
        displayNameArabic: 'لجنة رؤية الهلال',
      ),
      CalculationMethodOption(
        value: 'north_america',
        displayName: 'Islamic Society of North America (ISNA)',
        displayNameArabic: 'الجمعية الإسلامية لأمريكا الشمالية',
      ),
      CalculationMethodOption(
        value: 'kuwait',
        displayName: 'Kuwait',
        displayNameArabic: 'الكويت',
      ),
      CalculationMethodOption(
        value: 'qatar',
        displayName: 'Qatar',
        displayNameArabic: 'قطر',
      ),
      CalculationMethodOption(
        value: 'singapore',
        displayName: 'Singapore',
        displayNameArabic: 'سنغافورة',
      ),
    ];
  }

  /// Get available Adhan sounds
  List<AdhanSoundOption> getAdhanSounds() {
    return [
      AdhanSoundOption(
        path: 'silence.ogg',
        displayName: 'Silent',
        displayNameArabic: 'صامت',
      ),
      AdhanSoundOption(
        path: 'aqsa_athan.ogg',
        displayName: 'Al-Aqsa',
        displayNameArabic: 'الأقصى',
      ),
      AdhanSoundOption(
        path: 'baset_athan.ogg',
        displayName: 'Abdul Basit',
        displayNameArabic: 'عبد الباسط',
      ),
      AdhanSoundOption(
        path: 'qatami_athan.ogg',
        displayName: 'Al-Qatami',
        displayNameArabic: 'القطامي',
      ),
      AdhanSoundOption(
        path: 'salah_athan.ogg',
        displayName: 'Salah',
        displayNameArabic: 'صلاح الذيب',
      ),
      AdhanSoundOption(
        path: 'saqqaf_athan.ogg',
        displayName: 'Al-Saqqaf',
        displayNameArabic: 'السقاف',
      ),
      AdhanSoundOption(
        path: 'sarihi_athan.ogg',
        displayName: 'Al-Sarihi',
        displayNameArabic: 'الصريحي',
      ),
    ];
  }

  /// Get available reminder options (in minutes)
  List<int> getReminderOptions() {
    return [0, 5, 10, 15, 30]; // 0 means disabled
  }
}

/// State for prayer settings
class PrayerSettingsState extends Equatable {
  final String calculationMethod;
  final bool use24HourFormat;
  final int reminderMinutes;
  final String selectedAdhanSound;
  final bool persistentNotification;
  final bool fajrNotificationEnabled;
  final bool dhuhrNotificationEnabled;
  final bool asrNotificationEnabled;
  final bool maghribNotificationEnabled;
  final bool ishaNotificationEnabled;
  final String locationMode;

  const PrayerSettingsState({
    required this.calculationMethod,
    required this.use24HourFormat,
    required this.reminderMinutes,
    required this.selectedAdhanSound,
    required this.persistentNotification,
    required this.fajrNotificationEnabled,
    required this.dhuhrNotificationEnabled,
    required this.asrNotificationEnabled,
    required this.maghribNotificationEnabled,
    required this.ishaNotificationEnabled,
    required this.locationMode,
  });

  factory PrayerSettingsState.initial() {
    return const PrayerSettingsState(
      calculationMethod: 'muslim_world_league',
      use24HourFormat: false,
      reminderMinutes: 0,
      selectedAdhanSound: 'aqsa_athan.ogg',
      persistentNotification: false,
      fajrNotificationEnabled: true,
      dhuhrNotificationEnabled: true,
      asrNotificationEnabled: true,
      maghribNotificationEnabled: true,
      ishaNotificationEnabled: true,
      locationMode: 'automatic',
    );
  }

  PrayerSettingsState copyWith({
    String? calculationMethod,
    bool? use24HourFormat,
    int? reminderMinutes,
    String? selectedAdhanSound,
    bool? persistentNotification,
    bool? fajrNotificationEnabled,
    bool? dhuhrNotificationEnabled,
    bool? asrNotificationEnabled,
    bool? maghribNotificationEnabled,
    bool? ishaNotificationEnabled,
    String? locationMode,
  }) {
    return PrayerSettingsState(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      selectedAdhanSound: selectedAdhanSound ?? this.selectedAdhanSound,
      persistentNotification: persistentNotification ?? this.persistentNotification,
      fajrNotificationEnabled: fajrNotificationEnabled ?? this.fajrNotificationEnabled,
      dhuhrNotificationEnabled: dhuhrNotificationEnabled ?? this.dhuhrNotificationEnabled,
      asrNotificationEnabled: asrNotificationEnabled ?? this.asrNotificationEnabled,
      maghribNotificationEnabled: maghribNotificationEnabled ?? this.maghribNotificationEnabled,
      ishaNotificationEnabled: ishaNotificationEnabled ?? this.ishaNotificationEnabled,
      locationMode: locationMode ?? this.locationMode,
    );
  }

  @override
  List<Object?> get props => [
        calculationMethod,
        use24HourFormat,
        reminderMinutes,
        selectedAdhanSound,
        persistentNotification,
        fajrNotificationEnabled,
        dhuhrNotificationEnabled,
        asrNotificationEnabled,
        maghribNotificationEnabled,
        ishaNotificationEnabled,
        locationMode,
      ];
}

/// Model for calculation method options
class CalculationMethodOption {
  final String value;
  final String displayName;
  final String displayNameArabic;

  CalculationMethodOption({
    required this.value,
    required this.displayName,
    required this.displayNameArabic,
  });
}

/// Model for Adhan sound options
class AdhanSoundOption {
  final String path;
  final String displayName;
  final String displayNameArabic;

  AdhanSoundOption({
    required this.path,
    required this.displayName,
    required this.displayNameArabic,
  });
}
