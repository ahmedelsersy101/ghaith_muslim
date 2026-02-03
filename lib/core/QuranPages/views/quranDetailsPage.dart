// ignore_for_file: unrelated_type_equality_checks, depend_on_referenced_packages, file_names
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:ghaith/blocs/quran_page_player_bloc.dart';
import 'package:ghaith/core/QuranPages/helpers/remove_html_tags.dart';
import 'package:ghaith/core/QuranPages/widgets/bookmark_dialog.dart';
import '../helpers/translation/get_translation_data.dart' as get_translation_data;
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:fluttericon/mfg_labs_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:ghaith/core/QuranPages/helpers/translation/translationdata.dart';
import 'package:ghaith/models/reciter.dart';
import 'package:ghaith/core/QuranPages/helpers/convertNumberToAr.dart';
import 'package:ghaith/core/QuranPages/views/screenshot_preview.dart';
import 'package:ghaith/core/QuranPages/widgets/bismallah.dart';
import 'package:ghaith/core/QuranPages/widgets/header_widget.dart';
import 'package:ghaith/core/QuranPages/widgets/tafseer_and_translation_sheet.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran/quran.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:easy_container/easy_container.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:fluttericon/elusive_icons.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:quran/quran.dart' as quran;
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import '../helpers/translation/get_translation_data.dart' as translate;

class QuranReadingPage extends StatefulWidget {
  const QuranReadingPage({super.key});

  @override
  State<QuranReadingPage> createState() => _QuranReadingPageState();
}

class _QuranReadingPageState extends State<QuranReadingPage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
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

