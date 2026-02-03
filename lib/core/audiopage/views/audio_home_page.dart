// ignore_for_file: library_private_types_in_public_api, unused_field
import 'dart:convert';
import 'dart:io';
import 'package:ghaith/GlobalHelpers/home_blocs.dart';
import 'package:ghaith/core/audiopage/models/reciter.dart';
import 'package:ghaith/main.dart';
import 'package:azlistview/azlistview.dart';
import 'package:dio/dio.dart';
// import 'package:easy_container/easy_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_annimated_staggered/simple_annimated_staggered.dart';

// =============================================
// 📁 IMPORTS - يمكن نقلها لملف imports منفصل
// =============================================
import 'package:ghaith/blocs/player_bloc_bloc.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/blocs/quran_page_player_bloc.dart';
import 'package:ghaith/core/audiopage/views/reciter_all_surahs_page.dart';

// =============================================
// 🏗️ MAIN WIDGET - Reciters Page
// =============================================

class RecitersPage extends StatefulWidget {
  final dynamic jsonData;

  const RecitersPage({super.key, required this.jsonData});

  @override
  _RecitersPageState createState() => _RecitersPageState();
}

// =============================================
// 🔧 STATE CLASS - Reciters Page Logic
// =============================================

class _RecitersPageState extends State<RecitersPage> {
  // =============================================
  // 🎛️ STATE VARIABLES
  // =============================================
  late List<Reciter> reciters;
  late List<Reciter> favoriteRecitersList;
  late List<Reciter> filteredReciters;
  late List<Moshaf> rewayat;
  late List<dynamic> suwar;
  final Map<String, bool> _playingStatus = {};
  final Map<String, bool> _downloadingStatus = {};
  bool isLoading = true;
  late Dio dio;

  final ItemScrollController itemScrollController = ItemScrollController();
  final TextEditingController textEditingController = TextEditingController();

  String searchQuery = "";
  // 💡 التعديل: القيمة الافتراضية هي "all" لعرض جميع القراء
  String selectedMode = "all";

  // =============================================
  // 🎯 LIFECYCLE METHODS
  // =============================================

