import 'package:easy_container/easy_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/main.dart';
import 'package:screenshot/screenshot.dart';

// =============================================
// 📁 IMPORTS - يمكن نقلها لملف imports منفصل
// =============================================
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/core/QuranPages/helpers/save_image.dart';
import 'package:ghaith/core/QuranPages/helpers/share_image.dart';
import 'package:ghaith/core/hadith/models/hadith.dart';

// =============================================
// 🏗️ MAIN WIDGET - Hadith ScreenShot Preview
// =============================================

class HadithScreenShotPreviewPage extends StatefulWidget {
  final Hadith hadithAr;
  final dynamic hadithOtherLanguage;
  final bool addMeanings;
  final bool addExplanation;

  const HadithScreenShotPreviewPage({
    super.key,
    required this.hadithAr,
    required this.addExplanation,
    required this.addMeanings,
    required this.hadithOtherLanguage,
  });

  @override
  State<HadithScreenShotPreviewPage> createState() => _ScreenShotPreviewPageState();
}

// =============================================
// 🔧 STATE CLASS - ScreenShot Preview Logic
// =============================================

class _ScreenShotPreviewPageState extends State<HadithScreenShotPreviewPage> {
  // =============================================
  // 🎛️ STATE VARIABLES - يمكن نقلها لملف state management
  // =============================================
  final ScreenshotController screenshotController = ScreenshotController();
  double textSize = 16;
  bool addAppSlogan = true;
  bool isShooting = false;
  final int indexOfTheme = getValue("quranPageolorsIndex");

  // =============================================
  // 🎨 UI CONSTANTS - يمكن نقلها لملف constants أو themes
  // =============================================

  // [CAN_BE_EXTRACTED_CONSTANTS] -> app_constants.dart
  static const Color _charcoalDarkGrayDark = Color(0xff555555);
  static const Color _deepBurgundyRed = Color(0xffAE8422);
  static const Color _appNameColor = Color(0xffA28858);
  static const String _arabicFont = 'Taha';
  static const String _secondaryArabicFont = 'Amiri';
  static const String _englishFont = 'roboto';

  // =============================================
  // 🖼️ PREVIEW WIDGET BUILD METHOD
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // =============================================
  // 🧩 WIDGET COMPONENTS - يمكن نقلها لملف widgets منفصل
  // =============================================

