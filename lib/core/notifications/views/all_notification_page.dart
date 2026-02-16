import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:ghaith/main.dart';

// =============================================
// 📁 IMPORTS - يمكن نقلها لملف imports منفصل
// =============================================
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/services/notification_service.dart';

// =============================================
// 🏗️ MAIN WIDGET - Notifications Page
// =============================================

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

// =============================================
// 🔧 STATE CLASS - Notifications Page Logic
// =============================================

class _NotificationsPageState extends State<NotificationsPage> {
  // =============================================
  // 🎛️ STATE VARIABLES
  // =============================================
  late List<Map<String, dynamic>> _notificationPeriods;

  // =============================================
  // 🎯 LIFECYCLE METHODS
  // =============================================

  @override
  void initState() {
    super.initState();
    _initializeNotificationPeriods();
  }

  // =============================================
  // 🔧 INITIALIZATION METHODS
  // =============================================

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  void _initializeNotificationPeriods() {
    _notificationPeriods = [
      {"index": 0, "name": "15 ${"minute".tr()}", "minutes": 15},
      {"index": 1, "name": "30 ${"minute".tr()}", "minutes": 30},
      {"index": 2, "name": "45 ${"minute".tr()}", "minutes": 45},
      {"index": 3, "name": "hour".tr(), "minutes": 60},
      {"index": 4, "name": "1.5 ${"hour".tr()}", "minutes": 90},
      {"index": 5, "name": "2 ${"hour".tr()}", "minutes": 120},
      {"index": 6, "name": "3 ${"hour".tr()}", "minutes": 180},
    ];
  }

  // =============================================
  // 🧩 UI BUILD METHODS
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softOffWhite,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // =============================================
  // 🎨 UI COMPONENTS - يمكن نقلها لملف widgets منفصل
  // =============================================

  // [CAN_BE_EXTRACTED] -> widgets/notifications_app_bar.dart
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _getAppBarColor(),
      centerTitle: true,
      title: Text(
        "notifications".tr(),
        style: const TextStyle(
          fontFamily: "cairo",
          color: softOffWhite,
        ),
      ),
      foregroundColor: softOffWhite,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notifications_body.dart
  Widget _buildBody() {
    return Container(
      color: _getsoftOffWhite(),
      child: ListView(
        children: [
          _buildQuranDailyReadingCard(), // ⭐ جديد: الورد القرآني
          _buildMorningAzkarCard(), // ⭐ جديد: أذكار الصباح
          _buildEveningAzkarCard(), // ⭐ جديد: أذكار المساء
          _buildSalahNotificationCard(),
          _buildAyahNotificationCard(),
          _buildHadithNotificationCard(),
          _buildZikrNotificationCard2(),
          // _buildZikrNotificationCard(),
        ],
      ),
    );
  }

  // ⭐ جديد: بطاقة الورد القرآني اليومي
  Widget _buildQuranDailyReadingCard() {
    return _buildTimeBasedNotificationCard(
      title: "الورد القرآني اليومي",
      description: "تذكير يومي بقراءة وردك من القرآن الكريم",
      settingKey: "shouldShowQuranDailyReading",
      timeKey: "quranDailyReadingTime",
      // imagePath: "assets/images/zikrnotification2.jpeg",
      onToggle: _onQuranDailyReadingToggle,
      onTest: _onQuranDailyReadingTest,
      onTimeSelect: _onSelectQuranReadingTime,
    );
  }

  // ⭐ جديد: بطاقة أذكار الصباح
  Widget _buildMorningAzkarCard() {
    return _buildTimeBasedNotificationCard(
      title: "أذكار الصباح",
      description: "تذكير يومي بأذكار الصباح",
      settingKey: "shouldShowMorningAzkar",
      timeKey: "morningAzkarTime",
      // imagePath: "assets/images/zikrnotification2.jpeg",
      onToggle: _onMorningAzkarToggle,
      onTest: _onMorningAzkarTest,
      onTimeSelect: _onSelectMorningAzkarTime,
    );
  }