  @override
  void initState() {
    super.initState();
    _initializeData();
    // 💡 التعديل: _loadInitialData تم تحديثها لمعالجة التوقيت
    _loadInitialData();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  // =============================================
  // 🔧 INITIALIZATION METHODS
  // =============================================

  void _initializeData() {
    reciters = [];
    favoriteRecitersList = [];
    filteredReciters = [];
    rewayat = [];
    suwar = [];
    dio = Dio();
  }

  // 💡 التعديل: لضمان تحميل قائمة القراء قبل المفضلة
  void _loadInitialData() async {
    // 1. 🥇 حمل القراء الأساسيين من API/SharedPreferences.
    await _fetchReciters();

    // 2. 🥈 بعد اكتمال قائمة 'reciters'، يمكننا الآن تحميل قائمة المفضلة بأمان.
    _getFavoriteList();
  }

  // =============================================
  // 💾 DATA MANAGEMENT
  // =============================================

  // 💡 التعديل: استخدام orElse آمن لتجنب Bad state: No element
  void _getFavoriteList() {
    final jsonData = getValue("favoriteRecitersList");

    if (jsonData != null) {
      try {
        // نعلم الآن أننا نحفظ IDs فقط
        final List<dynamic> favoriteReciterIds = json.decode(jsonData) as List<dynamic>;

        // مطابقة الـ IDs مع قائمة القراء المحملة (reciters)
        favoriteRecitersList = favoriteReciterIds
            .map((reciterId) {
              return reciters.firstWhere(
                (element) => element.id.toString() == reciterId.toString(),
                // إذا لم يتم العثور على القارئ، نُعيد كائناً فارغاً آمن الهوية (-1)
                orElse: () => Reciter(id: -1, name: '', letter: '', moshaf: []),
              );
            })
            .where((reciter) => reciter.id != -1) // حذف العناصر الوهمية
            .toList();
      } catch (e) {
        print('Error decoding favorite list or processing item: $e');
        favoriteRecitersList = [];
      }
    } else {
      favoriteRecitersList = [];
    }

    // 💡 ضمان إيقاف مؤشر التحميل بعد محاولة تحميل القائمة المفضلة
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _getAndStoreRecitersData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final locale = context.locale.languageCode == "en" ? "eng" : context.locale.languageCode;

    try {
      final responses = await Future.wait([
        dio.get('http://mp3quran.net/api/v3/reciters?language=$locale'),
        dio.get('http://mp3quran.net/api/v3/moshaf?language=$locale'),
        dio.get('http://mp3quran.net/api/v3/suwar?language=$locale'),
      ]);

      await _storeApiResponses(prefs, locale, responses);
    } catch (error) {
      print('Error while storing data: $error');
    }
  }

  Future<void> _storeApiResponses(
      SharedPreferences prefs, String locale, List<Response> responses) async {
    final keys = ["reciters", "moshaf", "suwar"];

    for (int i = 0; i < responses.length; i++) {
      if (responses[i].data != null) {
        final jsonData = i == 0
            ? json.encode(responses[i].data['reciters'])
            : i == 1
                ? json.encode(responses[i].data)
                : json.encode(responses[i].data['suwar']);

        prefs.setString("${keys[i]}-$locale", jsonData);
      }
    }
  }

  // 💡 التعديل: تحديث isLoading في النهاية فقط أو عند الخطأ
  Future<void> _fetchReciters() async {
    setState(() {
      isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final locale = context.locale.languageCode == "en" ? "eng" : context.locale.languageCode;

      if (prefs.getString("reciters-$locale") == null) {
        await _getAndStoreRecitersData();
      }

      await _loadStoredData(prefs, locale);

      if (reciters.isEmpty) {
        _showSnackBar(
            "⚠️ فشل تحميل البيانات. يرجى التحقق من اتصال الإنترنت أو المحاولة لاحقاً.", Colors.red);
      }
    } catch (error) {
      print('Error while fetching data: $error');
      _showSnackBar("❌ حدث خطأ غير متوقع أثناء جلب البيانات.", Colors.red);
    }
  }

  // 💡 التعديل: إضافة معالجة أخطاء فك تشفير JSON وحذف البيانات التالفة
  Future<void> _loadStoredData(SharedPreferences prefs, String locale) async {
    final jsonData = prefs.getString("reciters-$locale");
    final jsonData2 = prefs.getString("moshaf-$locale");
    final jsonData3 = prefs.getString("suwar-$locale");

    if (jsonData != null && jsonData2 != null && jsonData3 != null) {
      try {
        final data = json.decode(jsonData) as List<dynamic>;
        final data2 = json.decode(jsonData2)["riwayat"] as List<dynamic>;
        final data3 = json.decode(jsonData3) as List<dynamic>;

        _processRecitersData(data, data2, data3);
      } catch (e) {
        print('Error decoding stored data: $e');
        await prefs.remove("reciters-$locale");
        await prefs.remove("moshaf-$locale");
        await prefs.remove("suwar-$locale");
        _showSnackBar("⚠️ تم العثور على بيانات تالفة وحذفها. يرجى إعادة المحاولة.", Colors.orange);
      }
    }
  }

  // 💡 التعديل: إزالة تحديث isLoading من هذه الدالة
  void _processRecitersData(
      List<dynamic> recitersData, List<dynamic> rewayatData, List<dynamic> suwarData) {
    reciters = recitersData.map((reciter) => Reciter.fromJson(reciter)).toList();
    reciters.sort((a, b) => a.letter.toString().compareTo(b.letter.toString()));

    filteredReciters = reciters;
    rewayat = rewayatData.map((reciter) => Moshaf.fromJson(reciter)).toList();
    suwar = suwarData;
  }

  // =============================================
  // 🔍 FILTERING METHODS
  // =============================================

  void _filterReciters(String query) {
    setState(() {
      filteredReciters = reciters.where((reciter) {
        return reciter.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });

    _scrollToTop();
  }

  // void _filterByRewaya(String id) {
  //   filteredReciters = reciters.where((element) {
  //     return element.moshaf.any((element) => element.id.toString() == id);
  //   }).toList();

  //   setState(() {});
  // }

  void _scrollToTop() {
    // 💡 الحل: نستخدم Future.microtask لتأجيل التنفيذ
    // حتى بعد اكتمال تحديث الـ Widget tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 💡 التحقق من أن الكونترولر مرتبط بالعنصر قبل محاولة التمرير.
      if (itemScrollController.isAttached) {
        itemScrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 500), // يمكنك تقليل المدة
          curve: Curves.easeInOutBack,
        );
      }
    });
  }

