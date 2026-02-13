// ignore_for_file: unrelated_type_equality_checks, depend_on_referenced_packages, file_names
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' as flutter_foundation;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:ghaith/core/QuranPages/views/quran_sura_list.dart';
import 'package:ghaith/core/QuranPages/widgets/bottom_sheets/ayah_options_sheet.dart';
import 'package:ghaith/helpers/home_state.dart';
import '../helpers/translation/get_translation_data.dart' as get_translation_data;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:ghaith/core/QuranPages/helpers/translation/translationdata.dart';
import 'package:ghaith/models/reciter.dart';
import 'package:ghaith/core/QuranPages/helpers/convertNumberToAr.dart';
import 'package:ghaith/core/QuranPages/widgets/common/bismallah.dart';
import 'package:ghaith/core/QuranPages/widgets/common/header_widget.dart';
import 'package:quran/quran.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:io';
import 'package:easy_container/easy_container.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:ghaith/blocs/quran_page_player_bloc.dart';
import 'package:ghaith/blocs/bookmark_cubit.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:quran/quran.dart' as quran;
import 'package:ghaith/blocs/quran_reading_cubit.dart';
import 'package:ghaith/core/QuranPages/models/bookmark_model.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ghaith/core/QuranPages/widgets/common/mushaf_divider.dart';
import 'package:ghaith/core/QuranPages/widgets/common/mushaf_page_shell.dart';
import 'package:ghaith/core/QuranPages/widgets/bottom_sheets/settings_bottom_sheet.dart';
part 'alignment_views/verse_by_verse_view.dart';
part 'alignment_views/vertical_view.dart';
part 'alignment_views/page_view.dart';

class QuranReadingPage extends StatelessWidget {
  const QuranReadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranReaderCubit, QuranReadingState>(
      buildWhen: (previous, current) => previous.isLoading != current.isLoading,
      builder: (context, state) {
        if (state.isLoading) {
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return QuranDetailsPage(
          pageNumber: state.position.page,
          jsonData: widgejsonData,
          quarterJsonData: quarterjsonData,
          shouldHighlightText: false,
          highlightVerse: "",
          shouldHighlightSura: false,
        );
      },
    );
  }
}

class QuranDetailsPage extends StatefulWidget {
  int pageNumber;
  var jsonData;
  var quarterJsonData;
  var shouldHighlightText;
  var highlightVerse;
  var shouldHighlightSura;
  // var highlighSurah;
  QuranDetailsPage(
      {super.key,
      required this.pageNumber,
      required this.jsonData,
      required this.shouldHighlightText,
      required this.highlightVerse,
      required this.quarterJsonData,
      required this.shouldHighlightSura});

  @override
  State<QuranDetailsPage> createState() => QuranDetailsPageState();
}

