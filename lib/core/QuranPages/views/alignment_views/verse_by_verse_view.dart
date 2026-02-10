// ignore_for_file: file_names

part of '../quranDetailsPage.dart';

extension VerseByVerseViewExtension on QuranDetailsPageState {
  Scaffold buildVerseByVerseView(Size screenSize, BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: softOffWhites[getValue("quranPageolorsIndex")],
      body: Stack(
        children: [
          ScrollablePositionedList.separated(
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
                            color: softOffWhites[getValue("quranPageolorsIndex")]),
                      ),
                      Text(
                        widget.jsonData[quran.getPageData(index)[0]["surah"] - 1]["name"],
                        style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontFamilies[0],
                            color: softOffWhites[getValue("quranPageolorsIndex")]),
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
              if (index == 0) {
                return Container(
                  color: const Color(0xffFFFCE7),
                  child: Image.asset(
                    "assets/images/quran.jpg",
                    fit: BoxFit.fill,
                  ),
                );
              }
              return MushafPageShell(
                screenSize: screenSize,
                isEvenPage: index.isEven,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 4.h),
                    MushafDivider(color: secondaryColors[getValue("quranPageolorsIndex")]),
                    SizedBox(height: 6.h),
                    Directionality(
                      textDirection: m.TextDirection.rtl,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        child: SizedBox(
                            width: double.infinity,
                            child: RichText(
                              key: richTextKeys[index - 1],
                              textDirection: m.TextDirection.rtl,
                              textAlign: TextAlign.right,
                              softWrap: true,
                              text: TextSpan(
                                locale: const Locale("ar"),
                                children: quran.getPageData(index).expand((e) {
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
                                              showAyahOptionsSheet(index, e["surah"], i);
                                              print("longpressed");
                                            }
                                            ..onLongPressDown = (details) {
                                              updateState(() {
                                                selectedSpan = " ${e["surah"]}$i";
                                              });
                                            }
                                            ..onLongPressUp = () {
                                              updateState(() {
                                                selectedSpan = "";
                                              });
                                              print("finished long press");
                                            }
                                            ..onLongPressCancel = () => updateState(() {
                                                  selectedSpan = "";
                                                }),
                                          text: quran.getVerse(e["surah"], i),
                                          style: TextStyle(
                                            color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                                            fontSize: getValue("verseByVerseFontSize").toDouble(),
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
                                            text: " ${convertToArabicNumber((i).toString())} ",
                                            style: TextStyle(
                                                fontSize: 24.sp,
                                                color: isVerseStarred(e["surah"], i)
                                                    ? Colors.amber
                                                    : secondaryColors[
                                                        getValue("quranPageolorsIndex")],
                                                fontFamily: "KFGQPC Uthmanic Script HAFS Regular")),
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
                                                        fontFamily: 'cairo',
                                                        fontSize: FontSize(14.sp),
                                                        lineHeight: LineHeight(1.7.sp),
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
                                                        color: darkWarmBrowns[
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
                                          color: darkWarmBrowns[getValue("quranPageolorsIndex")]
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
                    SizedBox(height: 6.h),
                    MushafDivider(color: secondaryColors[getValue("quranPageolorsIndex")]),
                    SizedBox(height: 2.h),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: EdgeInsets.only(top: 28.0.h),
            child: Container(
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
                              color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                            )),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: (screenSize.width * .27).w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                            onPressed: () {
                              SettingsBottomSheet.show(context, onSettingsChanged: () {
                                getTranslationData();
                                updateState(() {});
                              });
                            },
                            icon: Icon(
                              Icons.settings,
                              size: 24.sp,
                              color: darkWarmBrowns[getValue("quranPageolorsIndex")],
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
}
