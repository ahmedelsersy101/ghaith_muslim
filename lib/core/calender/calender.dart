import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart' as j;
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:flutter/material.dart' as m;
import 'package:jhijri_picker/jhijri_picker.dart';
// import 'package:jhijri_picker/jhijri_picker.dart';
import 'package:ghaith/main.dart';

class CalenderPage extends StatefulWidget {
  const CalenderPage({super.key});

  @override
  State<CalenderPage> createState() => _CalenderPageState();
}

class _CalenderPageState extends State<CalenderPage> {
  int index = 1;
  var _today = j.HijriCalendar.now().toFormat(
    "dd - MMMM - yyyy",
  );
  var date = DateTime.now();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight,
      appBar: AppBar(
        title: Text(
          "calender".tr(),
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: isDarkModeNotifier.value ? darkModeSecondaryColor : orangeColor,
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 30.h,
          ),
          Container(
            decoration:
                BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                    color: isDarkModeNotifier.value
                        ? quranPagesColorDark
                        : quranPagesColorLight.withOpacity(.6),
                    borderRadius: BorderRadius.circular(20.r)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _today,
                        style: TextStyle(
                            color: isDarkModeNotifier.value ? Colors.white : Colors.black,
                            fontSize: 20.sp),
                      ),
                      Text(
                        DateFormat.yMMMEd(context.locale.languageCode).format(date),
                        style: TextStyle(
                            color: isDarkModeNotifier.value ? Colors.white : Colors.black,
                            fontSize: 20.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20.h,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: JGlobalDatePicker(
              widgetType: WidgetType.JContainer,
              pickerType: index == 0 ? PickerType.JHijri : PickerType.JNormal,
              buttons: const SizedBox(),
              primaryColor: isDarkModeNotifier.value ? backgroundColor : orangeColor,
              calendarTextColor:
                  isDarkModeNotifier.value ? backgroundColor.withOpacity(0.3) : orangeColor,
              backgroundColor: isDarkModeNotifier.value
                  ? darkModeSecondaryColor
                  : backgroundColor.withOpacity(0.3),
              borderRadius: const Radius.circular(0),
              headerTitle: Container(
                decoration: BoxDecoration(
                    color: isDarkModeNotifier.value
                        ? darkModeSecondaryColor.withOpacity(0.7)
                        : orangeColor),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            index = 0;
                          });
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "calender".tr(),
                              style: TextStyle(color: Colors.white, fontSize: 18.sp),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            index = 1;
                          });
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "normalCalender".tr(),
                              style: TextStyle(color: Colors.white, fontSize: 18.sp),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              startDate: JDateModel(dateTime: DateTime.parse("1984-12-24")),
              selectedDate: JDateModel(dateTime: DateTime.now()),
              endDate: JDateModel(dateTime: DateTime.parse("2030-09-20")),
              pickerMode: DatePickerMode.day,
              pickerTheme: Theme.of(context),
              locale: context.locale,
              textDirection: m.TextDirection.rtl,
              onChange: (val) {
                date = val.date;

                _today = j.HijriCalendar.fromDate(val.date).toFormat(
                  "dd - MMMM - yyyy",
                );
                setState(() {});
                // return val;
              },
            ),
          ),
        ],
      ),
    );
  }
}
