import 'package:animate_do/animate_do.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:ghaith/main.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/core/hadith/models/hadith.dart';
import 'package:ghaith/core/hadith/views/widgets/sharing_options.dart';
import 'package:flutter/services.dart';

class HadithDetailsPage extends StatefulWidget {
  final String id;
  final String locale;
  final String title;

  const HadithDetailsPage({
    super.key,
    required this.locale,
    required this.id,
    required this.title,
  });
  @override
  State<HadithDetailsPage> createState() => _HadithDetailsPageState();
}

class _HadithDetailsPageState extends State<HadithDetailsPage> {
  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل متغيرات الحالة لملف state/hadith_details_state.dart
  bool _isLoading = true;
  bool _noConnection = false;
  bool _loadError = false;
  late Hadith _hadithAr;
  dynamic _hadithOtherLanguage;

  // 🔹 متغيرات التوسيع/الطي
  bool _isExpandedExplanation = false;
  bool _isExpandedWords = false;
  bool _isExpandedHints = false;
  bool _isExpandedReference = false;

  @override
  void initState() {
    super.initState();
    _getHadithData();
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل جلب البيانات لملف services/hadith_details_service.dart
  Future<void> _getHadithData() async {
    if (!mounted) return;

    setState(() {
      _noConnection = false;
      _loadError = false;
      _isLoading = true;
    });

    // 💡 التحقق من الاتصال بالإنترنت
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);

    if (!hasConnection) {
      if (mounted) {
        setState(() {
          _noConnection = true;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // 💡 جلب البيانات من الـ API
      final responses = await Future.wait([
        Dio().get("https://hadeethenc.com/api/v1/hadeeths/one/?language=ar&id=${widget.id}"),
        Dio().get(
            "https://hadeethenc.com/api/v1/hadeeths/one/?language=${widget.locale}&id=${widget.id}"),
      ]);

      _hadithAr = Hadith.fromJson(responses[0].data);
      _hadithOtherLanguage = responses[1].data;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (error) {
      print('Error loading hadith: $error');
      if (mounted) {
        setState(() {
          _loadError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _getBackgroundDecoration(),
      child: Container(
        decoration: _getOverlayDecoration(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(),
          body: _buildBody(),
        ),
      ),
    );
  }

  // 💡 دالة لبناء الـ body بناءً على الحالة
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_noConnection || _loadError) {
      return _buildErrorView();
    }

    return _buildHadithContent();
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل الديكور والخلفية لملف ui/decoration/hadith_background.dart
  BoxDecoration _getBackgroundDecoration() {
    return BoxDecoration(
      color: isDarkModeNotifier.value ? Colors.black.withOpacity(.87) : Colors.white,
      image: const DecorationImage(
        image: AssetImage("assets/images/mosquepnggold.png"),
        opacity: .3,
        alignment: Alignment.bottomCenter,
      ),
    );
  }

  BoxDecoration _getOverlayDecoration() {
    return const BoxDecoration(
      color: Colors.transparent,
      image: DecorationImage(
        image: AssetImage("assets/images/background.png"),
        fit: BoxFit.fill,
        opacity: .2,
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل الـ AppBar لملف ui/components/hadith_app_bar.dart
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      iconTheme: _getAppBarIconTheme(),
      elevation: 0,
      centerTitle: true,
      title: Text(
        widget.title,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : const Color(0xffA28858),
        ),
      ),
    );
  }

  IconThemeData _getAppBarIconTheme() {
    return IconThemeData(
      color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
    );
  }

  // 💡 مؤشر التحميل المحسّن
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // دائرة التحميل
          CircularProgressIndicator(
            color: isDarkModeNotifier.value ? orangeColor : orangeColor,
            strokeWidth: 3,
          ),
          SizedBox(height: 24.h),
          // نص التحميل
          FadeIn(
            duration: const Duration(milliseconds: 800),
            child: Text(
              "loadingHadith".tr(),
              style: TextStyle(
                fontFamily: "cairo",
                fontSize: 16.sp,
                color: isDarkModeNotifier.value ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          // رسالة انتظار
          FadeIn(
            delay: const Duration(milliseconds: 400),
            duration: const Duration(milliseconds: 800),
            child: Text(
              "pleaseWait".tr(),
              style: TextStyle(
                fontFamily: "cairo",
                fontSize: 14.sp,
                color: isDarkModeNotifier.value ? Colors.white54 : Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final isNoConnection = _noConnection;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة الخطأ مع أنيميشن
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Icon(
                isNoConnection ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
                size: 64.sp,
                color: (isDarkModeNotifier.value ? Colors.white : Colors.black87).withOpacity(0.6),
              ),
            ),
            SizedBox(height: 24.h),
            // عنوان الخطأ
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 600),
              child: Text(
                isNoConnection ? "noInternet".tr() : "loadError".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "cairo",
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkModeNotifier.value ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // رسالة الخطأ
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 600),
              child: Text(
                isNoConnection ? "noInternetMessage".tr() : "loadErrorMessage".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "cairo",
                  fontSize: 14.sp,
                  color: isDarkModeNotifier.value ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
            SizedBox(height: 24.h),
            // زر إعادة المحاولة
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 600),
              child: ElevatedButton.icon(
                onPressed: _getHadithData,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  "Retry".tr(),
                  style: const TextStyle(
                    fontFamily: "cairo",
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل محتوى الحديث لملف ui/views/hadith_content_view.dart
  Widget _buildHadithContent() {
    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          SizedBox(height: 8.h),
          _buildArabicHadithSection(),
          _buildExplanationSection(),
          _buildWordsMeaningsSection(),
          _buildHintsSection(),
          _buildReferenceSection(),
          SizedBox(height: 8.h),
          _buildSharingButtons(),
          if (widget.locale != "ar") _buildTranslationSection(),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل أقسام الحديث لملف ui/sections/hadith_sections.dart
  Widget _buildArabicHadithSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: Text(
              _hadithAr.hadeeth,
              textDirection: m.TextDirection.rtl,
              locale: const Locale("ar"),
              textAlign: TextAlign.right,
              style: _getHadithTextStyle(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, right: 12),
            child: Text(
              '[${_hadithAr.attribution}] - [${_hadithAr.grade}]',
              textDirection: m.TextDirection.rtl,
              locale: const Locale("ar"),
              textAlign: TextAlign.right,
              style: _getSecondaryTextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationSection() {
    return _buildExpandableSection(
      isExpanded: _isExpandedExplanation,
      onTap: () => setState(() => _isExpandedExplanation = !_isExpandedExplanation),
      collapsedText: 'شرح الحديث...',
      expandedText: "الشرح: \n${_hadithAr.explanation}",
    );
  }

  Widget _buildWordsMeaningsSection() {
    return _buildExpandableListSection(
      isExpanded: _isExpandedWords,
      onTap: () => setState(() => _isExpandedWords = !_isExpandedWords),
      collapsedText: 'معاني الكلمات...',
      title: 'معاني الكلمات:',
      items: _hadithAr.wordsMeanings,
      builder: (item) => "- ${item.word}: ${item.meaning}",
    );
  }

  Widget _buildHintsSection() {
    return _buildExpandableListSection(
      isExpanded: _isExpandedHints,
      onTap: () => setState(() => _isExpandedHints = !_isExpandedHints),
      collapsedText: 'الفوائد من الحديث...',
      title: 'الفوائد:',
      items: _hadithAr.hints.asMap().entries.toList(),
      builder: (entry) => "${entry.key + 1}- ${entry.value}",
    );
  }

  Widget _buildReferenceSection() {
    return _buildExpandableSection(
      isExpanded: _isExpandedReference,
      onTap: () => setState(() => _isExpandedReference = !_isExpandedReference),
      collapsedText: 'الإسناد...',
      expandedText: "إسناده: \n${_hadithAr.reference}",
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل الأقسام القابلة للتوسيع لملف ui/components/expandable_section.dart
  Widget _buildExpandableSection({
    required bool isExpanded,
    required VoidCallback onTap,
    required String collapsedText,
    required String expandedText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4.0, right: 12),
            child: FadeIn(
              child: Text(
                isExpanded ? expandedText : collapsedText,
                textDirection: m.TextDirection.rtl,
                locale: const Locale("ar"),
                textAlign: TextAlign.right,
                style: _getExpandableTextStyle(isExpanded),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableListSection<T>({
    required bool isExpanded,
    required VoidCallback onTap,
    required String collapsedText,
    required String title,
    required List<T> items,
    required String Function(T) builder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        InkWell(
          onTap: onTap,
          child: isExpanded
              ? FadeIn(child: _buildExpandedListSection(title, items, builder))
              : FadeIn(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0, right: 12),
                    child: Text(
                      collapsedText,
                      textDirection: m.TextDirection.rtl,
                      locale: const Locale("ar"),
                      textAlign: TextAlign.right,
                      style: _getExpandableTextStyle(false),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildExpandedListSection<T>(String title, List<T> items, String Function(T) builder) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0, right: 12),
          child: Directionality(
            textDirection: m.TextDirection.rtl,
            child: Row(
              children: [
                Text(
                  title,
                  textDirection: m.TextDirection.rtl,
                  locale: const Locale("ar"),
                  textAlign: TextAlign.right,
                  style: _getExpandableTextStyle(true),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0, right: 12),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) => Text(
              builder(items[index]),
              textDirection: m.TextDirection.rtl,
              locale: const Locale("ar"),
              textAlign: TextAlign.right,
              style: _getExpandableTextStyle(true),
            ),
          ),
        ),
      ],
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل أزرار المشاركة لملف ui/components/hadith_sharing_buttons.dart
  Widget _buildSharingButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, right: 12),
      child: Directionality(
        textDirection: m.TextDirection.rtl,
        child: Row(
          children: [
            _buildCopyButton(),
            SizedBox(width: 10.w),
            _buildSharingButton(),
            SizedBox(width: 10.w),
          ],
        ),
      ),
    );
  }

  Widget _buildSharingButton() {
    return InkWell(
      onTap: () => _showSharingOptions(true),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xffF5EFE8).withOpacity(.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Icon(
              Icons.share,
              color: Colors.black87,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyButton() {
    return InkWell(
      onTap: () async {
        final arabicText = _hadithAr.hadeeth;
        final otherLangText = widget.locale != "ar" ? "\n\n${_hadithOtherLanguage["hadeeth"]}" : "";
        final textToCopy = "$arabicText$otherLangText";

        await Clipboard.setData(ClipboardData(text: textToCopy));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ تم نسخ الحديث بنجاح'),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(12),
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xffF5EFE8).withOpacity(.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Icon(
              Icons.copy,
              color: Colors.black87,
              size: 24.sp,
            ),
          ),
        ),
      ),
    );
  }

  void _showSharingOptions(bool isImage) {
    showModalBottomSheet(
      context: context,
      builder: (builder) => SharingOptions(
        isImage: isImage,
        data: {
          "hadithAr": _hadithAr,
          "hadithOtherLanguage": _hadithOtherLanguage,
        },
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل قسم الترجمة لملف ui/sections/translation_section.dart
  Widget _buildTranslationSection() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 400),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
            child: Text(
              _hadithOtherLanguage["hadeeth"],
              style: _getTranslationTextStyle(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, left: 12),
            child: Text(
              '${_hadithOtherLanguage["attribution"]} - [${_hadithOtherLanguage["grade"]}]',
              style: _getTranslationSecondaryStyle(),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل الأنماط لملف ui/styles/hadith_text_styles.dart
  TextStyle _getHadithTextStyle() {
    return TextStyle(
      color: isDarkModeNotifier.value ? Colors.white : Colors.black87,
      fontFamily: 'Taha',
      fontSize: 16.sp,
      height: 1.8,
    );
  }

  TextStyle _getSecondaryTextStyle() {
    return TextStyle(
      color: isDarkModeNotifier.value ? Colors.white.withOpacity(.45) : Colors.black45,
      fontFamily: 'Taha',
      fontSize: 16.sp,
    );
  }

  TextStyle _getExpandableTextStyle(bool isExpanded) {
    return TextStyle(
      color: isExpanded
          ? (isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87)
          : (isDarkModeNotifier.value ? orangeColor : const Color(0xffA28858)),
      fontFamily: 'Taha',
      fontSize: 16.sp,
    );
  }

  TextStyle _getTranslationTextStyle() {
    return TextStyle(
      color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
      fontSize: 16.sp,
      fontFamily: 'roboto',
    );
  }

  TextStyle _getTranslationSecondaryStyle() {
    return TextStyle(
      color: isDarkModeNotifier.value ? Colors.white.withOpacity(.45) : Colors.black45,
      fontSize: 16.sp,
      fontFamily: 'roboto',
    );
  }
}
