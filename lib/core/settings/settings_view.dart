import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/core/notifications/views/all_notification_page.dart';
import 'package:ghaith/core/settings/rate_share_section.dart';
import 'package:ghaith/main.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: isDark ? darkModeSecondaryColor : quranPagesColorLight,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'settings'.tr(),
              style: TextStyle(
                color: isDark ? backgroundColor : darkModeSecondaryColor,
                fontFamily: "cairo",
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            foregroundColor: isDark ? backgroundColor : darkModeSecondaryColor,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Language Setting Card
                  _buildSettingsCard(
                    isDark: isDark,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFF5E6E6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.language_rounded,
                            color: isDark ? Colors.white70 : const Color(0xFF8B4545),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'languageApp'.tr(),
                                style: TextStyle(
                                  color: isDark ? Colors.white : darkModeSecondaryColor,
                                  fontFamily: "cairo",
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.2)
                                      : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<Locale>(
                                    value: context.locale,
                                    isExpanded: true,
                                    isDense: true,
                                    dropdownColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                                    ),
                                    onChanged: (Locale? newValue) {
                                      context.setLocale(newValue!);
                                      getAndStoreRecitersData();
                                      downloadAndStoreHadithData();
                                      updateDateData();
                                    },
                                    items: [
                                      const Locale("ar"),
                                      const Locale('en'),
                                      const Locale('de'),
                                      const Locale("am"),
                                      const Locale("ms"),
                                      const Locale("pt"),
                                      const Locale("tr"),
                                      const Locale("ru"),
                                    ].map((locale) {
                                      return DropdownMenuItem<Locale>(
                                        value: locale,
                                        child: Text(
                                          getNativeLanguageName(locale.languageCode),
                                          style: TextStyle(
                                            color: isDark ? Colors.white : darkModeSecondaryColor,
                                            fontFamily: "cairo",
                                            fontSize: 15.sp,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Theme Setting Card
                  _buildSettingsCard(
                    isDark: isDark,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFF5E6E6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                            color: isDark ? Colors.white70 : const Color(0xFF8B4545),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'theme'.tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white : darkModeSecondaryColor,
                              fontFamily: "cairo",
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF8B4545) : const Color(0xFF8B4545),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B4545).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final newValue = !isDarkModeNotifier.value;
                                updateValue("darkMode", newValue);
                                isDarkModeNotifier.value = newValue;
                              },
                              child: Center(
                                child: Icon(
                                  isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notifications Setting Card
                  _buildSettingsCard(
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (builder) => const NotificationsPage(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFF5E6E6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: isDark ? Colors.white70 : const Color(0xFF8B4545),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "notifications".tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white : darkModeSecondaryColor,
                              fontFamily: "cairo",
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color.fromARGB(176, 252, 252, 252)
                                : const Color.fromARGB(202, 244, 244, 244),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            "assets/images/notifications.png",
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rate & Share Section
                  const RateShareSection(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        color: isDark ? const Color(0xFF6B4B4B).withOpacity(0.6) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: child,
          ),
        ),
      ),
    );
  }

  String getNativeLanguageName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'العربية';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'am':
        return 'አማርኛ';
      case 'jp':
        return '日本語';
      case 'ms':
        return 'Melayu';
      case 'pt':
        return 'Português';
      case 'tr':
        return 'Türkçe';
      case 'ru':
        return 'Русский';
      default:
        return languageCode;
    }
  }

  getAndStoreRecitersData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print("working");
    Response response;
    Response response2;
    Response response3;
    try {
      if (context.locale.languageCode == "ms") {
        response = await Dio().get('http://mp3quran.net/api/v3/reciters?language=eng');
        response2 = await Dio().get('http://mp3quran.net/api/v3/moshaf?language=eng');
        response3 = await Dio().get('http://mp3quran.net/api/v3/suwar?language=eng');
      } else {
        response = await Dio().get(
            'http://mp3quran.net/api/v3/reciters?language=${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}');
        response2 = await Dio().get(
            'http://mp3quran.net/api/v3/moshaf?language=${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}');
        response3 = await Dio().get(
            'http://mp3quran.net/api/v3/suwar?language=${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}');
      }

      if (response.data != null) {
        final jsonData = json.encode(response.data['reciters']);
        prefs.setString(
            "reciters-${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}",
            jsonData);
      }
      if (response2.data != null) {
        final jsonData2 = json.encode(response2.data);
        prefs.setString(
            "moshaf-${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}",
            jsonData2);
      }
      if (response3.data != null) {
        final jsonData3 = json.encode(response3.data['suwar']);
        prefs.setString(
            "suwar-${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}",
            jsonData3);
      }
      print("worked");
    } catch (error) {
      print('Error while storing data: $error');
    }

    prefs.setInt("zikrNotificationindex", 0);
  }

  updateDateData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    HijriCalendar.setLocal(context.locale.languageCode == "ar" ? "ar" : "en");
    setState(() {});
  }

  downloadAndStoreHadithData() async {
    await Future.delayed(const Duration(seconds: 1));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString("hadithlist-100000-${context.locale.languageCode}") == null) {
      Response response = await Dio().get(
          "https://hadeethenc.com/api/v1/categories/roots/?language=${context.locale.languageCode}");

      if (response.data != null) {
        final jsonData = json.encode(response.data);
        prefs.setString("categories-${context.locale.languageCode}", jsonData);

        response.data.forEach((category) async {
          Response response2 = await Dio().get(
              "https://hadeethenc.com/api/v1/hadeeths/list/?language=${context.locale.languageCode}&category_id=${category["id"]}&per_page=699999");

          if (response2.data != null) {
            final jsonData = json.encode(response2.data["data"]);
            prefs.setString(
                "hadithlist-${category["id"]}-${context.locale.languageCode}", jsonData);

            if (prefs.getString("hadithlist-100000-${context.locale.languageCode}") == null) {
              prefs.setString("hadithlist-100000-${context.locale.languageCode}", jsonData);
            } else {
              final dataOfOldHadithlist =
                  json.decode(prefs.getString("hadithlist-100000-${context.locale.languageCode}")!)
                      as List<dynamic>;
              dataOfOldHadithlist.addAll(json.decode(jsonData));
              prefs.setString("hadithlist-100000-${context.locale.languageCode}",
                  json.encode(dataOfOldHadithlist));
            }
          }
        });
      }
    }
  }
}
