import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:ghaith/main.dart';

// =============================================
// 📁 IMPORTS - يمكن نقلها لملف imports منفصل
// =============================================
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/core/azkar/data/azkar.dart';
import 'package:ghaith/core/azkar/model/dua_model.dart';
import 'package:ghaith/core/azkar/views/zikr_detailspage.dart';

// =============================================
// 🏗️ MAIN WIDGET - Azkar Home Page
// =============================================

class AzkarHomePage extends StatefulWidget {
  const AzkarHomePage({super.key});

  @override
  State<AzkarHomePage> createState() => _AzkarHomePageState();
}

// =============================================
// 🔧 STATE CLASS - Azkar Home Page Logic
// =============================================

class _AzkarHomePageState extends State<AzkarHomePage> {
  // =============================================
  // 🎛️ STATE VARIABLES
  // =============================================
  final TextEditingController _textEditingController = TextEditingController();
  List<dynamic> _filteredAzkar = azkar;

  // =============================================
  // 🔍 SEARCH METHODS - يمكن نقلها لملف service منفصل
  // =============================================

  // [CAN_BE_EXTRACTED] -> services/search_service.dart
  void _searchAzkar(String searchWords) {
    setState(() {
      if (searchWords.isEmpty) {
        _filteredAzkar = azkar;
      } else {
        _filteredAzkar = azkar.where((element) {
          final category = element["category"]?.toString() ?? "";
          return _removeDiacritics(category).contains(searchWords);
        }).toList();
      }
    });
  }

  // [CAN_BE_EXTRACTED] -> utils/text_utils.dart
  String _removeDiacritics(String text) {
    // يمكن استبدال هذا بدالة أكثر تطوراً لإزالة التشكيل إذا لزم الأمر
    return text.replaceAll(RegExp(r'[\u064B-\u065F]'), '');
  }

  // [CAN_BE_EXTRACTED] -> services/search_service.dart
  void _clearSearch() {
    _textEditingController.clear();
    _searchAzkar("");
  }

  // =============================================
  // 🧩 UI BUILD METHODS
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: _buildBackgroundDecoration(),
      child: Scaffold(
        backgroundColor: _getBackgroundColor(),
        body: CustomScrollView(
          slivers: <Widget>[
            _buildAppBar(),
            _buildAzkarList(),
          ],
        ),
      ),
    );
  }

  // =============================================
  // 🎨 UI COMPONENTS - يمكن نقلها لملف widgets منفصل
  // =============================================

  // [CAN_BE_EXTRACTED] -> widgets/background_decoration.dart
  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      image: DecorationImage(
        fit: BoxFit.contain,
        image: AssetImage("assets/images/try6.png"),
        alignment: Alignment.bottomCenter,
        opacity: .6,
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/azkar_app_bar.dart
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      iconTheme: const IconThemeData(color: Colors.white),
      backgroundColor: _getAppBarColor(),
      elevation: 0,
      title: Text(
        "azkar".tr(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.sp,
        ),
      ),
      centerTitle: true,
      expandedHeight: 100.h,
      collapsedHeight: kToolbarHeight,
      flexibleSpace: _buildFlexibleSpace(),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/search_bar.dart
  Widget _buildFlexibleSpace() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSearchField(),
          ),
          _buildClearSearchButton(),
        ],
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/search_field.dart
  Widget _buildSearchField() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      controller: _textEditingController,
      onChanged: _searchAzkar,
      decoration: InputDecoration(
        hintText: 'SearchDua'.tr(),
        hintStyle: const TextStyle(color: Colors.white),
        border: InputBorder.none,
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/clear_search_button.dart
  Widget _buildClearSearchButton() {
    if (_filteredAzkar.length == azkar.length) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: _clearSearch,
      icon: const Icon(Icons.close, color: Colors.white),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/azkar_list.dart
  SliverList _buildAzkarList() {
    return SliverList.builder(
      itemCount: _filteredAzkar.length,
      itemBuilder: (context, index) => _buildAzkarItem(index),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/azkar_item.dart
  Widget _buildAzkarItem(int index) {
    final azkarItem = _filteredAzkar[index];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0.w, vertical: 6.h),
      child: Material(
        color: _getCardColor(),
        shape: _buildCardShape(),
        child: InkWell(
          onTap: () => _onAzkarItemTap(azkarItem),
          splashColor: _getSplashColor(),
          borderRadius: BorderRadius.circular(17.0.r),
          child: _buildAzkarItemContent(azkarItem),
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/azkar_item_content.dart
  Widget _buildAzkarItemContent(dynamic azkarItem) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAzkarTitle(azkarItem),
                _buildForwardIcon(),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/azkar_title.dart
  Widget _buildAzkarTitle(dynamic azkarItem) {
    return Text(
      azkarItem["category"]?.toString() ?? "",
      style: _getAzkarTitleStyle(),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/forward_icon.dart
  Widget _buildForwardIcon() {
    return Icon(
      Icons.arrow_forward_ios,
      color: _getIconColor(),
    );
  }

  // =============================================
  // 🔧 EVENT HANDLERS
  // =============================================

  // [CAN_BE_EXTRACTED] -> services/navigation_service.dart
  void _onAzkarItemTap(dynamic azkarItem) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (builder) => ZikrPage(
          zikr: DuaModel.fromJson(azkarItem),
        ),
      ),
    );
  }

  // =============================================
  // 🎨 STYLE HELPER METHODS - يمكن نقلها لملف themes
  // =============================================

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getBackgroundColor() {
    return isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getAppBarColor() {
    return isDarkModeNotifier.value ? darkModeSecondaryColor.withOpacity(.9) : orangeColor;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getCardColor() {
    return isDarkModeNotifier.value
        ? darkModeSecondaryColor.withOpacity(.8)
        : const Color.fromARGB(255, 255, 255, 255).withOpacity(.2);
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getSplashColor() {
    return isDarkModeNotifier.value
        ? darkModeSecondaryColor.withOpacity(.5)
        : blueColor.withOpacity(.2);
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  TextStyle _getAzkarTitleStyle() {
    return TextStyle(
      color: _getTextColor(),
      fontSize: 18.sp,
    );
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getTextColor() {
    return isDarkModeNotifier.value ? Colors.white.withOpacity(.9) : Colors.black;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getIconColor() {
    return isDarkModeNotifier.value ? Colors.white.withOpacity(.9) : Colors.black;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  ShapeBorder _buildCardShape() {
    return SuperellipseShape(
      borderRadius: BorderRadius.circular(34.0.r),
    );
  }
}
