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
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';

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
      backgroundColor: backgroundColor,
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
          color: backgroundColor,
        ),
      ),
      foregroundColor: backgroundColor,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notifications_body.dart
  Widget _buildBody() {
    return Container(
      color: _getBackgroundColor(),
      child: ListView(
        children: [
          _buildSalahNotificationCard(),
          _buildAyahNotificationCard(),
          _buildHadithNotificationCard(),
          _buildZikrNotificationCard2(),
          _buildZikrNotificationCard(),
        ],
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_card.dart
  Widget _buildSalahNotificationCard() {
    return _buildNotificationCard(
      title: "ﷺ ${"الصلاة علي النبي "} ﷺ",
      description: "sallahNotificationDetails".tr(),
      settingKey: "shouldShowSallyNotification",
      frequencyKey: null, // لا يوجد اختيار تردد لهذا الإشعار
      imagePath: null,
      onToggle: _onSalahNotificationToggle,
      onTest: null, // لا يوجد زر تجربة لهذا الإشعار
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_card.dart
  Widget _buildAyahNotificationCard() {
    return _buildNotificationCard(
      title: "ayahnotification".tr(),
      description: "ayahnotificationdetails".tr(),
      settingKey: "shouldShowAyahNotification",
      frequencyKey: "timesForShowingAyahNotifications",
      imagePath: "assets/images/ayahNotification.jpeg",
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
      imagePath: "assets/images/hadithNotification.jpeg",
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
      imagePath: "assets/images/zikrnotification2.jpeg",
      onToggle: _onZikrNotification2Toggle,
      onTest: _onZikrNotification2Test,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_card.dart
  Widget _buildZikrNotificationCard() {
    return _buildNotificationCard(
      title: "zikrNotification".tr(),
      description: "zikrNotificationDetails".tr(),
      settingKey: "shouldShowZikrNotification",
      frequencyKey: "timesForShowingZikrNotifications",
      imagePath: "assets/images/zikrnotif.jpg",
      onToggle: _onZikrNotificationToggle,
      onTest: _onZikrNotificationTest,
      requiresOverlayPermission: true,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_card.dart
  Widget _buildNotificationCard({
    required String title,
    required String description,
    required String settingKey,
    required String? frequencyKey,
    required String? imagePath,
    required Function(bool) onToggle,
    required VoidCallback? onTest,
    bool requiresOverlayPermission = false,
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
                requiresOverlayPermission: requiresOverlayPermission,
              ),
              SizedBox(height: 8.h),
              _buildNotificationDescription(description),
              if (imagePath != null) _buildNotificationImage(imagePath),
              if (frequencyKey != null) _buildFrequencySelector(frequencyKey),
              SizedBox(height: 8.h),
            ],
          ),
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
            value: getValue(settingKey),
            onToggle: onToggle,
            requiresOverlayPermission: requiresOverlayPermission,
          ),
          if (onTest != null) _buildTestButton(onTest),
          _buildNotificationTitle(title, settingKey),
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
      activeColor: orangeColor,
      thumbColor: Colors.white,
      trackColor: Colors.grey,
      value: value,
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
          color: _getTextColor(),
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
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            color: _getTextColor(),
            fontWeight: FontWeight.bold,
            fontFamily: 'cairo',
          ),
        ),
        SizedBox(width: 5.w),
        _buildStatusIndicator(getValue(settingKey)),
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
          color: _getTextColor(),
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/notification_image.dart
  Widget _buildNotificationImage(String imagePath) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset(imagePath),
    );
  }

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
                      color: _getTextColor(),
                      fontSize: 16.sp,
                      fontFamily: 'cairo',
                    ),
                  ),
                  _buildFrequencyDropdown(frequencyKey),
                  Text(
                    "daily".tr(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _getTextColor(),
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
      value: getValue(frequencyKey),
      items: _notificationPeriods
          .map((period) => DropdownMenuItem(
                value: period["index"],
                child: Text(
                  period["name"],
                  style: TextStyle(
                    color: _getTextColor(),
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

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  void _onSalahNotificationToggle(bool value) {
    updateValue("shouldShowSallyNotification", value);
    if (value) {
      Workmanager().registerOneOffTask("sallahEnable", "sallahEnable");
    } else {
      Workmanager().registerOneOffTask("sallahDisable", "sallahDisable");
    }
    setState(() {});
  }

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  void _onAyahNotificationToggle(bool value) {
    updateValue("shouldShowAyahNotification", value);
    if (value) {
      final frequency =
          _notificationPeriods[getValue("timesForShowingAyahNotifications")]["minutes"];
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
          _notificationPeriods[getValue("timesForShowinghadithNotifications")]["minutes"];
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

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  void _onZikrNotification2Toggle(bool value) {
    updateValue("shouldShowZikrNotification2", value);
    if (value) {
      final frequency =
          _notificationPeriods[getValue("timesForShowingZikrNotifications2")]["minutes"];
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
  void _onZikrNotificationToggle(bool value) {
    updateValue("shouldShowZikrNotification", value);
    if (value) {
      final frequency =
          _notificationPeriods[getValue("timesForShowingZikrNotifications")]["minutes"];
      Workmanager().registerPeriodicTask(
        "zikrNotification",
        "zikrNotification",
        frequency: Duration(minutes: frequency),
      );
    } else {
      Workmanager().cancelByUniqueName("zikrNotification");
    }
    setState(() {});
  }

  // [CAN_BE_EXTRACTED] -> services/notification_service.dart
  Future<void> _onZikrNotificationTest() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
    if (await FlutterOverlayWindow.isPermissionGranted()) {
      Workmanager().registerOneOffTask("zikrNotificationTest", "zikrNotificationTest");
    }
    setState(() {});
  }

  // =============================================
  // 🎨 STYLE HELPER METHODS - يمكن نقلها لملف themes
  // =============================================

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getAppBarColor() {
    return isDarkModeNotifier.value ? darkModeSecondaryColor : orangeColor;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getBackgroundColor() {
    return isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getCardColor() {
    return isDarkModeNotifier.value ? darkModeSecondaryColor : Colors.white;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getTextColor() {
    return isDarkModeNotifier.value ? Colors.white : Colors.black;
  }
}
