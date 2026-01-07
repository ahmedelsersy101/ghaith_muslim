import 'dart:convert';
import 'dart:io';
import 'package:ghaith/GlobalHelpers/home_blocs.dart';
import 'package:ghaith/core/audiopage/models/reciter.dart';
import 'package:ghaith/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_container/easy_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;

// =============================================
// 📁 IMPORTS
// =============================================
import 'package:ghaith/blocs/player_bloc_bloc.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/blocs/quran_page_player_bloc.dart';
// =============================================
// 🏗️ MAIN WIDGET - Reciters Surah List Page
// =============================================

class RecitersSurahListPage extends StatefulWidget {
  final Reciter reciter;
  final Moshaf mushaf;
  final dynamic jsonData;

  const RecitersSurahListPage({
    super.key,
    required this.reciter,
    required this.mushaf,
    required this.jsonData,
  });

  @override
  State<RecitersSurahListPage> createState() => _RecitersSurahListPageState();
}

// =============================================
// 🔧 STATE CLASS - Surah List Logic
// =============================================

class _RecitersSurahListPageState extends State<RecitersSurahListPage> {
  // =============================================
  // 🎛️ STATE VARIABLES
  // =============================================
  // تم تعريفها بـ late، لذا يجب تهيئتها قبل استخدامها
  late List<dynamic> surahs;
  late List<dynamic> filteredSurahs;
  late List<dynamic> favoriteSurahs;
  late List<dynamic> favoriteSurahList;

  final Map<String, bool> _downloadingStatus = {};
  final Map<String, bool> _playingStatus = {};
  final Map<String, double> _downloadProgress = {};
  // 🆕 متغير جديد لتخزين رمز الإلغاء/الإيقاف المؤقت لكل سورة
  final Map<String, CancelToken> _cancelTokens = {};
  // 🆕 متغير جديد لتخزين مسار الملف الجزئي (للتحميل المتقطع)
  // final Map<String, int> _downloadedBytes = {};
  // 🆕 متغير جديد لتخزين الحجم الكلي للملفات المحملة (للاستئناف)
  late Map<String, int> _fileTotalSize;
  // الوضع الافتراضي لفلتر المفضلة
  String selectedMode = "all"; // "all" أو "favorite"
  String searchQuery = "";

  final TextEditingController _textEditingController = TextEditingController();
  Directory? _appDir;

  // =============================================
  // 🎯 LIFECYCLE METHODS
  // =============================================

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

// [استبدل دالة _initializeData في _RecitersSurahListPageState]
  void _initializeData() {
    // 🆕 تحميل الحجم الكلي للملفات من Hive (ويقوم بتهيئة المتغير)
    String totalSizesJson = getValue("TotalFileSizes_Reciter") ?? "{}";

    // يتم تعيين القيمة مباشرة إلى المتغير
    _fileTotalSize = {};
    if (totalSizesJson != "{}") {
      _fileTotalSize.addAll(
          Map<String, int>.from(json.decode(totalSizesJson).map((k, v) => MapEntry(k, v as int))));
    }

    _addSuraNames();
    _loadFavorites();

    if (selectedMode == "favorite") {
      _filterFavoritesOnly();
    }

    _storePhotoUrl();
    _getAppDirectory();
  }

  // =============================================
  // 💾 DATA MANAGEMENT
  // =============================================

  void _addSuraNames() {
    final surahIds = widget.mushaf.surahList.split(',');

    // تهيئة surahs و filteredSurahs قبل استخدامها
    surahs = surahIds.map((surahId) {
      final surahData = widget.jsonData.firstWhere(
        (element) => element["id"].toString() == surahId.toString(),
        orElse: () => {"name": "Unknown"},
      );

      return {
        "surahNumber": surahId,
        "suraName": surahData["name"],
      };
    }).toList();

    filteredSurahs = surahs;

    // لا نحتاج لـ setState هنا إلا إذا تم استدعاؤها خارج initState أو عند الانتهاء من دورة حياة الـ initState
    if (mounted) setState(() {});
  }

