import 'dart:io';
import 'package:easy_container/easy_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/core/QuranPages/helpers/convertNumberToAr.dart';
import 'package:ghaith/core/QuranPages/helpers/save_image.dart';
import 'package:ghaith/core/QuranPages/helpers/translation/translationdata.dart';
import 'package:ghaith/core/QuranPages/widgets/bismallah.dart';
import 'package:ghaith/core/QuranPages/widgets/header_widget.dart';
import 'package:path_provider/path_provider.dart';
import '../helpers/share_image.dart';
import 'package:quran/quran.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart' as m;
import '../helpers/translation/get_translation_data.dart' as get_translation_data;
import 'package:ghaith/main.dart';

class ScreenShotPreviewPage extends StatefulWidget {
  final int index;
  final int surahNumber;
  final dynamic jsonData;
  final int firstVerse;
  final int lastVerse;

  const ScreenShotPreviewPage({
    super.key,
    required this.index,
    required this.surahNumber,
    required this.jsonData,
    required this.firstVerse,
    required this.lastVerse,
  });

  @override
  State<ScreenShotPreviewPage> createState() => _ScreenShotPreviewPageState();
}

class _ScreenShotPreviewPageState extends State<ScreenShotPreviewPage> {
  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل متغيرات الحالة لملف state/screenshot_state.dart
  TextAlign _alignment = TextAlign.center;
  Directory? _appDir;
  int _indexOfTheme = getValue("quranPageolorsIndex");
  double _textSize = 22.0;

  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل التهيئة لملف services/screenshot_initializer.dart
  Future<void> _initialize() async {
    _appDir = await getTemporaryDirectory();
    await _getTranslationData();
    if (mounted) setState(() {});
  }

