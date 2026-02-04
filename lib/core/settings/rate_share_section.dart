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
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeNotifier,
      builder: (context, isDark, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            color: isDark
                ? const Color(0xFF6B4B4B).withOpacity(0.6)
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.4) 
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  ('rateShare').tr(),
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: isDark ? Colors.white : darkModeSecondaryColor,
                    fontFamily: "cairo",
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Rate App Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ('rateApp').tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white : darkModeSecondaryColor,
                                fontFamily: "cairo",
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (index) => const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.star_rounded,
                                color: Colors.orange,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '5.0',
                            style: TextStyle(
                              color: isDark ? Colors.white : darkModeSecondaryColor,
                              fontFamily: "cairo",
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _rateApp(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4545),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.rate_review_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                ('rateOnStore').tr(),
                                style: TextStyle(
                                  fontFamily: "cairo",
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Share App Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.white.withOpacity(0.15)
                                  : const Color(0xFFE8E8E8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.share_rounded,
                              color: isDark ? Colors.white70 : const Color(0xFF8B4545),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ('shareAppTitle').tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white : darkModeSecondaryColor,
                                fontFamily: "cairo",
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ('shareAppSubtitle').tr(),
                        style: TextStyle(
                          color: isDark 
                              ? Colors.white.withOpacity(0.7) 
                              : Colors.grey.shade600,
                          fontFamily: "cairo",
                          fontSize: 13.sp,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _shareApp(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B4545),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.share_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                ('shareApp').tr(),
                                style: TextStyle(
                                  fontFamily: "cairo",
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Info Box
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.orange.shade700,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ('sharingBenefits').tr(),
                          style: TextStyle(
                            color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                            fontFamily: "cairo",
                            fontSize: 13.sp,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        'اكتشف تطبيق غيث المسلم📿✨\n\n'
        'تطبيق واحد يجمع بين جمال القرآن الكريم، ونور الأحاديث النبوية، وروحانية الأذكار والأدعية.\n'
        'عيش تجربة إيمانية متكاملة تساعدك على تعزيز صلتك بالله في كل وقت.\n\n'
        'حمّل التطبيق الآن من متجر Google Play:\nhttps://play.google.com/store/apps/details?id=com.ghaith.muslim.app',
        subject: 'غيث المسلم - دليلك اليومي للإيمان والسكينة',
      );
    } catch (e) {
      print('Error sharing app: $e');
    }
  }
}