  void _loadFavorites() {
    favoriteSurahList = json.decode(getValue("favoriteSurahList") ?? "[]");
    _filterFavoritesOnly();
    if (mounted) setState(() {});
  }

  void _filterFavoritesOnly() {
    // يتم تنفيذ هذه الدالة الآن بعد تهيئة surahs، مما يحل مشكلة الـ LateInitializationError
    favoriteSurahs = surahs.where((surah) {
      final surahKey = _getSurahKey(surah["surahNumber"]);
      return favoriteSurahList.contains(surahKey);
    }).toList();

    // إعادة تطبيق البحث على المفضلة إن كان هناك بحث مفعل
    if (searchQuery.isNotEmpty) {
      favoriteSurahs = favoriteSurahs.where((surah) {
        return quran.normalise(surah["suraName"]).contains(quran.normalise(searchQuery));
      }).toList();
    }

    // عند تفعيل وضع المفضلة، يجب أن تكون filteredSurahs هي المفضلة
    if (selectedMode == "favorite" && searchQuery.isEmpty) {
      filteredSurahs = favoriteSurahs;
    }

    if (mounted) setState(() {});
  }

  void _toggleFavorite(dynamic surah) {
    final surahKey = _getSurahKey(surah["surahNumber"]);

    setState(() {
      if (favoriteSurahList.contains(surahKey)) {
        favoriteSurahList.remove(surahKey);
      } else {
        favoriteSurahList.add(surahKey);
      }
      updateValue("favoriteSurahList", json.encode(favoriteSurahList));
      _filterFavoritesOnly(); // لتحديث قائمة المفضلة المعروضة فوراً
    });
  }

  void _filterSurahs(String query) {
    setState(() {
      final List<dynamic> sourceList = (selectedMode == "all") ? surahs : favoriteSurahs;

      filteredSurahs = sourceList.where((surah) {
        return quran.normalise(surah["suraName"]).contains(quran.normalise(query));
      }).toList();
    });
  }

  Future<void> _storePhotoUrl() async {
    final cachedKey = "${widget.reciter.name} photo url";

    if (getValue(cachedKey) == null) {
      try {
        final url =
            'https://www.googleapis.com/customsearch/v1?key=AIzaSyCR7ttKFGB4dG5MDJI3ygqiESjpWmKePrY&cx=f7b7aaf5b2f0e47e0&q=القارئ ${widget.reciter.name}&searchType=image';
        final response = await Dio().get(url);

        if (response.statusCode == 200) {
          updateValue(cachedKey, response.data["items"][0]['link']);
          if (mounted) setState(() {});
        }
      } catch (error) {
        print('Error storing photo URL: $error');
      }
    }
  }

  Future<Directory> _getAppDirectory() async {
    if (_appDir != null) return _appDir!;

    final dir = await getExternalStorageDirectory();
    final path = Directory('${dir!.path}/Ghaith');

    if (!(await path.exists())) {
      await path.create(recursive: true);
    }

    _appDir = path;
    return path;
  }

  // =============================================
  // 🔧 HELPER METHODS
  // =============================================

  String _getSurahKey(String surahNumber) {
    return "${widget.reciter.name}${widget.mushaf.name}$surahNumber".trim();
  }

  String _getSurahName(dynamic surah) {
    final surahNumber = surah["surahNumber"];
    return quran.getSurahNameArabic(int.parse(surahNumber));
  }

  String _getRevelationPlace(String surahNumber) {
    final place = quran.getPlaceOfRevelation(int.parse(surahNumber));
    return (place == "makkah" || place == "Makkah") ? "Makkah" : "Madinah";
  }

  String _getFilePath(String surahNumber, Directory dir) {
    final surahNameArabic = quran.getSurahNameArabic(int.parse(surahNumber));
    return "${dir.path}/${widget.reciter.name}-${widget.mushaf.id}-$surahNameArabic.mp3";
  }

// [استبدل هذه الدالة]
  int _getSurahIndex(dynamic surah) {
    // 🆕 [تعديل] نحدد القائمة التي سنبحث فيها
    if (selectedMode == "favorite") {
      // البحث في قائمة المفضلة
      return favoriteSurahs.indexOf(surah);
    }
    // البحث في القائمة الكاملة "surahs" (السلوك الافتراضي)
    return surahs.indexOf(surah);
  }

