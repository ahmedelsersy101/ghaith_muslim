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
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        checkIfPageIncludesQuarterAndQuarterIndex(
                                        widget.quarterJsonData, quran.getPageData(index), indexes)
                                    .includesQuarter ==
                                true
                            ? "${"page".tr()} ${_convertNumbersToArabic(index.toString())} | ${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex + 1) == 1 ? "" : "${_convertNumbersToArabic((checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex).toString())}/${_convertNumbersToArabic(4.toString())}"} ${"hizb".tr()} ${_convertNumbersToArabic((checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).hizbIndex + 1).toString())} | ${"juz".tr()} ${_getArabicOrdinalJuzName(getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"]))}"
                            : "${"page".tr()} ${_convertNumbersToArabic(index.toString())} | ${"juz".tr()} ${_getArabicOrdinalJuzName(getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"]))}",
                        style: TextStyle(
                            fontSize: 14.sp,
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
            initialScrollIndex: getInitialPageIndex(context),
            itemPositionsListener: itemPositionsListener,
            itemBuilder: (context, index) {
              // تنظيف التظليل عند تغيير الصفحة في عرض الآية بآية
              verseHighlightTimer?.cancel();

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
                                          recognizer: LongPressGestureRecognizer(
                                            duration: const Duration(milliseconds: 300),
                                          )
                                            ..onLongPressDown = (details) {
                                              verseHighlightTimer?.cancel();
                                              updateState(() {
                                                selectedSpan = "${e["surah"]}:$i";
                                              });
                                            }
                                            ..onLongPress = () {
                                              showAyahOptionsSheet(index, e["surah"], i);
                                              print("longpressed");
                                            }
                                            ..onLongPressMoveUpdate = (details) {
                                              if (details.offsetFromOrigin.distance > 20) {
                                                verseHighlightTimer?.cancel();
                                                updateState(() {
                                                  selectedSpan = "";
                                                });
                                              }
                                            }
                                            ..onLongPressUp = () {
                                              verseHighlightTimer?.cancel();
                                              updateState(() {
                                                selectedSpan = "";
                                              });
                                              print("finished long press");
                                            }
                                            ..onLongPressCancel = () {
                                              verseHighlightTimer?.cancel();
                                              updateState(() {
                                                selectedSpan = "";
                                              });
                                            },
                                          text: quran.getVerse(e["surah"], i),
                                          style: TextStyle(
                                            color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                                            fontSize: getValue("verseByVerseFontSize").toDouble(),
                                            fontFamily: getValue("selectedFontFamily"),
                                            backgroundColor: selectedSpan == "${e["surah"]}:$i"
                                                ? secondaryColors[getValue("quranPageolorsIndex")]
                                                    .withOpacity(0.3)
                                                : hasLocalBookmark(
                                                    e["surah"] as int,
                                                    i as int,
                                                  )
                                                    ? localBookmarkColor(e["surah"] as int, i)
                                                            ?.withOpacity(.19) ??
                                                        Colors.transparent
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
                                        if (hasLocalBookmark(
                                          e["surah"] as int,
                                          i,
                                        ))
                                          WidgetSpan(
                                              alignment: PlaceholderAlignment.middle,
                                              child: Icon(
                                                Icons.bookmark,
                                                color: localBookmarkColor(
                                                      e["surah"] as int,
                                                      i,
                                                    ) ??
                                                    secondaryColors[
                                                        getValue("quranPageolorsIndex")],
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                color: secondaryColors[getValue("quranPageolorsIndex")],
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
                              onPressed: () async {
                                final pageNumber =
                                    await QuranDetailsPageState.showSurahNavigatorSheet(context);
                                if (pageNumber != null) {
                                  final readerCubit = context.read<QuranReaderCubit>();
                                  readerCubit.goToPage(pageNumber);
                                }
                              },
                              icon: Icon(
                                Icons.menu_book_rounded,
                                color: secondaryColors[getValue("quranPageolorsIndex")],
                              )),
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
                                color: secondaryColors[getValue("quranPageolorsIndex")],
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
