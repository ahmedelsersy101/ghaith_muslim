// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:easy_container/easy_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/main.dart';
import 'package:share_plus/share_plus.dart';

// =============================================
// 📁 IMPORTS - يمكن نقلها لملف imports منفصل
// =============================================
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/core/hadith/models/hadith.dart';
import 'package:ghaith/core/hadith/views/widgets/screenshot_preview.dart';

// =============================================
// 🏗️ MAIN WIDGET - Sharing Options
// =============================================

class SharingOptions extends StatefulWidget {
  final dynamic data;
  final bool isImage;

  const SharingOptions({
    super.key,
    required this.data,
    required this.isImage,
  });

  @override
  State<SharingOptions> createState() => _SharingOptionsState();
}

// =============================================
// 🔧 STATE CLASS - Sharing Options Logic
// =============================================

class _SharingOptionsState extends State<SharingOptions> {
  // =============================================
  // 🎛️ STATE VARIABLES - خيارات المشاركة
  // =============================================
  bool _includeExplanation = false;
  bool _includeMeanings = false;
  final bool _includeArabic = true;

  // =============================================
  // 🎯 MAIN BUILD METHOD
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _buildContainerDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildSharingOptions(),
          _buildActionButton(),
          SizedBox(height: 35.h),
        ],
      ),
    );
  }

  // =============================================
  // 🧩 WIDGET COMPONENTS - يمكن نقلها لملف widgets منفصل
  // =============================================

  // [CAN_BE_EXTRACTED] -> widgets/decorations.dart
  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      color: isDarkModeNotifier.value ? deepNavyBlack : Colors.white,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/sharing_header.dart
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        widget.isImage ? "asimage".tr() : "astext".tr(),
        style: TextStyle(
            fontSize: 18.sp, color: isDarkModeNotifier.value ? Colors.white : deepNavyBlack),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/sharing_options_list.dart
  Widget _buildSharingOptions() {
    return Column(
      children: [
        // يمكن إضافة خيار اللغة العربية لاحقاً إذا لزم الأمر
        // _buildArabicOption(),
        _buildExplanationOption(),
        _buildMeaningsOption(),
      ],
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/switch_option.dart
  Widget _buildExplanationOption() {
    return SwitchListTile(
      title: Text(
        "explanation".tr(),
        style: TextStyle(color: isDarkModeNotifier.value ? Colors.white : deepNavyBlack),
      ),
      value: _includeExplanation,
      onChanged: _onExplanationChanged,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/switch_option.dart
  Widget _buildMeaningsOption() {
    return SwitchListTile(
      title: Text("meanings".tr(),
          style: TextStyle(color: isDarkModeNotifier.value ? Colors.white : deepNavyBlack)),
      value: _includeMeanings,
      onChanged: _onMeaningsChanged,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/action_button.dart
  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: EasyContainer(
        onTap: _handleSharingAction,
        borderRadius: 22,
        color: wineRed,
        child: Text(
          widget.isImage ? "preview".tr() : "share".tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),
    );
  }

  // =============================================
  // 🔧 EVENT HANDLERS - معالجات الأحداث
  // =============================================

  void _onExplanationChanged(bool value) {
    setState(() {
      _includeExplanation = value;
    });
  }

  void _onMeaningsChanged(bool value) {
    setState(() {
      _includeMeanings = value;
    });
  }

  // =============================================
  // 🚀 SHARING LOGIC - منطق المشاركة
  // =============================================

  // [CAN_BE_EXTRACTED] -> services/sharing_service.dart
  void _handleSharingAction() {
    if (widget.isImage) {
      _navigateToImagePreview();
    } else {
      _shareAsText();
    }
  }

  // [CAN_BE_EXTRACTED] -> services/sharing_service.dart
  void _navigateToImagePreview() {
    final hadithAr = widget.data["hadithAr"] as Hadith;
    final hadithOtherLanguage = widget.data["hadithOtherLanguage"];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => HadithScreenShotPreviewPage(
          hadithAr: hadithAr,
          addExplanation: _includeExplanation,
          addMeanings: _includeMeanings,
          hadithOtherLanguage: hadithOtherLanguage,
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> services/sharing_service.dart
  void _shareAsText() {
    final shareText = _buildShareText();
    Share.share(shareText);
  }

  // [CAN_BE_EXTRACTED] -> services/text_builder_service.dart
  String _buildShareText() {
    final hadithAr = widget.data["hadithAr"] as Hadith;
    final hadithOtherLanguage = widget.data["hadithOtherLanguage"];

    String arabicText = _buildArabicText(hadithAr);
    String otherLanguageText = _buildOtherLanguageText(hadithOtherLanguage);

    return _combineTexts(arabicText, otherLanguageText);
  }

  // [CAN_BE_EXTRACTED] -> services/text_builder_service.dart
  String _buildArabicText(Hadith hadithAr) {
    if (!_includeArabic) return "";

    String text = "${hadithAr.hadeeth}\n" '[${hadithAr.attribution}] - [${hadithAr.grade}]';

    if (_includeExplanation) {
      text = "$text\n\nشرح الحديث: \n${hadithAr.explanation}";
    }

    if (_includeMeanings && hadithAr.wordsMeanings.isNotEmpty) {
      text = "$text\nمعاني الكلمات :\n${_buildWordsMeanings(hadithAr)}";
    }

    return text;
  }

  // [CAN_BE_EXTRACTED] -> services/text_builder_service.dart
  String _buildOtherLanguageText(dynamic hadithOtherLanguage) {
    if (context.locale.languageCode == "ar") return "";

    String text = "";

    if (_includeArabic) {
      text = "${hadithOtherLanguage["hadeeth"]}\n"
          '${hadithOtherLanguage["attribution"]} - [${hadithOtherLanguage["grade"]}]';
    }

    if (_includeExplanation) {
      final explanationText = _includeArabic
          ? "/n Explanation :${hadithOtherLanguage["explanation"]}"
          : "Explanation :${hadithOtherLanguage["explanation"]}";
      text = "$text$explanationText";
    }

    return text;
  }

  // [CAN_BE_EXTRACTED] -> services/text_builder_service.dart
  String _buildWordsMeanings(Hadith hadithAr) {
    final wordsMeanings = StringBuffer();

    for (var i = 0; i < hadithAr.wordsMeanings.length; i++) {
      wordsMeanings.write(
        "- ${hadithAr.wordsMeanings[i].word}:${hadithAr.wordsMeanings[i].meaning}",
      );

      if (i < hadithAr.wordsMeanings.length - 1) {
        wordsMeanings.write("\n");
      }
    }

    return wordsMeanings.toString();
  }

  // [CAN_BE_EXTRACTED] -> services/text_builder_service.dart
  String _combineTexts(String arabicText, String otherLanguageText) {
    if (arabicText.isNotEmpty && otherLanguageText.isNotEmpty) {
      return "$arabicText\n\n$otherLanguageText";
    } else if (arabicText.isNotEmpty) {
      return arabicText;
    } else {
      return otherLanguageText;
    }
  }
}