  List<dynamic> _getCurrentSurahsList() {
    // في حالة وجود بحث، نعرض filteredSurahs
    if (searchQuery.isNotEmpty) return filteredSurahs;

    // إذا لم يكن هناك بحث، نعرض إما كل السور أو المفضلة
    return selectedMode == "all" ? surahs : favoriteSurahs;
  }

  Moshaf _createFavoriteMushaf() {
    // 1. نحصل على قائمة أرقام السور من قائمة المفضلة
    // (نحن نفترض أن 'favoriteSurahs' مرتبة بنفس ترتيب 'surahs')
    final favoriteSurahIds = favoriteSurahs.map((surah) {
      return surah["surahNumber"].toString();
    }).toList();

// 2. نحولها إلى نص مفصول بفاصلة
    final String favoriteSurahListString = favoriteSurahIds.join(',');

// 3. ننشئ نسخة "مؤقتة" من المصحف
// نستخدم بيانات المصحف الأصلي، لكن نستبدل قائمة السور
    return Moshaf(
      id: widget.mushaf.id,
      name: widget.mushaf.name,
      server: widget.mushaf.server,
      surahTotal: favoriteSurahIds.length.toString(),
      surahList: favoriteSurahListString,
// 🆕 [هذا هو الإصلاح]
// نقوم بتمرير نفس نوع المصحف من المصحف الأصلي
      moshafType: widget.mushaf.moshafType,
    );
  }
  // =============================================
  // 🧩 UI BUILD METHODS
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: _getBackgroundColor(),
          appBar: _buildAppBar(),
          body: _buildSurahList(),
        ),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _getAppBarColor(),
      elevation: 0,
      foregroundColor: _getForegroundColor(),
      title: Text(
        "${widget.reciter.name} - ${widget.mushaf.name}",
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
      automaticallyImplyLeading: true,
      bottom: _buildAppBarBottom(),
      actions: [
        _buildReciterPhoto(),
      ],
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  Widget _buildReciterPhoto() {
    final photoUrl = getValue("${widget.reciter.name} photo url") ?? "";
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: orangeColor,
        backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
        child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
      ),
    );
  }

  // زر تبديل عرض المفضلة
  Widget _buildFavoriteFilterButton() {
    final isFavoriteMode = selectedMode == "favorite";
    return IconButton(
      onPressed: _toggleFavoriteMode,
      icon: Icon(
        isFavoriteMode ? Icons.favorite : Icons.favorite_border,
        color: isFavoriteMode ? Colors.white : Colors.white,
      ),
      tooltip: isFavoriteMode ? "عرض كل السور" : "عرض المفضلة",
    );
  }

  // // زر تحميل جميع السور
  // Widget _buildDownloadAllButton() {
  //   return IconButton(
  //     onPressed: _onDownloadAllPressed,
  //     icon: const Icon(Icons.cloud_download, color: Colors.white),
  //     tooltip: "تحميل جميع السور",
  //   );
  // }

  PreferredSize _buildAppBarBottom() {
    return PreferredSize(
      preferredSize: Size(
        MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height * .1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            _buildSearchField(),
            // _buildDownloadAllButton(), // زر تحميل الكل الجديد
            _buildFavoriteFilterButton(), // زر المفضلة الجديد
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
                    controller: _textEditingController,
                    onChanged: _onSearchTextChanged,
                    decoration: InputDecoration(
                      hintText: "searchBysura".tr(),
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
          searchQuery.isEmpty ? FontAwesome.search : Icons.close,
          color: const Color.fromARGB(73, 0, 0, 0),
        ),
      ),
    );
  }

  Widget _buildSurahList() {
    final currentSurahs = _getCurrentSurahsList();

    if (currentSurahs.isEmpty) {
      return Center(
        child: Text(
          selectedMode == "favorite" ? "لا توجد سور مفضلة" : "لا توجد نتائج بحث",
          style: TextStyle(
            color: _getTextColor(),
            fontSize: 18.sp,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: ListView.separated(
        padding: EdgeInsets.only(top: 150.h), // مسافة من تحت شريط التطبيق
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => const Divider(),
        itemCount: currentSurahs.length,
        itemBuilder: (context, index) => _buildSurahItem(currentSurahs[index], index),
      ),
    );
  }

  Widget _buildSurahItem(dynamic surah, int index) {
    return EasyContainer(
      borderRadius: 0,
      elevation: 0,
      padding: 4,
      margin: 0,
      onTap: () => _onSurahTap(surah, index),
      color: _getCardColor(),
      child: ListTile(
        leading: _buildRevelationIcon(surah),
        trailing: _buildSurahActions(surah, index),
        title: _buildSurahTitle(surah),
      ),
    );
  }

  Widget _buildRevelationIcon(dynamic surah) {
    final surahNumber = surah["surahNumber"];
    final place = _getRevelationPlace(surahNumber);

    return Image.asset(
      "assets/images/$place.png",
      height: 25.h,
      width: 25.w,
    );
  }

  Widget _buildSurahTitle(dynamic surah) {
    return Text(
      _getSurahName(surah),
      style: TextStyle(
        fontFamily: context.locale.languageCode == "ar" ? "qaloon" : "roboto",
        fontSize: context.locale.languageCode == "ar" ? 22.sp : 17.sp,
        color: _getTextColor(),
      ),
    );
  }

  Widget _buildSurahActions(dynamic surah, int index) {
    return SizedBox(
      width: 160.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildPlayButton(surah),
          _buildDownloadButton(surah),
          _buildFavoriteButton(surah),
        ],
      ),
    );
  }

  Widget _buildPlayButton(dynamic surah) {
    final surahKey = "${surah["surahNumber"]}-${widget.mushaf.id}";
    final isPlaying = _playingStatus[surahKey] ?? false;

    return IconButton(
      onPressed: () => _onPlayPressed(surah, surahKey, isPlaying),
      icon: Icon(
        isPlaying ? Icons.pause : Icons.play_arrow,
        size: 24.sp,
        color: blueColor,
      ),
    );
  }

  Widget _buildDownloadButton(dynamic surah) {
    final surahNumber = surah["surahNumber"];

    return IconButton(
      onPressed: () => _onDownloadPressed(surahNumber),
      icon: FutureBuilder<Directory>(
        future: _getAppDirectory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Icon(Icons.download, size: 24.sp);
          }
          return _buildDownloadIcon(surahNumber, snapshot.data!);
        },
      ),
      color: orangeColor,
    );
  }

