// ignore_for_file: file_names

part of '../quranDetailsPage.dart';

extension VerticalViewExtension on QuranDetailsPageState {
  Scaffold buildVerticalView(Size screenSize, BuildContext context) {
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
                            color: softOffWhites[getValue("quranPageolorsIndex")]),
                      ),
                      Text(
                        widget.jsonData[quran.getPageData(index)[0]["surah"] - 1]["name"],
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontFamily: "taha",
                            fontWeight: FontWeight.bold,
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
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
                                        //wordSpacing: -7,
                                        color: darkWarmBrowns[getValue("quranPageolorsIndex")],
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
                                      ],
                                    ));
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
              width: screenSize.width,
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