  // ⭐ جديد: بطاقة أذكار المساء
  Widget _buildEveningAzkarCard() {
    return _buildTimeBasedNotificationCard(
      title: "أذكار المساء",
      description: "تذكير يومي بأذكار المساء",
      settingKey: "shouldShowEveningAzkar",
      timeKey: "eveningAzkarTime",
      // imagePath: "assets/images/zikrnotification2.jpeg",
      onToggle: _onEveningAzkarToggle,
      onTest: _onEveningAzkarTest,
      onTimeSelect: _onSelectEveningAzkarTime,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_card.dart
  Widget _buildSalahNotificationCard() {
    return _buildNotificationCard(
      title: " ${"الصلاة علي النبي "} ﷺ",
      description: "sallahNotificationDetails".tr(),
      settingKey: "shouldShowSallyNotification",
      frequencyKey: "timesForShowingSallyNotifications", // ⭐ تحديث: إضافة التردد
      // imagePath: null,
      onToggle: _onSalahNotificationToggle,
      onTest: _onSalahNotificationTest, // ⭐ تحديث: إضافة زر التجربة
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_card.dart
  Widget _buildAyahNotificationCard() {
    return _buildNotificationCard(
      title: "ayahnotification".tr(),
      description: "ayahnotificationdetails".tr(),
      settingKey: "shouldShowAyahNotification",
      frequencyKey: "timesForShowingAyahNotifications",
      // imagePath: "assets/images/ayahNotification.jpeg",
      onToggle: _onAyahNotificationToggle,
      onTest: _onAyahNotificationTest,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_card.dart
  Widget _buildHadithNotificationCard() {
    return _buildNotificationCard(
      title: "hadithnotification".tr(),
      description: "hadithNotificationDetails".tr(),
      settingKey: "shouldShowhadithNotification",
      frequencyKey: "timesForShowinghadithNotifications",
      // imagePath: "assets/images/hadithNotification.jpeg",
      onToggle: _onHadithNotificationToggle,
      onTest: _onHadithNotificationTest,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_card.dart
  Widget _buildZikrNotificationCard2() {
    return _buildNotificationCard(
      title: "zikrNotification".tr(),
      description: "zikrNotificationDetails2".tr(),
      settingKey: "shouldShowZikrNotification2",
      frequencyKey: "timesForShowingZikrNotifications2",
      // imagePath: "assets/images/zikrnotification2.jpeg",
      onToggle: _onZikrNotification2Toggle,
      onTest: _onZikrNotification2Test,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_card.dart
  // Widget _buildZikrNotificationCard() {
  //   return _buildNotificationCard(
  //     title: "zikrNotification".tr(),
  //     description: "zikrNotificationDetails".tr(),
  //     settingKey: "shouldShowZikrNotification",
  //     frequencyKey: "timesForShowingZikrNotifications",
  //     // imagePath: "assets/images/zikrnotif.jpg",
  //     onToggle: _onZikrNotificationToggle,
  //     onTest: _onZikrNotificationTest,
  //     requiresOverlayPermission: true,
  //   );
  // }

  // [CAN_BE_EXTRACTED] -> widgets/notification_card.dart
  Widget _buildNotificationCard({
    required String title,
    required String description,
    required String settingKey,
    required String? frequencyKey,
    // required String? imagePath,
    required Function(bool) onToggle,
    required VoidCallback? onTest,
    bool requiresOverlayPermission = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      child: Card(
        elevation: .8,
        color: _getCardColor(),
        margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              _buildNotificationHeader(
                title: title,
                settingKey: settingKey,
                onToggle: onToggle,
                onTest: onTest,
                requiresOverlayPermission: requiresOverlayPermission,
              ),
              SizedBox(height: 8.h),
              _buildNotificationDescription(description),
              // if (imagePath != null) _buildNotificationImage(imagePath),
              if (frequencyKey != null) _buildFrequencySelector(frequencyKey),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  // ⭐ جديد: بطاقة للإشعارات المعتمدة على الوقت (time-based)
  Widget _buildTimeBasedNotificationCard({
    required String title,
    required String description,
    required String settingKey,
    required String timeKey,
    // required String? imagePath,
    required Function(bool) onToggle,
    required VoidCallback? onTest,
    required VoidCallback onTimeSelect,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      child: Card(
        elevation: .8,
        color: _getCardColor(),
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              _buildNotificationHeader(
                title: title,
                settingKey: settingKey,
                onToggle: onToggle,
                onTest: onTest,
                requiresOverlayPermission: false,
              ),
              SizedBox(height: 8.h),
              _buildNotificationDescription(description),
              // if (imagePath != null) _buildNotificationImage(imagePath),
              _buildTimeSelector(timeKey, onTimeSelect),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  // ⭐ جديد: منتقي الوقت
  Widget _buildTimeSelector(String timeKey, VoidCallback onTimeSelect) {
    final savedTime = getValue(timeKey) ?? "08:00"; // الوقت الافتراضي

    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "الوقت المحدد:",
              style: TextStyle(
                color: _getcharcoalDarkGray(),
                fontSize: 16.sp,
                fontFamily: 'cairo',
              ),
            ),
            InkWell(
              onTap: onTimeSelect,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  border: Border.all(color: wineRed),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: wineRed, size: 20),
                    SizedBox(width: 8.w),
                    Text(
                      savedTime,
                      style: TextStyle(
                        color: _getcharcoalDarkGray(),
                        fontSize: 16.sp,
                        fontFamily: 'cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_header.dart
  Widget _buildNotificationHeader({
    required String title,
    required String settingKey,
    required Function(bool) onToggle,
    required VoidCallback? onTest,
    required bool requiresOverlayPermission,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 3.0.w, right: 14.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildToggleSwitch(
            value: getValue(settingKey) ?? false, // ⭐ إصلاح: إضافة ?? false
            onToggle: onToggle,
            requiresOverlayPermission: requiresOverlayPermission,
          ),
          if (onTest != null) _buildTestButton(onTest),
          Expanded(child: _buildNotificationTitle(title, settingKey)),
        ],
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/toggle_switch.dart
  Widget _buildToggleSwitch({
    required bool value,
    required Function(bool) onToggle,
    required bool requiresOverlayPermission,
  }) {
    return CupertinoSwitch(
      activeColor: wineRed,
      thumbColor: Colors.white,
      trackColor: Colors.grey,
      value: value, // القيمة تأتي من getValue مع ?? false في المكان الذي يستدعيها
      onChanged: (newValue) async {
        if (requiresOverlayPermission) {
          if (!await FlutterOverlayWindow.isPermissionGranted()) {
            await FlutterOverlayWindow.requestPermission();
          }
          if (!await FlutterOverlayWindow.isPermissionGranted()) {
            return;
          }
        }
        onToggle(newValue);
      },
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/test_button.dart
  Widget _buildTestButton(VoidCallback onTest) {
    return TextButton(
      onPressed: onTest,
      child: Text(
        "test".tr(),
        style: TextStyle(
          color: _getcharcoalDarkGray(),
          fontSize: 14.sp,
          fontFamily: 'cairo',
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_title.dart
  Widget _buildNotificationTitle(String title, String settingKey) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              color: _getcharcoalDarkGray(),
              fontWeight: FontWeight.bold,
              fontFamily: 'cairo',
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.start, // Default
          ),
        ),
        SizedBox(width: 5.w),
        _buildStatusIndicator(getValue(settingKey) ?? false), // ⭐ إصلاح: إضافة ?? false
      ],
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/status_indicator.dart
  Widget _buildStatusIndicator(bool isActive) {
    return CircleAvatar(
      radius: 5,
      backgroundColor: isActive ? Colors.green : Colors.grey,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_description.dart
  Widget _buildNotificationDescription(String description) {
    return Padding(
      padding: EdgeInsets.only(left: 8.0.w),
      child: Text(
        description,
        softWrap: true,
        style: TextStyle(
          color: _getcharcoalDarkGray(),
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_image.dart
  // Widget _buildNotificationImage(String imagePath) {
  //   return Padding(
  //     padding: const EdgeInsets.all(8),
  //     child: Image.asset(imagePath),
  //   );
  // }

  // [CAN_BE_EXTRACTED] -> widgets/frequency_selector.dart
  Widget _buildFrequencySelector(String frequencyKey) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * .8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "shownotificationevery".tr(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _getcharcoalDarkGray(),
                      fontSize: 16.sp,
                      fontFamily: 'cairo',
                    ),
                  ),
                  _buildFrequencyDropdown(frequencyKey),
                  Text(
                    "daily".tr(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _getcharcoalDarkGray(),
                      fontSize: 16.sp,
                      fontFamily: 'cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/frequency_dropdown.dart
  Widget _buildFrequencyDropdown(String frequencyKey) {
    return DropdownButton(
      value: getValue(frequencyKey) ?? 0, // ⭐ إصلاح: إضافة ?? 0
      items: _notificationPeriods
          .map((period) => DropdownMenuItem(
                value: period["index"],
                child: Text(
                  period["name"],
                  style: TextStyle(
                    color: _getcharcoalDarkGray(),
                    fontSize: 16.sp,
                    fontFamily: 'cairo',
                  ),
                ),
              ))
          .toList(),
      onChanged: (newValue) {
        updateValue(frequencyKey, newValue);
        setState(() {});
      },
    );
  }

  // =============================================
  // 🔧 NOTIFICATION SERVICE METHODS - يمكن نقلها لملف service منفصل
  // =============================================

  // ⭐ تحديث: تحويل الصلاة على النبي لإشعار دوري
  void _onSalahNotificationToggle(bool value) {
    updateValue("shouldShowSallyNotification", value);
    if (value) {
      final frequency =
          _notificationPeriods[getValue("timesForShowingSallyNotifications") ?? 0]["minutes"];
      Workmanager().registerPeriodicTask(
        "sallahNotification",
        "sallahNotification",
        frequency: Duration(minutes: frequency),
      );
    } else {
      Workmanager().cancelByUniqueName("sallahNotification");
    }
    setState(() {});
  }

  // ⭐ جديد: اختبار إشعار الصلاة على النبي
  Future<void> _onSalahNotificationTest() async {
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    if (await Permission.notification.isGranted) {
      Workmanager().registerOneOffTask("sallahNotificationTest", "sallahNotificationTest");
    }
    setState(() {});
  }

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  void _onAyahNotificationToggle(bool value) {
    updateValue("shouldShowAyahNotification", value);
    if (value) {
      final frequency =
          _notificationPeriods[getValue("timesForShowingAyahNotifications") ?? 0]["minutes"];
      Workmanager().registerPeriodicTask(
        "ayahNotfication",
        "ayahNot",
        frequency: Duration(minutes: frequency),
      );
    } else {
      Workmanager().cancelByUniqueName("ayahNotfication");
    }
    setState(() {});
  }

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  Future<void> _onAyahNotificationTest() async {
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    if (await Permission.notification.isGranted) {
      Workmanager().registerOneOffTask("ayahNotTest", "ayahNotTest");
    }
    setState(() {});
  }

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  void _onHadithNotificationToggle(bool value) {
    updateValue("shouldShowhadithNotification", value);
    if (value) {
      final frequency =
          _notificationPeriods[getValue("timesForShowinghadithNotifications") ?? 0]["minutes"];
      Workmanager().registerPeriodicTask(
        "hadithNotfication",
        "hadithNot",
        frequency: Duration(minutes: frequency),
      );
    } else {
      Workmanager().cancelByUniqueName("hadithNotfication");
    }
    setState(() {});
  }

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  Future<void> _onHadithNotificationTest() async {
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    if (await Permission.notification.isGranted) {
      Workmanager().registerOneOffTask("hadithNotTest", "hadithNotTest");
    }
    setState(() {});
  }

  // ⭐ جديد: الورد القرآني اليومي
  void _onQuranDailyReadingToggle(bool value) {
    updateValue("shouldShowQuranDailyReading", value);
    if (value) {
      _scheduleQuranDailyReading();
    } else {
      NotificationService().cancelNotification(5);
    }
    setState(() {});
  }

  Future<void> _onQuranDailyReadingTest() async {
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    if (await Permission.notification.isGranted) {
      NotificationService().showNotification(
        id: 5,
        title: "⏰ الورد القرآني",
        body: "حان وقت قراءة وردك من القرآن الكريم",
        channelId: "quranDaily",
        channelName: "Quran Daily Reading",
      );
    }
    setState(() {});
  }

  Future<void> _onSelectQuranReadingTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTimeString(getValue("quranDailyReadingTime") ?? "08:00"),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: wineRed),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      updateValue("quranDailyReadingTime", timeString);

      // إعادة جدولة الإشعار بالوقت الجديد
      if (getValue("shouldShowQuranDailyReading") == true) {
        _scheduleQuranDailyReading();
      }
      setState(() {});
    }
  }

  void _scheduleQuranDailyReading() {
    final timeString = getValue("quranDailyReadingTime") ?? "08:00";
    final time = _parseTimeString(timeString);
    NotificationService().scheduleDailyNotification(
      id: 5,
      title: "⏰ الورد القرآني",
      body: "حان وقت قراءة وردك من القرآن الكريم",
      time: time,
      channelId: "quranDaily",
      channelName: "Quran Daily Reading",
    );
  }

  // ⭐ جديد: أذكار الصباح
  void _onMorningAzkarToggle(bool value) {
    updateValue("shouldShowMorningAzkar", value);
    if (value) {
      _scheduleMorningAzkar();
    } else {
      NotificationService().cancelNotification(6);
    }
    setState(() {});
  }

  Future<void> _onMorningAzkarTest() async {
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    if (await Permission.notification.isGranted) {
      NotificationService().showNotification(
        id: 6,
        title: "🌅 أذكار الصباح",
        body: "حان وقت أذكار الصباح",
        channelId: "morningAzkar",
        channelName: "Morning Azkar",
      );
    }
    setState(() {});
  }

  Future<void> _onSelectMorningAzkarTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTimeString(getValue("morningAzkarTime") ?? "06:00"),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: wineRed),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      updateValue("morningAzkarTime", timeString);

      if (getValue("shouldShowMorningAzkar") == true) {
        _scheduleMorningAzkar();
      }
      setState(() {});
    }
  }

  void _scheduleMorningAzkar() {
    final timeString = getValue("morningAzkarTime") ?? "06:00";
    final time = _parseTimeString(timeString);
    NotificationService().scheduleDailyNotification(
      id: 6,
      title: "🌅 أذكار الصباح",
      body: "حان وقت أذكار الصباح",
      time: time,
      channelId: "morningAzkar",
      channelName: "Morning Azkar",
    );
  }

  // ⭐ جديد: أذكار المساء
  void _onEveningAzkarToggle(bool value) {
    updateValue("shouldShowEveningAzkar", value);
    if (value) {
      _scheduleEveningAzkar();
    } else {
      NotificationService().cancelNotification(7);
    }
    setState(() {});
  }

  Future<void> _onEveningAzkarTest() async {
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    if (await Permission.notification.isGranted) {
      NotificationService().showNotification(
        id: 7,
        title: "🌙 أذكار المساء",
        body: "حان وقت أذكار المساء",
        channelId: "eveningAzkar",
        channelName: "Evening Azkar",
      );
    }
    setState(() {});
  }

  Future<void> _onSelectEveningAzkarTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTimeString(getValue("eveningAzkarTime") ?? "18:00"),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: wineRed),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      updateValue("eveningAzkarTime", timeString);

      if (getValue("shouldShowEveningAzkar") == true) {
        _scheduleEveningAzkar();
      }
      setState(() {});
    }
  }

  void _scheduleEveningAzkar() {
    final timeString = getValue("eveningAzkarTime") ?? "18:00";
    final time = _parseTimeString(timeString);
    NotificationService().scheduleDailyNotification(
      id: 7,
      title: "🌙 أذكار المساء",
      body: "حان وقت أذكار المساء",
      time: time,
      channelId: "eveningAzkar",
      channelName: "Evening Azkar",
    );
  }

  // ⭐ جديد: دالة مساعدة لتحويل النص إلى TimeOfDay
  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(":");
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  void _onZikrNotification2Toggle(bool value) {
    updateValue("shouldShowZikrNotification2", value);
    if (value) {
      final frequency =
          _notificationPeriods[getValue("timesForShowingZikrNotifications2") ?? 0]["minutes"];
      Workmanager().registerPeriodicTask(
        "zikrNotification2",
        "zikrNotification2",
        frequency: Duration(minutes: frequency),
      );
    } else {
      Workmanager().cancelByUniqueName("zikrNotification2");
    }
    setState(() {});
  }

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  void _onZikrNotification2Test() {
    Workmanager().registerOneOffTask("zikrNotificationTest2", "zikrNotificationTest2");
    setState(() {});
  }

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  // void _onZikrNotificationToggle(bool value) {
  //   updateValue("shouldShowZikrNotification", value);
  //   if (value) {
  //     final frequency =
  //         _notificationPeriods[getValue("timesForShowingZikrNotifications") ?? 0]["minutes"];
  //     Workmanager().registerPeriodicTask(
  //       "zikrNotification",
  //       "zikrNotification",
  //       frequency: Duration(minutes: frequency),
  //     );
  //   } else {
  //     Workmanager().cancelByUniqueName("zikrNotification");
  //   }
  //   setState(() {});
  // }

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  // Future<void> _onZikrNotificationTest() async {
  //   if (!await FlutterOverlayWindow.isPermissionGranted()) {
  //     await FlutterOverlayWindow.requestPermission();
  //   }
  //   if (await FlutterOverlayWindow.isPermissionGranted()) {
  //     Workmanager().registerOneOffTask("zikrNotificationTest", "zikrNotificationTest");
  //   }
  //   setState(() {});
  // }

  // =============================================
  // 🎨 STYLE HELPER METHODS - يمكن نقلها لملف themes
  // =============================================

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getAppBarColor() {
    return isDarkModeNotifier.value ? deepNavyBlack : wineRed;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getsoftOffWhite() {
    return isDarkModeNotifier.value ? darkSlateGray : paperBeige;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getCardColor() {
    return isDarkModeNotifier.value ? deepNavyBlack : Colors.white;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getcharcoalDarkGray() {
    return isDarkModeNotifier.value ? Colors.white : Colors.black;
  }
}
