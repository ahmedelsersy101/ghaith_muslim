import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/core/hadith/views/booklistpage.dart';
import 'package:ghaith/main.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:fluttericon/mfg_labs_icons.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/core/hadith/models/category.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HadithBooksPage extends StatefulWidget {
  final String locale;

  const HadithBooksPage({super.key, required this.locale});

  @override
  State<HadithBooksPage> createState() => _HadithBooksPageState();
}

class _HadithBooksPageState extends State<HadithBooksPage> {
  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل متغيرات الحالة لملف state/hadith_books_state.dart
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _noConnection = false;

  @override
  void initState() {
    _getCategories();
    super.initState();
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل جلب الفئات لملف services/categories_service.dart
  Future<void> _getCategories() async {
    setState(() {
      _noConnection = false;
      _isLoading = true;
    });
    _categories = [];

    // // إضافة فئة "كل الأحاديث"
    // _categories.add(Category(
    //     id: "100000", title: "allHadith".tr(), hadeethsCount: "2000+", parentId: "parentId"));

    await _loadCategories();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final hasCachedCategories = prefs.getString("categories-${widget.locale}") != null;

    if (!hasCachedCategories) {
      final results = await Connectivity().checkConnectivity();
      final hasConnection = results.any((r) => r != ConnectivityResult.none);

      if (!hasConnection) {
        if (mounted) setState(() => _noConnection = true);
        return;
      }
      await _fetchCategoriesFromAPI();
    } else {
      await _loadCategoriesFromStorage(prefs);
    }
  }

  Future<void> _fetchCategoriesFromAPI() async {
    try {
      Response response = await Dio()
          .get("https://hadeethenc.com/api/v1/categories/roots/?language=${widget.locale}");

      for (var cat in response.data) {
        _categories.add(Category.fromJson(cat));
      }
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  Future<void> _loadCategoriesFromStorage(SharedPreferences prefs) async {
    final jsonData = prefs.getString("categories-${widget.locale}");

    if (jsonData != null) {
      final data = json.decode(jsonData) as List<dynamic>;
      for (var cat in data) {
        _categories.add(Category.fromJson(cat));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getsoftOffWhite(),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _noConnection
              ? _buildNoConnectionView()
              : _isLoading
                  ? _buildLoadingIndicator()
                  : _buildCategoriesList(),
    );
  }

  Widget _buildNoConnectionView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64.sp,
              color: _getTitleColor().withOpacity(0.6),
            ),
            SizedBox(height: 24.h),
            Text(
              "noInternet".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "cairo",
                fontSize: 18.sp,
                color: _getCategoryTitleColor(),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "noInternetMessage".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "cairo",
                fontSize: 14.sp,
                color: _getCategoryCountColor(),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _getCategories,
              icon: const Icon(Icons.refresh_rounded),
              label: Text("Retry".tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getAppBarColor(),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل واجهة المستخدم لملف ui/hadith_books_view.dart
  Color _getsoftOffWhite() {
    return isDarkModeNotifier.value ? darkSlateGray.withOpacity(0.4) : paperBeige;
  }

  Color _getCardColor() {
    return isDarkModeNotifier.value
        ? darkSlateGray
        : const Color.fromARGB(255, 255, 255, 255).withOpacity(.2);
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _getAppBarColor(),
      elevation: 0,
      centerTitle: true,
      iconTheme: _getIconTheme(),
      title: Text(
        "Hadith".tr(),
        style: TextStyle(
          color: _getTitleColor(),
          fontFamily: "cairo",
        ),
      ),
    );
  }

  Color _getAppBarColor() {
    return isDarkModeNotifier.value ? darkSlateGray : wineRed;
  }

  IconThemeData _getIconTheme() {
    return const IconThemeData(
      color: Colors.white,
    );
  }

  Color _getTitleColor() {
    return Colors.white;
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        color: isDarkModeNotifier.value ? darkSlateGray : paperBeige,
      ),
    );
  }

  Widget _buildCategoriesList() {
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (BuildContext context, int index) => _buildCategoryItem(index),
    );
  }

  Widget _buildCategoryItem(int index) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration:
            BoxDecoration(color: _getCardColor(), borderRadius: BorderRadius.circular(17.0.r)),
        child: InkWell(
          onTap: () => _navigateToHadithList(index),
          child: Row(
            children: [
              _buildCategoryIcon(),
              SizedBox(width: 15.w),
              _buildCategoryInfo(index),
              _buildNavigationIcon(),
              SizedBox(width: 15.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _getCategoryIconColor(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Icon(
          MfgLabs.folder_empty,
          size: 30.sp,
          color: _getCategoryIconIconColor(),
        ),
      ),
    );
  }

  Color _getCategoryIconColor() {
    return isDarkModeNotifier.value ? _getCardColor() : const Color(0xffF5EFE8).withOpacity(.9);
  }

  Color _getCategoryIconIconColor() {
    return isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87;
  }

  Widget _buildCategoryInfo(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _categories[index].title,
          style: TextStyle(
            color: _getCategoryTitleColor(),
            fontSize: 14.sp,
          ),
        ),
        Text(
          "Hadith Count: ${_categories[index].hadeethsCount}",
          style: TextStyle(
            color: _getCategoryCountColor(),
          ),
        ),
      ],
    );
  }

  Color _getCategoryTitleColor() {
    return getValue("darkMode") ? Colors.white70 : Colors.black;
  }

  Color _getCategoryCountColor() {
    return isDarkModeNotifier.value ? Colors.white : Colors.black38;
  }

  Widget _buildNavigationIcon() {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            _getNavigationIcon(),
            color: _getNavigationIconColor(),
            size: 26.sp,
          ),
        ],
      ),
    );
  }

  IconData _getNavigationIcon() {
    return context.locale.languageCode == "ar" ? Entypo.left_open : Entypo.right_open;
  }

  Color _getNavigationIconColor() {
    return getValue("darkMode") ? Colors.white70 : Colors.black;
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل التنقل لملف services/navigation_service.dart
  void _navigateToHadithList(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => HadithList(
          // 🔹 الآن HadithList معروف
          title: _categories[index].title,
          count: _categories[index].hadeethsCount,
          locale: context.locale.languageCode,
          id: _categories[index].id,
        ),
      ),
    );
  }
}
