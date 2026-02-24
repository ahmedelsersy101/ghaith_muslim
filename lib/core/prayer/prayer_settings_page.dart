import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ghaith/core/prayer/cubits/prayer_settings_cubit.dart';
import 'package:ghaith/core/prayer/services/adhan_preview_service.dart';
import 'package:ghaith/helpers/constants.dart';

/// Prayer Settings Page
/// Allows users to configure prayer-related settings including:
/// - Adhan sound selection with preview
/// - 5-minute prayer reminders
/// - Location mode (automatic/manual)
class PrayerSettingsPage extends StatefulWidget {
  const PrayerSettingsPage({super.key});

  @override
  State<PrayerSettingsPage> createState() => _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends State<PrayerSettingsPage> {
  final AdhanPreviewService _previewService = AdhanPreviewService();

  @override
  void initState() {
    super.initState();
    // Load settings when page opens
    context.read<PrayerSettingsCubit>().loadSettings();
  }

  @override
  void dispose() {
    _previewService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? deepNavyBlack : paperBeige,
      appBar: AppBar(
        backgroundColor: isDark ? darkSlateGray : wineRed,
        elevation: 0,
        title: Text(
          'prayerSettings'.tr(),
          style: TextStyle(
            fontFamily: 'cairo',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: BlocBuilder<PrayerSettingsCubit, PrayerSettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Adhan Sound Selection Section
                  _buildSectionTitle(
                    'adhanSoundSelection'.tr(),
                    isDark,
                  ),
                  SizedBox(height: 12.h),
                  _buildAdhanSoundList(context, state, isDark, isArabic),

                  SizedBox(height: 32.h),

                  // 5-Minute Reminder Section
                  _buildSectionTitle(
                    'fiveMinuteReminder'.tr(),
                    isDark,
                  ),
                  SizedBox(height: 12.h),
                  _buildReminderToggle(context, state, isDark, isArabic),

                  SizedBox(height: 32.h),

                  // Location Mode Section
                  _buildSectionTitle(
                    'locationMode'.tr(),
                    isDark,
                  ),
                  SizedBox(height: 12.h),
                  _buildLocationModeSelector(context, state, isDark, isArabic),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        fontFamily: 'cairo',
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildAdhanSoundList(
    BuildContext context,
    PrayerSettingsState state,
    bool isDark,
    bool isArabic,
  ) {
    final cubit = context.read<PrayerSettingsCubit>();
    final adhanSounds = cubit.getAdhanSounds();

    return StreamBuilder<String?>(
      stream: _previewService.currentlyPlayingStream,
      builder: (context, snapshot) {
        final currentlyPlaying = snapshot.data;

        return Column(
          children: adhanSounds.map((sound) {
            final isSelected = state.selectedAdhanSound == sound.path;
            final isPlaying = currentlyPlaying == sound.path;

            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected ? (isDark ? wineRed : deepBurgundyRed) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    cubit.setAdhanSound(sound.path);
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        // Selection indicator
                        Container(
                          width: 24.sp,
                          height: 24.sp,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? (isDark ? wineRed : deepBurgundyRed)
                                  : (isDark
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.3)),
                              width: 2,
                            ),
                            color: isSelected
                                ? (isDark ? wineRed : deepBurgundyRed)
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16.sp,
                                  color: Colors.white,
                                )
                              : null,
                        ),

                        SizedBox(width: 16.w),

                        // Sound name
                        Expanded(
                          child: Text(
                            isArabic ? sound.displayNameArabic : sound.displayName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'cairo',
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),

                        // Play/Stop button
                        IconButton(
                          onPressed: () async {
                            if (isPlaying) {
                              await _previewService.stopPreview();
                            } else {
                              await _previewService.playAdhanPreview(sound.path);
                            }
                          },
                          icon: Icon(
                            isPlaying ? Icons.stop_circle : Icons.play_circle,
                            color: isDark ? wineRed : deepBurgundyRed,
                            size: 32.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildReminderToggle(
    BuildContext context,
    PrayerSettingsState state,
    bool isDark,
    bool isArabic,
  ) {
    final cubit = context.read<PrayerSettingsCubit>();
    final isEnabled = state.reminderMinutes == 10;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'fiveMinuteReminder'.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'cairo',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'reminderDescription'.tr(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: 'cairo',
                      color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: (value) {
                cubit.setReminderMinutes(value ? 10 : 0);
              },
              activeColor: isDark ? wineRed : deepBurgundyRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationModeSelector(
    BuildContext context,
    PrayerSettingsState state,
    bool isDark,
    bool isArabic,
  ) {
    final cubit = context.read<PrayerSettingsCubit>();

    return Column(
      children: [
        // Automatic option
        _buildLocationModeOption(
          context: context,
          mode: 'automatic',
          title: 'automaticLocation'.tr(),
          description: 'automaticLocationDesc'.tr(),
          isSelected: state.locationMode == 'automatic',
          isDark: isDark,
          onTap: () => cubit.setLocationMode('automatic'),
        ),

        SizedBox(height: 12.h),

        // Manual option
        // _buildLocationModeOption(
        //   context: context,
        //   mode: 'manual',
        //   title: 'manualLocation'.tr(),
        //   description: 'manualLocationDesc'.tr(),
        //   isSelected: state.locationMode == 'manual',
        //   isDark: isDark,
        //   onTap: () => cubit.setLocationMode('manual'),
        // ),
      ],
    );
  }

  Widget _buildLocationModeOption({
    required BuildContext context,
    required String mode,
    required String title,
    required String description,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? (isDark ? wineRed : deepBurgundyRed) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Selection indicator
                Container(
                  width: 24.sp,
                  height: 24.sp,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? wineRed : deepBurgundyRed)
                          : (isDark
                              ? Colors.white.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3)),
                      width: 2,
                    ),
                    color: isSelected ? (isDark ? wineRed : deepBurgundyRed) : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16.sp,
                          color: Colors.white,
                        )
                      : null,
                ),

                SizedBox(width: 16.w),

                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontFamily: 'cairo',
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'cairo',
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
