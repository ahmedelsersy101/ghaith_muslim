// ignore_for_file: prefer_single_quotes, unused_field
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghaith/blocs/quran_page_player_bloc.dart';
import 'package:ghaith/main.dart';
import 'dart:convert';
import 'package:easy_container/easy_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/core/QuranPages/views/quranDetailsPage.dart';
import 'package:ghaith/core/widgets/hizb_quarter_circle.dart';
import 'package:quran/quran.dart' as quran;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:group_list_view/group_list_view.dart';
import 'package:flutter/material.dart' as m;
import '../helpers/convertNumberToAr.dart';
import 'package:string_validator/string_validator.dart';

class SurahListPage extends StatefulWidget {
  final dynamic jsonData;
  final dynamic quarterjsonData;

  const SurahListPage({Key? key, required this.jsonData, required this.quarterjsonData})
      : super(key: key);

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل متغيرات الحالة لملف state/surah_list_state.dart
  bool isLoading = true;
  final TextEditingController textEditingController = TextEditingController();
  String searchQuery = "";
  dynamic filteredData;
  dynamic ayatFiltered;
  int _currentIndex = 0;
  final ItemScrollController _juzScrollController = ItemScrollController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  List<int> pageNumbers = [];
  List<dynamic> bookmarks = [];
  Set<String> starredVerses = {};
  int juzNumberLastRead = 0;

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل الـ tabs لملف constants/app_constants.dart
  final List<Tab> tabs = <Tab>[
    Tab(text: 'surah'.tr()),
    Tab(text: 'juz'.tr()),
    Tab(text: 'quarter'.tr()),
  ];

  @override
  void initState() {
    _initializeData();
    super.initState();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل التهيئة لملف services/surah_list_initializer.dart
  void _initializeData() {
    getStarredVerse();
    fetchBookmarks();
    addFilteredData();
    if (getValue("lastRead") != "non") {
      getJuzNumber();
    }
  }

  Future<void> getJuzNumber() async {
    if (getValue("lastRead") != "non") {
      juzNumberLastRead = quran.getJuzNumber(quran.getPageData(getValue("lastRead"))[0]["surah"],
          quran.getPageData(getValue("lastRead"))[0]["start"]);
      setState(() {});
    }
  }

  void fetchBookmarks() {
    bookmarks = json.decode(getValue("bookmarks"));
    setState(() {});
  }

  Future<void> getStarredVerse() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString("starredVerses");

    if (savedData != null) {
      starredVerses = Set<String>.from(json.decode(savedData));
    }
    setState(() {});
  }

