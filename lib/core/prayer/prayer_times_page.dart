import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ghaith/core/prayer/cubits/prayer_times_cubit.dart';
import 'package:ghaith/core/prayer/cubits/prayer_settings_cubit.dart';
import 'package:ghaith/core/prayer/components/next_prayer_highlight.dart';
import 'package:ghaith/core/prayer/components/prayer_item.dart';
import 'package:ghaith/core/prayer/prayer_settings_page.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/main.dart';
import 'package:shimmer/shimmer.dart';

/// Full prayer times page showing all daily prayers
class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  @override
  void initState() {
    super.initState();
    // Refresh prayer times when page opens
    context.read<PrayerTimesCubit>().refreshPrayerTimes();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? deepNavyBlack : paperBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'prayerTimes'.tr(),
          style: TextStyle(
            fontFamily: 'cairo',
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IconButton(
              icon: Icon(
                Icons.settings_rounded,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () {
                // Navigate to settings page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrayerSettingsPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: BlocListener<PrayerSettingsCubit, PrayerSettingsState>(
        listener: (context, state) {
          // Reload prayer times when settings change
          context.read<PrayerTimesCubit>().loadPrayerTimes();
        },
        child: BlocBuilder<PrayerTimesCubit, PrayerTimesState>(
          builder: (context, state) {
            if (state is PrayerTimesLoading) {
              return _buildShimmerLoading(isDark);
            }

            if (state is PrayerTimesError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64.sp,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        isArabic ? 'حدث خطأ' : 'An error occurred',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'cairo',
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'cairo',
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.black.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<PrayerTimesCubit>().loadPrayerTimes();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? wineRed : deepBurgundyRed,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is! PrayerTimesLoaded) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<PrayerTimesCubit>().refreshPrayerTimes();
              },
              color: isDark ? wineRed : deepBurgundyRed,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),

                    // Location button
                    _buildLocationButton(context, state, isDark, isArabic),

                    SizedBox(height: 16.h),

                    // Next prayer highlight
                    NextPrayerHighlight(
                      prayerName: state.nextPrayer,
                      prayerNameArabic: state.nextPrayerArabic,
                      prayerTime: state.nextPrayerTime,
                      countdown: state.countdown,
                    ),

                    SizedBox(height: 24.h),

                    // Section title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        isArabic ? 'مواقيت الصلاة اليومية' : 'Daily Prayer Times',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'cairo',
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Prayer times list
                    PrayerItem(
                      prayerName: 'Fajr',
                      prayerNameArabic: 'fajr'.tr(),
                      prayerTime: state.fajr,
                      isNextPrayer: state.nextPrayer.toLowerCase() == 'fajr',
                    ),
                    PrayerItem(
                      prayerName: 'Sunrise',
                      prayerNameArabic: 'sunrise'.tr(),
                      prayerTime: state.sunrise,
                      isSunrise: true,
                    ),
                    PrayerItem(
                      prayerName: 'Dhuhr',
                      prayerNameArabic: 'dhuhr'.tr(),
                      prayerTime: state.dhuhr,
                      isNextPrayer: state.nextPrayer.toLowerCase() == 'dhuhr',
                    ),
                    PrayerItem(
                      prayerName: 'Asr',
                      prayerNameArabic: 'asr'.tr(),
                      prayerTime: state.asr,
                      isNextPrayer: state.nextPrayer.toLowerCase() == 'asr',
                    ),
                    PrayerItem(
                      prayerName: 'Maghrib',
                      prayerNameArabic: 'maghrib'.tr(),
                      prayerTime: state.maghrib,
                      isNextPrayer: state.nextPrayer.toLowerCase() == 'maghrib',
                    ),
                    PrayerItem(
                      prayerName: 'Isha',
                      prayerNameArabic: 'isha'.tr(),
                      prayerTime: state.isha,
                      isNextPrayer: state.nextPrayer.toLowerCase() == 'isha',
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationButton(
    BuildContext context,
    PrayerTimesLoaded state,
    bool isDark,
    bool isArabic,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Material(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () {
            // Show location options dialog
            _showLocationDialog(context, isArabic);
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: isDark ? wineRed : deepBurgundyRed,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'مواقيت الصلاة حسب موقعك'
                            : 'Prayer times based on your location',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontFamily: 'cairo',
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        state.location,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'cairo',
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkModeNotifier.value ? Colors.black : paperBeige,
        title: Text(
          isArabic ? 'تحديد الموقع' : 'Set Location',
          style: const TextStyle(fontFamily: 'cairo'),
        ),
        content: Text(
          isArabic
              ? 'يمكنك استخدام موقعك الحالي أو إدخال موقع يدوياً'
              : 'You can use your current location or enter a location manually',
          style: const TextStyle(fontFamily: 'cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PrayerTimesCubit>().loadPrayerTimes();
            },
            child: Text(
              isArabic ? 'استخدام الموقع الحالي' : 'Use Current Location',
              style: const TextStyle(fontFamily: 'cairo'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isArabic ? 'إلغاء' : 'Cancel',
              style: const TextStyle(fontFamily: 'cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),
            // Location button shimmer
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.sp,
                    height: 24.sp,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 200.w,
                          height: 12.h,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 150.w,
                          height: 16.h,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Next prayer highlight shimmer (matching NextPrayerHighlight widget)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              height: 380.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32.r),
              ),
            ),

            SizedBox(height: 24.h),

            // Title shimmer
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                width: 180.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Prayer items shimmer
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32.sp,
                            height: 32.sp,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Container(
                            width: 80.w,
                            height: 20.h,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        width: 80.w,
                        height: 30.h,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