  // [CAN_BE_EXTRACTED] -> widgets/app_bar_widget.dart
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: isDarkModeNotifier.value ? deepNavyBlack : wineRed,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.white,
      title: Text(
        "preview".tr(),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/preview_body.dart
  Widget _buildBody() {
    return Center(
      child: ListView(
        children: [
          _buildAppSloganToggle(),
          _buildTextSizeSlider(),
          _buildPreviewContainer(),
        ],
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/toggle_switch.dart
  Widget _buildAppSloganToggle() {
    return Row(
      children: [
        Checkbox(
          fillColor: WidgetStatePropertyAll(darkWarmBrowns[indexOfTheme]),
          checkColor: softOffWhites[indexOfTheme],
          value: addAppSlogan,
          onChanged: (newValue) {
            setState(() {
              addAppSlogan = !addAppSlogan;
            });
          },
        ),
        Text(
          'addappname'.tr(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16.0,
          ),
        ),
      ],
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/slider_widget.dart
  Widget _buildTextSizeSlider() {
    return Slider(
      label: textSize.toString(),
      divisions: 30,
      value: textSize,
      min: 10.0,
      max: 45.0,
      onChanged: (newSize) {
        setState(() {
          textSize = newSize;
        });
      },
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/preview_container.dart
  Widget _buildPreviewContainer() {
    return Container(
      decoration: _buildContainerShadow(),
      child: Screenshot(
        controller: screenshotController,
        child: Container(
          decoration: _buildBackgroundDecoration(),
          child: _buildPreviewContent(),
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/decorations.dart
  BoxDecoration _buildContainerShadow() {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: darkWarmBrowns[indexOfTheme].withOpacity(.2),
          blurRadius: 4,
          spreadRadius: 4,
          offset: const Offset(0, 2),
        )
      ],
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/decorations.dart
  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      color: Colors.white,
      image: DecorationImage(
        image: AssetImage("assets/images/mosquepnggold.png"),
        opacity: .1,
        alignment: Alignment.bottomCenter,
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/preview_content.dart
  Widget _buildPreviewContent() {
    return Container(
      decoration: _buildOverlayDecoration(),
      child: Column(
        children: [
          SizedBox(height: 10.h),
          _buildHadithText(),
          // _buildHadithMetadata(),
          if (widget.addExplanation) _buildExplanation(),
          SizedBox(height: 10.h),
          if (widget.addMeanings) _buildWordMeanings(),
          if (_shouldShowTranslation()) _buildTranslation(),
          _buildAppSlogan(),
          SizedBox(height: 15.h),
        ],
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/decorations.dart
  BoxDecoration _buildOverlayDecoration() {
    return const BoxDecoration(
      color: Colors.transparent,
      image: DecorationImage(
        image: AssetImage("assets/images/try6.png"),
        fit: BoxFit.fill,
        opacity: .25,
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/hadith_text.dart
  Widget _buildHadithText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Text(
        widget.hadithAr.hadeeth,
        textDirection: m.TextDirection.rtl,
        locale: const Locale("ar"),
        textAlign: TextAlign.right,
        style: TextStyle(
          color: _charcoalDarkGrayDark,
          fontFamily: _arabicFont,
          fontSize: textSize.sp,
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/hadith_metadata.dart
  // Widget _buildHadithMetadata() {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 4.0, right: 12),
  //     child: Directionality(
  //       textDirection: m.TextDirection.rtl,
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.start,
  //         children: [
  //           Text(
  //             '[${widget.hadithAr.attribution}] - [${widget.hadithAr.grade}]',
  //             textDirection: m.TextDirection.rtl,
  //             locale: const Locale("ar"),
  //             textAlign: TextAlign.right,
  //             style: TextStyle(
  //               color: _deepBurgundyRed,
  //               fontSize: textSize.sp,
  //               fontFamily: _arabicFont,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // [CAN_BE_EXTRACTED] -> widgets/explanation_widget.dart
  Widget _buildExplanation() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, right: 12),
      child: Text(
        "الشرح: \n${widget.hadithAr.explanation}",
        textDirection: m.TextDirection.rtl,
        locale: const Locale("ar"),
        textAlign: TextAlign.right,
        style: TextStyle(
          color: Colors.black87,
          fontSize: textSize.sp,
          fontFamily: _arabicFont,
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/word_meanings.dart
  Widget _buildWordMeanings() {
    return Column(
      children: [
        if (widget.hadithAr.wordsMeanings.isNotEmpty) _buildWordMeaningsHeader(),
        _buildWordMeaningsList(),
      ],
    );
  }

  Widget _buildWordMeaningsHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, right: 12),
      child: Directionality(
        textDirection: m.TextDirection.rtl,
        child: Row(
          children: [
            Text(
              'معاني الكلمات:',
              textDirection: m.TextDirection.rtl,
              locale: const Locale("ar"),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.black87,
                fontSize: textSize.sp,
                fontFamily: _secondaryArabicFont,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordMeaningsList() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, right: 12),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.hadithAr.wordsMeanings.length,
        itemBuilder: (c, i) => Text(
          "- ${widget.hadithAr.wordsMeanings[i].word}:${widget.hadithAr.wordsMeanings[i].meaning}",
          textDirection: m.TextDirection.rtl,
          locale: const Locale("ar"),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.black87,
            fontSize: textSize.sp,
            fontFamily: _secondaryArabicFont,
          ),
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/translation_widget.dart
  Widget _buildTranslation() {
    return Column(
      children: [
        _buildTranslationText(),
        _buildTranslationMetadata(),
      ],
    );
  }

  Widget _buildTranslationText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Text(
        widget.hadithOtherLanguage["hadeeth"],
        style: TextStyle(
          color: _charcoalDarkGrayDark,
          fontSize: 16.sp,
          fontFamily: _englishFont,
        ),
      ),
    );
  }

  Widget _buildTranslationMetadata() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 12),
      child: Row(
        children: [
          Text(
            '${widget.hadithOtherLanguage["attribution"]} - [${widget.hadithOtherLanguage["grade"]}]',
            style: TextStyle(
              color: _deepBurgundyRed,
              fontSize: 16.sp,
              fontFamily: _englishFont,
            ),
          ),
        ],
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/app_slogan.dart
  Widget _buildAppSlogan() {
    if (!addAppSlogan) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(height: 15.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: const AssetImage("assets/images/ghaith.png"),
              height: 25.h,
            ),
            SizedBox(width: 6.w),
            Text(
              "تطبيق غيث المسلم",
              style: TextStyle(
                fontSize: 10.sp,
                color: _appNameColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/bottom_navigation.dart
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: _buildBottomNavDecoration(),
      child: Padding(
        padding: const EdgeInsets.only(left: 25.0, right: 25, bottom: 10, top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildShareButton(),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/decorations.dart
  BoxDecoration _buildBottomNavDecoration() {
    return BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: darkWarmBrowns[getValue("quranPageolorsIndex")].withOpacity(.4),
          blurRadius: 1,
          spreadRadius: 1,
          offset: const Offset(1, 0),
        )
      ],
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/action_buttons.dart
  Widget _buildShareButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: EasyContainer(
        height: 50,
        width: MediaQuery.of(context).size.width * .3,
        onTap: _shareScreenshot,
        color: darkSlateGray,
        child: Text(
          "shareexternal".tr(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/action_buttons.dart
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: EasyContainer(
        height: 50,
        width: MediaQuery.of(context).size.width * .3,
        onTap: _saveScreenshot,
        color: darkSlateGray,
        child: Text(
          "savetogallery".tr(),
          style: TextStyle(
            fontSize: context.locale.languageCode == "ar" ? 12.sp : 15.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // =============================================
  // 🔧 HELPER METHODS - يمكن نقلها لملف service منفصل
  // =============================================

  // [CAN_BE_EXTRACTED] -> services/screenshot_service.dart
  Future<void> _shareScreenshot() async {
    await screenshotController.capture().then((capturedImage) => shareImage(capturedImage!));
  }

  // [CAN_BE_EXTRACTED] -> services/screenshot_service.dart
  Future<void> _saveScreenshot() async {
    await screenshotController
        .capture()
        .then((capturedImage) => saveImageToGallery(capturedImage!));
  }

  bool _shouldShowTranslation() {
    return context.locale.languageCode != "ar";
  }
}