class QuranDetailsPageState extends State<QuranDetailsPage> {
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
  List bookmarks = [];
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
    bookmarks = json.decode(getValue("bookmarks"));
    setState(() {});
  }

  Future<void> getTranslationData() async {
    if (getValue("indexOfTranslationInVerseByVerse") > 1) {
      File file = File(
          "${appDir!.path}/${translationDataList[getValue("indexOfTranslationInVerseByVerse")].typeText}.json");

      String jsonData = await file.readAsString();
      dataOfCurrentTranslation = json.decode(jsonData);
    }
    setState(() {});
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
    _pageController = PageController(initialPage: index);
    _pageController.addListener(_pagecontroller_scrollListner);

    // Setup highlight animations
    changeHighlightSurah();
    highlightVerseFunction();

    // Configure system UI
    _configureSystemUI();

    // Save last read position
    updateValue("lastRead", widget.pageNumber);
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
    final screenSize = MediaQuery.of(context).size;

    return BlocBuilder<QuranPagePlayerBloc, QuranPagePlayerState>(
      builder: (context, state) {
        return Scaffold(
          key: scaffoldKey,
          endDrawer: SizedBox(
            height: screenSize.height,
            width: screenSize.width * .5,
          ),
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Builder(
                builder: (context2) {
                  return _buildAlignmentView(screenSize, context);
                },
              ),
            ],
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
        return alignmentTypeVerticalView(screenSize, context);
      case "pageview":
        return alignmentTypePageView(context, screenSize);
      case "versebyverse":
        return alignmentTypeVersebyVerse(screenSize, context);
      default:
        return Container();
    }
  }

  // ==================== Alignment Views ====================
  // [CAN_BE_EXTRACTED] -> widgets/vertical_view_widget.dart

  Scaffold alignmentTypeVersebyVerse(Size screenSize, BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColors[getValue("quranPageolorsIndex")],
      body: Stack(
        children: [
          ScrollablePositionedList.separated(
            // ph
            // physics: const ClampingScrollPhysics(),

            itemCount: quran.totalPagesCount + 1,
            separatorBuilder: (context, index) {
              if (index == 0) return Container();
              return Container(
                color: secondaryColors[getValue("quranPageolorsIndex")].withOpacity(.45),
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 77.0.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        checkIfPageIncludesQuarterAndQuarterIndex(
                                        widget.quarterJsonData, quran.getPageData(index), indexes)
                                    .includesQuarter ==
                                true
                            ? "${"page".tr()} ${(index).toString()} | ${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex + 1) == 1 ? "" : "${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex).toString()}/${4.toString()}"} ${"hizb".tr()} ${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).hizbIndex + 1).toString()} | ${"juz".tr()}: ${getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"])} "
                            : "${"page".tr()} $index | ${"juz".tr()}: ${getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"])}",
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: backgroundColors[getValue("quranPageolorsIndex")]),
                      ),
                      Text(
                        widget.jsonData[quran.getPageData(index)[0]["surah"] - 1]["name"],
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontFamilies[0],
                            color: backgroundColors[getValue("quranPageolorsIndex")]),
                      )
                    ],
                  ),
                ),
              );
            },
            itemScrollController: itemScrollController,
            initialScrollIndex: getValue("lastRead"),
            itemPositionsListener: itemPositionsListener,
            itemBuilder: (context, index) {
              // updateValue("lastRead", index);
              // bool isEvenPage = index.isEven;

              if (index == 0) {
                return Container(
                  color: const Color(0xffFFFCE7),
                  child: Image.asset(
                    "assets/images/quran.jpg",
                    fit: BoxFit.fill,
                  ),
                );
              }
              return Column(
                children: [
                  Directionality(
                    textDirection: m.TextDirection.rtl,
                    child: Padding(
                      padding: const EdgeInsets.all(26.0),
                      child: SizedBox(
                          width: double.infinity,
                          child: RichText(
                            key: richTextKeys[index - 1],
                            textDirection: m.TextDirection.rtl,
                            textAlign: TextAlign.right,
                            softWrap: true, //locale: const Locale("ar"),
                            text: TextSpan(
                              locale: const Locale("ar"),
                              children: quran.getPageData(index).expand((e) {
                                // print(e);
                                List<InlineSpan> spans = [];
                                for (var i = e["start"]; i <= e["end"]; i++) {
                                  // Header
                                  if (i == 1) {
                                    spans.add(WidgetSpan(
                                      child: HeaderWidget(e: e, jsonData: widget.jsonData),
                                    ));

                                    if (index != 187 && index != 1) {
                                      spans.add(WidgetSpan(
                                          child: Basmallah(
                                        index: getValue("quranPageolorsIndex"),
                                      )));
                                    }
                                    if (index == 187 || index == 1) {
                                      spans.add(WidgetSpan(
                                          child: Container(
                                        height: 10.h,
                                      )));
                                    }
                                  }

                                  // Verses
                                  spans.add(TextSpan(
                                    locale: const Locale("ar"),
                                    children: [
                                      TextSpan(
                                        recognizer: LongPressGestureRecognizer()
                                          ..onLongPress = () {
                                            // print(
                                            //     "$index, ${e["surah"]}, ${e["start"] + i - 1}");
                                            showAyahOptionsSheet(index, e["surah"], i);
                                            print("longpressed");
                                          }
                                          ..onLongPressDown = (details) {
                                            setState(() {
                                              selectedSpan = " ${e["surah"]}$i";
                                            });
                                          }
                                          ..onLongPressUp = () {
                                            setState(() {
                                              selectedSpan = "";
                                            });
                                            print("finished long press");
                                          }
                                          ..onLongPressCancel = () => setState(() {
                                                selectedSpan = "";
                                              }),
                                        text: quran.getVerse(e["surah"], i),
                                        style: TextStyle(
                                          color: primaryColors[getValue("quranPageolorsIndex")],
                                          fontSize: getValue("verseByVerseFontSize").toDouble(),
                                          // wordSpacing: -1.4,
                                          fontFamily: getValue("selectedFontFamily"),
                                          backgroundColor: bookmarks
                                                  .where((element) =>
                                                      element["suraNumber"] == e["surah"] &&
                                                      element["verseNumber"] == i)
                                                  .isNotEmpty
                                              ? Color(int.parse(
                                                      "0x${bookmarks.where((element) => element["suraNumber"] == e["surah"] && element["verseNumber"] == i).first["color"]}"))
                                                  .withOpacity(.19)
                                              : shouldHighlightText
                                                  ? (highlightVerse == " ${e["surah"]}$i" ||
                                                          selectedSpan == " ${e["surah"]}$i")
                                                      ? highlightColors[
                                                              getValue("quranPageolorsIndex")]
                                                          .withOpacity(.25)
                                                      : Colors.transparent
                                                  : selectedSpan == " ${e["surah"]}$i"
                                                      ? highlightColors[
                                                              getValue("quranPageolorsIndex")]
                                                          .withOpacity(.25)
                                                      : Colors.transparent,
                                        ),
                                      ),
                                      TextSpan(
                                          text:
                                              " ${convertToArabicNumber((i).toString())} " //               quran.getVerseEndSymbol()
                                          ,
                                          style: TextStyle(
                                              fontSize: 24.sp,
                                              color: isVerseStarred(e["surah"], i)
                                                  ? Colors.amber
                                                  : secondaryColors[
                                                      getValue("quranPageolorsIndex")],
                                              fontFamily:
                                                  "KFGQPC Uthmanic Script HAFS Regular" //4  -- 7 like ayah
                                              // fontFamilies[5]
                                              )),
                                      if (bookmarks
                                          .where((element) =>
                                              element["suraNumber"] == e["surah"] &&
                                              element["verseNumber"] == i)
                                          .isNotEmpty)
                                        WidgetSpan(
                                            alignment: PlaceholderAlignment.middle,
                                            child: Icon(
                                              Icons.bookmark,
                                              color: Color(int.parse(
                                                  "0x${bookmarks.where((element) => element["suraNumber"] == e["surah"] && element["verseNumber"] == i).first["color"]}")),
                                            )),
                                      WidgetSpan(
                                          child: Divider(
                                        color: Colors.grey.withOpacity(.2),
                                      )),
                                      WidgetSpan(
                                          child: SizedBox(
                                        width: double.infinity,
                                        child: Directionality(
                                          textDirection: translationDataList[getValue(
                                                          "indexOfTranslationInVerseByVerse")]
                                                      .typeInNativeLanguage ==
                                                  "العربية"
                                              ? m.TextDirection.rtl
                                              : m.TextDirection.ltr,
                                          child: get_translation_data
                                                  .getVerseTranslationForVerseByVerse(
                                                    dataOfCurrentTranslation,
                                                    e["surah"],
                                                    i,
                                                    translationDataList[getValue(
                                                        "indexOfTranslationInVerseByVerse")],
                                                  )
                                                  .contains(">")
                                              ? Html(
                                                  data: get_translation_data
                                                      .getVerseTranslationForVerseByVerse(
                                                    dataOfCurrentTranslation,
                                                    e["surah"],
                                                    i,
                                                    translationDataList[getValue(
                                                        "indexOfTranslationInVerseByVerse")],
                                                  ),
                                                  style: {
                                                    '*': Style(
                                                      fontFamily:
                                                          'cairo', // Set your custom font family
                                                      fontSize: FontSize(14.sp),
                                                      lineHeight: LineHeight(1.7.sp),

                                                      // color: primaryColors[getValue("quranPageolorsIndex")]
                                                      //     .withOpacity(.9),
                                                    ),
                                                  },
                                                )
                                              : Text(
                                                  get_translation_data
                                                      .getVerseTranslationForVerseByVerse(
                                                    dataOfCurrentTranslation,
                                                    e["surah"],
                                                    i,
                                                    translationDataList[getValue(
                                                        "indexOfTranslationInVerseByVerse")],
                                                  ),
                                                  style: TextStyle(
                                                      color: primaryColors[
                                                          getValue("quranPageolorsIndex")],
                                                      fontFamily: translationDataList[getValue(
                                                                          "indexOfTranslationInVerseByVerse") ??
                                                                      0]
                                                                  .typeInNativeLanguage ==
                                                              "العربية"
                                                          ? "cairo"
                                                          : "roboto",
                                                      fontSize: 14.sp),
                                                ),
                                        ),
                                      )),
                                      WidgetSpan(
                                          child: Divider(
                                        height: 15.h,
                                        color: primaryColors[getValue("quranPageolorsIndex")]
                                            .withOpacity(.3),
                                      ))
                                    ],
                                  ));
                                }
                                return spans;
                              }).toList(),
                            ),
                          )),
                    ),
                  ),
                ],
              );
            },
          ),
          Padding(
            padding: EdgeInsets.only(top: 28.0.h),
            child: Container(
              // duration: const Duration(milliseconds: 500),
              height: 45.h,
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: (screenSize.width * .27).w,
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.arrow_back_ios,
                              size: 24.sp,
                              color: primaryColors[getValue("quranPageolorsIndex")],
                            )),
                      ],
                    ),
                  ),
                  // // زر تشغيل السورة كاملة
                  // Expanded(
                  //   child: Builder(
                  //     builder: (context) {
                  //       final blocState = context.watch<QuranPagePlayerBloc>().state;
                  //       final currentPageSurah = index > 0 && index <= quran.totalPagesCount
                  //           ? quran.getPageData(index)[0]["surah"]
                  //           : null;
                  //       // ✅ التحقق من currentSurahNumber أولاً لتحديث الأيقونة فوراً
                  //       final isPlaying = currentSurahNumber == currentPageSurah ||
                  //           (blocState is QuranPagePlayerPlaying &&
                  //               blocState.suraNumber == currentPageSurah);

                  //       return Center(
                  //         child: currentPageSurah != null
                  //             ? IconButton(
                  //                 onPressed: () {
                  //                   if (isPlaying) {
                  //                     // إيقاف التشغيل
                  //                     BlocProvider.of<QuranPagePlayerBloc>(context, listen: false)
                  //                         .add(KillPlayerEvent());
                  //                   } else {
                  //                     // تشغيل السورة
                  //                     _playFullSurah(context, currentPageSurah);
                  //                   }
                  //                 },
                  //                 icon: Icon(
                  //                   isPlaying ? Icons.stop_circle : FontAwesome5.play_circle,
                  //                   size: 28.sp,
                  //                   color: isPlaying
                  //                       ? Colors.red
                  //                       : primaryColors[getValue("quranPageolorsIndex")],
                  //                 ),
                  //                 tooltip: isPlaying ? "إيقاف التشغيل" : "تشغيل السورة كاملة",
                  //               )
                  //             : const SizedBox.shrink(),
                  //       );
                  //     },
                  //   ),
                  // ),
                  SizedBox(
                    width: (screenSize.width * .27).w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                            onPressed: () {
                              showSettingsSheet(context);
                            },
                            icon: Icon(
                              Icons.settings,
                              size: 24.sp,
                              color: primaryColors[getValue("quranPageolorsIndex")],
                            ))
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Scaffold alignmentTypeVerticalView(Size screenSize, BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColors[getValue("quranPageolorsIndex")],
      body: Stack(
        children: [
          ScrollablePositionedList.separated(
            itemCount: quran.totalPagesCount + 1,
            separatorBuilder: (context, index) {
              if (index == 0) return Container();
              return Container(
                color: secondaryColors[getValue("quranPageolorsIndex")].withOpacity(.45),
                width: double.infinity,
                height: 30.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        checkIfPageIncludesQuarterAndQuarterIndex(
                                        widget.quarterJsonData, quran.getPageData(index), indexes)
                                    .includesQuarter ==
                                true
                            ? "${"page".tr()} ${(index).toString()} | ${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex + 1) == 1 ? "" : "${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex).toString()}/${4.toString()}"} ${"hizb".tr()} ${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).hizbIndex + 1).toString()} | ${"juz".tr()}: ${getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"])} "
                            : "${"page".tr()} $index | ${"juz".tr()}: ${getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"])}",
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: backgroundColors[getValue("quranPageolorsIndex")]),
                      ),
                      Text(
                        widget.jsonData[quran.getPageData(index)[0]["surah"] - 1]["name"],
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontFamily: "taha",
                            fontWeight: FontWeight.bold,
                            color: backgroundColors[getValue("quranPageolorsIndex")]),
                      )
                    ],
                  ),
                ),
              );
            },
            itemScrollController: itemScrollController,
            initialScrollIndex: getValue("lastRead"),
            itemPositionsListener: itemPositionsListener,
            itemBuilder: (context, index) {
              // updateValue("lastRead", index);
              // bool isEvenPage = index.isEven;

              if (index == 0) {
                return Container(
                  color: const Color(0xffFFFCE7),
                  child: Image.asset(
                    "assets/images/quran.jpg",
                    fit: BoxFit.fill,
                  ),
                );
              }

              return Column(
                children: [
                  Directionality(
                    textDirection: m.TextDirection.rtl,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 26.h),
                      child: SizedBox(
                          width: double.infinity,
                          child: RichText(
                            key: richTextKeys[index - 1],
                            textDirection: m.TextDirection.rtl,
                            textAlign: TextAlign.center,
                            softWrap: true, //locale: const Locale("ar"),
                            text: TextSpan(
                              locale: const Locale("ar"),
                              children: quran.getPageData(index).expand((e) {
                                // print(e);
                                List<InlineSpan> spans = [];
                                for (var i = e["start"]; i <= e["end"]; i++) {
                                  // Header
                                  if (i == 1) {
                                    spans.add(WidgetSpan(
                                      child: HeaderWidget(e: e, jsonData: widget.jsonData),
                                    ));

                                    if (index != 187 && index != 1) {
                                      spans.add(WidgetSpan(
                                          child: Basmallah(
                                        index: getValue("quranPageolorsIndex"),
                                      )));
                                    }
                                    if (index == 187 || index == 1) {
                                      spans.add(WidgetSpan(
                                          child: Container(
                                        height: 10.h,
                                      )));
                                    }
                                  }

                                  // Verses
                                  spans.add(TextSpan(
                                    locale: const Locale("ar"),
                                    recognizer: LongPressGestureRecognizer()
                                      ..onLongPress = () {
                                        // print(
                                        //     "$index, ${e["surah"]}, ${e["start"] + i - 1}");
                                        showAyahOptionsSheet(index, e["surah"], i);
                                        print("longpressed");
                                      }
                                      ..onLongPressDown = (details) {
                                        setState(() {
                                          selectedSpan = " ${e["surah"]}$i";
                                        });
                                      }
                                      ..onLongPressUp = () {
                                        setState(() {
                                          selectedSpan = "";
                                        });
                                        print("finished long press");
                                      }
                                      ..onLongPressCancel = () => setState(() {
                                            selectedSpan = "";
                                          }),
                                    text: quran.getVerse(e["surah"], i),
                                    style: TextStyle(
                                      //wordSpacing: -7,
                                      color: primaryColors[getValue("quranPageolorsIndex")],
                                      fontSize: getValue("verticalViewFontSize").toDouble(),
                                      // wordSpacing: -1.4,
                                      fontFamily: getValue("selectedFontFamily"),
                                      // letterSpacing: 1,
                                      //fontWeight: FontWeight.bold,
                                      backgroundColor: bookmarks
                                              .where((element) =>
                                                  element["suraNumber"] == e["surah"] &&
                                                  element["verseNumber"] == i)
                                              .isNotEmpty
                                          ? Color(int.parse(
                                                  "0x${bookmarks.where((element) => element["suraNumber"] == e["surah"] && element["verseNumber"] == i).first["color"]}"))
                                              .withOpacity(.19)
                                          : shouldHighlightText
                                              ? (highlightVerse == " ${e["surah"]}$i" ||
                                                      selectedSpan == " ${e["surah"]}$i")
                                                  ? highlightColors[getValue("quranPageolorsIndex")]
                                                      .withOpacity(.25)
                                                  : Colors.transparent
                                              : selectedSpan == " ${e["surah"]}$i"
                                                  ? highlightColors[getValue("quranPageolorsIndex")]
                                                      .withOpacity(.25)
                                                  : Colors.transparent,
                                    ),
                                    children: [
                                      TextSpan(
                                          text:
                                              " ${convertToArabicNumber((i).toString())} " //               quran.getVerseEndSymbol()
                                          ,
                                          style: TextStyle(
                                              //wordSpacing: -10,letterSpacing: -5,
                                              color: isVerseStarred(e["surah"], i)
                                                  ? Colors.amber
                                                  : secondaryColors[
                                                      getValue("quranPageolorsIndex")],
                                              fontFamily: "KFGQPC Uthmanic Script HAFS Regular")),

                                      //               ],
                                      //             ),
                                      //           ),
                                      //         ),
                                      //     ),
                                      //     ),
                                    ],
                                  ));
                                  // if (bookmarks.contains(
                                  //     "${e["surah"]}-$i")) {
                                  //   spans.add(WidgetSpan(
                                  //       alignment:
                                  //           PlaceholderAlignment
                                  //               .middle,
                                  //       child: Icon(
                                  //         Icons.bookmark,
                                  //         color: colorsOfBookmarks2[
                                  //             bookmarks
                                  //                 .indexOf(
                                  //                     "${e["surah"]}-$i")],
                                  //       )));
                                  // }
                                  if (bookmarks
                                      .where((element) =>
                                          element["suraNumber"] == e["surah"] &&
                                          element["verseNumber"] == i)
                                      .isNotEmpty) {
                                    spans.add(WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Icon(
                                          Icons.bookmark,
                                          color: Color(int.parse(
                                              "0x${bookmarks.where((element) => element["suraNumber"] == e["surah"] && element["verseNumber"] == i).first["color"]}")),
                                        )));
                                  }
                                }
                                return spans;
                              }).toList(),
                            ),
                          )),
                    ),
                  ),
                ],
              );
            },
          ),
          Padding(
            padding: EdgeInsets.only(top: 28.0.h),
            child: Container(
              // duration: const Duration(milliseconds: 500),
              height: 45.h, width: screenSize.width,
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: (screenSize.width * .27).w,
                    child: Row(
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.arrow_back_ios,
                              size: 24.sp,
                              color: primaryColors[getValue("quranPageolorsIndex")],
                            )),
                      ],
                    ),
                  ),
                  // // زر تشغيل السورة كاملة
                  // Expanded(
                  //   child: Builder(
                  //     builder: (context) {
                  //       final blocState = context.watch<QuranPagePlayerBloc>().state;
                  //       final currentPageSurah = index > 0 && index <= quran.totalPagesCount
                  //           ? quran.getPageData(index)[0]["surah"]
                  //           : null;
                  //       // ✅ التحقق من currentSurahNumber أولاً لتحديث الأيقونة فوراً
                  //       final isPlaying = currentSurahNumber == currentPageSurah ||
                  //           (blocState is QuranPagePlayerPlaying &&
                  //               blocState.suraNumber == currentPageSurah);

                  //       return Center(
                  //         child: currentPageSurah != null
                  //             ? IconButton(
                  //                 onPressed: () {
                  //                   if (isPlaying) {
                  //                     // إيقاف التشغيل
                  //                     BlocProvider.of<QuranPagePlayerBloc>(context, listen: false)
                  //                         .add(KillPlayerEvent());
                  //                   } else {
                  //                     // تشغيل السورة
                  //                     _playFullSurah(context, currentPageSurah);
                  //                   }
                  //                 },
                  //                 icon: Icon(
                  //                   isPlaying ? Icons.stop_circle : FontAwesome5.play_circle,
                  //                   size: 28.sp,
                  //                   color: isPlaying
                  //                       ? Colors.red
                  //                       : primaryColors[getValue("quranPageolorsIndex")],
                  //                 ),
                  //                 tooltip: isPlaying ? "إيقاف التشغيل" : "تشغيل السورة كاملة",
                  //               )
                  //             : const SizedBox.shrink(),
                  //       );
                  //     },
                  //   ),
                  // ),
                  SizedBox(
                    width: (screenSize.width * .27).w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                            onPressed: () {
                              //  Scaffold.of(  scaffoldKey.currentState!.context)
                              // .openEndDrawer();
                              showSettingsSheet(context);
                            },
                            icon: Icon(
                              Icons.settings,
                              size: 24.sp,
                              color: primaryColors[getValue("quranPageolorsIndex")],
                            ))
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          // Positioned(
          //     right: 1,
          //     height: screenSize.height,
          //     child: Padding(
          //       padding: EdgeInsets.symmetric(vertical: 108.0.h),
          //       child: Opacity(opacity: .25,
          //         child: SfSlider.vertical(
          //           isInversed: true,
          //           min: 0.0,
          //           max: 10.0,inactiveColor: primaryColors[getValue("quranPageolorsIndex")].withOpacity(.5),
          //           value: valueOfSlider,
          //           activeColor: secondaryColors[getValue("quranPageolorsIndex")],
          //           // interval: 0,
          //           showTicks: false,
          //           showLabels: false,
          //           enableTooltip: false,
          //           minorTicksPerInterval: 1,
          //           onChanged: (dynamic value) {                             //       itemScrollController.scrollTo(index: 614, duration: const Duration(hours: 1));

          //             setState(() {
          //               valueOfSlider = value;
          //             });
          //           },

          //           onChangeEnd: (dynamic value){
          //             itemScrollController.scrollTo(index: 604, duration:  Duration(minutes:1~/value));
          //           },
          //         ),
          //       ),
          //     ))
        ],
      ),
    );
  }

  PageView alignmentTypePageView(BuildContext context, Size screenSize) {
    return PageView.builder(
      // physics: const CustomPageViewScrollPhysics(),
      scrollDirection: Axis.horizontal,
      onPageChanged: (a) {
        setState(() {
          selectedSpan = "";
        });
        index = a;
        updateValue("lastRead", a);
      },
      controller: _pageController,
      // onPageChanged: _onPageChanged,
      reverse: context.locale.languageCode == "ar" ? false : true,
      itemCount: quran.totalPagesCount + 1 /* specify the total number of pages */,
      itemBuilder: (context, index) {
        bool isEvenPage = index.isEven;

        if (index == 0) {
          return Container(
            color: const Color(0xffFFFCE7),
            child: Image.asset(
              "assets/images/quran.jpg",
              fit: BoxFit.fill,
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
              color: backgroundColors[getValue("quranPageolorsIndex")],
              boxShadow: [
                if (isEvenPage) // Add shadow only for even-numbered pages
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5, // Controls the spread of the shadow
                    blurRadius: 10, // Controls the blur effect
                    offset: const Offset(-5, 0), // Left side shadow for even numbers
                  ),
              ],
              //index % 2 == 0
              border: Border.fromBorderSide(BorderSide(
                  color: primaryColors[getValue("quranPageolorsIndex")].withOpacity(.05)))),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(right: 8.0.w, left: 8.w),
                child: Column(
                  children: [
                    // ===== Header (ثابت في الأعلى) =====
                    SizedBox(
                      width: screenSize.width,
                      child: Row(
                        mainAxisAlignment: m.MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: m.MainAxisAlignment.start,
                            children: [
                              IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: Icon(
                                    Icons.arrow_back_ios,
                                    size: 24.sp,
                                    color: secondaryColors[getValue("quranPageolorsIndex")],
                                  )),
                              IconButton(
                                  onPressed: () {
                                    showSettingsSheet(context);
                                  },
                                  icon: Icon(
                                    Icons.settings,
                                    size: 24.sp,
                                    color: secondaryColors[getValue("quranPageolorsIndex")],
                                  )),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4).r,
                            child: Text(
                                widget.jsonData[quran.getPageData(index)[0]["surah"] - 1]["name"],
                                style: TextStyle(
                                    color: secondaryColors[getValue("quranPageolorsIndex")],
                                    fontFamily: "Taha",
                                    fontSize: 20.sp)),
                          ),
                        ],
                      ),
                    ),
                    // ===== محتوى القرآن (يتكيف مع المساحة المتاحة) =====
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: screenSize.width - 24.w,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if ((index == 1 || index == 2))
                                SizedBox(
                                  height: (screenSize.height * .24),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Directionality(
                                  textDirection: m.TextDirection.rtl,
                                  child: SizedBox(
                                      width: double.infinity,
                                      child: RichText(
                                        key: richTextKeys[index - 1],
                                        textDirection: m.TextDirection.rtl,
                                        textAlign: TextAlign.center,
                                        softWrap: true, //locale: const Locale("ar"),
                                        text: TextSpan(
                                          locale: const Locale("ar"),
                                          children: quran.getPageData(index).expand((e) {
                                            // print(e);
                                            List<InlineSpan> spans = [];
                                            for (var i = e["start"]; i <= e["end"]; i++) {
                                              // Header
                                              if (i == 1) {
                                                spans.add(WidgetSpan(
                                                  child:
                                                      HeaderWidget(e: e, jsonData: widget.jsonData),
                                                ));

                                                if (index != 187 && index != 1) {
                                                  spans.add(WidgetSpan(
                                                      child: Basmallah(
                                                    index: getValue("quranPageolorsIndex"),
                                                  )));
                                                }
                                                if (index == 187 || index == 1) {
                                                  spans.add(WidgetSpan(
                                                      child: Container(
                                                    height: 10.h,
                                                  )));
                                                }
                                              }

                                              // Verses
                                              spans.add(TextSpan(
                                                locale: const Locale("ar"),
                                                recognizer: LongPressGestureRecognizer()
                                                  ..onLongPress = () {
                                                    // print(
                                                    //     "$index, ${e["surah"]}, ${e["start"] + i - 1}");
                                                    showAyahOptionsSheet(index, e["surah"], i);
                                                    print("longpressed");
                                                  }
                                                  ..onLongPressDown = (details) {
                                                    setState(() {
                                                      selectedSpan = " ${e["surah"]}$i";
                                                    });
                                                  }
                                                  ..onLongPressUp = () {
                                                    setState(() {
                                                      selectedSpan = "";
                                                    });
                                                    print("finished long press");
                                                  }
                                                  ..onLongPressCancel = () => setState(() {
                                                        selectedSpan = "";
                                                      }),
                                                text: quran.getVerse(e["surah"], i),
                                                style: TextStyle(
                                                  wordSpacing: -1.4,
                                                  color: primaryColors[
                                                      getValue("quranPageolorsIndex")],
                                                  fontSize: 24.sp,
                                                  fontFamily: getValue("selectedFontFamily"),
                                                  backgroundColor: bookmarks
                                                          .where((element) =>
                                                              element["suraNumber"] == e["surah"] &&
                                                              element["verseNumber"] == i)
                                                          .isNotEmpty
                                                      ? Color(int.parse(
                                                              "0x${bookmarks.where((element) => element["suraNumber"] == e["surah"] && element["verseNumber"] == i).first["color"]}"))
                                                          .withOpacity(.19)
                                                      : shouldHighlightText
                                                          ? (highlightVerse == " ${e["surah"]}$i" ||
                                                                  selectedSpan ==
                                                                      " ${e["surah"]}$i")
                                                              ? highlightColors[getValue(
                                                                      "quranPageolorsIndex")]
                                                                  .withOpacity(.25)
                                                              : Colors.transparent
                                                          : selectedSpan == " ${e["surah"]}$i"
                                                              ? highlightColors[getValue(
                                                                      "quranPageolorsIndex")]
                                                                  .withOpacity(.25)
                                                              : Colors.transparent,
                                                ),
                                                children: [
                                                  TextSpan(
                                                      text:
                                                          " ${convertToArabicNumber((i).toString())} " //               quran.getVerseEndSymbol()
                                                      ,
                                                      style: TextStyle(
                                                          //wordSpacing: -10,letterSpacing: -5,
                                                          color: isVerseStarred(e["surah"], i)
                                                              ? Colors.amber
                                                              : secondaryColors[
                                                                  getValue("quranPageolorsIndex")],
                                                          fontFamily:
                                                              "KFGQPC Uthmanic Script HAFS Regular")),

                                                  //               ],
                                                  //             ),
                                                  //           ),
                                                  //         ),
                                                  //     ),
                                                  //     ),
                                                ],
                                              ));
                                              // if (bookmarks.contains(
                                              //     "${e["surah"]}-$i")) {
                                              //   spans.add(WidgetSpan(
                                              //       alignment:
                                              //           PlaceholderAlignment
                                              //               .middle,
                                              //       child: Icon(
                                              //         Icons.bookmark,
                                              //         color: colorsOfBookmarks2[
                                              //             bookmarks
                                              //                 .indexOf(
                                              //                     "${e["surah"]}-$i")],
                                              //       )));
                                              // }
                                              if (bookmarks
                                                  .where((element) =>
                                                      element["suraNumber"] == e["surah"] &&
                                                      element["verseNumber"] == i)
                                                  .isNotEmpty) {
                                                spans.add(WidgetSpan(
                                                    alignment: PlaceholderAlignment.middle,
                                                    child: Icon(
                                                      Icons.bookmark,
                                                      color: Color(int.parse(
                                                          "0x${bookmarks.where((element) => element["suraNumber"] == e["surah"] && element["verseNumber"] == i).first["color"]}")),
                                                    )));
                                              }
                                            }
                                            return spans;
                                          }).toList(),
                                        ),
                                      )),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ===== Footer (ثابت في أسفل الشاشة) =====
                    SizedBox(height: 8.h),
                    Center(
                      child: checkIfPageIncludesQuarterAndQuarterIndex(
                                  widget.quarterJsonData, quran.getPageData(index), indexes)
                              .includesQuarter
                          ? EasyContainer(
                              borderRadius: 12.r,
                              color:
                                  secondaryColors[getValue("quranPageolorsIndex")].withOpacity(.5),
                              borderColor: backgroundColors[getValue("quranPageolorsIndex")],
                              showBorder: true,
                              height: 30.h,
                              width: 250.w,
                              padding: 0,
                              margin: 0,
                              child: Center(
                                child: Text(
                                  "${"page".tr()} ${(index).toString()}  |  ${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex + 1) == 1 ? "" : "${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex).toString()}/${4.toString()}"} ${"hizb".tr()} ${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).hizbIndex + 1).toString()} | ${"juz".tr()} ${getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"])}",
                                  style: TextStyle(
                                    fontFamily: 'aldahabi',
                                    fontSize: 12.sp,
                                    color: backgroundColors[getValue("quranPageolorsIndex")],
                                  ),
                                ),
                              ),
                            )
                          : EasyContainer(
                              borderRadius: 12.r,
                              color:
                                  secondaryColors[getValue("quranPageolorsIndex")].withOpacity(.5),
                              borderColor: backgroundColors[getValue("quranPageolorsIndex")],
                              showBorder: true,
                              height: 30.h,
                              width: 250.w,
                              padding: 0,
                              margin: 0,
                              child: Center(
                                child: Text(
                                  "${"page".tr()} $index  |  ${"juz".tr()} ${getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"])}",
                                  style: TextStyle(
                                    fontFamily: 'aldahabi',
                                    fontSize: 12.sp,
                                    color: backgroundColors[getValue("quranPageolorsIndex")],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ),
          ),
        ); /* Your page content */
      },
    );
  }

  // ==================== Bottom Sheets ====================
  // [CAN_BE_EXTRACTED] -> widgets/settings_bottom_sheet.dart

  void showSettingsSheet(context) {
    int index = 0;

    showMaterialModalBottomSheet(
      enableDrag: true,
      duration: const Duration(milliseconds: 600),
      backgroundColor: Colors.transparent,
      context: context,
      animationCurve: Curves.easeInOutQuart,
      elevation: 0,
      barrierColor: Colors.black.withOpacity(.1),
      bounce: true,
      builder: (a) => StatefulBuilder(builder: (BuildContext context, StateSetter setStatee) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.transparent,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        setStatee((() {
                          index = 0;
                        }));
                      },
                      child: CircleAvatar(
                        backgroundColor: index == 0
                            ? secondaryColors[getValue("quranPageolorsIndex")]
                            : Colors.grey,
                        child: const Icon(
                          Icons.color_lens,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        setStatee((() {
                          index = 1;
                        }));
                      },
                      child: CircleAvatar(
                        backgroundColor: index == 1
                            ? secondaryColors[getValue("quranPageolorsIndex")]
                            : Colors.grey,
                        child: const Icon(
                          Icons.font_download,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        setStatee((() {
                          index = 2;
                        }));
                      },
                      child: CircleAvatar(
                        backgroundColor: index == 2
                            ? secondaryColors[getValue("quranPageolorsIndex")]
                            : Colors.grey,
                        child: const Icon(
                          FontAwesome.align_center,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (index == 0)
              Container(
                // height: (MediaQuery.of(context).size.height*.2).h,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: primaryColors[getValue("quranPageolorsIndex")].withOpacity(.3)),
                  color: Colors.grey,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 230.h,
                      width: MediaQuery.of(context).size.width,
                      child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, childAspectRatio: 1.8 / 1),
                          scrollDirection: Axis.vertical,
                          itemCount: primaryColors.length,
                          itemBuilder: (a, i) {
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.0.w),
                              child: GestureDetector(
                                onTap: () {
                                  updateValue("quranPageolorsIndex", i);
                                  setState(() {});
                                  setStatee(() {});
                                },
                                child: SizedBox(
                                  width: 90.w,
                                  height: 40.h,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 90.w,
                                          height: 40.h,
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                  blurRadius: 1,
                                                  color: Colors.grey.withOpacity(.3)),
                                              BoxShadow(
                                                  blurRadius: 1,
                                                  offset: const Offset(-1, 1),
                                                  color: Colors.grey.withOpacity(.3)),
                                            ],
                                            shape: BoxShape.rectangle,
                                            borderRadius: BorderRadius.circular(10),
                                            color: backgroundColors[i],
                                          ),
                                        ),
                                      ),
                                      if (getValue("quranPageolorsIndex") != i)
                                        Center(
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: primaryColors[i],
                                            ),
                                          ),
                                        ),
                                      if (getValue("quranPageolorsIndex") == i)
                                        Center(
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: primaryColors[i],
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.check,
                                                color: backgroundColors[
                                                    getValue("quranPageolorsIndex")],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                    ),
                    SizedBox(
                      height: 4.h,
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                    SizedBox(
                      height: 10.h,
                    ),
                  ],
                ),
              ),
            if (index == 1)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: primaryColors[getValue("quranPageolorsIndex")].withOpacity(.3)),
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
                height: (MediaQuery.of(context).size.height * .4).h,
                child: Column(
                  children: [
                    Slider(
                      label: (getValue("alignmentType") == "versebyverse"
                              ? getValue("verseByVerseFontSize").toDouble()
                              : getValue("alignmentType") == "verticalview"
                                  ? getValue("verticalViewFontSize").toDouble()
                                  : getValue("pageViewFontSize").toDouble())
                          .toString(),
                      divisions: 30,
                      value: getValue("alignmentType") == "versebyverse"
                          ? getValue("verseByVerseFontSize").toDouble()
                          : getValue("alignmentType") == "verticalview"
                              ? getValue("verticalViewFontSize").toDouble()
                              : getValue("pageViewFontSize").toDouble(),
                      min: 15.0, // Minimum font size
                      max: 45.0, // Maximum font size
                      onChanged: (newSize) {
                        if (getValue("alignmentType") == "versebyverse") {
                          updateValue("verseByVerseFontSize", newSize);
                        } else if (getValue("alignmentType") == "verticalview") {
                          updateValue("verticalViewFontSize", newSize);
                        } else if (getValue("alignmentType") == "pageview") {
                          updateValue("pageViewFontSize", newSize);
                        }
                        // Call the function to update font size
                        setState(() {});
                        setStatee(
                          () {},
                        );
                      },
                    ),
                    EasyContainer(
                      child: Text("reset".tr()),
                      onTap: () {
                        updateValue("selectedFontFamily", "UthmanicHafs13");

                        if (getValue("alignmentType") == "versebyverse") {
                          updateValue("verseByVerseFontSize", 24);
                        } else if (getValue("alignmentType") == "verticalview") {
                          updateValue("verticalViewFontSize", 23);
                        } else if (getValue("alignmentType") == "pageview") {
                          updateValue("pageViewFontSize", 23);
                        }
                        updateValue("currentHeight", 2.0);

                        updateValue("currentLetterSpacing", 0);
                        setState(() {
                          // currentFontSize = 23;
                          currentHeight = 2;
                          // currentWordSpacing =
                          //     0;
                          currentLetterSpacing = 0;
                        });
                        setStatee(
                          () {},
                        );
                      },
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: fontFamilies.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            onTap: () {
                              updateValue("selectedFontFamily", fontFamilies[index]);
                              setState(() {});
                              setStatee(
                                  () {}); // I'm not sure what setStatee is, make sure it's defined correctly
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'بِسْمِ اللَّـهِ الرَّحْمَـٰنِ الرَّحِيمِ',
                                    style: TextStyle(
                                      fontFamily: fontFamilies[index],
                                      fontSize: 18, // Use the current font size
                                    ),
                                  ),
                                  const VerticalDivider(),
                                  Text(
                                    fontFamilies[index],
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (getValue("selectedFontFamily") == fontFamilies[index])
                                    Icon(
                                      Elusive.ok_circled,
                                      color: primaryColors[getValue("quranPageolorsIndex")],
                                    )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            if (index == 2)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: primaryColors[getValue("quranPageolorsIndex")].withOpacity(.3)),
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
                width: MediaQuery.of(context).size.width,
                // height: (MediaQuery.of(context).size.height * .4).h,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                        onPressed: () async {
                          updateValue("alignmentType", "verticalview");

                          setState(() {});
                          // print(index);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_pageController.hasClients) {
                              _pageController.jumpToPage(
                                getValue("lastRead"),
                              );
                            }
                          });
                          setStatee(() {});
                        },
                        child: Text("verticalview".tr())),
                    TextButton(
                        onPressed: () async {
                          updateValue("alignmentType", "pageview");

                          setState(() {});
                          await Future.delayed(const Duration(microseconds: 400));
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            itemScrollController.jumpTo(
                              index: getValue("lastRead"),
                            );
                          });
                          setStatee(() {});
                        },
                        child: Text("pageview".tr())),
                    TextButton(
                        onPressed: () {
                          setState(() {});
                          updateValue("alignmentType", "versebyverse");
                          setStatee(() {});
                        },
                        child: Text("versebyverse".tr())),
                    if (getValue("alignmentType") == "versebyverse")
                      Directionality(
                        textDirection: m.TextDirection.rtl,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () {
                              showMaterialModalBottomSheet(
                                  enableDrag: true,
                                  animationCurve: Curves.easeInOutQuart,
                                  elevation: 0,
                                  bounce: true,
                                  duration: const Duration(milliseconds: 400),
                                  backgroundColor: backgroundColor,
                                  context: context,
                                  builder: (builder) {
                                    return Directionality(
                                      textDirection: m.TextDirection.rtl,
                                      child: SizedBox(
                                        height: MediaQuery.of(context).size.height * .8,
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                "choosetranslation".tr(),
                                                style: TextStyle(
                                                    color: primaryColor,
                                                    fontSize: 22.sp,
                                                    fontFamily: context.locale.languageCode == "ar"
                                                        ? "cairo"
                                                        : "roboto"),
                                              ),
                                            ),
                                            Expanded(
                                              child: ListView.separated(
                                                  separatorBuilder: ((context, index) {
                                                    return const Divider();
                                                  }),
                                                  itemCount: translationDataList.length,
                                                  itemBuilder: (c, i) {
                                                    return Container(
                                                      color: i ==
                                                              getValue(
                                                                  "indexOfTranslationInVerseByVerse")
                                                          ? Colors.blueGrey.withOpacity(.1)
                                                          : Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () async {
                                                          if (isDownloading !=
                                                              translationDataList[i].url) {
                                                            if (File("${appDir!.path}/${translationDataList[i].typeText}.json")
                                                                    .existsSync() ||
                                                                i == 0 ||
                                                                i == 1) {
                                                              updateValue(
                                                                  "indexOfTranslationInVerseByVerse",
                                                                  i);
                                                              setState(() {});
                                                            } else {
                                                              PermissionStatus status =
                                                                  await Permission.storage
                                                                      .request();
                                                              //PermissionStatus status1 = await Permission.accessMediaLocation.request();
                                                              PermissionStatus status2 =
                                                                  await Permission
                                                                      .manageExternalStorage
                                                                      .request();
                                                              print('status $status   -> $status2');
                                                              if (status.isGranted &&
                                                                  status2.isGranted) {
                                                                print(true);
                                                              } else if (status
                                                                      .isPermanentlyDenied ||
                                                                  status2.isPermanentlyDenied) {
                                                                await openAppSettings();
                                                              } else if (status.isDenied) {
                                                                print('Permission Denied');
                                                              }

                                                              await Dio().download(
                                                                  translationDataList[i].url,
                                                                  "${appDir!.path}/${translationDataList[i].typeText}.json");
                                                            }
                                                            getTranslationData();
                                                            setState(() {});
                                                          }

                                                          setState(() {});

                                                          setStatee(() {});
                                                          if (mounted) {
                                                            Navigator.pop(context);
                                                          }
                                                        },
                                                        child: Padding(
                                                          padding: EdgeInsets.symmetric(
                                                              horizontal: 18.0.w, vertical: 2.h),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                translationDataList[i]
                                                                    .typeTextInRelatedLanguage,
                                                                style: TextStyle(
                                                                    color: primaryColor
                                                                        .withOpacity(.9),
                                                                    fontSize: 14.sp),
                                                              ),
                                                              isDownloading !=
                                                                      translationDataList[i].url
                                                                  ? Icon(
                                                                      i == 0 || i == 1
                                                                          ? MfgLabs.hdd
                                                                          : File("${appDir!.path}/${translationDataList[i].typeText}.json")
                                                                                  .existsSync()
                                                                              ? Icons.done
                                                                              : Icons
                                                                                  .cloud_download,
                                                                      color: Colors.blueAccent,
                                                                      size: 18.sp,
                                                                    )
                                                                  : const CircularProgressIndicator(
                                                                      strokeWidth: 2,
                                                                      color: Colors.blueAccent,
                                                                    )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: 40.h,
                              decoration: BoxDecoration(
                                  color: Colors.blueGrey.withOpacity(.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14.0.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      translationDataList[
                                              getValue("indexOfTranslationInVerseByVerse") ?? 0]
                                          .typeTextInRelatedLanguage,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: translationDataList[getValue(
                                                              "indexOfTranslationInVerseByVerse") ??
                                                          0]
                                                      .typeInNativeLanguage ==
                                                  "العربية"
                                              ? "cairo"
                                              : "roboto"),
                                    ),
                                    Icon(
                                      FontAwesome.ellipsis,
                                      size: 24.sp,
                                      color: secondaryColors[getValue("quranPageolorsIndex")],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(
                      height: 20,
                    )
                  ],
                ),
              )
          ],
        );
      }),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/ayah_options_bottom_sheet.dart

  void showAyahOptionsSheet(
    int index,
    int surahNumber,
    int verseNumber,
  ) {
    final parentContext = context;

    showMaterialModalBottomSheet(
      enableDrag: true,
      duration: const Duration(milliseconds: 500),
      backgroundColor: Colors.transparent,
      context: parentContext,
      animationCurve: Curves.easeInOutQuart,
      elevation: 0,
      bounce: true,
      builder: (c) => StatefulBuilder(
        builder: (context, setstatee) {
          return Padding(
            padding: const EdgeInsets.all(0),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColors[getValue("quranPageolorsIndex")],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      "${context.locale.languageCode == "ar" ? quran.getSurahNameArabic(surahNumber) : quran.getSurahNameEnglish(surahNumber)}: $verseNumber",
                      style: TextStyle(color: primaryColors[getValue("quranPageolorsIndex")]),
                    ),
                    trailing: SizedBox(
                      width: 200.w,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              isVerseStarred(surahNumber, verseNumber)
                                  ? removeStarredVerse(surahNumber, verseNumber)
                                  : addStarredVerse(surahNumber, verseNumber);
                              setstatee(() {});
                              setState(() {});
                              richTextKeys[index - 1].currentState?.build(context);
                            },
                            icon: Icon(
                              isVerseStarred(surahNumber, verseNumber)
                                  ? FontAwesome.star
                                  : FontAwesome.star_empty,
                              color: primaryColors[getValue("quranPageolorsIndex")],
                            ),
                          ),
                          IconButton(
                              onPressed: () {
                                takeScreenshotFunction(index, surahNumber, verseNumber);
                              },
                              icon: Icon(Icons.share,
                                  color: primaryColors[getValue("quranPageolorsIndex")])),
                        ],
                      ),
                    ),
                  ),
                  Divider(
                    height: 10.h,
                    color: primaryColors[getValue("quranPageolorsIndex")],
                  ),
                  SizedBox(height: 10.h),

                  // ✅ قائمة العلامات المرجعية (Bookmarks)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: primaryColors[getValue("quranPageolorsIndex")].withOpacity(.05),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            if (bookmarks.isNotEmpty)
                              ListView.separated(
                                separatorBuilder: (context, index) => const Divider(),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: bookmarks.length,
                                itemBuilder: (c, i) {
                                  return GestureDetector(
                                    onTap: () async {
                                      List bookmarks = json.decode(getValue("bookmarks"));
                                      bookmarks[i]["verseNumber"] = verseNumber;
                                      bookmarks[i]["suraNumber"] = surahNumber;
                                      updateValue("bookmarks", json.encode(bookmarks));
                                      setState(() {});
                                      fetchBookmarks();
                                      Navigator.of(context).pop();
                                    },
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: Row(
                                        children: [
                                          SizedBox(width: 20.w),
                                          Icon(Icons.bookmark,
                                              color:
                                                  Color(int.parse("0x${bookmarks[i]["color"]}"))),
                                          SizedBox(width: 20.w),
                                          Text(
                                            bookmarks[i]["name"],
                                            style: TextStyle(
                                              fontFamily: "cairo",
                                              fontSize: 14.sp,
                                              color: primaryColors[getValue("quranPageolorsIndex")],
                                            ),
                                          ),
                                          const Spacer(),
                                          Expanded(
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                getVerse(
                                                  int.parse(bookmarks[i]["suraNumber"].toString()),
                                                  int.parse(bookmarks[i]["verseNumber"].toString()),
                                                ),
                                                textDirection: m.TextDirection.rtl,
                                                style: TextStyle(
                                                  fontFamily: fontFamilies[0],
                                                  fontSize: 13.sp,
                                                  color: primaryColors[
                                                      getValue("quranPageolorsIndex")],
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              List bookmarks = json.decode(getValue("bookmarks"));
                                              Fluttertoast.showToast(
                                                msg: "${bookmarks[i]["name"]} removed",
                                              );
                                              bookmarks.removeWhere(
                                                  (e) => e["color"] == bookmarks[i]["color"]);
                                              updateValue("bookmarks", json.encode(bookmarks));
                                              setState(() {});
                                              fetchBookmarks();
                                              Navigator.of(context).pop();
                                            },
                                            icon: Icon(
                                              Icons.delete,
                                              color: Color(int.parse("0x${bookmarks[i]["color"]}")),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            if (bookmarks.isNotEmpty) const Divider(),
                            EasyContainer(
                              color: Colors.transparent,
                              onTap: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) => BookmarksDialog(
                                    suraNumber: surahNumber,
                                    verseNumber: verseNumber,
                                  ),
                                );
                                fetchBookmarks();
                              },
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Row(
                                  children: [
                                    SizedBox(width: 20.w),
                                    Icon(Icons.bookmark_add,
                                        color: secondaryColors[getValue("quranPageolorsIndex")]),
                                    SizedBox(width: 20.w),
                                    Text(
                                      "newBookmark".tr(),
                                      style: TextStyle(
                                        fontFamily: "cairo",
                                        fontSize: 14.sp,
                                        color: primaryColors[getValue("quranPageolorsIndex")],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // ✅ التفسير والترجمة
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EasyContainer(
                      color: primaryColors[getValue("quranPageolorsIndex")].withOpacity(.05),
                      borderRadius: 12,
                      onTap: () {
                        showMaterialModalBottomSheet(
                          enableDrag: true,
                          context: context,
                          animationCurve: Curves.easeInOutQuart,
                          elevation: 0,
                          bounce: true,
                          duration: const Duration(milliseconds: 400),
                          backgroundColor: backgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(13.r),
                              topLeft: Radius.circular(13.r),
                            ),
                          ),
                          isDismissible: true,
                          builder: (d) {
                            return TafseerAndTranslateSheet(
                              surahNumber: surahNumber,
                              isVerseByVerseSelection: false,
                              verseNumber: verseNumber,
                            );
                          },
                        );
                      },
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            SizedBox(width: 20.w),
                            Icon(
                              FontAwesome5.book_open,
                              color: getValue("quranPageolorsIndex") == 0
                                  ? secondaryColors[getValue("quranPageolorsIndex")]
                                  : highlightColors[getValue("quranPageolorsIndex")],
                            ),
                            SizedBox(width: 20.w),
                            Text(
                              "${"tafseer".tr()} - ${"translation".tr()}",
                              style: TextStyle(
                                fontFamily: "cairo",
                                fontSize: 14.sp,
                                color: primaryColors[getValue("quranPageolorsIndex")],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // ✅ تشغيل الآية
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: EasyContainer(
                      borderRadius: 8,
                      color: primaryColors[getValue("quranPageolorsIndex")].withOpacity(.05),
                      onTap: () async {
                        Navigator.pop(context);

                        // ✅ استخدم الـ context الأصلي للوصول إلى الـ Bloc
                        final quranPagePlayerBloc =
                            BlocProvider.of<QuranPagePlayerBloc>(parentContext, listen: false);

                        // أوقف التشغيل الحالي إن وجد
                        if (quranPagePlayerBloc.state is QuranPagePlayerPlaying) {
                          quranPagePlayerBloc.add(KillPlayerEvent());
                        }

                        // شغل من الآية المطلوبة
                        quranPagePlayerBloc.add(
                          PlayFromVerse(
                            verseNumber,
                            reciters[getValue("reciterIndex")].identifier,
                            surahNumber,
                            quran.getSurahNameEnglish(surahNumber),
                          ),
                        );

                        // لو العرض عمودي، ارجع للآية الحالية بعد التشغيل
                        if (getValue("alignmentType") == "verticalview" &&
                            quran.getPageNumber(surahNumber, verseNumber) > 600) {
                          await Future.delayed(const Duration(milliseconds: 1000));
                          itemScrollController.jumpTo(
                            index: quran.getPageNumber(surahNumber, verseNumber),
                          );
                        }
                      },
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            SizedBox(width: 8.w),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    primaryColors[getValue("quranPageolorsIndex")].withOpacity(.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "play".tr(),
                                style: TextStyle(
                                  fontFamily: "cairo",
                                  fontSize: 14.sp,
                                  color: primaryColors[getValue("quranPageolorsIndex")],
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            DropdownButton<int>(
                              value: getValue("reciterIndex"),
                              dropdownColor: backgroundColors[getValue("quranPageolorsIndex")],
                              onChanged: (int? newIndex) {
                                updateValue("reciterIndex", newIndex);
                                setState(() {});
                                setstatee(() {});
                              },
                              items: reciters.map((reciter) {
                                return DropdownMenuItem<int>(
                                  value: reciters.indexOf(reciter),
                                  child: Text(
                                    context.locale.languageCode == "ar"
                                        ? reciter.name
                                        : reciter.englishName,
                                    style: TextStyle(
                                      color: primaryColors[getValue("quranPageolorsIndex")],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/screenshot_dialog.dart

  void takeScreenshotFunction(index, surahNumber, verseNumber) {
    int firstVerse = verseNumber;
    int lastVerse = verseNumber;
    showDialog(
      // animationType: DialogTransitionType.size,
      context: context,
      builder: (builder) {
        return StatefulBuilder(builder: (context, setstatter) {
          return Dialog(
            // title: const Text('Share Ayah'),
            backgroundColor: backgroundColors[getValue("quranPageolorsIndex")],

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    Text(
                      "share".tr(),
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: primaryColors[getValue("quranPageolorsIndex")],
                        fontWeight: FontWeight.w700,
                        fontSize: 20.0, // Increase font size
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0), // Add spacing at the top
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'fromayah'.tr(),
                      style: TextStyle(
                        color: primaryColors[getValue("quranPageolorsIndex")],
                        fontSize: 16.0, // Increase font size
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    DropdownButton<int>(
                      dropdownColor: backgroundColors[getValue("quranPageolorsIndex")],
                      value: firstVerse,
                      onChanged: (newValue) {
                        if (newValue! > lastVerse) {
                          setState(() {
                            lastVerse = newValue;
                          });
                          setstatter(() {});
                        }
                        setState(() {
                          firstVerse = newValue;
                        });
                        setstatter(() {});
                        // Handle dropdown selection
                      },
                      items: List.generate(
                        quran.getVerseCount(surahNumber),
                        (index) => DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: primaryColors[getValue("quranPageolorsIndex")],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20.0),
                    Text(
                      'toayah'.tr(),
                      style: TextStyle(
                        color: primaryColors[getValue("quranPageolorsIndex")],
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    DropdownButton<int>(
                      dropdownColor: backgroundColors[getValue("quranPageolorsIndex")],
                      value: lastVerse,
                      onChanged: (newValue) {
                        if (newValue! > firstVerse) {
                          setState(() {
                            lastVerse = newValue;
                          });
                          setstatter(() {});
                        }
                        // Handle dropdown selection
                      },
                      items: List.generate(
                        quran.getVerseCount(surahNumber),
                        (index) => DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: primaryColors[getValue("quranPageolorsIndex")],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0), // Add spacing between rows
                RadioListTile(
                  activeColor: highlightColors[getValue("quranPageolorsIndex")],
                  fillColor: WidgetStatePropertyAll(primaryColors[getValue("quranPageolorsIndex")]),
                  title: Text(
                    'asimage'.tr(),
                    style: TextStyle(
                      color: primaryColors[getValue("quranPageolorsIndex")],
                    ),
                  ),
                  value: 0,
                  groupValue: getValue("selectedShareTypeIndex"),
                  onChanged: (value) {
                    updateValue("selectedShareTypeIndex", value);
                    setState(() {});
                    setstatter(() {});
                  },
                ),
                RadioListTile(
                  activeColor: highlightColors[getValue("quranPageolorsIndex")],
                  fillColor: WidgetStatePropertyAll(primaryColors[getValue("quranPageolorsIndex")]),
                  title: Text(
                    'astext'.tr(),
                    style: TextStyle(
                      color: primaryColors[getValue("quranPageolorsIndex")],
                    ),
                  ),
                  value: 1,
                  groupValue: getValue("selectedShareTypeIndex"),
                  onChanged: (value) {
                    updateValue("selectedShareTypeIndex", value);
                    setState(() {});
                    setstatter(() {});
                  },
                ),
                if (getValue("selectedShareTypeIndex") == 1)
                  Row(
                    children: [
                      Checkbox(
                        fillColor:
                            WidgetStatePropertyAll(primaryColors[getValue("quranPageolorsIndex")]),
                        checkColor: backgroundColors[getValue("quranPageolorsIndex")],
                        value: getValue("textWithoutDiacritics"),
                        onChanged: (newValue) {
                          updateValue("textWithoutDiacritics", newValue);
                          setState(() {});
                          setstatter(() {});
                        },
                      ),
                      Text(
                        'withoutdiacritics'.tr(),
                        style: TextStyle(
                          color: primaryColors[getValue("quranPageolorsIndex")],
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),

                // if (getValue("selectedShareTypeIndex") == 0)
                Row(
                  children: [
                    Checkbox(
                      fillColor:
                          WidgetStatePropertyAll(primaryColors[getValue("quranPageolorsIndex")]),
                      checkColor: backgroundColors[getValue("quranPageolorsIndex")],
                      value: getValue("addAppSlogan"),
                      onChanged: (newValue) {
                        updateValue("addAppSlogan", newValue);

                        setState(() {});
                        setstatter(() {});
                      },
                    ),
                    Text(
                      'addappname'.tr(),
                      style: TextStyle(
                        color: primaryColors[getValue("quranPageolorsIndex")],
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      fillColor:
                          WidgetStatePropertyAll(primaryColors[getValue("quranPageolorsIndex")]),
                      checkColor: backgroundColors[getValue("quranPageolorsIndex")],
                      value: getValue("addTafseer"),
                      onChanged: (newValue) {
                        updateValue("addTafseer", newValue);

                        setState(() {});
                        setstatter(() {});
                      },
                    ),
                    Text(
                      'addtafseer'.tr(),
                      style: TextStyle(
                        color: primaryColors[getValue("quranPageolorsIndex")],
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                ),
                if (getValue("addTafseer") == true)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20.w,
                      ),
                      Directionality(
                        textDirection: m.TextDirection.rtl,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            onTap: () {
                              showMaterialModalBottomSheet(
                                  enableDrag: true,
                                  animationCurve: Curves.easeInOutQuart,
                                  elevation: 0,
                                  bounce: true,
                                  duration: const Duration(milliseconds: 150),
                                  backgroundColor: backgroundColor,
                                  context: context,
                                  builder: (builder) {
                                    return Directionality(
                                      textDirection: m.TextDirection.rtl,
                                      child: SizedBox(
                                        height: MediaQuery.of(context).size.height * .8,
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                "choosetranslation".tr(),
                                                style: TextStyle(
                                                    color: primaryColor,
                                                    fontSize: 22.sp,
                                                    fontFamily: context.locale.languageCode == "ar"
                                                        ? "cairo"
                                                        : "roboto"),
                                              ),
                                            ),
                                            Expanded(
                                              child: ListView.separated(
                                                  separatorBuilder: ((context, index) {
                                                    return const Divider();
                                                  }),
                                                  itemCount: translationDataList.length,
                                                  itemBuilder: (c, i) {
                                                    return Container(
                                                      color: i == getValue("addTafseerValue")
                                                          ? Colors.blueGrey.withOpacity(.1)
                                                          : Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () async {
                                                          if (isDownloading !=
                                                              translationDataList[i].url) {
                                                            if (File("${appDir!.path}/${translationDataList[i].typeText}.json")
                                                                    .existsSync() ||
                                                                i == 0 ||
                                                                i == 1) {
                                                              updateValue("addTafseerValue", i);
                                                              setState(() {});
                                                              setstatter(() {});
                                                            } else {
                                                              PermissionStatus status =
                                                                  await Permission.storage
                                                                      .request();
                                                              //PermissionStatus status1 = await Permission.accessMediaLocation.request();
                                                              PermissionStatus status2 =
                                                                  await Permission
                                                                      .manageExternalStorage
                                                                      .request();
                                                              // print(
                                                              //     'status $status   -> $status2');
                                                              if (status.isGranted &&
                                                                  status2.isGranted) {
                                                                // print(true);
                                                              } else if (status
                                                                      .isPermanentlyDenied ||
                                                                  status2.isPermanentlyDenied) {
                                                                await openAppSettings();
                                                              } else if (status.isDenied) {
                                                                // print(
                                                                //     'Permission Denied');
                                                              }

                                                              await Dio().download(
                                                                  translationDataList[i].url,
                                                                  "${appDir!.path}/${translationDataList[i].typeText}.json");
                                                            }
                                                            getTranslationData();
                                                            updateValue("addTafseerValue", i);
                                                            setState(() {});
                                                            setstatter(() {});
                                                          }

                                                          setState(() {});

                                                          // setStatee(() {});
                                                          if (mounted) {
                                                            setstatter(() {});

                                                            Navigator.pop(context);
                                                            setstatter(() {});
                                                          }
                                                          setstatter(() {});
                                                        },
                                                        child: Padding(
                                                          padding: EdgeInsets.symmetric(
                                                              horizontal: 18.0.w, vertical: 2.h),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Text(
                                                                translationDataList[i]
                                                                    .typeTextInRelatedLanguage,
                                                                style: TextStyle(
                                                                    color: primaryColor
                                                                        .withOpacity(.9),
                                                                    fontSize: 14.sp),
                                                              ),
                                                              isDownloading !=
                                                                      translationDataList[i].url
                                                                  ? Icon(
                                                                      i == 0 || i == 1
                                                                          ? MfgLabs.hdd
                                                                          : File("${appDir!.path}/${translationDataList[i].typeText}.json")
                                                                                  .existsSync()
                                                                              ? Icons.done
                                                                              : Icons
                                                                                  .cloud_download,
                                                                      color: Colors.blueAccent,
                                                                      size: 18.sp,
                                                                    )
                                                                  : const CircularProgressIndicator(
                                                                      strokeWidth: 2,
                                                                      color: Colors.blueAccent,
                                                                    )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  });
                            },
                            child: Container(
                              width: MediaQuery.of(context).size.width * .7,
                              height: 40.h,
                              decoration: BoxDecoration(
                                  color: Colors.blueGrey.withOpacity(.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14.0.w),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      translationDataList[getValue("addTafseerValue") ?? 0]
                                          .typeTextInRelatedLanguage,
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontFamily:
                                              translationDataList[getValue("addTafseerValue") ?? 0]
                                                          .typeInNativeLanguage ==
                                                      "العربية"
                                                  ? "cairo"
                                                  : "roboto"),
                                    ),
                                    Icon(
                                      FontAwesome.ellipsis,
                                      size: 24.sp,
                                      color: secondaryColors[getValue("quranPageolorsIndex")],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                if (getValue("selectedShareTypeIndex") == 1)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: EasyContainer(
                        onTap: () async {
                          if (getValue("selectedShareTypeIndex") == 1) {
                            // print("sharing ");
                            List verses = [];
                            for (int i = firstVerse; i <= lastVerse; i++) {
                              verses.add(quran.getVerse(surahNumber, i, verseEndSymbol: true));
                            }
                            if (getValue("textWithoutDiacritics")) {
                              if (getValue("addTafseer")) {
                                String tafseer = "";
                                for (int verseNumber = firstVerse;
                                    verseNumber <= lastVerse;
                                    verseNumber++) {
                                  String verseTafseer = await translate.getVerseTranslation(
                                    surahNumber,
                                    verseNumber,
                                    translationDataList[getValue("addTafseerValue")],
                                  );
                                  tafseer = "$tafseer $verseTafseer";
                                }
                                Share.share(
                                  // "",
                                  "{${removeDiacritics(verses.join(''))}} [${quran.getSurahNameArabic(surahNumber)}: $firstVerse : $lastVerse]\n\n${removeHtmlTags(removeDiacritics(tafseer))}\n\n${getValue("addAppSlogan") ? "تطبيق غيث المسلم - faithful companion" : ""}",
                                  // "text/plain"
                                );
                              } else {
                                Share.share(
                                  // "",
                                  "{${removeDiacritics(verses.join(''))}} [${quran.getSurahNameArabic(surahNumber)}: $firstVerse : $lastVerse]${getValue("addAppSlogan") ? "تطبيق غيث المسلم - faithful companion" : ""}",
                                  // "text/plain"
                                );
                              }
                            } else {
                              if (getValue("addTafseer")) {
                                String tafseer = "";
                                for (int verseNumber = firstVerse;
                                    verseNumber <= lastVerse;
                                    verseNumber++) {
                                  String cTafseer = await translate.getVerseTranslation(
                                      surahNumber,
                                      verseNumber,
                                      translationDataList[getValue("addTafseerValue")]);
                                  tafseer = "$tafseer $cTafseer ";
                                }
                                Share.share(
                                  // "",
                                  "{${verses.join('')}} [${quran.getSurahNameArabic(surahNumber)}: $firstVerse : $lastVerse]\n\n${translationDataList[getValue("addTafseerValue")].typeTextInRelatedLanguage}:\n${removeHtmlTags(tafseer)}\n\n${getValue("addAppSlogan") ? "تطبيق غيث المسلم" : ""}",
                                  // "text/plain"
                                );
                              } else {
                                Share.share(
                                  // "",
                                  "{${verses.join('')}} [${quran.getSurahNameArabic(surahNumber)}: $firstVerse : $lastVerse]${getValue("addAppSlogan") ? "تطبيق غيث المسلم" : ""}",
                                  // "text/plain"
                                );
                              }
                            }
                          }
                        },
                        color: primaryColors[getValue("quranPageolorsIndex")],
                        child: Text(
                          "astext".tr(),
                          style:
                              TextStyle(color: backgroundColors[getValue("quranPageolorsIndex")]),
                        )),
                  ),
                if (getValue("selectedShareTypeIndex") == 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: EasyContainer(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (builder) => ScreenShotPreviewPage(
                                      index: index,
                                      surahNumber: surahNumber,
                                      jsonData: widget.jsonData,
                                      firstVerse: firstVerse,
                                      lastVerse: lastVerse)));
                        },
                        color: primaryColors[getValue("quranPageolorsIndex")],
                        child: Text(
                          "preview".tr(),
                          style:
                              TextStyle(color: backgroundColors[getValue("quranPageolorsIndex")]),
                        )),
                  )
              ],
            ),
          );
        });
      },
    );
  }

  // ==================== Starred Verses Management ====================
  // [CAN_BE_EXTRACTED] -> helpers/starred_verses_helper.dart

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

  bool isVerseStarred(int surahNumber, int verseNumber) {
    final verseKey = "$surahNumber-$verseNumber";
    return starredVerses.contains(verseKey);
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
