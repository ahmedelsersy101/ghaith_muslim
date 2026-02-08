import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart' as j;
import 'package:ghaith/helpers/constants.dart';
import 'package:flutter/material.dart' as m;
import 'package:jhijri_picker/jhijri_picker.dart';
import 'package:ghaith/main.dart';

class CalenderPage extends StatefulWidget {
  const CalenderPage({super.key});

  @override
  State<CalenderPage> createState() => _CalenderPageState();
}

class _CalenderPageState extends State<CalenderPage> with TickerProviderStateMixin {
  int index = 1;
  var _today = j.HijriCalendar.now().toFormat(
    "dd - MMMM - yyyy",
  );
  var date = DateTime.now();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkModeNotifier.value;
    final darkWarmBrown = isDark ? wineRed : wineRed;
    final deepBurgundyRedApp = isDark ? wineRed : wineRed;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [deepNavyBlack, deepNavyBlack]
              : [
                  paperBeige.withOpacity(0.99),
                  paperBeige.withOpacity(0.99),
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.h),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [darkWarmBrown, deepBurgundyRedApp],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppBar(
              elevation: 0,
              backgroundColor: isDarkModeNotifier.value ? darkSlateGray : wineRed,
              toolbarHeight: 70.h,
              title: Text(
                "calender".tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'cairo',
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white, size: 28),
            ),
          ),
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              children: [
                // Date Display Card
                Container(
                  decoration: BoxDecoration(
                    color: isDarkModeNotifier.value ? darkSlateGray : wineRed,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: darkWarmBrown.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative pattern overlay
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: CustomPaint(
                            painter: CalendarPatternPainter(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          children: [
                            // Hijri Date
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Flexible(
                                    child: Text(
                                      _today,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'cairo',
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // Gregorian Date
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_rounded,
                                    color: Colors.white,
                                    size: 24.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Flexible(
                                    child: Text(
                                      DateFormat.yMMMEd(context.locale.languageCode).format(date),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'roboto',
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Calendar Type Selector
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? darkSlateGray : paperBeige,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCalendarTypeButton(
                            label: "calender".tr(),
                            isSelected: index == 1,
                            onTap: () {
                              setState(() {
                                index = 1;
                              });
                            },
                            darkWarmBrown: darkWarmBrown,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildCalendarTypeButton(
                            label: "normalCalender".tr(),
                            isSelected: index == 0,
                            onTap: () {
                              setState(() {
                                index = 0;
                              });
                            },
                            darkWarmBrown: darkWarmBrown,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // Calendar Widget
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? darkSlateGray : paperBeige,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: darkWarmBrown.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24.r),
                    child: JGlobalDatePicker(
                      widgetType: WidgetType.JContainer,
                      pickerType: index == 1 ? PickerType.JHijri : PickerType.JNormal,
                      buttons: const SizedBox(),
                      primaryColor: wineRed,
                      calendarTextColor: isDark ? Colors.white.withOpacity(0.9) : charcoalDarkGray,
                      backgroundColor: isDark ? darkSlateGray : paperBeige,
                      borderRadius: const Radius.circular(0),
                      headerTitle: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [wineRed, paperBeige],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: const SizedBox(),
                      ),
                      startDate: JDateModel(dateTime: DateTime.parse("1984-12-24")),
                      selectedDate: JDateModel(dateTime: DateTime.now()),
                      endDate: JDateModel(dateTime: DateTime.parse("2030-09-20")),
                      pickerMode: DatePickerMode.day,
                      pickerTheme: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: darkWarmBrown,
                              onPrimary: Colors.white,
                            ),
                      ),
                      locale: context.locale,
                      textDirection: m.TextDirection.rtl,
                      onChange: (val) {
                        date = val.date;
                        _today = j.HijriCalendar.fromDate(val.date).toFormat(
                          "dd - MMMM - yyyy",
                        );
                        setState(() {});
                      },
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarTypeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color darkWarmBrown,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [wineRed, wineRed.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white.withOpacity(0.6) : charcoalDarkGray.withOpacity(0.6)),
                fontSize: 16.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontFamily: 'cairo',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Calendar Pattern
class CalendarPatternPainter extends CustomPainter {
  final Color color;

  CalendarPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 50.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw small squares
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 12, 12),
            const Radius.circular(2),
          ),
          paint,
        );

        // Draw circles
        if ((x + spacing / 2) < size.width && (y + spacing / 2) < size.height) {
          canvas.drawCircle(
            Offset(x + spacing / 2, y + spacing / 2),
            5,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
