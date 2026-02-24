import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/core/QuranPages/helpers/translation/translation_info.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';
import 'package:ghaith/core/QuranPages/helpers/remove_html_tags.dart';
import 'package:ghaith/core/QuranPages/views/screenshot_preview.dart';

class ShareAyahDialog extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final int index;
  final dynamic jsonData;
  final List<TranslationData> translationDataList;

  const ShareAyahDialog({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.index,
    required this.jsonData,
    required this.translationDataList,
  });

  @override
  State<ShareAyahDialog> createState() => _ShareAyahDialogState();
}

class _ShareAyahDialogState extends State<ShareAyahDialog> {
  late int firstVerse;
  late int lastVerse;

  @override
  void initState() {
    super.initState();
    firstVerse = widget.verseNumber;
    lastVerse = widget.verseNumber;
  }

  @override
  Widget build(BuildContext context) {
    final colorIndex = getValue("quranPageolorsIndex");
    final primaryColor = darkWarmBrowns[colorIndex];
    final backgroundColor = softOffWhites[colorIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.share_rounded,
                    color: primaryColor,
                    size: 22.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    "share".tr(),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 18.sp,
                      fontFamily: "cairo",
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Verse Range Selection
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: primaryColor.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // From Verse
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'fromayah'.tr(),
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.7),
                            fontSize: 12.sp,
                            fontFamily: "cairo",
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              dropdownColor: backgroundColor,
                              value: firstVerse,
                              isDense: true,
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: primaryColor,
                                size: 20.sp,
                              ),
                              onChanged: (newValue) {
                                if (newValue! > lastVerse) {
                                  setState(() {
                                    lastVerse = newValue;
                                  });
                                }
                                setState(() {
                                  firstVerse = newValue;
                                });
                              },
                              items: List.generate(
                                quran.getVerseCount(widget.surahNumber),
                                (index) => DropdownMenuItem<int>(
                                  value: index + 1,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: primaryColor.withOpacity(0.4),
                      size: 18.sp,
                    ),
                  ),

