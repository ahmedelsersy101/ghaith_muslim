import 'dart:convert';
import 'package:ghaith/main.dart';
import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/core/hadith/models/hadith_min.dart';
import 'package:ghaith/core/hadith/views/hadithdetailspage.dart';
import 'package:quran/quran.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HadithList extends StatefulWidget {
  final String locale;
  final String id;
  final String count;
  final String title;

  const HadithList({
    super.key,
    required this.locale,
    required this.id,
    required this.title,
    required this.count,
  });

  @override
  State<HadithList> createState() => _HadithListState();
}

class _HadithListState extends State<HadithList> {
  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل متغيرات الحالة لملف state/hadith_list_state.dart
  bool _isLoading = true;
  bool _isSearching = false; // 💡 متغير جديد للتحكم في حالة البحث
  List<HadithMin> _hadithes = [];
  List<HadithMin> _filteredHadithes = [];
  List<HadithMin> _tempHadithes = [];
  final TextEditingController _searchController = TextEditingController(); // 💡 كنترولر للبحث

  @override
  void initState() {
    _getHadithList();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose(); // 💡 تنظيف الكنترولر
    super.dispose();
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل جلب البيانات لملف services/hadith_data_service.dart
  Future<void> _getHadithList() async {
    _hadithes = [];

    if (widget.id == "100000") {
      await _loadAllHadiths();
    } else {
      await _loadCategoryHadiths();
    }

    _tempHadithes = _hadithes;
    setState(() => _isLoading = false);
  }

  Future<void> _loadAllHadiths() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString("hadithlist-100000-${widget.locale}");

    if (jsonData != null) {
      final data = json.decode(jsonData) as List<dynamic>;
      _addUniqueHadiths(data);
    } else {
      await _fetchHadithsFromAPI();
    }
  }

  Future<void> _loadCategoryHadiths() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString("hadithlist-${widget.id}-${widget.locale}");

    if (jsonData != null) {
      final data = json.decode(jsonData) as List<dynamic>;
      _addHadiths(data);
    } else {
      await _fetchHadithsFromAPI();
    }
  }

  void _addUniqueHadiths(List<dynamic> data) {
    for (var hadith in data) {
      if (_hadithes.indexWhere((element) => element.title == hadith["title"]) == -1) {
        _hadithes.add(HadithMin.fromJson(hadith));
      }
    }
  }

  void _addHadiths(List<dynamic> data) {
    for (var hadith in data) {
      _hadithes.add(HadithMin.fromJson(hadith));
    }
  }

  Future<void> _fetchHadithsFromAPI() async {
    try {
      Response response = await Dio().get(
          "https://hadeethenc.com/api/v1/hadeeths/list/?language=${widget.locale}&category_id=${widget.id}&per_page=699999");

      if (response.data["data"] != null) {
        for (var hadith in response.data["data"]) {
          _hadithes.add(HadithMin.fromJson(hadith));
        }
      }
    } catch (error) {
      print('Error fetching hadiths: $error');
    }
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل البحث لملف utils/hadith_search_utils.dart
  void _searchHadiths(String searchWords) {
    if (searchWords.isEmpty) {
      _hadithes = _tempHadithes;
    } else {
      _filteredHadithes = _tempHadithes
          .where((element) => removeDiacritics(element.title).contains(searchWords))
          .toList();
      _hadithes = _filteredHadithes;
    }
    setState(() {});
  }

  // 💡 دالة جديدة للتبديل بين وضع البحث
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchHadiths("");
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkModeNotifier.value ? darkSlateGray : paperBeige,
      body: _isLoading ? _buildLoadingIndicator() : _buildHadithList(),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل واجهة المستخدم لملف ui/hadith_list_view.dart
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildHadithList() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        _buildHadithItems(),
      ],
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      iconTheme: _getIconTheme(),
      backgroundColor: _getAppBarColor(),
      elevation: 0,
      centerTitle: true,
      // 💡 عرض مربع البحث في الـ title عند تفعيل البحث
      title: _isSearching ? _buildSearchField() : _buildAppBarTitle(),
      actions: [
        // 💡 زر البحث
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
          ),
        ),
      ],
    );
  }

  IconThemeData _getIconTheme() {
    return IconThemeData(
      color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
    );
  }

  Color _getAppBarColor() {
    return isDarkModeNotifier.value ? deepNavyBlack : const Color(0xffF5EFE8).withOpacity(.3);
  }

  Widget _buildAppBarTitle() {
    return Text(
      "${widget.title}- ${widget.count}",
      style: TextStyle(
        color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
        fontSize: 16.sp,
      ),
    );
  }

  // 💡 مربع البحث المبسط في الـ title
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true, // 💡 لفتح الكيبورد تلقائياً
      style: _getSearchTextStyle(),
      onChanged: _searchHadiths,
      decoration: _getSearchInputDecoration(),
    );
  }

  TextStyle _getSearchTextStyle() {
    return TextStyle(
      color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
    );
  }

  InputDecoration _getSearchInputDecoration() {
    return InputDecoration(
      hintText: 'SearchHadith'.tr(),
      border: InputBorder.none,
      hintStyle: TextStyle(
        color: isDarkModeNotifier.value ? Colors.white60 : Colors.black54,
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل عناصر القائمة لملف ui/components/hadith_list_items.dart
  Widget _buildHadithItems() {
    return SliverList.builder(
      itemCount: _hadithes.length,
      itemBuilder: (BuildContext context, int index) => _buildHadithItem(index),
    );
  }

  Widget _buildHadithItem(int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: OpenContainer(
        closedElevation: 0,
        closedColor: _getItemsoftOffWhite(),
        middleColor: _getItemsoftOffWhite(),
        transitionType: ContainerTransitionType.fadeThrough,
        transitionDuration: const Duration(milliseconds: 200),
        openBuilder: (context, action) => _buildHadithDetailsPage(index),
        closedBuilder: (context, action) => _buildHadithListItem(index),
      ),
    );
  }

  Color _getItemsoftOffWhite() {
    return isDarkModeNotifier.value ? deepNavyBlack : Colors.white.withOpacity(0.8);
  }

  Widget _buildHadithDetailsPage(int index) {
    return HadithDetailsPage(
      title: _hadithes[index].title,
      locale: context.locale.languageCode,
      id: _hadithes[index].id,
    );
  }

  Widget _buildHadithListItem(int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _getListItemColor(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildHadithTitle(index),
            _buildExpandIcon(),
          ],
        ),
      ),
    );
  }

  Color _getListItemColor() {
    return isDarkModeNotifier.value ? deepNavyBlack : const Color(0xffF5EFE8).withOpacity(.4);
  }

  Widget _buildHadithTitle(int index) {
    return Text(
      _hadithes[index].title,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16.sp,
        fontFamily: "Taha",
        color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
      ),
    );
  }

  Widget _buildExpandIcon() {
    return Icon(
      Entypo.down_open_mini,
      color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
    );
  }
}