  Future<void> addFilteredData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      filteredData = widget.jsonData;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: KeyboardDismissOnTap(
        dismissOnCapturedTaps: true,
        child: Container(
          decoration: BoxDecoration(
              color: isDarkModeNotifier.value ? quranPagesColorDark : backgroundColor),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: isDarkModeNotifier.value ? quranPagesColorDark : backgroundColor,
            endDrawer: SafeArea(child: _buildBookmarksDrawer(context)),
            key: scaffoldKey,
            appBar: _buildAppBar(context),
            body: _buildTabBarView(context),
          ),
        ),
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل الـ AppBar لملف ui/components/surah_list_app_bar.dart
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      actions: [_buildBookmarkButton(context)],
      leading: _buildBackButton(),
      bottom: _buildTabBar(),
      elevation: 0,
      centerTitle: true,
      backgroundColor: isDarkModeNotifier.value ? darkModeSecondaryColor : orangeColor,
      title: Text(
        "alQuran".tr(),
        style: TextStyle(color: Colors.white, fontSize: 20.sp),
      ),
    );
  }

  Widget _buildBookmarkButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0.w, vertical: 8.h),
      child: Builder(builder: (context) {
        return IconButton(
          onPressed: () => Scaffold.of(context).openEndDrawer(),
          icon: const Icon(Iconsax.bookmark, color: backgroundColor),
        );
      }),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 8.h),
      child: IconButton(
        icon: Icon(Icons.arrow_back_ios, size: 20.sp, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  PreferredSize _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TabBar(
          indicatorPadding: EdgeInsets.symmetric(horizontal: 35.w),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          indicatorWeight: 4,
          tabs: tabs,
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) getJuzNumber();
          },
        ),
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل الـ TabBarView لملف ui/tabs/surah_tab_view.dart
  Widget _buildTabBarView(BuildContext context) {
    return TabBarView(
      children: [
        _buildSurahTab(context),
        _buildJuzTab(),
        _buildQuarterTab(),
      ],
    );
  }

  Widget _buildSurahTab(BuildContext context) {
    return SafeArea(
      child: Container(
        color: isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight,
        child: Column(
          children: [
            if (getValue("lastRead") != "non") _buildLastReadSection(),
            _buildSearchSection(),
            _buildSurahList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: EasyContainer(
        color: isDarkModeNotifier.value ? darkPrimaryColor : orangeColor,
        height: 60.h,
        padding: 12,
        margin: 0,
        borderRadius: 15.r,
        onTap: _navigateToLastRead,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("lastRead".tr(), style: const TextStyle(color: Colors.white)),
              _buildLastReadInfo(),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastReadInfo() {
    final pageData = quran.getPageData(getValue("lastRead"))[0];
    final surahNumber = pageData["surah"];
    final pageNumber = getValue("lastRead");

    final surahName = context.locale.languageCode == "ar"
        ? quran.getSurahNameArabic(surahNumber)
        : quran.getSurahName(surahNumber);

    return Text("$surahName - $pageNumber", style: const TextStyle(color: Colors.white));
  }

  void _navigateToLastRead() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (builder) => QuranDetailsPage(
          shouldHighlightSura: false,
          pageNumber: getValue("lastRead"),
          jsonData: widget.jsonData,
          shouldHighlightText: false,
          highlightVerse: "",
          quarterJsonData: widget.quarterjsonData,
        ),
      ),
    );
    setState(() {});
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0.w),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  textDirection: m.TextDirection.rtl,
                  controller: textEditingController,
                  onChanged: _onSearchTextChanged,
                  style: _searchTextStyle(),
                  cursorColor: Colors.black,
                  decoration: _buildSearchInputDecoration(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildSearchInputDecoration() {
    return InputDecoration(
      hintText: 'searchQuran'.tr(),
      suffixIcon: _buildSearchSuffixIcon(),
      hintStyle: _searchHintStyle(),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.black, width: 1.w),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: primaryColor, width: 1.w),
      ),
    );
  }

  Widget _buildSearchSuffixIcon() {
    return GestureDetector(
      onTap: _clearSearch,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: searchQuery.isNotEmpty
            ? Icon(Icons.close, color: _getSearchIconColor())
            : Icon(FontAwesome.search, color: _getSearchIconColor()),
      ),
    );
  }

  Color _getSearchIconColor() {
    return getValue("darkMode") ? Colors.white70 : const Color.fromARGB(73, 0, 0, 0);
  }

  TextStyle _searchTextStyle() {
    return TextStyle(
      fontFamily: "aldahabi",
      color: isDarkModeNotifier.value
          ? const Color.fromARGB(228, 255, 255, 255)
          : const Color.fromARGB(190, 0, 0, 0),
    );
  }

  TextStyle _searchHintStyle() {
    return TextStyle(
      fontFamily: "aldahabi",
      color: isDarkModeNotifier.value ? Colors.white70 : const Color.fromARGB(73, 0, 0, 0),
    );
  }

  void _onSearchTextChanged(String value) {
    setState(() => searchQuery = value);

    if (value.isEmpty) {
      filteredData = widget.jsonData;
      pageNumbers.clear();
      return;
    }

    _handlePageNumberSearch(value);

    if (value.length > 3 || value.contains(" ")) {
      _performTextSearch(value);
    }
  }

  void _handlePageNumberSearch(String value) {
    if (isInt(value)) {
      pageNumbers.add(toInt(value) as int);
    }
  }

  void _performTextSearch(String value) {
    setState(() {
      ayatFiltered = [];
      searchQuery = value;
      ayatFiltered = quran.searchWords(searchQuery);

      filteredData = widget.jsonData.where((sura) {
        final suraName = sura['englishName'].toLowerCase();
        final suraNameArabic = quran.getSurahNameArabic(sura["number"]);

        return suraName.contains(searchQuery.toLowerCase()) ||
            suraNameArabic.contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  void _clearSearch() {
    if (searchQuery.isNotEmpty) {
      filteredData = widget.jsonData;
      textEditingController.clear();
      pageNumbers.clear();
      setState(() => searchQuery = "");
    }
  }

  Widget _buildSurahList() {
    return Expanded(
      child: isLoading
          ? _buildShimmerLoading()
          : ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                if (pageNumbers.isNotEmpty) _buildPageNumbersList(),
                _buildSurahsListView(),
                if (ayatFiltered != null) _buildSearchResults(),
              ],
            ),
    );
  }

  Widget _buildPageNumbersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("page".tr()),
        ),
        ListView.separated(
          reverse: true,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0.w),
            child: Divider(color: Colors.grey.withOpacity(.5)),
          ),
          itemCount: pageNumbers.length,
          itemBuilder: (ctx, index) => _buildPageNumberItem(pageNumbers[index]),
        ),
      ],
    );
  }

  Widget _buildPageNumberItem(int pageNumber) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: EasyContainer(
        color: getValue("darkMode") ? Colors.white70 : primaryColor,
        onTap: () => _navigateToPage(pageNumber),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(pageNumber.toString()),
              Text(quran.getSurahName(quran.getPageData(pageNumber)[0]["surah"])),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(int pageNumber) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (builder) => QuranDetailsPage(
          shouldHighlightSura: true,
          shouldHighlightText: false,
          highlightVerse: "",
          jsonData: widget.jsonData,
          quarterJsonData: widget.quarterjsonData,
          pageNumber: pageNumber,
        ),
      ),
    );
  }

  Widget _buildSurahsListView() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0.w),
        child: Divider(color: Colors.grey.withOpacity(.5)),
      ),
      itemCount: filteredData.length,
      itemBuilder: (context, index) => _buildSurahListItem(index),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل بناء عنصر السورة لملف ui/components/surah_list_item.dart
  Widget _buildSurahListItem(int index) {
    final suraData = filteredData[index];
    final suraNumber = index + 1;
    final suraNumberInQuran = suraData["number"];
    final hasBookmark =
        bookmarks.indexWhere((a) => a.toString().split("-")[0] == "$suraNumberInQuran") != -1;

    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: ListTile(
        leading: _buildSurahNumberCircle(suraNumberInQuran),
        title: _buildSurahTitle(suraData, hasBookmark, suraNumberInQuran),
        subtitle: _buildSurahSubtitle(suraData),
        // trailing: _buildSurahTrailing(suraNumber),
        onTap: () => _navigateToSurah(suraNumberInQuran),
      ),
    );
  }

  Widget _buildSurahNumberCircle(int suraNumber) {
    return Container(
      width: 45,
      height: 45,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/sura_frame.png"),
        ),
      ),
      child: Center(
        child: Text(
          suraNumber.toString(),
          style: TextStyle(
              color: isDarkModeNotifier.value ? Colors.white : Colors.black, fontSize: 14.sp),
        ),
      ),
    );
  }

  Widget _buildSurahTitle(Map<String, dynamic> suraData, bool hasBookmark, int suraNumber) {
    return SizedBox(
      width: 90.w,
      child: Row(
        children: [
          Text(
            "سورة ${suraData["name"]}",
            style: TextStyle(
              color: getValue("darkMode") ? Colors.white70 : Colors.black,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              fontFamily: "arsura",
            ),
          ),
          if (hasBookmark) _buildBookmarkIcon(suraNumber),
        ],
      ),
    );
  }

  Widget _buildBookmarkIcon(int suraNumber) {
    final bookmarkIndex = bookmarks.indexWhere((a) => a.toString().startsWith("$suraNumber"));
    return Icon(
      Icons.bookmark,
      size: 16.sp,
      color: colorsOfBookmarks2[bookmarkIndex].withOpacity(.7),
    );
  }

  Widget _buildSurahSubtitle(Map<String, dynamic> suraData) {
    final ayahCount = quran.getVerseCount(suraData["number"]);
    return Text(
      "${suraData["englishName"]} ($ayahCount)",
      style: TextStyle(fontFamily: "uthmanic", fontSize: 14.sp, color: Colors.grey.withOpacity(.8)),
    );
  }

  // Widget _buildSurahTrailing(int suraNumber) {
  //   return RichText(
  //     text: TextSpan(
  //       text: "$suraNumber",
  //       style: TextStyle(
  //         color: getValue("darkMode") ? Colors.white70 : Colors.black,
  //         fontSize: 28.sp,
  //         fontFamily: "arsura",
  //       ),
  //     ),
  //   );
  // }

  void _navigateToSurah(int suraNumber) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (builder) => BlocProvider(
          create: (context) => QuranPagePlayerBloc(),
          child: QuranDetailsPage(
            shouldHighlightSura: true,
            shouldHighlightText: false,
            highlightVerse: "",
            jsonData: widget.jsonData,
            quarterJsonData: widget.quarterjsonData,
            pageNumber: quran.getPageNumber(suraNumber, 1),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final resultCount = ayatFiltered["occurences"] > 10 ? 10 : ayatFiltered["occurences"];

    return Column(
      children: [
        const Divider(),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: resultCount,
          itemBuilder: (context, index) => _buildSearchResultItem(index),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(int index) {
    final result = ayatFiltered["result"][index];
    final surah = result["surah"];
    final verse = result["verse"];

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: EasyContainer(
        color: isDarkModeNotifier.value ? darkModeSecondaryColor : Colors.white70,
        borderRadius: 14,
        onTap: () => _navigateToSearchResult(surah, verse),
        child: Text(
          "سورة ${quran.getSurahNameArabic(surah)} - ${quran.getVerse(surah, verse, verseEndSymbol: true)}",
          textDirection: m.TextDirection.rtl,
          style: TextStyle(
            color: isDarkModeNotifier.value ? Colors.white : Colors.black,
            fontFamily: "uthmanic",
            fontSize: 17.sp,
          ),
        ),
      ),
    );
  }

  void _navigateToSearchResult(int surah, int verse) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (builder) => QuranDetailsPage(
          shouldHighlightSura: false,
          pageNumber: quran.getPageNumber(surah, verse),
          jsonData: widget.jsonData,
          shouldHighlightText: true,
          highlightVerse: quran.getVerse(surah, verse),
          quarterJsonData: widget.quarterjsonData,
        ),
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل تبويب الجزء لملف ui/tabs/juz_tab.dart
  Widget _buildJuzTab() {
    return ScrollablePositionedList.builder(
      itemCount: 30,
      itemScrollController: _juzScrollController,
      itemBuilder: (BuildContext context, index) => _buildJuzListItem(index),
    );
  }

  Widget _buildJuzListItem(int index) {
    final juzNumber = index + 1;
    final surahAndVerses = quran.getSurahAndVersesFromJuz(juzNumber);
    final firstSurah = surahAndVerses.keys.first;
    final firstVerse = surahAndVerses.values.first[0];
    final isLastRead = juzNumberLastRead == juzNumber;

    return Card(
      color:
          isDarkModeNotifier.value ? darkModeSecondaryColor.withOpacity(.8) : quranPagesColorLight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(
            quran.getSurahNameArabic(firstSurah),
            style: _juzTextStyle(),
          ),
          subtitle: Text(
            quran.getVerse(firstSurah, firstVerse),
            style: _juzVerseStyle(),
          ),
          onTap: () => _navigateToJuz(juzNumber, firstSurah, firstVerse),
          leading: _buildJuzNumberCircle(juzNumber, isLastRead),
        ),
      ),
    );
  }

  Widget _buildJuzNumberCircle(int juzNumber, bool isLastRead) {
    return Container(
      width: 33.sp,
      height: 33.sp,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLastRead
            ? isDarkModeNotifier.value
                ? quranPagesColorDark
                : quranPagesColorLight
            : isDarkModeNotifier.value
                ? quranPagesColorDark
                : quranPagesColorLight.withOpacity(.1),
      ),
      child: Center(
        child: Text(
          juzNumber.toString(),
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkModeNotifier.value ? primaryColor : const Color.fromARGB(228, 0, 0, 0),
          ),
        ),
      ),
    );
  }

  void _navigateToJuz(int juzNumber, int firstSurah, int firstVerse) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (builder) => QuranDetailsPage(
          shouldHighlightSura: false,
          quarterJsonData: widget.quarterjsonData,
          shouldHighlightText: true,
          highlightVerse: quran.getVerse(firstSurah, firstVerse),
          pageNumber: quran.getPageNumber(firstSurah, firstVerse),
          jsonData: widget.jsonData,
        ),
      ),
    );
    getJuzNumber();
    setState(() {});
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل تبويب الربع لملف ui/tabs/quarter_tab.dart
  Widget _buildQuarterTab() {
    return GroupListView(
      sectionsCount: 60,
      countOfItemInSection: (int section) => 4,
      itemBuilder: (BuildContext context, IndexPath index) => _buildQuarterListItem(index),
      groupHeaderBuilder: (BuildContext context, int section) => _buildQuarterHeader(section),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      sectionSeparatorBuilder: (context, section) => const SizedBox(height: 10),
    );
  }

  Widget _buildQuarterListItem(IndexPath index) {
    final quarterData = widget.quarterjsonData[indexes[index.section][index.index] - 1];
    final surah = quarterData["surah"];
    final ayah = quarterData["ayah"];

    return Card(
      color:
          isDarkModeNotifier.value ? darkModeSecondaryColor.withOpacity(.8) : quranPagesColorLight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(
            quran.getSurahNameArabic(surah),
            style: _juzTextStyle(),
          ),
          subtitle: Text(
            quran.getVerse(surah, ayah),
            style: _juzVerseStyle(),
          ),
          onTap: () => _navigateToQuarter(surah, ayah),
          leading: _buildQuarterCircle(index.index, index.section + 1),
        ),
      ),
    );
  }

  Widget _buildQuarterCircle(int index, int hizbNumber) {
    return getCircleWidget(index, hizbNumber);
  }

  Widget _buildQuarterHeader(int section) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Text(
        "${"hizb".tr()} ${section + 1}",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkModeNotifier.value
              ? const Color.fromARGB(234, 255, 255, 255)
              : const Color.fromARGB(228, 0, 0, 0),
        ),
      ),
    );
  }

  void _navigateToQuarter(int surah, int ayah) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (builder) => QuranDetailsPage(
          shouldHighlightSura: false,
          quarterJsonData: widget.quarterjsonData,
          shouldHighlightText: true,
          highlightVerse: quran.getVerse(surah, ayah),
          pageNumber: quran.getPageNumber(surah, ayah),
          jsonData: widget.jsonData,
        ),
      ),
    );
    setState(() {});
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل دوائر الأرباع لملف utils/quarter_circle_utils.dart
  Widget getCircleWidget(int index, int hizbNumber) {
    final circleColor =
        isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight.withOpacity(.1);
    final iconColor = isDarkModeNotifier.value ? primaryColor : const Color.fromARGB(228, 0, 0, 0);

    switch (index) {
      case 0:
        return Container(
          width: 33.sp,
          height: 33.sp,
          decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
          child: Center(
            child: Text(hizbNumber.toString(), style: TextStyle(fontSize: 14.sp, color: iconColor)),
          ),
        );
      case 1:
        return Container(
          width: 20.sp,
          height: 20.sp,
          decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
          child: QuarterCircle(color: iconColor, size: 20.sp),
        );
      case 2:
        return Container(
          width: 20.sp,
          height: 20.sp,
          decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
          child: HalfCircle(color: iconColor, size: 20.sp),
        );
      case 3:
        return Container(
          width: 20.sp,
          height: 20.sp,
          decoration: BoxDecoration(shape: BoxShape.circle, color: circleColor),
          child: ThreeQuartersCircle(color: iconColor, size: 20.sp),
        );
      default:
        return Container();
    }
  }

  TextStyle _juzTextStyle() {
    return TextStyle(
      color: isDarkModeNotifier.value
          ? const Color.fromARGB(234, 255, 255, 255)
          : const Color.fromARGB(228, 0, 0, 0),
    );
  }

  TextStyle _juzVerseStyle() {
    return TextStyle(
      fontFamily: "UthmanicHafs13",
      fontSize: 18.sp,
      color: isDarkModeNotifier.value
          ? const Color.fromARGB(234, 255, 255, 255)
          : const Color.fromARGB(228, 0, 0, 0),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل درج الإشارات المرجعية لملف ui/drawers/bookmarks_drawer.dart
  Widget _buildBookmarksDrawer(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width * .7,
      color: isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight,
      child: ListView(
        shrinkWrap: true,
        children: [
          _buildBookmarksList(),
          _buildStarredVersesHeader(),
          _buildStarredVersesList(),
        ],
      ),
    );
  }

  Widget _buildBookmarksList() {
    if (bookmarks.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookmarks.length,
      itemBuilder: (c, i) => _buildBookmarkItem(bookmarks[i]),
    );
  }

  Widget _buildBookmarkItem(dynamic bookmark) {
    final suraNumber = int.parse(bookmark["suraNumber"].toString());
    final verseNumber = int.parse(bookmark["verseNumber"].toString());
    final bookmarkColor = Color(int.parse("0x${bookmark["color"]}"));

    return EasyContainer(
      borderRadius: 18,
      color: primaryColors[0].withOpacity(.05),
      onTap: () => _navigateToBookmark(suraNumber, verseNumber),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            _buildBookmarkHeader(bookmark, bookmarkColor),
            const Divider(),
            _buildBookmarkVerse(suraNumber, verseNumber),
            const Divider(),
            _buildBookmarkInfo(suraNumber, verseNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkHeader(dynamic bookmark, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bookmark, color: color),
        SizedBox(width: 20.w),
        Text(
          bookmark["name"],
          style: TextStyle(
            fontFamily: "cairo",
            fontSize: 14.sp,
            color: getValue("darkMode") ? Colors.white.withOpacity(.87) : primaryColors[0],
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkVerse(int suraNumber, int verseNumber) {
    return SizedBox(
      child: Text(
        quran.getVerse(suraNumber, verseNumber),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: fontFamilies[0],
          fontSize: 18.sp,
          color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : primaryColors[0],
        ),
      ),
    );
  }

  Widget _buildBookmarkInfo(int suraNumber, int verseNumber) {
    return Column(
      children: [
        Text(
          context.locale.languageCode == "ar"
              ? quran.getSurahNameArabic(suraNumber)
              : quran.getSurahNameEnglish(suraNumber),
          style: TextStyle(
            color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
          ),
        ),
        Text(
          convertToArabicNumber(verseNumber.toString()),
          style: TextStyle(
            fontSize: 24.sp,
            color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
            fontFamily: "KFGQPC Uthmanic Script HAFS Regular",
          ),
        ),
      ],
    );
  }

  void _navigateToBookmark(int suraNumber, int verseNumber) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (builder) => QuranDetailsPage(
          shouldHighlightSura: false,
          pageNumber: quran.getPageNumber(suraNumber, verseNumber),
          jsonData: widget.jsonData,
          shouldHighlightText: true,
          highlightVerse: quran.getVerse(suraNumber, verseNumber),
          quarterJsonData: widget.quarterjsonData,
        ),
      ),
    );
  }

  Widget _buildStarredVersesHeader() {
    return Column(
      children: [
        Center(
          child: Padding(
            padding: EdgeInsets.only(top: 8.0.h),
            child: Text(
              "starredverses".tr(),
              style: TextStyle(
                color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black,
                fontSize: 18.sp,
              ),
            ),
          ),
        ),
        Center(child: Icon(Icons.keyboard_arrow_down, size: 18.sp)),
      ],
    );
  }

  Widget _buildStarredVersesList() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: starredVerses.map((e) => _buildStarredVerseItem(e)).toList(),
    );
  }

  Widget _buildStarredVerseItem(String verseKey) {
    final parts = verseKey.split("-");
    final suraNumber = int.parse(parts[0]);
    final verseNumber = int.parse(parts[1]);

    return EasyContainer(
      color: primaryColors[0].withOpacity(.05),
      onTap: () => _navigateToStarredVerse(suraNumber, verseNumber),
      child: Column(
        children: [
          _buildStarredVerseText(suraNumber, verseNumber),
          _buildStarredVerseInfo(suraNumber, verseNumber),
        ],
      ),
    );
  }

  Widget _buildStarredVerseText(int suraNumber, int verseNumber) {
    return Text(
      quran.getVerse(suraNumber, verseNumber),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: fontFamilies[0],
        fontSize: 18.sp,
        color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : primaryColors[0],
      ),
    );
  }

  Widget _buildStarredVerseInfo(int suraNumber, int verseNumber) {
    return Column(
      children: [
        Text(
          context.locale.languageCode == "ar"
              ? quran.getSurahNameArabic(suraNumber)
              : quran.getSurahNameEnglish(suraNumber),
          textAlign: TextAlign.center,
        ),
        Text(
          convertToArabicNumber(verseNumber.toString()),
          style: TextStyle(
            fontSize: 24.sp,
            color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black87,
            fontFamily: "KFGQPC Uthmanic Script HAFS Regular",
          ),
        ),
      ],
    );
  }

  void _navigateToStarredVerse(int suraNumber, int verseNumber) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (builder) => QuranDetailsPage(
          shouldHighlightSura: false,
          pageNumber: quran.getPageNumber(suraNumber, verseNumber),
          jsonData: widget.jsonData,
          shouldHighlightText: true,
          highlightVerse: quran.getVerse(suraNumber, verseNumber),
          quarterJsonData: widget.quarterjsonData,
        ),
      ),
    );
  }

  // 🔹 [CAN_BE_EXTRACTED] يمكن نقل تأثير التحميل لملف ui/components/shimmer_loading.dart
  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300.withOpacity(.5),
          highlightColor: isDarkModeNotifier.value ? darkModeSecondaryColor : quranPagesColorLight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 8.h),
            child: ListTile(
              leading: Container(width: 45, height: 45, color: backgroundColor),
              title: Container(height: 15, color: backgroundColor),
              subtitle: Container(height: 12, color: backgroundColor),
            ),
          ),
        );
      },
    );
  }
}