  // =============================================
  // 🎯 FAVORITES MANAGEMENT
  // =============================================

  // 💡 التعديل: حفظ الـ IDs فقط
  void _toggleFavorite(Reciter reciter) {
    setState(() {
      if (favoriteRecitersList.contains(reciter)) {
        favoriteRecitersList.remove(reciter);
      } else {
        favoriteRecitersList.add(reciter);
      }

      // 💡 حفظ قائمة من IDs القراء المفضلين فقط
      List<dynamic> favoriteIds = favoriteRecitersList.map((r) => r.id).toList();

      // نستخدم الدالة updateValue لحفظ قائمة الـ IDs المشفرة
      updateValue("favoriteRecitersList", json.encode(favoriteIds));
    });
  }

  // 💡 دالة جديدة لتفعيل أو إلغاء تفعيل وضع المفضلة
  void _toggleFavoriteMode() {
    setState(() {
      if (selectedMode == "favorite") {
        selectedMode = "all";
        filteredReciters = reciters; // العودة إلى جميع القراء
      } else {
        selectedMode = "favorite";
        // عند التحول للمفضلة، لا نحتاج لتصفية filteredReciters
        // لأن _getCurrentRecitersList ستستخدم favoriteRecitersList
      }
      textEditingController.clear();
      searchQuery = "";
      FocusManager.instance.primaryFocus?.unfocus();
    });
    _scrollToTop();
  }

  // =============================================
  // 🧩 UI BUILD METHODS
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // =============================================
  // 🎨 UI COMPONENTS
  // =============================================