// =============================================
// 🧩 UI BUILD METHODS
// =============================================
// ... (الكود السابق)

// [استبدل هذه الدالة]
  Widget _buildDownloadIcon(String surahNumber, Directory dir) {
    final filePath = _getFilePath(surahNumber, dir);
    final fileExists = File(filePath).existsSync();
    final isDownloading = _downloadingStatus[surahNumber] ?? false;
    final progress = _downloadProgress[surahNumber] ?? 0.0;

    // 1. تحديد حالة الاكتمال الدائمة:
    bool isCompleted = false;
    if (_fileTotalSize.containsKey(surahNumber) && fileExists) {
      // الملف مكتمل إذا كان حجمه يساوي أو أكبر من الحجم الكلي المخزن
      isCompleted = File(filePath).lengthSync() >= _fileTotalSize[surahNumber]!;
    }

    // 2. حالة التحميل الجاري (الحالة المؤقتة الوحيدة التي يمكن عرضها)
    if (isDownloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              backgroundColor: Colors.grey.shade300,
              color: const Color(0xFF00A2B5),
              value: progress > 0.0 ? progress : null,
            ),
          ),
          // [التعديل] أيقونة الإلغاء بدلاً من الإيقاف المؤقت
          Icon(
            Icons.close,
            size: 16.sp,
            color: Colors.red,
          ),
        ],
      );
    }

    // 3. عرض الحالة الدائمة بعد العودة للصفحة (عدم وجود isDownloading):

    if (isCompleted) {
      // ✅ اكتمل التحميل: عرض علامة الصح الخضراء
      return Icon(
        Icons.download_done,
        size: 24.sp,
        color: Colors.green,
      );
    } else if (fileExists && !isCompleted) {
      // ⏯️ ملف جزئي موجود (تم إيقافه مؤقتاً أو فقدت حالته): عرض زر الاستئناف (Play)
      // هذا هو الحل لمشكلة الملفات التي فقدت حالتها بعد التنقل.
      return Icon(
        Icons.download_done,
        size: 24.sp,
        color: orangeColor,
      );
    }

    // ⬇️ لم يبدأ التحميل: عرض أيقونة التحميل العادية
    return Icon(
      Icons.download,
      size: 24.sp,
      color: orangeColor,
    );
  }

  Widget _buildFavoriteButton(dynamic surah) {
    final isFavorite = favoriteSurahList.contains(_getSurahKey(surah["surahNumber"]));

    return IconButton(
      onPressed: () => _toggleFavorite(surah),
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        size: 24.sp,
      ),
      color: orangeColor,
    );
  }

  // =============================================
  // 🔧 EVENT HANDLERS & SERVICE METHODS
  // =============================================

  void _onSearchTextChanged(String value) {
    setState(() {
      searchQuery = value.trim();
    });

    if (searchQuery.isEmpty) {
      if (selectedMode == "all") {
        filteredSurahs = surahs;
      } else {
        _filterFavoritesOnly();
      }
    } else {
      _filterSurahs(searchQuery);
    }
  }

  void _onSearchActionTap() {
    if (searchQuery.isNotEmpty) {
      _textEditingController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        searchQuery = "";
        if (selectedMode == "all") {
          filteredSurahs = surahs;
        } else {
          _filterFavoritesOnly();
        }
      });
    }
  }

  void _toggleFavoriteMode() {
    setState(() {
      if (selectedMode == "all") {
        selectedMode = "favorite";
        _filterFavoritesOnly();
        filteredSurahs = favoriteSurahs;
      } else {
        selectedMode = "all";
        _addSuraNames();
        filteredSurahs = surahs;
      }
      // مسح شريط البحث عند التبديل
      _textEditingController.clear();
      searchQuery = "";
    });
  }

  Future<void> _onSurahTap(dynamic surah, int index) async {
    if (qurapPagePlayerBloc.state is QuranPagePlayerPlaying) {
      await _showPlayerCloseDialog();
      return;
    }

    //  التعديل هنا: نستخدم "_getSurahIndex(surah)" بدلاً من "index"
    _startPlayingSurah(surah, _getSurahIndex(surah));
  }

  Future<void> _onPlayPressed(dynamic surah, String surahKey, bool isPlaying) async {
    if (isPlaying) {
      playerPageBloc.add(PausePlayer());
      setState(() => _playingStatus[surahKey] = false);
      return;
    }

    _playingStatus.updateAll((key, value) => false);

    setState(() => _playingStatus[surahKey] = true);
    _startPlayingSurah(surah, _getSurahIndex(surah));
  }

