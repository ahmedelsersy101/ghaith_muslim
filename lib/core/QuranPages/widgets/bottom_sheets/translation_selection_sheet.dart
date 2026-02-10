import 'dart:io';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttericon/mfg_labs_icons.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/core/QuranPages/helpers/translation/translationdata.dart';
import 'package:ghaith/main.dart';

class TranslationSelectionSheet {
  static void show(
    BuildContext context, {
    required VoidCallback onSettingsChanged,
    Future<void> Function()? onTranslationSelected,
  }) {
    showMaterialModalBottomSheet(
      enableDrag: true,
      animationCurve: Curves.easeInOutCubic,
      elevation: 0,
      bounce: true,
      duration: const Duration(milliseconds: 400),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (builder) {
        return _TranslationSelectionModal(
          onSettingsChanged: onSettingsChanged,
          onTranslationSelected: onTranslationSelected,
        );
      },
    );
  }
}

class _TranslationSelectionModal extends StatefulWidget {
  final VoidCallback onSettingsChanged;
  final Future<void> Function()? onTranslationSelected;

  const _TranslationSelectionModal({
    required this.onSettingsChanged,
    this.onTranslationSelected,
  });

  @override
  State<_TranslationSelectionModal> createState() => _TranslationSelectionModalState();
}

class _TranslationSelectionModalState extends State<_TranslationSelectionModal> {
  Directory? appDir;
  String isDownloading = "";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    appDir = await getTemporaryDirectory();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = isDarkModeNotifier.value;
    final quranColorIndex = getValue("quranPageolorsIndex") ?? 0;

    // Use theme-aware colors if available, fallback to settings-aware colors
    final bgColor = softOffWhites[quranColorIndex];
    final textColor = darkWarmBrowns[quranColorIndex];
    final accentColor = secondaryColors[quranColorIndex];

    return Container(
      height: screenSize.height * 0.8,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.translate_rounded,
                    color: accentColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  "choosetranslation".tr(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: context.locale.languageCode == "ar" ? "cairo" : "roboto",
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: textColor.withOpacity(0.1),
          ),

          // Translations list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: translationDataList.length,
              itemBuilder: (c, i) {
                final translation = translationDataList[i];
                final isSelected = i == getValue("indexOfTranslationInVerseByVerse");
                final isDownloadingThis = isDownloading == translation.url;
                final isDownloaded = (appDir != null &&
                        File("${appDir!.path}/${translation.typeText}.json").existsSync()) ||
                    i == 0 ||
                    i == 1;

                return Directionality(
                  textDirection: m.TextDirection.rtl,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected ? accentColor.withOpacity(0.3) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      onTap: () async {
                        if (isDownloadingThis) return;

                        if (isDownloaded) {
                          updateValue("indexOfTranslationInVerseByVerse", i);
                          if (widget.onTranslationSelected != null) {
                            await widget.onTranslationSelected!();
                          }
                          widget.onSettingsChanged();
                          if (mounted) Navigator.pop(context);
                        } else {
                          await _downloadTranslation(i);
                        }
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accentColor.withOpacity(0.15)
                                    : textColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                isDownloadingThis
                                    ? Icons.downloading_rounded
                                    : (isDownloaded
                                        ? (i == 0 || i == 1
                                            ? MfgLabs.hdd
                                            : Icons.check_circle_rounded)
                                        : Icons.cloud_download_rounded),
                                color: isSelected ? accentColor : textColor.withOpacity(0.6),
                                size: 20.sp,
                              ),
                            ),

                            SizedBox(width: 12.w),

                            // Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    translation.typeTextInRelatedLanguage,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 15.sp,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      fontFamily: translation.typeInNativeLanguage == "العربية"
                                          ? "cairo"
                                          : "roboto",
                                    ),
                                  ),
                                  if (translation.typeInNativeLanguage != "")
                                    Text(
                                      translation.typeInNativeLanguage,
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.5),
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Loading or check
                            if (isDownloadingThis)
                              SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(accentColor),
                                ),
                              )
                            else if (isSelected)
                              Icon(
                                Icons.check_rounded,
                                color: accentColor,
                                size: 20.sp,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTranslation(int index) async {
    try {
      appDir ??= await getTemporaryDirectory();

      setState(() => isDownloading = translationDataList[index].url);

      await Dio().download(
        translationDataList[index].url,
        "${appDir!.path}/${translationDataList[index].typeText}.json",
      );

      updateValue("indexOfTranslationInVerseByVerse", index);
      if (widget.onTranslationSelected != null) {
        await widget.onTranslationSelected!();
      }
      widget.onSettingsChanged();

      if (mounted) {
        setState(() => isDownloading = "");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isDownloading = "");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.locale.languageCode == "ar"
                  ? "حدث خطأ أثناء التحميل. يرجى المحاولة مرة أخرى."
                  : "Download failed. Please try again.",
              style: const TextStyle(fontFamily: "cairo"),
            ),
            backgroundColor: deepBurgundyRed,
          ),
        );
      }
    }
  }
}
