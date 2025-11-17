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
          backgroundColor: isDark ? darkModeSecondaryColor.withOpacity(0.7) : quranPagesColorLight,
          appBar: AppBar(
            backgroundColor: isDark ? quranPagesColorDark.withOpacity(0.5) : quranPagesColorLight,
            elevation: 0,
            title: Text(
              'settings'.tr(),
              style: TextStyle(
                color: isDark ? backgroundColor : darkModeSecondaryColor,
                fontFamily: "cairo",
                fontSize: 24.sp,
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
                  listTileSettingsView(
                    'languageApp'.tr(),
                    Icon(Icons.language, color: isDark ? backgroundColor : orangeColor, size: 32),
                    DropdownButton<Locale>(
                      value: context.locale,
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
                              color: isDark ? backgroundColor : orangeColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  listTileSettingsView(
                    'theme'.tr(),
                    Icon(Icons.dark_mode_outlined,
                        color: isDark ? backgroundColor : orangeColor, size: 32),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: isDark
                            ? const Color(0xffFEFEFE)
                            : darkModeSecondaryColor.withOpacity(0.9),
                      ),
                      child: IconButton(
                        onPressed: () {
                          final newValue = !isDarkModeNotifier.value;
                          updateValue("darkMode", newValue);
                          isDarkModeNotifier.value = newValue;
                        },
                        icon: Icon(
                          Icons.dark_mode_outlined,
                          color: isDark ? goldColor : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      // await FlutterOverlayWindow.requestPermission();
                      Navigator.push(context,
                          CupertinoPageRoute(builder: (builder) => const NotificationsPage()));
                    },
                    child: listTileSettingsView(
                      "notifications".tr(),
                      Icon(Icons.notifications_active_outlined,
                          color: isDark ? backgroundColor : orangeColor, size: 32),
                      Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              color: const Color(0xffFEFEFE)),
                          child: Image.asset(
                            "assets/images/notifications.png",
                            width: 50,
                            height: 50,
                          )),
                    ),
                  ),
                  const SizedBox(height: 8),
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

  Container listTileSettingsView(
    String title,
    Widget leading,
    Widget trailing,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkModeNotifier.value
            ? quranPagesColorDark.withOpacity(0.5)
            : const Color(0xffFEFEFE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          textAlign: TextAlign.start,
          style: TextStyle(
            color: isDarkModeNotifier.value ? backgroundColor : darkModeSecondaryColor,
            fontFamily: "cairo",
            fontSize: 22.sp,
          ),
        ),
        leading: leading,
        trailing: trailing,
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
        return languageCode; // Return the language code if not found
    }
  }

  // ignore: unused_field
  var _today = HijriCalendar.now();

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
    _today = HijriCalendar.now();
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

            ///add to category of all hadithlist
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

    //  if (response.data != null) {
    //       final jsonData = json.encode(response.data['reciters']);
    //       prefs.setString(
    //           "reciters-${context.locale.languageCode == "en" ? "eng" : context.locale.languageCode}",
    //           jsonData);
    //     }
  }
}