// =============================================
// 🔧 EVENT HANDLERS & SERVICE METHODS
// =============================================
// ... (الكود السابق)

  Future<void> _onDownloadPressed(String surahNumber) async {
    final dir = await _getAppDirectory();
    final filePath = _getFilePath(surahNumber, dir);
    final fileExists = File(filePath).existsSync();

    // تحديد حالة الاكتمال الدائمة
    bool isCompleted = false;
    if (_fileTotalSize.containsKey(surahNumber) && fileExists) {
      isCompleted = File(filePath).lengthSync() >= _fileTotalSize[surahNumber]!;
    }

    // 1. [تعديل] التحقق من حالة التحميل الجاري (للإلغاء والحذف)
    if (_downloadingStatus[surahNumber] == true) {
      // إرسال أمر الإلغاء
      _cancelTokens[surahNumber]?.cancel("User cancelled and deleted");

      // عرض رسالة فورية (سيتم الحذف الفعلي في دالة _downloadSurah)
      _showSnackBar("جاري إلغاء التحميل وحذف الملف...", Colors.red);
      return;
    }

    // 2. التحقق من اكتمال التحميل
    if (isCompleted) {
      _showSnackBar("✅ السورة محمّلة بالفعل", Colors.green);
      return;
    }

    // 3. الاستئناف (لم تكن جارية، وليست مكتملة، لكن الملف موجود - يعني ملف جزئي)
    if (fileExists && !isCompleted) {
      await _downloadSurah(surahNumber, filePath);
      return;
    }

    // 4. بدء تحميل جديد (في حالة عدم وجود الملف أصلاً)
    await _downloadSurah(surahNumber, filePath);
  }
  // Future<void> _onDownloadAllPressed() async {
  //   _showSnackBar("⏳ جاري بدء تحميل جميع السور...", const Color(0xFF00A2B5));

  //   final dir = await _getAppDirectory();
  //   final allSurahsToDownload = surahs;

  //   for (final surah in allSurahsToDownload) {
  //     final surahNumber = surah["surahNumber"];
  //     final filePath = _getFilePath(surahNumber, dir);

  //     if (!File(filePath).existsSync() && (_downloadingStatus[surahNumber] != true)) {
  //       await _downloadSurah(surahNumber, filePath);
  //       // الانتظار قليلاً بين عمليات التحميل لتجنب الضغط على الشبكة
  //       await Future.delayed(const Duration(milliseconds: 500));
  //     }
  //   }

  //   _showSnackBar("✅ انتهت محاولة تحميل جميع السور", Colors.green);
  // }

  // [استبدل هذه الدالة]
  void _startPlayingSurah(dynamic surah, int index) {
    // 🆕 [تعديل]
    // 1. نحدد المصحف الذي سيتم تشغيله
    final Moshaf playlistMushaf = (selectedMode == "all")
        ? widget.mushaf // المصحف الأصلي الكامل
        : _createFavoriteMushaf(); // المصحف المؤقت للمفضلة

    // 2. (الـ index أصبح صحيحاً الآن بفضل تعديل _getSurahIndex)

    playerPageBloc.add(StartPlaying(
      buildContext: context,
      moshaf: playlistMushaf, // 🆕 نستخدم المصحف الصحيح (الكامل أو المفضلة)
      reciter: widget.reciter,
      suraNumber: int.parse(surah["surahNumber"]),
      initialIndex: index, // 🆕 الـ 'index' الآن صحيح 100%
      jsonData: widget.jsonData,
    ));
  }