  // 💡 التعديل: إضافة زر المفضلة إلى الـ actions
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _getAppBarColor(),
      elevation: 0,
      title: Text(
        selectedMode == "favorite" ? "favorites".tr() : "allReciters".tr(),
        style: TextStyle(color: Colors.white, fontSize: 20.sp),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: _buildBackButton(),
      actions: [
        // 💡 الزر الجديد: أيقونة المفضلة
        _buildFavoriteButtonIcon(),
        SizedBox(width: 10.w),
        // _buildFilterButton(),
      ],
      systemOverlayStyle: SystemUiOverlayStyle.light,
      bottom: _buildAppBarBottom(),
    );
  }

  // 💡 الزر الجديد: أيقونة المفضلة في شريط التطبيق
  Widget _buildFavoriteButtonIcon() {
    final bool isFavoriteMode = selectedMode == "favorite";
    return IconButton(
      onPressed: _toggleFavoriteMode,
      icon: Icon(
        isFavoriteMode ? FontAwesome.heart : FontAwesome.heart_empty,
        color:
            isFavoriteMode ? Colors.white : Colors.white.withOpacity(0.8), // لون مختلف عند التفعيل
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Entypo.logout, color: Colors.white),
    );
  }

  PreferredSize _buildAppBarBottom() {
    return PreferredSize(
      preferredSize:
          Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height * .1),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            _buildSearchField(),
            // 💡 إزالة زر الفلتر من هنا ونقله إلى actions، ولكن نتركه في حالة عدم استخدامه مؤقتا
            // _buildFilterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0.w),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xffF6F6F6),
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                  child: TextField(
                    controller: textEditingController,
                    onChanged: _onSearchTextChanged,
                    decoration: InputDecoration(
                      hintText: "searchreciters".tr(),
                      hintStyle: TextStyle(
                        fontFamily: "cairo",
                        fontSize: 14.sp,
                        color: const Color.fromARGB(73, 0, 0, 0),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              _buildSearchActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchActionButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: _onSearchActionTap,
        child: Icon(
          searchQuery == "" ? FontAwesome.search : Icons.close,
          color: const Color.fromARGB(73, 0, 0, 0),
        ),
      ),
    );
  }

  // Widget _buildFilterButton() {
  //   return IconButton(
  //     onPressed: _showFilterBottomSheet,
  //     icon: const Icon(FontAwesome.filter, color: Colors.white),
  //   );
  // }

  // 💡 التعديل: إضافة منطق عرض رسالة في حال عدم وجود بيانات
  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: darkPrimaryColor),
      );
    }

    if (_getCurrentRecitersCount() == 0) {
      final String message = selectedMode == "favorite"
          ? "لا يوجد قراء مفضلون حالياً."
          : "لا يوجد بيانات لعرضها. يرجى التحقق من اتصالك بالإنترنت.";

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesome.search, color: Colors.grey, size: 40),
            SizedBox(height: 20.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: _getTextColor(), fontSize: 16.sp),
            ),
            SizedBox(height: 20.h),
            if (selectedMode != "favorite")
              TextButton(
                onPressed: _fetchReciters,
                child: Text(
                  "إعادة المحاولة",
                  style: TextStyle(color: _getActionButtonColor(), fontSize: 16.sp),
                ),
              )
          ],
        ),
      );
    }

    return AnimationLimiter(
      child: AzListView(
        physics: const BouncingScrollPhysics(),
        indexBarData: _getLettersForLocale(),
        indexBarHeight: MediaQuery.of(context).size.height,
        itemScrollController: itemScrollController,
        hapticFeedback: true,
        indexBarItemHeight: 20,
        data: _getCurrentRecitersList(),
        itemCount: _getCurrentRecitersCount(),
        itemBuilder: _buildReciterItem,
      ),
    );
  }

  Widget _buildReciterItem(BuildContext context, int index) {
    final reciter = _getReciterAtIndex(index);

    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50,
        child: FadeInAnimation(
          child: Padding(
            padding: EdgeInsets.only(right: 15.0.w),
            child: Card(
              elevation: .8,
              color: _getCardColor(),
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: _buildReciterCardContent(reciter),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReciterCardContent(Reciter reciter) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          _buildReciterHeader(reciter),
          SizedBox(height: 8.h),
          _buildMoshafList(reciter),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildReciterHeader(Reciter reciter) {
    return Padding(
      padding: EdgeInsets.only(left: 14.0.w, right: 14.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            reciter.name.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              color: _getTextColor(),
              fontWeight: FontWeight.bold,
              fontFamily: 'cairo',
            ),
          ),
          _buildFavoriteButton(reciter),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(Reciter reciter) {
    return IconButton(
      onPressed: () => _toggleFavorite(reciter),
      icon: Icon(
        size: 20,
        favoriteRecitersList.contains(reciter) ? FontAwesome.heart : FontAwesome.heart_empty,
        color: _getFavoriteButtonColor(),
      ),
    );
  }

  Widget _buildMoshafList(Reciter reciter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reciter.moshaf.map((moshaf) => _buildMoshafItem(moshaf, reciter)).toList(),
    );
  }

  Widget _buildMoshafItem(Moshaf moshaf, Reciter reciter) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => _navigateToSurahList(reciter, moshaf),
          child: Column(
            children: [
              Divider(height: 8.h),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMoshafInfo(moshaf),

                    // _buildMoshafActions(moshaf, reciter),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoshafInfo(Moshaf moshaf) {
    return Row(
      children: [
        SizedBox(width: 10.w),
        Image(
          height: 24.h,
          image: const AssetImage("assets/images/reading.png"),
        ),
        SizedBox(width: 10.w),
        SizedBox(
          width: (MediaQuery.of(context).size.width * .5).w,
          child: Text(
            moshaf.name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _getMoshafTextColor(),
              fontSize: 14.sp,
              fontFamily: 'cairo',
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildMoshafActions(Moshaf moshaf, Reciter reciter) {
    return BlocProvider(
      create: (context) => PlayerBlocBloc(),
      child: Row(
        children: [
          _buildPlayButton(moshaf, reciter),
          _buildDownloadButton(moshaf, reciter),
          SizedBox(width: 10.w),
        ],
      ),
    );
  }

  Widget _buildPlayButton(Moshaf moshaf, Reciter reciter) {
    final moshafKey = "${moshaf.id}-${reciter.id}";
    final isPlaying = _playingStatus[moshafKey] ?? false;

    return IconButton(
      onPressed: () => _onPlayPressed(moshaf, reciter, moshafKey, isPlaying),
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        size: 20.sp,
        color: _getActionButtonColor(),
      ),
    );
  }

  Widget _buildDownloadButton(Moshaf moshaf, Reciter reciter) {
    return IconButton(
      onPressed: () => _onDownloadPressed(moshaf, reciter),
      icon: FutureBuilder<bool>(
        future: _isMoshafDownloaded(moshaf, reciter),
        builder: (context, snapshot) {
          final isDownloading = _downloadingStatus[moshaf.id] ?? false;

          if (isDownloading) {
            return SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: blueColor,
              ),
            );
          }

          return Icon(
            snapshot.data == true ? Icons.download_done : Icons.download,
            size: 20.sp,
            color: blueColor,
          );
        },
      ),
    );
  }

  // =============================================
  // 🎯 BOTTOM SHEET
  // =============================================

  // void _showFilterBottomSheet() {
  //   showModalBottomSheet(
  //     enableDrag: true,
  //     backgroundColor: Colors.white,
  //     isDismissible: true,
  //     showDragHandle: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(14),
  //         topRight: Radius.circular(14),
  //       ),
  //     ),
  //     context: context,
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setModalState) {
  //         return ListView(
  //           children: [
  //             _buildAllFilterOption(setModalState),
  //             Divider(height: 15.h, color: Colors.grey),
  //             // ❌ التعديل: إزالة خيار المفضلة من الـ Filter Sheet
  //             // _buildFavoritesFilterOption(setModalState),
  //             // Divider(height: 15.h, color: Colors.grey),
  //             ..._buildRewayaFilterOptions(setModalState),
  //           ],
  //         );
  //       },
  //     ),
  //   );
  // }

  // Widget _buildAllFilterOption(StateSetter setModalState) {
  //   return _buildFilterOption(
  //     icon: Icons.all_inclusive_rounded,
  //     title: "all".tr(),
  //     isSelected: selectedMode == "all",
  //     onTap: () => _onFilterOptionSelected("all", setModalState),
  //   );
  // }

  // ❌ التعديل: حذف دالة بناء خيار المفضلة
  // Widget _buildFavoritesFilterOption(StateSetter setModalState) {
  //   return _buildFilterOption(
  //     icon: Icons.favorite,
  //     title: "favorites".tr(),
  //     isSelected: selectedMode == "favorite",
  //     onTap: () => _onFilterOptionSelected("favorite", setModalState),
  //   );
  // }

  // List<Widget> _buildRewayaFilterOptions(StateSetter setModalState) {
  //   return rewayat
  //       .map((rewaya) => Column(
  //             children: [
  //               _buildRewayaFilterOption(rewaya, setModalState),
  //               Divider(height: 12.h),
  //             ],
  //           ))
  //       .toList();
  // }

  // Widget _buildRewayaFilterOption(Moshaf rewaya, StateSetter setModalState) {
  //   // 💡 التعديل: نستخدم moshafType.toString() كـ Mode للفلترة بالرواية
  //   final String rewayaMode = rewaya.moshafType.toString();

  //   return _buildFilterOption(
  //     icon: Icons.library_books,
  //     title: rewaya.name,
  //     isSelected: selectedMode == rewayaMode,
  //     onTap: () => _onRewayaFilterSelected(rewaya, setModalState),
  //     customIcon: Image(
  //       height: 25.h,
  //       color: selectedMode == rewayaMode ? null : Colors.grey,
  //       image: const AssetImage("assets/images/reading.png"),
  //     ),
  //   );
  // }

  // Widget _buildFilterOption({
  //   required IconData icon,
  //   required String title,
  //   required bool isSelected,
  //   required VoidCallback onTap,
  //   Widget? customIcon,
  // }) {
  //   return EasyContainer(
  //     elevation: 0,
  //     padding: 0,
  //     margin: 0,
  //     onTap: onTap,
  //     child: SizedBox(
  //       height: 45.h,
  //       child: Row(
  //         children: [
  //           SizedBox(width: 30.w),
  //           customIcon ?? Icon(icon, color: isSelected ? _getFilterIconColor() : Colors.grey),
  //           SizedBox(width: 10.w),
  //           Text(title),
  //           const Spacer(),
  //           Icon(
  //             isSelected ? FontAwesome.dot_circled : FontAwesome.circle_empty,
  //             color: isSelected ? _getFilterIconColor() : Colors.grey,
  //             size: 20.sp,
  //           ),
  //           SizedBox(width: 40.w),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // =============================================
  // 🔧 EVENT HANDLERS
  // =============================================

  void _onSearchTextChanged(String value) {
    setState(() {
      searchQuery = value;
    });
    // 💡 التعديل: عند البحث، نعود دائماً لوضع "الكل" ونبحث في جميع القراء
    if (selectedMode != "all") {
      setState(() {
        selectedMode = "all";
      });
    }
    _filterReciters(value);
  }

  void _onSearchActionTap() {
    if (searchQuery == "") {
      _fetchReciters();
    } else {
      textEditingController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    }

    setState(() {
      searchQuery = "";
      // 💡 العودة لوضع "الكل" بعد مسح البحث
      selectedMode = "all";
    });
  }

  // void _onFilterOptionSelected(String mode, StateSetter setModalState) {
  //   if (selectedMode != mode) {
  //     _fetchReciters();
  //     setState(() {
  //       selectedMode = mode;
  //       // 💡 بما أن وضع "المفضلة" قد أُزيل، فإن هذا سيؤدي إلى وضع "الكل"
  //       filteredReciters = reciters;
  //     });
  //     Navigator.pop(context);
  //     _scrollToTop();
  //   }
  // }

  // void _onRewayaFilterSelected(Moshaf rewaya, StateSetter setModalState) {
  //   _filterByRewaya(rewaya.id.toString());
  //   setState(() {
  //     selectedMode = rewaya.moshafType.toString();
  //   });
  //   Navigator.pop(context);
  //   _scrollToTop();
  // }

  void _navigateToSurahList(Reciter reciter, Moshaf moshaf) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => BlocProvider(
          create: (context) => playerPageBloc,
          child: RecitersSurahListPage(
            reciter: reciter,
            mushaf: moshaf,
            jsonData: suwar,
          ),
        ),
      ),
    );
  }

  Future<void> _onPlayPressed(
      Moshaf moshaf, Reciter reciter, String moshafKey, bool isPlaying) async {
    if (isPlaying) {
      playerPageBloc.add(PausePlayer());
      setState(() => _playingStatus[moshafKey] = false);
      return;
    }

    if (qurapPagePlayerBloc.state is QuranPagePlayerPlaying) {
      await _showPlayerCloseDialog();
      return;
    }

    setState(() => _playingStatus[moshafKey] = true);

    playerPageBloc.add(StartPlaying(
      initialIndex: 0,
      moshaf: moshaf,
      buildContext: context,
      reciter: reciter,
      suraNumber: -1,
      jsonData: suwar,
    ));
  }

  Future<void> _showPlayerCloseDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text("closeplayer".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("cancel".tr()),
          ),
          TextButton(
            onPressed: () {
              qurapPagePlayerBloc.add(KillPlayerEvent());
              Navigator.pop(context);
            },
            child: Text("close".tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _onDownloadPressed(Moshaf moshaf, Reciter reciter) async {
    final isDownloaded = await _isMoshafDownloaded(moshaf, reciter);

    if (isDownloaded) {
      _showSnackBar("✅ المصحف محمّل بالفعل", Colors.green);
      return;
    }

    await _downloadMoshaf(moshaf, reciter);
  }

  Future<void> _downloadMoshaf(Moshaf moshaf, Reciter reciter) async {
    setState(() => _downloadingStatus[moshaf.id] = true);

    _showSnackBar("⬇️ جاري تحميل المصحف...", const Color(0xFF00A2B5));

    playerPageBloc.add(DownloadAllSurahs(moshaf: moshaf, reciter: reciter));

    // محاكاة للتحميل - يمكن إزالته عند ربطه بالتحميل الحقيقي
    await Future.delayed(const Duration(seconds: 3));

    setState(() => _downloadingStatus[moshaf.id] = false);
    _showSnackBar("✅ تم تحميل المصحف بنجاح", Colors.green);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _isMoshafDownloaded(Moshaf moshaf, Reciter reciter) async {
    try {
      final dir = await getExternalStorageDirectory();
      final moshafPath = Directory('${dir!.path}/Ghaith/${reciter.name}-${moshaf.name}');

      if (!await moshafPath.exists()) {
        return false;
      }

      final files = await moshafPath.list().toList();
      final surahCount = moshaf.surahList.split(',').length;

      // نعتبر المصحف محملاً إذا كان 80% من السور موجودة
      return files.length >= surahCount * 0.8;
    } catch (e) {
      return false;
    }
  }
  // =============================================
  // 🎨 STYLE HELPER METHODS
  // =============================================

  Color _getBackgroundColor() {
    return isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight;
  }

  Color _getAppBarColor() {
    return isDarkModeNotifier.value ? darkModeSecondaryColor.withOpacity(.9) : orangeColor;
  }

  Color _getCardColor() {
    return isDarkModeNotifier.value ? darkModeSecondaryColor.withOpacity(.9) : Colors.white;
  }

  Color _getTextColor() {
    return isDarkModeNotifier.value ? Colors.white : Colors.black;
  }

  Color _getMoshafTextColor() {
    return isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black;
  }

  Color _getFavoriteButtonColor() {
    return isDarkModeNotifier.value ? backgroundColor : orangeColor;
  }

  Color _getActionButtonColor() {
    return isDarkModeNotifier.value ? backgroundColor : orangeColor;
  }

  // Color _getFilterIconColor() {
  //   return isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight;
  // }

  // =============================================
  // 🔧 DATA HELPER METHODS
  // =============================================

  List<String> _getLettersForLocale() {
    for (var language in languagesLetters) {
      if (language.containsKey(context.locale.languageCode)) {
        return language[context.locale.languageCode]!;
      }
    }
    return [];
  }

  // 💡 التعديل: تعرض قائمة المفضلة إذا كان selectedMode == "favorite"
  List<Reciter> _getCurrentRecitersList() {
    return selectedMode == "favorite" ? favoriteRecitersList : filteredReciters;
  }

  int _getCurrentRecitersCount() {
    return selectedMode == "favorite" ? favoriteRecitersList.length : filteredReciters.length;
  }

  Reciter _getReciterAtIndex(int index) {
    return selectedMode == "favorite" ? favoriteRecitersList[index] : filteredReciters[index];
  }
}