  Future<void> _getTranslationData() async {
    if (getValue("addTafseerValue") > 1) {
      File file = File(
          "${_appDir!.path}/${translationDataList[getValue("addTafseerValue")].typeText}.json");
      String jsonData = await file.readAsString();
      setState(() {
      });
    }
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل بناء النص لملف builders/verse_text_builder.dart
  List<InlineSpan> _buildVerseSpans(int surahNumber, int firstVerseNumber, int lastVerseNumber) {
    List<InlineSpan> verseSpans = [];

    for (int verseNumber = firstVerseNumber; verseNumber <= lastVerseNumber; verseNumber++) {
      String verseText = getVerse(surahNumber, verseNumber);

      verseSpans.addAll([
        TextSpan(
          text: "$verseText ",
          style: _getVerseTextStyle(),
        ),
        TextSpan(
          locale: const Locale("ar"),
          text: " ${convertToArabicNumber(verseNumber.toString())} ",
          style: _getVerseNumberStyle(),
        ),
      ]);
    }

    return verseSpans;
  }

  TextStyle _getVerseTextStyle() {
    return TextStyle(
      color: primaryColors[_indexOfTheme],
      fontSize: _textSize.sp,
      wordSpacing: 0,
      height: 2,
      fontFamily: getValue("selectedFontFamily"),
    );
  }

  TextStyle _getVerseNumberStyle() {
    return TextStyle(
      color: secondaryColors[_indexOfTheme],
      fontSize: _textSize.sp,
      fontFamily: "KFGQPC Uthmanic Script HAFS Regular",
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل بناء التفسير لملف builders/tafseer_builder.dart
  Future<List<InlineSpan>> _buildTafseerSpans(
      int surahNumber, int firstVerseNumber, int lastVerseNumber, dynamic translatee) async {
    List<InlineSpan> tafseerSpans = [];

    tafseerSpans.add(
      TextSpan(
        text: "${translatee.typeTextInRelatedLanguage}: ",
        style: _getTafseerHeaderStyle(),
      ),
    );

    for (int verseNumber = firstVerseNumber; verseNumber <= lastVerseNumber; verseNumber++) {
      String text =
          await get_translation_data.getVerseTranslation(surahNumber, verseNumber, translatee);
      text = text.replaceAll("<p>", "\n").replaceAll("</p>", "");

      tafseerSpans.add(
        TextSpan(
          text: "$text (${convertToArabicNumber(verseNumber.toString())}) ",
          style: _getTafseerTextStyle(),
        ),
      );
    }

    return tafseerSpans;
  }

  TextStyle _getTafseerHeaderStyle() {
    return TextStyle(
      color: primaryColors[_indexOfTheme],
      fontSize: ((_textSize + 6.5) / 2).sp,
      wordSpacing: .2,
      letterSpacing: .2,
      fontFamily: "cairo",
    );
  }

  TextStyle _getTafseerTextStyle() {
    return TextStyle(
      color: primaryColors[_indexOfTheme],
      fontSize: ((_textSize + 6) / 2).sp,
      wordSpacing: .2,
      letterSpacing: .2,
      fontFamily: "cairo",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل الـ AppBar لملف ui/components/screenshot_app_bar.dart
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: isDarkModeNotifier.value ? darkModeSecondaryColor : orangeColor,
      elevation: 0,
      foregroundColor: Colors.white,
      title: Text(
        "preview".tr(),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل الجسم الرئيسي لملف ui/views/screenshot_preview_view.dart
  Widget _buildBody() {
    return Center(
      child: ListView(
        children: [
          _buildSettingsSection(),
          _buildThemeSelector(),
          SizedBox(height: 30.h),
          _buildScreenshotPreview(),
        ],
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل إعدادات المعاينة لملف ui/sections/screenshot_settings.dart
  Widget _buildSettingsSection() {
    return Column(
      children: [
        _buildSettingCheckbox(
          value: getValue("showSuraHeader"),
          onChanged: (newValue) => _updateSetting("showSuraHeader", newValue),
          label: 'showsuraheader'.tr(),
        ),
        _buildSettingCheckbox(
          value: getValue("showBottomBar"),
          onChanged: (newValue) => _updateSetting("showBottomBar", newValue),
          label: 'showbottombar'.tr(),
        ),
        _buildTafseerSettings(),
        _buildTextAlignmentSettings(),
        _buildTextSizeSlider(),
      ],
    );
  }

  Widget _buildSettingCheckbox({
    required bool value,
    required Function(bool?) onChanged,
    required String label,
  }) {
    return Row(
      children: [
        Checkbox(
          fillColor: WidgetStatePropertyAll(primaryColors[getValue("quranPageolorsIndex")]),
          checkColor: backgroundColors[getValue("quranPageolorsIndex")],
          value: value,
          onChanged: onChanged,
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16.0,
          ),
        ),
      ],
    );
  }

  void _updateSetting(String key, bool? newValue) {
    updateValue(key, newValue);
    setState(() {});
  }

  Widget _buildTafseerSettings() {
    return Column(
      children: [
        _buildSettingCheckbox(
          value: getValue("addTafseer"),
          onChanged: (newValue) => _updateSetting("addTafseer", newValue),
          label: 'addtafseer'.tr(),
        ),
        if (getValue("addTafseer") == true) _buildTafseerSelector(),
      ],
    );
  }

  Widget _buildTafseerSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: 20.w),
        Directionality(
          textDirection: m.TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: _showTafseerSelectionSheet,
              child: Container(
                width: MediaQuery.of(context).size.width * .9,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        translationDataList[getValue("addTafseerValue") ?? 0]
                            .typeTextInRelatedLanguage,
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: translationDataList[getValue("addTafseerValue") ?? 0]
                                      .typeInNativeLanguage ==
                                  "العربية"
                              ? "cairo"
                              : "roboto",
                        ),
                      ),
                      Icon(
                        FontAwesome.ellipsis,
                        size: 24.sp,
                        color: secondaryColors[_indexOfTheme],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTafseerSelectionSheet() {
  }

  Widget _buildTextAlignmentSettings() {
    return Column(
      children: [
        RadioListTile(
          title: Text("centerText".tr()),
          value: TextAlign.center,
          groupValue: _alignment,
          onChanged: (value) => setState(() => _alignment = value!),
        ),
        RadioListTile(
          title: Text("justifyText".tr()),
          value: TextAlign.justify,
          groupValue: _alignment,
          onChanged: (value) => setState(() => _alignment = value!),
        ),
      ],
    );
  }

  Widget _buildTextSizeSlider() {
    return Slider(
      label: _textSize.toString(),
      divisions: 30,
      value: _textSize,
      min: 15.0,
      max: 45.0,
      onChanged: (newSize) => setState(() => _textSize = newSize),
    );
  }

  Widget _buildThemeSelector() {
    return SizedBox(
      height: 70,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: primaryColors.length,
        itemBuilder: (context, index) => _buildThemeOption(index),
      ),
    );
  }

  Widget _buildThemeOption(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () => setState(() => _indexOfTheme = index),
        child: SizedBox(
          width: 90,
          height: 40,
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 90,
                  height: 40,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(blurRadius: 1, color: Colors.grey.withOpacity(.5)),
                    ],
                    borderRadius: BorderRadius.circular(10),
                    color: backgroundColors[index],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColors[index],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل معاينة الصورة لملف ui/components/screenshot_preview.dart
  Widget _buildScreenshotPreview() {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: primaryColors[_indexOfTheme].withOpacity(.2),
              blurRadius: 4,
              spreadRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Screenshot(
          controller: _screenshotController,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColors[_indexOfTheme],
            ),
            child: Column(
              children: [
                SizedBox(height: 10.h),
                if (getValue("showSuraHeader") == true) _buildSuraHeader(),
                SizedBox(height: widget.firstVerse == 1 ? 5.h : 10.h),
                if (_shouldShowBasmallah()) _buildBasmallah(),
                _buildVersesText(),
                if (getValue("addTafseer") == true) _buildTafseerSection(),
                if (getValue("addAppSlogan") == true) _buildAppSlogan(),
                SizedBox(height: 15.h),
                if (getValue("showBottomBar") == true) _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuraHeader() {
    return HeaderWidget(
      e: {"surah": widget.surahNumber},
      jsonData: widget.jsonData,
      indexOfTheme: _indexOfTheme,
    );
  }

  bool _shouldShowBasmallah() {
    return widget.firstVerse == 1 && widget.index != 1 && widget.index != 187;
  }

  Widget _buildBasmallah() {
    return Basmallah(index: _indexOfTheme);
  }

  Widget _buildVersesText() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0.w),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: RichText(
          textAlign: _alignment,
          textWidthBasis: TextWidthBasis.longestLine,
          locale: const Locale("ar"),
          textDirection: m.TextDirection.rtl,
          text: TextSpan(
            text: '',
            style: TextStyle(
              color: primaryColors[_indexOfTheme],
              fontSize: 20.sp,
              fontFamily: getValue("selectedFontFamily"),
            ),
            children: _buildVerseSpans(widget.surahNumber, widget.firstVerse, widget.lastVerse),
          ),
        ),
      ),
    );
  }

  Widget _buildTafseerSection() {
    return Column(
      children: [
        const Divider(),
        FutureBuilder(
          future: _buildTafseerSpans(
            widget.surahNumber,
            widget.firstVerse,
            widget.lastVerse,
            translationDataList[getValue("addTafseerValue")],
          ),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return Padding(
              padding: const EdgeInsets.all(6.0),
              child: RichText(
                textDirection: _getTafseerTextDirection(),
                text: TextSpan(children: snapshot.hasData ? snapshot.data : null),
              ),
            );
          },
        ),
      ],
    );
  }

  m.TextDirection _getTafseerTextDirection() {
    return translationDataList[getValue("addTafseerValue")].typeInNativeLanguage.toString() ==
            "العربية"
        ? m.TextDirection.rtl
        : m.TextDirection.ltr;
  }

  Widget _buildAppSlogan() {
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
              style: TextStyle(fontSize: 10.sp, color: primaryColors[_indexOfTheme]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: secondaryColors[_indexOfTheme].withOpacity(.45),
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 77.0.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "[${widget.firstVerse} - ${widget.lastVerse}]",
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: backgroundColors[_indexOfTheme].withOpacity(.6),
              ),
            ),
            Text(
              widget.jsonData[widget.surahNumber - 1]["name"],
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                fontFamily: fontFamilies[0],
                color: backgroundColors[_indexOfTheme].withOpacity(.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل شريط الأدوات السفلي لملف ui/components/screenshot_bottom_bar.dart
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: isDarkModeNotifier.value ? darkModeSecondaryColor : Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              text: "shareexternal".tr(),
              onTap: _shareScreenshot,
              width: MediaQuery.of(context).size.width * .3,
            ),
            _buildActionButton(
              text: "savetogallery".tr(),
              onTap: _saveScreenshot,
              width: MediaQuery.of(context).size.width * .3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onTap,
    required double width,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: EasyContainer(
        height: 50,
        width: width,
        onTap: onTap,
        color: orangeColor,
        child: Text(
          text,
          style: TextStyle(
            fontSize: _getButtonTextSize(),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  double _getButtonTextSize() {
    return context.locale.languageCode == "ar" ? 12.sp : 15.sp;
  }

  Future<void> _shareScreenshot() async {
    await _screenshotController.capture().then((capturedImage) => shareImage(capturedImage!));
  }

  Future<void> _saveScreenshot() async {
    await _screenshotController
        .capture()
        .then((capturedImage) => saveImageToGallery(capturedImage!));
  }
}