class QuranDetailsPageState extends State<QuranDetailsPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  // ==================== Controllers ====================
  final ScrollController _scrollController = ScrollController();
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  late PageController _pageController;
  ScreenshotController screenshotController = ScreenshotController();

  // ==================== State Variables ====================
  int index = 0;
  int playIndexPage = 0;
  String selectedSpan = "";
  String isDownloading = "";
  var highlightVerse;
  var shouldHighlightText;
  var currentVersePlaying;
  var dataOfCurrentTranslation;
  String? swipeDirection;

  // ==================== Full Surah Playback ====================
  int? currentSurahNumber;
  int? currentPlayingVerse = 0; // الآية التي يتم تشغيلها حالياً
  StreamSubscription<SequenceState?>? positionSubscription;
  StreamSubscription<ProcessingState>? processingSubscription;
  Timer? verseTrackingTimer;
  bool isTrackingStarted = false; // flag لمنع بدء التتبع مرتين

  // ==================== Bookmarks & Starred Verses ====================
  List<BookmarkModel> bookmarks = [];
  Set<String> starredVerses = {};

  // ==================== UI State ====================
  double valueOfSlider = 0;
  double currentHeight = 2.0;
  double currentLetterSpacing = 0.0;
  bool showSuraHeader = true;
  bool addAppSlogan = true;

  // ==================== Helpers ====================
  late Timer timer;
  Directory? appDir;
  var english = RegExp(r'[a-zA-Z]');
  List<GlobalKey> richTextKeys = List.generate(604, (_) => GlobalKey());
  GlobalKey scaffoldKey = GlobalKey<ScaffoldState>();

  // ==================== Reciters ====================
  List<QuranPageReciter> reciters = [];

  // ==================== Quran Reading Cubit Sync ====================
  bool _hasSyncedInitialPosition = false;

  // ==================== Initialization Methods ====================

  void setIndex() {
    setState(() {
      index = widget.pageNumber;
    });
  }

  Future<void> initialize() async {
    appDir = await getTemporaryDirectory();
    getTranslationData();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> checkIfSelectHighlight() async {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (selectedSpan != "") {
        setState(() {
          selectedSpan = "";
        });
      }
    });
  }

  // ==================== Data Fetching Methods ====================

  void fetchBookmarks() {
    final state = context.read<BookmarkCubit>().state;
    setState(() {
      bookmarks = state.bookmarks;
    });
  }

  static Future<dynamic> _decodeJson(String jsonString) async {
    return json.decode(jsonString);
  }

  Future<void> getTranslationData() async {
    if (getValue("indexOfTranslationInVerseByVerse") > 1) {
      File file = File(
          "${appDir!.path}/${translationDataList[getValue("indexOfTranslationInVerseByVerse")].typeText}.json");

      if (await file.exists()) {
        String jsonData = await file.readAsString();
        // Offload JSON decoding to background thread
        dataOfCurrentTranslation = await flutter_foundation.compute(_decodeJson, jsonData);
      }
    }
    if (mounted) setState(() {});
  }

  // [CAN_BE_EXTRACTED] -> helpers/audio_url_fixer.dart
  String fixAudioUrl(String url) {
    if (url.contains('audio-surah')) {
      return url.replaceAll('audio-surah', 'audio');
    }
    return url;
  }

  @override
  void initState() {
    super.initState();

    // Initialize data
    setIndex();
    fetchBookmarks();
    initialize();
    getTranslationData();
    addReciters();

    // Setup listeners
    _scrollController.addListener(_scrollListener);
    checkIfSelectHighlight();

    // Setup page controller
    _pageController = PageController(initialPage: widget.pageNumber);
    _pageController.addListener(_pagecontroller_scrollListner);

    // Setup highlight animations
    changeHighlightSurah();
    highlightVerseFunction();

    // Configure system UI
    _configureSystemUI();
  }

  @override
  void didUpdateWidget(QuranDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageNumber != oldWidget.pageNumber && widget.pageNumber != index) {
      // Only update local state if widget.pageNumber changed due to a deliberate parent update,
      // though now we handle most updates via BlocListener.
      setState(() {
        index = widget.pageNumber;
      });
      // We rely on BlocListener for navigation now to avoid conflicts
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ensure we only sync the initial reading position once.
    if (!_hasSyncedInitialPosition) {
      _hasSyncedInitialPosition = true;

      // Precache the Quran page background image for smoother transition
      precacheImage(const AssetImage("assets/images/quran.jpg"), context);

      final readerCubit = context.read<QuranReaderCubit>();
      readerCubit.updateFromPageChange(widget.pageNumber);
    }
  }

  // ==================== System UI Configuration ====================

  void _configureSystemUI() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // [CAN_BE_EXTRACTED] -> helpers/reciters_helper.dart
  void addReciters() {
    quran.getReciters().forEach((element) {
      reciters.add(QuranPageReciter(
        identifier: element["identifier"],
        language: element["language"],
        name: element["name"],
        englishName: element["englishName"],
        format: element["format"],
        type: element["type"],
        direction: element["direction"],
      ));
    });
  }

  // ==================== Scroll Listeners ====================

  void _scrollListener() {
    if (_scrollController.position.isScrollingNotifier.value && selectedSpan != "") {
      setState(() {
        selectedSpan = "";
      });
    }
  }

  void _pagecontroller_scrollListner() {
    if (_pageController.position.isScrollingNotifier.value && selectedSpan != "") {
      setState(() {
        selectedSpan = "";
      });
    }
  }

  // ==================== Highlight Functions ====================

  Future<void> changeHighlightSurah() async {
    await Future.delayed(const Duration(seconds: 2));
    widget.shouldHighlightSura = false;
  }

  void highlightVerseFunction() {
    setState(() {
      shouldHighlightText = widget.shouldHighlightText;
    });
    if (widget.shouldHighlightText) {
      // إذا كان highlightVerse نص آية، نحوله للتنسيق الجديد
      if (widget.highlightVerse is String && widget.highlightVerse.toString().isNotEmpty) {
        // محاولة استخراج رقم السورة والآية من النص
        final verseText = widget.highlightVerse.toString();
        // البحث في بيانات الصفحة الحالية للعثور على الآية
        try {
          final pageData = quran.getPageData(index > 0 ? index : widget.pageNumber);
          for (var e in pageData) {
            for (var i = e["start"]; i <= e["end"]; i++) {
              if (quran.getVerse(e["surah"], i) == verseText) {
                highlightVerse = " ${e["surah"]}$i";
                break;
              }
            }
          }
        } catch (e) {
          highlightVerse = widget.highlightVerse;
        }
      } else {
        highlightVerse = widget.highlightVerse;
      }

      Timer.periodic(const Duration(milliseconds: 400), (timer) {
        if (mounted) {
          setState(() {
            shouldHighlightText = false;
          });
        }
        Timer(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              shouldHighlightText = true;
            });
          }
          if (timer.tick == 4) {
            if (mounted) {
              setState(() {
                highlightVerse = "";

                shouldHighlightText = false;
              });
            }
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    // Cancel timers
    timer.cancel();
    verseTrackingTimer?.cancel();

    // Cancel subscriptions
    positionSubscription?.cancel();
    processingSubscription?.cancel();

    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Cleanup
    getTotalCharacters(quran.getVersesTextByPage(widget.pageNumber));

    super.dispose();
  }

  // ==================== Utility Methods ====================

  int total = 0;
  int total1 = 0;
  int total3 = 0;

  int getTotalCharacters(List<String> stringList) {
    total = 0;
    for (String str in stringList) {
      total += str.length;
    }
    return total;
  }

  void checkIfAyahIsAStartOfSura() {}

  bool hasLocalBookmark(int surahNumber, int verseNumber) {
    return bookmarks.any(
      (b) => b.suraNumber == surahNumber && b.verseNumber == verseNumber,
    );
  }

  Color? localBookmarkColor(int surahNumber, int verseNumber) {
    for (final b in bookmarks) {
      if (b.suraNumber == surahNumber && b.verseNumber == verseNumber) {
        try {
          return Color(int.parse('0x${b.color}'));
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  /// Resolve the initial page index for scrollable views (vertical / verse-by-verse)
  /// using the QuranReaderCubit when available, otherwise falling back to the
  /// legacy `lastRead` Hive value.
  int getInitialPageIndex(BuildContext context) {
    final readerCubit = context.watch<QuranReaderCubit>();
    final dynamic legacyLastRead = getValue("lastRead");

    if (!readerCubit.state.isLoading) {
      return readerCubit.state.position.page;
    }

    if (legacyLastRead is int && legacyLastRead > 0) {
      return legacyLastRead;
    }

    // Fallback to first page (Al-Fatiha)
    return 1;
  }

  // [CAN_BE_EXTRACTED] -> helpers/quran_page_helper.dart
  Result checkIfPageIncludesQuarterAndQuarterIndex(array, pageData, indexes) {
    for (int i = 0; i < array.length; i++) {
      int surah = array[i]['surah'];
      int ayah = array[i]['ayah'];
      for (int j = 0; j < pageData.length; j++) {
        int pageSurah = pageData[j]['surah'];
        int start = pageData[j]['start'];
        int end = pageData[j]['end'];
        if ((surah == pageSurah) && (ayah >= start) && (ayah <= end)) {
          int targetIndex = i + 1;
          for (int hizbIndex = 0; hizbIndex < indexes.length; hizbIndex++) {
            List<int> hizb = indexes[hizbIndex];
            for (int quarterIndex = 0; quarterIndex < hizb.length; quarterIndex++) {
              if (hizb[quarterIndex] == targetIndex) {
                return Result(true, i, hizbIndex, quarterIndex);
              }
            }
          }
        }
      }
    }
    return Result(false, -1, -1, -1);
  }

  // ==================== Build Method ====================

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenSize = MediaQuery.of(context).size;

    return MultiBlocListener(
      listeners: [
        BlocListener<BookmarkCubit, BookmarkState>(
          listener: (context, state) {
            setState(() {
              bookmarks = state.bookmarks;
            });
          },
        ),
        BlocListener<QuranReaderCubit, QuranReadingState>(
          listenWhen: (previous, current) => previous.position.page != current.position.page,
          listener: (context, state) {
            final int targetPage = state.position.page;
            // Use the controller's page as the truth if available, otherwise fallback to index.
            // This prevents conflicts if didUpdateWidget updated 'index' prematurely.
            final int currentPage =
                _pageController.hasClients ? (_pageController.page?.round() ?? index) : index;

            if (targetPage != currentPage) {
              setState(() {
                index = targetPage;
              });
              if (_pageController.hasClients) {
                final int diff = (targetPage - currentPage).abs();
                if (diff > 5) {
                  _pageController.jumpToPage(targetPage);
                } else {
                  _pageController.animateToPage(
                    targetPage,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutQuart,
                  );
                }
              }
              if (itemScrollController.isAttached) {
                itemScrollController.jumpTo(index: targetPage);
              }
            }
          },
        ),
      ],
      child: BlocBuilder<QuranPagePlayerBloc, QuranPagePlayerState>(
        builder: (context, state) {
          return SafeArea(
            child: Scaffold(
              key: scaffoldKey,
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.transparent,
              body: Builder(
                builder: (context2) {
                  return _buildAlignmentView(screenSize, context);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== Immersive Chrome ====================

  // Widget _buildTopChrome(
  //   BuildContext context,
  //   Size screenSize,
  //   QuranReadingState readingState,
  // ) {
  //   final bool isVisible = readingState.isChromeVisible;
  //   final theme = Theme.of(context);

  //   return Positioned(
  //     top: 0,
  //     left: 0,
  //     right: 0,
  //     child: AnimatedSlide(
  //       duration: const Duration(milliseconds: 220),
  //       curve: Curves.easeInOut,
  //       offset: Offset(0, isVisible ? 0 : -1),
  //       child: AnimatedOpacity(
  //         duration: const Duration(milliseconds: 200),
  //         opacity: isVisible ? 1 : 0,
  //         child: Container(
  //           height: 56.h,
  //           margin: EdgeInsets.symmetric(vertical: 8.h),
  //           padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
  //           decoration: BoxDecoration(
  //             color: isDarkModeNotifier.value ? Colors.black : paperBeige,
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.15),
  //                 blurRadius: 12,
  //                 offset: const Offset(0, 4),
  //               ),
  //             ],
  //           ),
  //           child: Row(
  //             children: [
  //               IconButton(
  //                 icon: Icon(
  //                   Icons.arrow_back_ios_new_rounded,
  //                   size: 18.sp,
  //                 ),
  //                 onPressed: () => Navigator.pop(context),
  //               ),
  //               SizedBox(width: 4.w),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Text(
  //                       quran.getSurahNameArabic(
  //                         readingState.position.surahNumber,
  //                       ),
  //                       overflow: TextOverflow.ellipsis,
  //                       style: TextStyle(
  //                         fontFamily: 'arsura',
  //                         fontSize: 16.sp,
  //                         fontWeight: FontWeight.w700,
  //                       ),
  //                     ),
  //                     SizedBox(height: 2.h),
  //                     Text(
  //                       '${"page".tr()} ${readingState.position.page} • ${"ayah".tr()} ${convertToArabicNumber(readingState.position.ayahNumber.toString())}',
  //                       overflow: TextOverflow.ellipsis,
  //                       style: TextStyle(
  //                         fontSize: 11.sp,
  //                         color: Colors.grey.withOpacity(0.8),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               IconButton(
  //                 icon: const Icon(Icons.settings_rounded),
  //                 onPressed: () {
  //                   SettingsBottomSheet.show(
  //                     context,
  //                     onSettingsChanged: () {
  //                       getTranslationData();
  //                       updateState(() {});
  //                     },
  //                   );
  //                 },
  //               ),
  //               IconButton(
  //                 icon: const Icon(Icons.menu_book_rounded),
  //                 onPressed: () async {
  //                   final page = await showSurahNavigatorSheet(context);
  //                   if (page != null && context.mounted) {
  //                     context.read<QuranReaderCubit>().goToPage(page);
  //                   }
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  static Future<int?> showSurahNavigatorSheet(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.only(top: 100),
          child: SurahListPage(
            jsonData: widgejsonData,
            quarterjsonData: quarterjsonData,
          ),
        );
      },
    );
  }

  // ==================== View Selection ====================

  Widget _buildAlignmentView(Size screenSize, BuildContext context) {
    final alignmentType = getValue("alignmentType");

    switch (alignmentType) {
      case "verticalview":
        return buildVerticalView(screenSize, context);
      case "pageview":
        return buildPageView(context, screenSize);
      case "versebyverse":
        return buildVerseByVerseView(screenSize, context);
      default:
        return buildVerseByVerseView(screenSize, context);
    }
  }

  bool isVerseStarred(int surah, int ayah) {
    return starredVerses.contains("$surah:$ayah");
  }

  void showAyahOptionsSheet(
    int index,
    int surahNumber,
    int verseNumber,
  ) {
    showMaterialModalBottomSheet(
      enableDrag: true,
      duration: const Duration(milliseconds: 500),
      backgroundColor: Colors.transparent,
      context: context,
      animationCurve: Curves.easeInOutQuart,
      elevation: 0,
      bounce: true,
      builder: (c) => AyahOptionsSheet(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        index: index,
        starredVerses: starredVerses,
        bookmarks: bookmarks,
        reciters: reciters,
        translationDataList: translationDataList,
        verseKey:
            (index - 1 >= 0 && index - 1 < richTextKeys.length) ? richTextKeys[index - 1] : null,
        appDir: appDir,
        jsonData: widget.jsonData,
        itemScrollController: itemScrollController,
        onUpdate: () => setState(() {}),
        onAddStarredVerse: addStarredVerse,
        onRemoveStarredVerse: removeStarredVerse,
        onFetchBookmarks: fetchBookmarks,
      ),
    );
  }

  Future<void> addStarredVerse(int surahNumber, int verseNumber) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the data as a string, not as a map
    final String? savedData = prefs.getString("starredVerses");

    if (savedData != null) {
      // Decode the JSON string to a List<String>
      starredVerses = Set<String>.from(json.decode(savedData));
    }

    final verseKey = "$surahNumber-$verseNumber"; // Create a unique key
    starredVerses.add(verseKey);

    final jsonData = json.encode(starredVerses.toList()); // Convert Set to List for serialization
    prefs.setString("starredVerses", jsonData);
    Fluttertoast.showToast(msg: "Added to Starred verses");
  }

  Future<void> removeStarredVerse(int surahNumber, int verseNumber) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the data as a string, not as a map
    final String? savedData = prefs.getString("starredVerses");

    if (savedData != null) {
      // Decode the JSON string to a List<String>
      starredVerses = Set<String>.from(json.decode(savedData));
    }

    final verseKey = "$surahNumber-$verseNumber"; // Create the same unique key
    starredVerses.remove(verseKey);

    final jsonData = json.encode(starredVerses.toList()); // Convert Set to List for serialization
    prefs.setString("starredVerses", jsonData);
    Fluttertoast.showToast(msg: "Removed from Starred verses");
  }

  void updateState(VoidCallback fn) {
    setState(fn);
  }
}

class Result {
  bool includesQuarter;
  int index;
  int hizbIndex;
  int quarterIndex;

  Result(this.includesQuarter, this.index, this.hizbIndex, this.quarterIndex);
}

class CustomPageViewScrollPhysics extends ScrollPhysics {
  const CustomPageViewScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 50,
        stiffness: 100,
        damping: 0.8,
      );
}

class ScrollListener extends ChangeNotifier {
  double bottom = 0;
  double _last = 0;

  ScrollListener.initialise(ScrollController controller, [double height = 56]) {
    controller.addListener(() {
      final current = controller.offset;
      bottom += _last - current;
      if (bottom <= -height) bottom = -height;
      if (bottom >= 0) bottom = 0;
      _last = current;
      if (bottom <= 0 && bottom >= -height) notifyListeners();
    });
  }
}

class WidgetSpanWrapper extends StatefulWidget {
  const WidgetSpanWrapper({super.key, required this.child});

  final Widget child;

  @override
  // ignore: library_private_types_in_public_api
  _WidgetSpanWrapperState createState() => _WidgetSpanWrapperState();
}

class _WidgetSpanWrapperState extends State<WidgetSpanWrapper> {
  Offset offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: widget.child,
    );
  }
}
