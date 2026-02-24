// ignore_for_file: library_private_types_in_public_api, unused_field
import 'dart:convert';
import 'dart:io';
import 'package:ghaith/helpers/home_blocs.dart';
import 'package:ghaith/core/audiopage/models/reciter.dart';
import 'package:ghaith/main.dart';
import 'package:azlistview/azlistview.dart';
import 'package:dio/dio.dart';
// import 'package:easy_container/easy_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
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
  String selectedMode = "all";
  bool _isSearching = false; // 💡 متغير جديد للتحكم في حالة البحث

  // =============================================
  // 🎯 LIFECYCLE METHODS
  // =============================================

  @override
  void initState() {
    super.initState();
    _initializeData();
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

  void _loadInitialData() async {
    await _fetchReciters();
    _getFavoriteList();
  }

  // =============================================
  // 💾 DATA MANAGEMENT
  // =============================================

  void _getFavoriteList() {
    final jsonData = getValue("favoriteRecitersList");

    if (jsonData != null) {
      try {
        final List<dynamic> favoriteReciterIds = json.decode(jsonData) as List<dynamic>;

        favoriteRecitersList = favoriteReciterIds
            .map((reciterId) {
              return reciters.firstWhere(
                (element) => element.id.toString() == reciterId.toString(),
                orElse: () => Reciter(id: -1, name: '', letter: '', moshaf: []),
              );
            })
            .where((reciter) => reciter.id != -1)
            .toList();
      } catch (e) {
        print('Error decoding favorite list or processing item: $e');
        favoriteRecitersList = [];
      }
    } else {
      favoriteRecitersList = [];
    }

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

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemScrollController.isAttached) {
        itemScrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutBack,
        );
      }
    });
  }

  // =============================================
  // 🎯 FAVORITES MANAGEMENT
  // =============================================

  void _toggleFavorite(Reciter reciter) {
    setState(() {
      if (favoriteRecitersList.contains(reciter)) {
        favoriteRecitersList.remove(reciter);
      } else {
        favoriteRecitersList.add(reciter);
      }

      List<dynamic> favoriteIds = favoriteRecitersList.map((r) => r.id).toList();
      updateValue("favoriteRecitersList", json.encode(favoriteIds));
    });
  }

  void _toggleFavoriteMode() {
    setState(() {
      if (selectedMode == "favorite") {
        selectedMode = "all";
        filteredReciters = reciters;
      } else {
        selectedMode = "favorite";
      }
      textEditingController.clear();
      searchQuery = "";
      _isSearching = false; // 💡 إخفاء البحث عند التبديل للمفضلة
      FocusManager.instance.primaryFocus?.unfocus();
    });
    _scrollToTop();
  }

  // 💡 دالة جديدة للتبديل بين وضع البحث
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        textEditingController.clear();
        searchQuery = "";
        filteredReciters = reciters;
        selectedMode = "all";
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  // =============================================
  // 🧩 UI BUILD METHODS
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getsoftOffWhite(),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // =============================================
  // 🎨 UI COMPONENTS
  // =============================================

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _getAppBarColor(),
      elevation: 0,
      // 💡 عرض مربع البحث في الـ title عند تفعيل البحث
      title: _isSearching
          ? _buildSearchField()
          : Text(
              selectedMode == "favorite" ? "favorites".tr() : "allReciters".tr(),
              style: TextStyle(color: Colors.white, fontSize: 20.sp),
            ),
      centerTitle: true,
      automaticallyImplyLeading: !_isSearching, // 💡 إخفاء زر الرجوع عند البحث
      leading: _isSearching ? null : _buildBackButton(),
      actions: [
        // 💡 زر البحث
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: Colors.white,
          ),
        ),
        // 💡 زر المفضلة (يظهر فقط عندما لا يكون في وضع البحث)
        if (!_isSearching) _buildFavoriteButtonIcon(),
        SizedBox(width: 10.w),
      ],
      // systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  Widget _buildFavoriteButtonIcon() {
    final bool isFavoriteMode = selectedMode == "favorite";
    return IconButton(
      onPressed: _toggleFavoriteMode,
      icon: Icon(
        isFavoriteMode ? FontAwesome.heart : FontAwesome.heart_empty,
        color: isFavoriteMode ? Colors.white : Colors.white.withOpacity(0.8),
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: const Icon(Entypo.logout, color: Colors.white),
    );
  }

  // 💡 تعديل مربع البحث ليكون أكثر بساطة
  Widget _buildSearchField() {
    return TextField(
      controller: textEditingController,
      autofocus: true, // 💡 لفتح الكيبورد تلقائياً
      style: const TextStyle(color: Colors.white),
      onChanged: _onSearchTextChanged,
      decoration: InputDecoration(
        hintText: "searchreciters".tr(),
        hintStyle: TextStyle(
          color: Colors.white70,
          fontSize: 16.sp,
        ),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: deepNavyBlack),
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
              style: TextStyle(color: _getcharcoalDarkGray(), fontSize: 16.sp),
            ),
            SizedBox(height: 20.h),
            if (selectedMode != "favorite")
              TextButton(
                onPressed: _fetchReciters,
                child: Text(
                  "إعادة المحاولة",
                  style: TextStyle(color: _getActionmutedGreen(), fontSize: 16.sp),
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
            padding: EdgeInsets.only(right: 16.0.w),
            child: Card(
              elevation: 8,
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
              color: _getcharcoalDarkGray(),
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
        color: _getFavoritemutedGreen(),
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
              color: _getMoshafcharcoalDarkGray(),
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
        color: _getActionmutedGreen(),
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
            return const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tealBlue,
              ),
            );
          }

          return Icon(
            snapshot.data == true ? Icons.download_done : Icons.download,
            size: 20.sp,
            color: tealBlue,
          );
        },
      ),
    );
  }

  // =============================================
  // 🔧 EVENT HANDLERS
  // =============================================

  void _onSearchTextChanged(String value) {
    setState(() {
      searchQuery = value;
    });
    if (selectedMode != "all") {
      setState(() {
        selectedMode = "all";
      });
    }
    _filterReciters(value);
  }

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

    await Future.delayed(const Duration(seconds: 3));

    setState(() => _downloadingStatus[moshaf.id] = false);
    _showSnackBar("✅ تم تحميل المصحف بنجاح", Colors.green);
  }

  void _showSnackBar(String message, Color softOffWhite) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: softOffWhite,
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

      return files.length >= surahCount * 0.8;
    } catch (e) {
      return false;
    }
  }

  // =============================================
  // 🎨 STYLE HELPER METHODS
  // =============================================

  Color _getsoftOffWhite() {
    return isDarkModeNotifier.value ? darkSlateGray : paperBeige.withOpacity(.99);
  }

  Color _getAppBarColor() {
    return isDarkModeNotifier.value ? deepNavyBlack.withOpacity(.9) : wineRed;
  }

  Color _getCardColor() {
    return isDarkModeNotifier.value ? deepNavyBlack.withOpacity(.9) : paperBeige.withOpacity(.9);
  }

  Color _getcharcoalDarkGray() {
    return isDarkModeNotifier.value ? Colors.white : Colors.black;
  }

  Color _getMoshafcharcoalDarkGray() {
    return isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black;
  }

  Color _getFavoritemutedGreen() {
    return isDarkModeNotifier.value ? softOffWhite : wineRed;
  }

  Color _getActionmutedGreen() {
    return isDarkModeNotifier.value ? softOffWhite : wineRed;
  }

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