// =============================================
// 🔧 EVENT HANDLERS & SERVICE METHODS
// =============================================
// ...

// [استبدل هذه الدالة]
  // =============================================
// 🔧 EVENT HANDLERS & SERVICE METHODS
// =============================================
// ... (الكود السابق)

  Future<void> _downloadSurah(String surahNumber, String filePath) async {
    final downloadUrl = "${widget.mushaf.server}/${surahNumber.padLeft(3, "0")}.mp3";
    final file = File(filePath);

    // 1. تحديد عدد البايتات المحملة مسبقاً (لاستئناف التحميل)
    int downloadedBytes = 0;
    if (file.existsSync()) {
      downloadedBytes = await file.length();
    }

    // 2. [إعادة إضافة] تحديث الـ Cancel Token
    final token = CancelToken();
    _cancelTokens[surahNumber] = token;

    // 3. تحديث حالة الواجهة للبدء
    if (mounted) {
      setState(() {
        _downloadingStatus[surahNumber] = true;
        // إعادة حساب نسبة التقدم الأولية
        if (_fileTotalSize.containsKey(surahNumber) && _fileTotalSize[surahNumber]! > 0) {
          _downloadProgress[surahNumber] = downloadedBytes / _fileTotalSize[surahNumber]!;
        } else {
          _downloadProgress[surahNumber] = 0.0;
        }
      });
      _showSnackBar("⬇️ جاري تحميل سورة ${quran.getSurahNameArabic(int.parse(surahNumber))}...",
          const Color(0xFF00A2B5));
    }

    try {
      // 4. [إعادة إضافة] إرسال طلب التحميل مع cancelToken
      await Dio().download(
        downloadUrl,
        filePath,
        options: Options(
          headers: {HttpHeaders.rangeHeader: 'bytes=$downloadedBytes-'},
        ),
        deleteOnError: false, // مهم: لا تحذف الملف تلقائياً عند الخطأ
        cancelToken: token, // <--- تمت الإعادة
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            if (!_fileTotalSize.containsKey(surahNumber)) {
              _fileTotalSize[surahNumber] = downloadedBytes + total;
            }

            final totalSize = _fileTotalSize[surahNumber];

            if (totalSize != null && totalSize > 0) {
              int totalReceived = downloadedBytes + received;
              double newProgress = totalReceived / totalSize;

              setState(() {
                _downloadProgress[surahNumber] = newProgress;
              });
            }
          }
        },
      );

      // 5. عند الاكتمال بنجاح (نفس الكود)
      playerPageBloc.add(DownloadSurah(
        reciter: widget.reciter,
        moshaf: widget.mushaf,
        suraNumber: surahNumber,
        url: downloadUrl,
        savePath: filePath,
      ));

      if (mounted) {
        final file = File(filePath);
        if (file.existsSync()) {
          _fileTotalSize[surahNumber] = file.lengthSync();
          updateValue("TotalFileSizes_Reciter", json.encode(_fileTotalSize));
        }
        setState(() {
          _downloadingStatus[surahNumber] = false;
          _downloadProgress.remove(surahNumber);
          _cancelTokens.remove(surahNumber); // <--- تمت الإعادة
        });
        _showSnackBar("✅ تم تحميل سورة ${quran.getSurahNameArabic(int.parse(surahNumber))} بنجاح",
            Colors.green);
      }
    } on DioException catch (error) {
      // 6. [تعديل] التعامل مع الإلغاء (الحذف)
      if (error.type == DioExceptionType.cancel) {
        if (mounted) {
          // نقوم بحذف الملف
          if (await file.exists()) {
            await file.delete();
          }

          // تحديث الحالة والواجهة
          setState(() {
            _downloadingStatus[surahNumber] = false;
            _downloadProgress.remove(surahNumber);
            _cancelTokens.remove(surahNumber); // <--- تمت الإعادة
            _fileTotalSize.remove(surahNumber); // <--- مهم جداً
          });

          // تحديث Hive
          updateValue("TotalFileSizes_Reciter", json.encode(_fileTotalSize));

          _showSnackBar(
              "❌ تم إلغاء تحميل سورة ${quran.getSurahNameArabic(int.parse(surahNumber))} وحذف الملف",
              Colors.red);
        }
      } else {
        // 7. التعامل مع الأخطاء الأخرى (نفس الكود)
        if (mounted) {
          setState(() {
            _downloadingStatus[surahNumber] = false;
            _downloadProgress.remove(surahNumber);
            _cancelTokens.remove(surahNumber); // <--- تمت الإعادة
            _fileTotalSize.remove(surahNumber);
          });
          updateValue("TotalFileSizes_Reciter", json.encode(_fileTotalSize));
          _showSnackBar(
              "❌ فشل تحميل سورة ${quran.getSurahNameArabic(int.parse(surahNumber))}", Colors.red);
        }
      }
    }
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

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
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

  Color _getForegroundColor() {
    return isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight;
  }

  Color _getCardColor() {
    return isDarkModeNotifier.value ? darkModeSecondaryColor.withOpacity(.9) : Colors.white;
  }

  Color _getTextColor() {
    return isDarkModeNotifier.value ? Colors.white.withOpacity(.9) : Colors.black87;
  }
}
