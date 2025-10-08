import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/main.dart';
import 'package:share_plus/share_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class RateShareSection extends StatelessWidget {
  const RateShareSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkModeNotifier.value
            ? quranPagesColorDark.withOpacity(0.5)
            : const Color(0xffFEFEFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ('rateShare').tr(),
            textAlign: TextAlign.start,
            style: TextStyle(
                color: isDarkModeNotifier.value ? backgroundColor : darkModeSecondaryColor,
                fontFamily: "cairo",
                fontSize: 24.sp),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkModeNotifier.value
                  ? quranPagesColorDark.withOpacity(0.5)
                  : const Color(0xffFEFEFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      ('rateApp').tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color:
                              isDarkModeNotifier.value ? backgroundColor : darkModeSecondaryColor,
                          fontFamily: "cairo",
                          fontSize: 16.sp),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => const Icon(Icons.star, color: Colors.orange, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '5.0',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color:
                              isDarkModeNotifier.value ? backgroundColor : darkModeSecondaryColor,
                          fontFamily: "cairo",
                          fontSize: 16.sp),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _rateApp(),
                    icon: const Icon(Icons.rate_review, size: 18),
                    label: Text(
                      ('rateOnStore').tr(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkModeNotifier.value ? backgroundColor : orangeColor,
                      foregroundColor: isDarkModeNotifier.value ? orangeColor : backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkModeNotifier.value
                  ? quranPagesColorDark.withOpacity(0.5)
                  : const Color(0xffFEFEFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.tertiary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.share,
                        color: isDarkModeNotifier.value ? backgroundColor : darkModeSecondaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      ('shareAppTitle').tr(),
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color:  isDarkModeNotifier.value ? backgroundColor : darkModeSecondaryColor,
                          fontFamily: "cairo",
                          fontSize: 16.sp),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ('shareAppSubtitle').tr(),
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      color:  isDarkModeNotifier.value ? backgroundColor : darkModeSecondaryColor,
                      fontFamily: "cairo",
                      fontSize: 12.sp),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _shareApp(),
                    icon: const Icon(
                      Icons.share,
                      size: 18,
                    ),
                    label: Text(
                      ('shareApp').tr(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkModeNotifier.value ? backgroundColor : orangeColor,
                      foregroundColor: isDarkModeNotifier.value ? orangeColor : backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isDarkModeNotifier.value
                  ? quranPagesColorDark.withOpacity(0.5)
                  : const Color(0xffFEFEFE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.tertiary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: isDarkModeNotifier.value ? backgroundColor : orangeColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ('sharingBenefits').tr(),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                        color: isDarkModeNotifier.value ? backgroundColor : orangeColor,
                        fontFamily: "cairo",
                        fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    String url;

    if (Platform.isAndroid) {
      url = 'https://play.google.com/store/apps/details?id=com.ghaith.muslim.app';
    } else if (Platform.isIOS) {
      url = 'https://apps.apple.com/app/weekly-app/id123456789';
    } else {
      url = 'https://ahmedsersy10.github.io/portfolio/';
    }

    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch app store');
      }
    } catch (e) {
      print('Error launching app store: $e');
    }
  }

  Future<void> _shareApp() async {
    try {
      await Share.share(
        'Check out Weekly App - Your Personal Task Manager! 📱✨\n\n'
        'Stay organized and productive with this amazing app!\n\n'
        'Download now: https://play.google.com/store/apps/details?id=com.ghaith.muslim.app',
        subject: 'Weekly App - Task Management Made Simple',
      );
    } catch (e) {
      print('Error sharing app: $e');
    }
  }
}
