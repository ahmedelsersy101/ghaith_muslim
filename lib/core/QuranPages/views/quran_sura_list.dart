// ignore_for_file: prefer_single_quotes, unused_field
import 'package:ghaith/main.dart';

import 'dart:convert';
import 'package:easy_container/easy_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ghaith/blocs/bloc/quran_page_player_bloc.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/core/QuranPages/views/quranDetailsPage.dart';
import 'package:ghaith/core/widgets/hizb_quarter_circle.dart';
import 'package:ghaith/models/surah.dart';
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
  var jsonData;
  var quarterjsonData;
  SurahListPage({Key? key, required this.jsonData, required this.quarterjsonData})
      : super(key: key);

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  bool isLoading = true;
  @override
  void dispose() {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
    // overlays: SystemUiOverlay.values);
    super.dispose();
  }

  List pageNumbers = [];
  TextEditingController textEditingController = TextEditingController();
  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 10, // Choose a suitable number of shimmering items
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300.withOpacity(.5),
          highlightColor: isDarkModeNotifier.value ? darkModeSecondaryColor : quranPagesColorLight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 8.h),
            child: ListTile(
              leading: Container(
                width: 45,
                height: 45,
                color: backgroundColor, // Shimmer effect
              ),
              title: Container(
                height: 15,
                color: backgroundColor, // Shimmer effect
              ),
              subtitle: Container(
                height: 12,
                color: backgroundColor, // Shimmer effect
              ),
            ),
          ),
        );
      },
    );
  }

  getCircleWidget(index, hizbNumber) {
    if (index == 0) {
      return Container(
        width: 33.sp,
        height: 33.sp,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkModeNotifier.value
              ? quranPagesColorDark
              : quranPagesColorLight.withOpacity(.1), // Replace with your logic
        ),
        child: Center(
          child: Text(
            hizbNumber.toString(),
            style: TextStyle(
                fontSize: 14.sp,
                color: isDarkModeNotifier.value ? orangeColor : const Color.fromARGB(228, 0, 0, 0)),
          ),
        ),
      );
    } else if (index == 1) {
      return Container(
          width: 20.sp,
          height: 20.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkModeNotifier.value
                ? quranPagesColorDark
                : quranPagesColorLight.withOpacity(.1), // Replace with your logic
          ),
          child: QuarterCircle(
              color: isDarkModeNotifier.value ? orangeColor : const Color.fromARGB(228, 0, 0, 0),
              size: 20.sp));
    } else if (index == 2) {
      return Container(
          width: 20.sp,
          height: 20.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkModeNotifier.value
                ? quranPagesColorDark
                : quranPagesColorLight.withOpacity(.1), // Replace with your logic
          ),
          child: HalfCircle(
              color: isDarkModeNotifier.value ? orangeColor : const Color.fromARGB(228, 0, 0, 0),
              size: 20.sp));
    } else if (index == 3) {
      return Container(
          width: 20.sp,
          height: 20.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkModeNotifier.value
                ? quranPagesColorDark
                : quranPagesColorLight.withOpacity(.1), // Replace with your logic
          ),
          child: ThreeQuartersCircle(
              color: isDarkModeNotifier.value ? orangeColor : const Color.fromARGB(228, 0, 0, 0),
              size: 20.sp));
    }
  }

  var searchQuery = "";
  var filteredData;
  @override
  void initState() {
    getStarredVerse();
    getValue("lastRead") != "non";
    fetchBookmarks();
    addFilteredData();
    super.initState();
  }

  int juzNumberLastRead = 0;
  getJuzNumber() async {
    juzNumberLastRead = quran.getJuzNumber(quran.getPageData(getValue("lastRead"))[0]["surah"],
        quran.getPageData(getValue("lastRead"))[0]["start"]);
    setState(() {});
  }

  List bookmarks = [];
  fetchBookmarks() {
    bookmarks = json.decode(getValue("bookmarks"));
    setState(() {});
    // print(bookmarks);
  }

  int quarterNumberLastRead = 0;
  getJquarterNumber() async {
    juzNumberLastRead = quran.getJuzNumber(quran.getPageData(getValue("lastRead"))[0]["surah"],
        quran.getPageData(getValue("lastRead"))[0]["start"]);
    setState(() {});
  }

  final ItemScrollController _juzScrollController = ItemScrollController();

  addFilteredData() async {
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      filteredData = widget.jsonData;
      isLoading = false;
    });
  }

  List<Surah> surahList = [];
  int _currentIndex = 0;

  // Define the tabs
  final List<Tab> tabs = <Tab>[
    Tab(text: 'surah'.tr()),
    Tab(text: 'juz'.tr()),
    Tab(text: 'quarter'.tr()),
  ];
  var ayatFiltered;
  GlobalKey scaffoldKey = GlobalKey<ScaffoldState>();
  Set<String> starredVerses = {};

  getStarredVerse() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the data as a string, not as a map
    final String? savedData = prefs.getString("starredVerses");

    if (savedData != null) {
      // Decode the JSON string to a List<String>
      starredVerses = Set<String>.from(json.decode(savedData));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: KeyboardDismissOnTap(
        dismissOnCapturedTaps: true,
        child: Container(
          decoration: BoxDecoration(
              color: isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight),
          child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor:
                  isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight,
              endDrawer: SafeArea(
                child: bookMarksListView(context),
              ),
              key: scaffoldKey,
              appBar: appBarSurahListView(context),
              body: tapBarSurahListView(context)),
        ),
      ),
    );
  }

  TabBarView tapBarSurahListView(BuildContext context) {
    return TabBarView(
              children: [
                SafeArea(
                  child: Container(
                    color: isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight,
                    child: Column(
                      children: [
                        if (getValue("lastRead") != "non")
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: EasyContainer(
                                color: orangeColor,
                                height: 60.h,
                                padding: 0,
                                margin: 0,
                                borderRadius: 15.r,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "lastRead".tr(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      Text(
                                          "${context.locale.languageCode == "ar" ? (quran.getSurahNameArabic(quran.getPageData(getValue("lastRead"))[0]["surah"])) : (quran.getSurahName(quran.getPageData(getValue("lastRead"))[0]["surah"]))} - ${getValue("lastRead")}",
                                          style: const TextStyle(color: Colors.white)),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                          builder: (builder) => BlocProvider(
                                                create: (context) => QuranPagePlayerBloc(),
                                                child: QuranDetailsPage(
                                                    shouldHighlightSura: false,
                                                    pageNumber: getValue("lastRead"),
                                                    jsonData: widget.jsonData,
                                                    shouldHighlightText: false,
                                                    highlightVerse: "",
                                                    quarterJsonData: widget.quarterjsonData),
                                              )));
                                  setState(() {});
                                }),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0.w),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: backgroundColor.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12.r)),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                                            child: TextField(
                                              textDirection: m.TextDirection.rtl,
                                              controller: textEditingController,
                                              onChanged: (value) {
                                                setState(() {
                                                  searchQuery = value;
                                                });
                                                if (value == "") {
                                                  filteredData = widget.jsonData;
                                                  pageNumbers = [];
                                                  setState(() {});
                                                }

                                                /*https://api.alquran.cloud/v1/search/%D8%A7%D8%A8%D8%B1%D8%A7%D9%87%D9%8A%D9%85/all/ar*/
                                                if (searchQuery.isNotEmpty &&
                                                    isInt(searchQuery)) {
                                                  pageNumbers.add(toInt(searchQuery));
                                                }
                                                if (searchQuery.length > 3 ||
                                                    searchQuery.toString().contains(" ")) {
                                                  setState(() {
                                                    ayatFiltered = [];
                                                    searchQuery = value;

                                                    ayatFiltered = quran.searchWords(searchQuery);
                                                    filteredData = widget.jsonData.where((sura) {
                                                      final suraName =
                                                          sura['englishName'].toLowerCase();
                                                      // final suraNameTranslated =
                                                      //     sura['name']
                                                      //         .toString()
                                                      //         .toLowerCase();
                                                      final suraNameTranslated = quran
                                                          .getSurahNameArabic(sura["number"]);

                                                      return suraName.contains(
                                                              searchQuery.toLowerCase()) ||
                                                          suraNameTranslated.contains(
                                                              searchQuery.toLowerCase());
                                                    }).toList();
                                                  });
                                                }
                                              },
                                              style: TextStyle(
                                                  fontFamily: "aldahabi",
                                                  color: isDarkModeNotifier.value
                                                      ? const Color.fromARGB(228, 255, 255, 255)
                                                      : const Color.fromARGB(190, 0, 0, 0)),
                                              cursorColor: isDarkModeNotifier.value
                                                  ? quranPagesColorDark
                                                  : quranPagesColorLight,
                                              decoration: InputDecoration(
                                                  hintText: 'searchQuran'.tr(),
                                                  hintStyle: TextStyle(
                                                      fontFamily: "aldahabi",
                                                      color: isDarkModeNotifier.value
                                                          ? Colors.white70
                                                          : const Color.fromARGB(73, 0, 0, 0)),
                                                  border: InputBorder.none),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            if (searchQuery.isNotEmpty) {
                                              filteredData = widget.jsonData;
                                              textEditingController.clear();
                                              pageNumbers.clear();
                                              setState(() {
                                                searchQuery = "";
                                              });
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: searchQuery.isNotEmpty
                                                ? Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Icon(Icons.close,
                                                          color: getValue("darkMode")
                                                              ? Colors.white70
                                                              : const Color.fromARGB(
                                                                  73, 0, 0, 0)),
                                                    ),
                                                  )
                                                : Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Icon(FontAwesome.search,
                                                        color: getValue("darkMode")
                                                            ? Colors.white70
                                                            : const Color.fromARGB(73, 0, 0, 0)),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        listViewAllSurah(context),
                      ],
                    ),
                  ),
                ),
                // const Text("data"),
                ScrollablePositionedList.builder(
                  itemCount: 30,
                  itemScrollController: _juzScrollController,
                  itemBuilder: (BuildContext context, index) {
                    return Card(
                      color: isDarkModeNotifier.value
                          ? darkModeSecondaryColor.withOpacity(.8)
                          : quranPagesColorLight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                            title: Text(
                              quran.getSurahNameArabic(
                                  quran.getSurahAndVersesFromJuz(index + 1).keys.first),
                              style: TextStyle(
                                  color: isDarkModeNotifier.value
                                      ? const Color.fromARGB(234, 255, 255, 255)
                                      : const Color.fromARGB(228, 0, 0, 0)),
                            ),
                            subtitle: Text(
                              quran.getVerse(quran.getSurahAndVersesFromJuz(index + 1).keys.first,
                                  quran.getSurahAndVersesFromJuz(index + 1).values.first[0]),
                              style: TextStyle(
                                  fontFamily: "UthmanicHafs13",
                                  fontSize: 18.sp,
                                  color: isDarkModeNotifier.value
                                      ? const Color.fromARGB(234, 255, 255, 255)
                                      : const Color.fromARGB(228, 0, 0, 0)
                                  // fontWeight: FontWeight.w600
                                  ),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                      builder: (builder) => BlocProvider(
                                            create: (context) => QuranPagePlayerBloc(),
                                            child: QuranDetailsPage(
                                                shouldHighlightSura: false,
                                                quarterJsonData: widget.quarterjsonData,
                                                shouldHighlightText: true,
                                                highlightVerse: quran.getVerse(
                                                    quran
                                                        .getSurahAndVersesFromJuz(index + 1)
                                                        .keys
                                                        .first,
                                                    quran
                                                        .getSurahAndVersesFromJuz(index + 1)
                                                        .values
                                                        .first[0]),
                                                pageNumber: quran.getPageNumber(
                                                    quran
                                                        .getSurahAndVersesFromJuz(index + 1)
                                                        .keys
                                                        .first,
                                                    quran
                                                        .getSurahAndVersesFromJuz(index + 1)
                                                        .values
                                                        .first[0]),
                                                jsonData: widget.jsonData),
                                          )));
                              getJuzNumber();
                              setState(() {});
                            },
                            leading: Container(
                              width: 33.sp,
                              height: 33.sp,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: juzNumberLastRead == index + 1
                                    ? isDarkModeNotifier.value
                                        ? quranPagesColorDark
                                        : quranPagesColorLight
                                    : isDarkModeNotifier.value
                                        ? quranPagesColorDark
                                        : quranPagesColorLight
                                            .withOpacity(.1), // Replace with your logic
                              ),
                              child: Center(
                                child: Text(
                                  (index + 1).toString(),
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      color: isDarkModeNotifier.value
                                          ? orangeColor
                                          : const Color.fromARGB(228, 0, 0, 0)),
                                ),
                              ),
                            )),
                      ),
                    );
                  },
                ),

                GroupListView(
                  sectionsCount: 60,
                  countOfItemInSection: (int section) {
                    return 4;
                  },
                  itemBuilder: (BuildContext context, IndexPath index) {
                    return Card(
                      color: isDarkModeNotifier.value
                          ? darkModeSecondaryColor.withOpacity(.8)
                          : quranPagesColorLight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(
                            quran.getSurahNameArabic(
                                widget.quarterjsonData[indexes[index.section][index.index] - 1]
                                    ["surah"]),
                            style: TextStyle(
                                color: isDarkModeNotifier.value
                                    ? const Color.fromARGB(234, 255, 255, 255)
                                    : const Color.fromARGB(228, 0, 0, 0)),
                          ),
                          subtitle: Text(
                            quran.getVerse(
                                widget.quarterjsonData[indexes[index.section][index.index] - 1]
                                    ["surah"],
                                widget.quarterjsonData[indexes[index.section][index.index] - 1]
                                    ["ayah"]),
                            style: TextStyle(
                                fontFamily: "UthmanicHafs13",
                                fontSize: 18.sp,
                                color: isDarkModeNotifier.value
                                    ? const Color.fromARGB(234, 255, 255, 255)
                                    : const Color.fromARGB(228, 0, 0, 0)
                                // fontWeight: FontWeight.w600
                                ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                                context,
                                CupertinoPageRoute(
                                    builder: (builder) => BlocProvider(
                                          create: (context) => QuranPagePlayerBloc(),
                                          child: QuranDetailsPage(
                                              shouldHighlightSura: false,
                                              quarterJsonData: widget.quarterjsonData,
                                              shouldHighlightText: true,
                                              highlightVerse: quran.getVerse(
                                                  widget.quarterjsonData[indexes[index.section][index.index] - 1]
                                                      ["surah"],
                                                  widget.quarterjsonData[indexes[index.section][index.index] - 1]
                                                      ["ayah"]),
                                              pageNumber: quran.getPageNumber(
                                                  widget.quarterjsonData[
                                                          indexes[index.section][index.index] - 1]
                                                      ["surah"],
                                                  widget.quarterjsonData[
                                                          indexes[index.section][index.index] - 1]
                                                      ["ayah"]),
                                              jsonData: widget.jsonData),
                                        )));

                            setState(() {});
                          },
                          leading: getCircleWidget(index.index, index.section + 1),
                        ),
                      ),
                    );
                  },
                  groupHeaderBuilder: (BuildContext context, int section) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: Text(
                        "${"hizb".tr()} ${section + 1}",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDarkModeNotifier.value
                                ? const Color.fromARGB(234, 255, 255, 255)
                                : const Color.fromARGB(228, 0, 0, 0)),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  sectionSeparatorBuilder: (context, section) => const SizedBox(height: 10),
                ),
              ],
            );
  }

  Expanded listViewAllSurah(BuildContext context) {
    return Expanded(
                        child: isLoading
                            ? _buildShimmerLoading()
                            : ListView(
                                shrinkWrap: true,
                                physics: const ClampingScrollPhysics(),
                                children: [
                                  if (pageNumbers.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text("page".tr()),
                                    ),
                                  ListView.separated(
                                      reverse: true,
                                      itemBuilder: (ctx, index) {
                                        return Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: EasyContainer(
                                            color: getValue("darkMode")
                                                ? Colors.white70
                                                : orangeColor,
                                            onTap: () {
                                              Navigator.push(
                                                  context,
                                                  CupertinoPageRoute(
                                                      builder: (builder) => BlocProvider(
                                                            create: (context) =>
                                                                QuranPagePlayerBloc(),
                                                            child: QuranDetailsPage(
                                                                shouldHighlightSura: true,
                                                                shouldHighlightText: false,
                                                                highlightVerse: "",
                                                                jsonData: widget.jsonData,
                                                                quarterJsonData:
                                                                    widget.quarterjsonData,
                                                                pageNumber: pageNumbers[index]),
                                                          )));
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(pageNumbers[index].toString()),
                                                  Text(quran.getSurahName(
                                                      quran.getPageData(pageNumbers[index])[0]
                                                          ["surah"]))
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      separatorBuilder: (context, index) => Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8.0.w),
                                            child: Divider(
                                              color: Colors.grey.withOpacity(.5),
                                            ),
                                          ),
                                      itemCount: pageNumbers.length),
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    separatorBuilder: (context, index) => Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8.0.w),
                                      child: Divider(
                                        color: Colors.grey.withOpacity(.5),
                                      ),
                                    ),
                                    itemCount: filteredData.length,
                                    itemBuilder: (context, index) {
                                      int suraNumber = index + 1;
                                      String suraName = filteredData[index]["englishName"];
                                      String suraNameEnglishTranslated =
                                          filteredData[index]["englishNameTranslation"];
                                      int suraNumberInQuran = filteredData[index]["number"];
                                      String suraNameTranslated =
                                          filteredData[index]["name"].toString();
                                      int ayahCount = quran.getVerseCount(suraNumber);

                                      return Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: ListTile(
                                          leading: Container(
                                            width: 45,
                                            height: 45,
                                            decoration: const BoxDecoration(
                                                image: DecorationImage(
                                              image: AssetImage(
                                                "assets/images/sura_frame.png",
                                              ),
                                            )),
                                            child: Center(
                                              child: Text(
                                                suraNumberInQuran.toString(),
                                                style: TextStyle(
                                                    color: getValue("darkMode") ? Colors.white70 : Colors.black,
                                                    fontSize: 14.sp),
                                              ),
                                            ),
                                          ) //  Material(

                                          ,
                                          minVerticalPadding: 0,
                                          title: SizedBox(
                                            width: 90.w,
                                            child: Row(
                                              children: [
                                                Text(
                                                  suraName,
                                                  style: TextStyle(
                                                      // fontWeight: FontWeight.bold,
                                                      color: getValue("darkMode")
                                                          ? Colors.white70
                                                          : Colors.black,
                                                      fontSize: 14.sp,
                                                      fontWeight: FontWeight.w700, // Text color
                                                      fontFamily: "uthmanic"),
                                                ),
                                                if (bookmarks.indexWhere((a) {
                                                      return a.toString().split("-")[0] ==
                                                          "$suraNumberInQuran";
                                                    }) !=
                                                    -1)
                                                  Icon(Icons.bookmark,
                                                      size: 16.sp,
                                                      color: colorsOfBookmarks2[
                                                              bookmarks.indexWhere((a) {
                                                        return a
                                                            .toString()
                                                            .startsWith("$suraNumberInQuran");
                                                      })]
                                                          .withOpacity(.7))
                                              ],
                                            ),
                                          ),
                                          subtitle: Text(
                                            "$suraNameEnglishTranslated ($ayahCount)",
                                            style: TextStyle(
                                                fontFamily: "uthmanic",
                                                fontSize: 14.sp,
                                                color: Colors.grey.withOpacity(.8)),
                                          ),
                                          trailing: RichText(
                                            text: TextSpan(
                                              text: "$suraNumber",
                                              style: TextStyle(
                                                  // fontWeight: FontWeight.bold,
                                                  color: getValue("darkMode")
                                                      ? Colors.white70
                                                      : Colors
                                                          .black, //fontWeight: FontWeight.bold,
                                                  fontSize: 28.sp, // Text color
                                                  fontFamily: "arsura"),
                                            ),
                                          ),
                                          onTap: () async {
                                            await Navigator.push(
                                                context,
                                                CupertinoPageRoute(
                                                    builder: (builder) => BlocProvider(
                                                          create: (context) =>
                                                              QuranPagePlayerBloc(),
                                                          child: QuranDetailsPage(
                                                              shouldHighlightSura: true,
                                                              shouldHighlightText: false,
                                                              highlightVerse: "",
                                                              jsonData: widget.jsonData,
                                                              quarterJsonData:
                                                                  widget.quarterjsonData,
                                                              pageNumber: quran.getPageNumber(
                                                                  suraNumberInQuran, 1)),
                                                        )));
                                            // Handle tapping on a sura item here
                                            // You can navigate to the sura details page or perform any other action.
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                  if (ayatFiltered != null) const Divider(),
                                  if (ayatFiltered != null)
                                    ListView.builder(
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: ayatFiltered["occurences"] > 10
                                          ? 10
                                          : ayatFiltered["occurences"],
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: EasyContainer(
                                            color: isDarkModeNotifier.value
                                                ? darkModeSecondaryColor
                                                : Colors.white70,
                                            borderRadius: 14,
                                            onTap: () async {
                                              await Navigator.push(
                                                  context,
                                                  CupertinoPageRoute(
                                                      builder: (builder) => BlocProvider(
                                                            create: (context) =>
                                                                QuranPagePlayerBloc(),
                                                            child: QuranDetailsPage(
                                                                shouldHighlightSura: false,
                                                                pageNumber: quran.getPageNumber(
                                                                    ayatFiltered["result"]
                                                                        [index]["surah"],
                                                                    ayatFiltered["result"]
                                                                        [index]["verse"]),
                                                                jsonData: widget.jsonData,
                                                                shouldHighlightText: true,
                                                                highlightVerse: quran.getVerse(
                                                                    ayatFiltered["result"]
                                                                        [index]["surah"],
                                                                    ayatFiltered["result"]
                                                                        [index]["verse"]),
                                                                quarterJsonData:
                                                                    widget.quarterjsonData),
                                                          )));
                                            },
                                            child: Text(
                                              "سورة ${quran.getSurahNameArabic(ayatFiltered["result"][index]["surah"])} - ${quran.getVerse(ayatFiltered["result"][index]["surah"], ayatFiltered["result"][index]["verse"], verseEndSymbol: true)}",
                                              textDirection: m.TextDirection.rtl,
                                              style: TextStyle(
                                                  color: isDarkModeNotifier.value
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontFamily: "uthmanic",
                                                  fontSize: 17.sp),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                      );
  }

  PreferredSize appBarSurahListView(BuildContext context) {
    return PreferredSize(
              preferredSize: Size(MediaQuery.of(context).size.width.w, 80.h),
              child: AppBar(
                actions: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0.w, vertical: 8.h),
                    child: Builder(builder: (context) {
                      return IconButton(
                          onPressed: () {
                            Scaffold.of(context).openEndDrawer();
                          },
                          icon: const Icon(
                            Iconsax.bookmark,
                            color: backgroundColor,
                          ));
                    }),
                  )
                ],
                leading: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 8.h),
                  child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        size: 20.sp,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                ),
                bottom: PreferredSize(
                  preferredSize: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height * 0.04,
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.04,
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Change this to your desired color
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TabBar(
                      indicatorPadding: EdgeInsets.symmetric(horizontal: 35.w),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white,
                      indicatorWeight: 4,
                      indicatorAnimation: TabIndicatorAnimation.elastic,
                      tabs: tabs,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                        // if(index==1)getJuzNumber();
                      },
                    ),
                  ),
                ),
                elevation: 0,
                centerTitle: true,
                backgroundColor: isDarkModeNotifier.value ? darkModeSecondaryColor : orangeColor,
                title: Text(
                  "alQuran".tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                  ),
                ),
              ),
            );
  }

  Container bookMarksListView(BuildContext context) {
    return Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width * .7,
                color: isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight,
                child: ListView(
                    shrinkWrap: true,
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          if (bookmarks.isNotEmpty)
                            ListView.separated(
                                separatorBuilder: (context, index) => const Divider(),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: bookmarks.length,
                                itemBuilder: (c, i) {
                                  return EasyContainer(
                                    borderRadius: 18,
                                    color: primaryColors[0].withOpacity(.05),
                                    onTap: () async {
                                      {
                                        await Navigator.push(
                                            context,
                                            CupertinoPageRoute(
                                                builder: (builder) => BlocProvider(
                                                      create: (context) => QuranPagePlayerBloc(),
                                                      child: QuranDetailsPage(
                                                          shouldHighlightSura: false,
                                                          pageNumber: quran.getPageNumber(
                                                            int.parse(bookmarks[i]["suraNumber"]
                                                                .toString()),
                                                            int.parse(bookmarks[i]["verseNumber"]
                                                                .toString()),
                                                          ),
                                                          jsonData: widget.jsonData,
                                                          shouldHighlightText: true,
                                                          highlightVerse: quran.getVerse(
                                                            int.parse(bookmarks[i]["suraNumber"]
                                                                .toString()),
                                                            int.parse(bookmarks[i]["verseNumber"]
                                                                .toString()),
                                                          ),
                                                          quarterJsonData:
                                                              widget.quarterjsonData),
                                                    )));
                                      }
                                    },
                                    child: SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.bookmark,
                                                color: Color(
                                                    int.parse("0x${bookmarks[i]["color"]}")),
                                              ),
                                              SizedBox(
                                                width: 20.w,
                                              ),
                                              Text(bookmarks[i]["name"],
                                                  style: TextStyle(
                                                      fontFamily: "cairo",
                                                      fontSize: 14.sp,
                                                      color: getValue("darkMode")
                                                          ? Colors.white.withOpacity(.87)
                                                          : primaryColors[0])),
                                            ],
                                          ),
                                          const Divider(),

                                          SizedBox(
                                            // width: MediaQuery.of(context).size.width * .4,
                                            child: Text(
                                                quran.getVerse(
                                                  int.parse(
                                                      bookmarks[i]["suraNumber"].toString()),
                                                  int.parse(
                                                      bookmarks[i]["verseNumber"].toString()),
                                                ),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontFamily: fontFamilies[0],
                                                  fontSize: 18.sp,
                                                  color: isDarkModeNotifier.value
                                                      ? Colors.white.withOpacity(.87)
                                                      : primaryColors[0],
                                                )),
                                          ),
                                          const Divider(),
                                          Text(
                                            context.locale.languageCode == "ar"
                                                ? quran.getSurahNameArabic(int.parse(
                                                    bookmarks[i]["suraNumber"].toString()))
                                                : quran.getSurahNameEnglish(int.parse(
                                                    bookmarks[i]["suraNumber"].toString())),
                                            style: TextStyle(
                                                color: isDarkModeNotifier.value
                                                    ? Colors.white.withOpacity(.87)
                                                    : Colors.black87),
                                          ),
                                          //
                                          Text(
                                              "${convertToArabicNumber(int.parse(bookmarks[i]["verseNumber"].toString()).toString())} " //               quran.getVerseEndSymbol()
                                              ,
                                              style: TextStyle(
                                                  fontSize: 24.sp,
                                                  color: isDarkModeNotifier.value
                                                      ? Colors.white.withOpacity(.87)
                                                      : Colors.black87,
                                                  fontFamily:
                                                      "KFGQPC Uthmanic Script HAFS Regular"))
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                        ],
                      ),
                      Center(
                          child: Padding(
                        padding: EdgeInsets.only(top: 8.0.h),
                        child: Text(
                          "starredverses".tr(),
                          style: TextStyle(
                            color: isDarkModeNotifier.value
                                ? Colors.white.withOpacity(.87)
                                : Colors.black,
                            fontSize: 18.sp,
                          ),
                        ),
                      )),
                      Center(
                        child: Icon(Icons.keyboard_arrow_down, size: 18.sp),
                      ),
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: starredVerses
                            .map((e) => EasyContainer(
                                color: primaryColors[0].withOpacity(.05),
                                onTap: () async {
                                  await Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                          builder: (builder) => BlocProvider(
                                                create: (context) => QuranPagePlayerBloc(),
                                                child: QuranDetailsPage(
                                                    shouldHighlightSura: false,
                                                    pageNumber: quran.getPageNumber(
                                                        int.parse(e.split("-")[0]),
                                                        int.parse(e.split("-")[1])),
                                                    jsonData: widget.jsonData,
                                                    shouldHighlightText: true,
                                                    highlightVerse: quran.getVerse(
                                                        int.parse(e.split("-")[0]),
                                                        int.parse(e.split("-")[1])),
                                                    quarterJsonData: widget.quarterjsonData),
                                              )));
                                },
                                child: Column(
                                  children: [
                                    Text(
                                        quran.getVerse(int.parse(e.split("-")[0]),
                                            int.parse(e.split("-")[1])),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: fontFamilies[0],
                                          fontSize: 18.sp,
                                          color: isDarkModeNotifier.value
                                              ? Colors.white.withOpacity(.87)
                                              : primaryColors[0],
                                        )),
                                    Text(
                                      context.locale.languageCode == "ar"
                                          ? quran.getSurahNameArabic(int.parse(e.split("-")[0]))
                                          : quran.getSurahNameEnglish(int.parse(e.split("-")[0])),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                        "${convertToArabicNumber((int.parse(e.split("-")[1]).toString()))} " //               quran.getVerseEndSymbol()
                                        ,
                                        style: TextStyle(
                                            fontSize: 24.sp,
                                            color: isDarkModeNotifier.value
                                                ? Colors.white.withOpacity(.87)
                                                : Colors.black87,
                                            fontFamily: "KFGQPC Uthmanic Script HAFS Regular"))
                                  ],
                                )))
                            .toList(),
                      )
                    ]),
              );
  }
}