                  // To Verse
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'toayah'.tr(),
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.7),
                            fontSize: 12.sp,
                            fontFamily: "cairo",
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              dropdownColor: backgroundColor,
                              value: lastVerse,
                              isDense: true,
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: primaryColor,
                                size: 20.sp,
                              ),
                              onChanged: (newValue) {
                                if (newValue! >= firstVerse) {
                                  setState(() {
                                    lastVerse = newValue;
                                  });
                                }
                              },
                              items: List.generate(
                                quran.getVerseCount(widget.surahNumber),
                                (index) => DropdownMenuItem<int>(
                                  value: index + 1,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Share Type Selection
            _buildRadioOption(
              title: 'asimage'.tr(),
              value: 0,
              groupValue: getValue("selectedShareTypeIndex"),
              primaryColor: primaryColor,
              backgroundColor: backgroundColor,
              icon: Icons.image_rounded,
            ),

            _buildRadioOption(
              title: 'astext'.tr(),
              value: 1,
              groupValue: getValue("selectedShareTypeIndex"),
              primaryColor: primaryColor,
              backgroundColor: backgroundColor,
              icon: Icons.text_fields_rounded,
            ),

            // Additional Options
            if (getValue("selectedShareTypeIndex") == 1) ...[
              _buildCheckboxOption(
                title: 'withoutdiacritics'.tr(),
                value: getValue("textWithoutDiacritics"),
                primaryColor: primaryColor,
                backgroundColor: backgroundColor,
              ),
            ],

            _buildCheckboxOption(
              title: 'addappname'.tr(),
              value: getValue("addAppSlogan"),
              primaryColor: primaryColor,
              backgroundColor: backgroundColor,
            ),

            _buildCheckboxOption(
              title: 'addtafseer'.tr(),
              value: getValue("addTafseer"),
              primaryColor: primaryColor,
              backgroundColor: backgroundColor,
            ),

            // Tafseer Selection
            if (getValue("addTafseer") == true)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.15),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.translationDataList[getValue("addTafseerValue") ?? 0]
                              .typeTextInRelatedLanguage,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 13.sp,
                            fontFamily: widget.translationDataList[getValue("addTafseerValue") ?? 0]
                                        .typeInNativeLanguage ==
                                    "العربية"
                                ? "cairo"
                                : "roboto",
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 22.sp,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16.h),

            // Action Button
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 35.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleShare(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: backgroundColor,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        getValue("selectedShareTypeIndex") == 0
                            ? Icons.visibility_rounded
                            : Icons.share_rounded,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        getValue("selectedShareTypeIndex") == 0 ? "preview".tr() : "astext".tr(),
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: "cairo",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required int value,
    required int groupValue,
    required Color primaryColor,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: value == groupValue ? primaryColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: value == groupValue ? primaryColor.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: RadioListTile(
        activeColor: primaryColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
        dense: true,
        title: Row(
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: primaryColor.withOpacity(value == groupValue ? 1 : 0.6),
            ),
            SizedBox(width: 10.w),
            Text(
              title,
              style: TextStyle(
                color: primaryColor,
                fontSize: 14.sp,
                fontWeight: value == groupValue ? FontWeight.w600 : FontWeight.w400,
                fontFamily: "cairo",
              ),
            ),
          ],
        ),
        value: value,
        groupValue: groupValue,
        onChanged: (newValue) {
          updateValue("selectedShareTypeIndex", newValue);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildCheckboxOption({
    required String title,
    required bool value,
    required Color primaryColor,
    required Color backgroundColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 24.w,
            height: 24.h,
            child: Checkbox(
              value: value,
              activeColor: primaryColor,
              checkColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
              ),
              side: BorderSide(
                color: primaryColor.withOpacity(0.3),
                width: 1.5,
              ),
              onChanged: (newValue) {
                if (title == 'withoutdiacritics'.tr()) {
                  updateValue("textWithoutDiacritics", newValue);
                } else if (title == 'addappname'.tr()) {
                  updateValue("addAppSlogan", newValue);
                } else if (title == 'addtafseer'.tr()) {
                  updateValue("addTafseer", newValue);
                }
                setState(() {});
              },
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontSize: 14.sp,
              fontFamily: "cairo",
            ),
          ),
        ],
      ),
    );
  }

  void _handleShare(BuildContext context) async {
    if (getValue("selectedShareTypeIndex") == 0) {
      // Preview as image
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (builder) => ScreenShotPreviewPage(
            index: widget.index,
            surahNumber: widget.surahNumber,
            jsonData: widget.jsonData,
            firstVerse: firstVerse,
            lastVerse: lastVerse,
          ),
        ),
      );
    } else {
      // Share as text
      List verses = [];
      for (int i = firstVerse; i <= lastVerse; i++) {
        verses.add(quran.getVerse(widget.surahNumber, i, verseEndSymbol: true));
      }

      String shareText = "";

      if (getValue("textWithoutDiacritics")) {
        shareText = "{${quran.removeDiacritics(verses.join(''))}}";
      } else {
        shareText = "{${verses.join('')}}";
      }

      shareText += " [${quran.getSurahNameArabic(widget.surahNumber)}: $firstVerse";
      if (firstVerse != lastVerse) shareText += " - $lastVerse";
      shareText += "]";

      if (getValue("addTafseer")) {
        String tafseer = "";
        for (int verseNumber = firstVerse; verseNumber <= lastVerse; verseNumber++) {
          String verseTafseer = quran.getVerseTranslation(
            widget.surahNumber,
            verseNumber,
            getValue("addTafseerValue"),
          );
          tafseer = "$tafseer $verseTafseer";
        }
        shareText += "\n\n${removeHtmlTags(tafseer)}";
      }

      if (getValue("addAppSlogan")) {
        shareText += "\n\nتطبيق غيث المسلم - faithful companion";
      }

      Share.share(shareText);
    }
  }
}
