import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/main.dart';
import 'package:ghaith/core/QuranPages/widgets/bottom_sheets/translation_selection_sheet.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/core/QuranPages/helpers/convertNumberToAr.dart';
import 'package:ghaith/core/QuranPages/helpers/translation/get_translation_data.dart';
import 'package:ghaith/core/QuranPages/helpers/translation/translationdata.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:quran/quran.dart' as quran;

class TafseerAndTranslateSheet extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final bool isVerseByVerseSelection;

  const TafseerAndTranslateSheet({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.isVerseByVerseSelection,
  });

  @override
  State<TafseerAndTranslateSheet> createState() => _TafseerAndTranslateSheetState();
}

class _TafseerAndTranslateSheetState extends State<TafseerAndTranslateSheet> {
  String data = "";
  int verseNumber = 0;
  // appDir and isDownloading are now managed by TranslationSelectionSheet

  @override
  void initState() {
    super.initState();
    getData();
    initialize();
  }

  Future<void> initialize() async {
    // No longer need to pre-initialize appDir here as it's handled by the selector
  }

  Future<void> getData() async {
    data = await getVerseTranslation(
      widget.surahNumber,
      widget.verseNumber + verseNumber,
      translationDataList[getValue("indexOfTranslationInVerseByVerse") ?? 0],
    );
    if (mounted) setState(() {});
  }

  void _navigateVerse(bool isNext) {
    final currentVerse = widget.verseNumber + verseNumber;
    final totalVerses = quran.getVerseCount(widget.surahNumber);

    if (isNext && currentVerse < totalVerses) {
      setState(() => verseNumber++);
      getData();
    } else if (!isNext && currentVerse > 1) {
      setState(() => verseNumber--);
      getData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkModeNotifier.value;
    final bgColor = isDark ? deepNavyBlack : softOffWhite;
    final textColor = isDark ? softOffWhite : darkWarmBrown;
    final accentColor = isDark ? tealBlue : deepBurgundyRed;
    final currentVerse = widget.verseNumber + verseNumber;
    final totalVerses = quran.getVerseCount(widget.surahNumber);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              children: [
                SizedBox(height: 8.h),

                // Verse Navigation Header
                _buildVerseNavigationHeader(
                  currentVerse,
                  totalVerses,
                  accentColor,
                  textColor,
                ),

                SizedBox(height: 20.h),

                // Quran Verse Card
                _buildQuranVerseCard(textColor, bgColor),

                SizedBox(height: 20.h),

                // Translation Selector
                _buildTranslationSelector(context, textColor, accentColor),

                SizedBox(height: 16.h),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: textColor.withOpacity(0.1),
                ),

                SizedBox(height: 16.h),

                // Translation Content
                _buildTranslationContent(textColor),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseNavigationHeader(
    int currentVerse,
    int totalVerses,
    Color accentColor,
    Color textColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          _buildNavigationButton(
            icon: Icons.arrow_back_ios_rounded,
            isEnabled: currentVerse > 1,
            onPressed: () => _navigateVerse(false),
            accentColor: accentColor,
          ),

          // Verse number display
          Column(
            children: [
              Text(
                "آية",
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 12.sp,
                  fontFamily: "cairo",
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.15),
                      accentColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  convertToArabicNumber(currentVerse.toString()),
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: "KFGQPC Uthmanic Script HAFS Regular",
                  ),
                ),
              ),
            ],
          ),

          // Next button
          _buildNavigationButton(
            icon: Icons.arrow_forward_ios_rounded,
            isEnabled: currentVerse < totalVerses,
            onPressed: () => _navigateVerse(true),
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onPressed,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? accentColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isEnabled ? accentColor.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: IconButton(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          icon,
          size: 18.sp,
          color: isEnabled ? accentColor : Colors.grey.withOpacity(0.3),
        ),
        padding: EdgeInsets.all(8.r),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildQuranVerseCard(Color textColor, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color:
            isDarkModeNotifier.value ? darkSlateGray.withOpacity(0.5) : paperBeige.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: textColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Decorative top ornament
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 2.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      textColor.withOpacity(0),
                      textColor.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.auto_awesome,
                size: 16.sp,
                color: textColor.withOpacity(0.4),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 40.w,
                height: 2.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      textColor.withOpacity(0.3),
                      textColor.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Quran verse text
          Text(
            quran.getVerse(
              widget.surahNumber,
              widget.verseNumber + verseNumber,
            ),
            textAlign: TextAlign.center,
            locale: const Locale("ar"),
            style: TextStyle(
              color: textColor,
              fontSize: 22.sp,
              height: 2.2,
              fontFamily: getValue("selectedFontFamily"),
              letterSpacing: 0.5,
            ),
          ),

          SizedBox(height: 16.h),

          // Decorative bottom ornament
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40.w,
                height: 2.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      textColor.withOpacity(0),
                      textColor.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.auto_awesome,
                size: 16.sp,
                color: textColor.withOpacity(0.4),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 40.w,
                height: 2.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      textColor.withOpacity(0.3),
                      textColor.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationSelector(
    BuildContext context,
    Color textColor,
    Color accentColor,
  ) {
    final selectedTranslation =
        translationDataList[getValue("indexOfTranslationInVerseByVerse") ?? 0];

    return Directionality(
      textDirection: m.TextDirection.rtl,
      child: InkWell(
        onTap: () => TranslationSelectionSheet.show(
          context,
          onSettingsChanged: () => setState(() {}),
          onTranslationSelected: getData,
        ),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.08),
                accentColor.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: accentColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
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
                  size: 20.sp,
                  color: accentColor,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الترجمة",
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 11.sp,
                        fontFamily: "cairo",
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      selectedTranslation.typeTextInRelatedLanguage,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: selectedTranslation.typeInNativeLanguage == "العربية"
                            ? "cairo"
                            : "roboto",
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 24.sp,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _showTranslationBottomSheet and _downloadTranslation are removed
  // in favor of TranslationSelectionSheet.show

  Widget _buildTranslationContent(Color textColor) {
    final selectedTranslation = translationDataList[getValue("indexOfTranslation") ?? 0];
    final isArabic = selectedTranslation.typeInNativeLanguage == "العربية";

    return Directionality(
      textDirection: isArabic ? m.TextDirection.rtl : m.TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isDarkModeNotifier.value
              ? darkSlateGray.withOpacity(0.3)
              : paperBeige.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: data.contains(">")
            ? Html(
                data: data,
                style: {
                  '*': Style(
                    fontFamily: isArabic ? 'cairo' : 'roboto',
                    fontSize: FontSize(16.sp),
                    lineHeight: const LineHeight(1.8),
                    color: textColor,
                  ),
                },
              )
            : Text(
                data,
                style: TextStyle(
                  color: textColor,
                  fontFamily: isArabic ? "cairo" : "roboto",
                  fontSize: 16.sp,
                  height: 1.8,
                ),
              ),
      ),
    );
  }
}
