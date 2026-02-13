// ignore_for_file: file_names

part of '../quranDetailsPage.dart';

extension PageViewExtension on QuranDetailsPageState {
  PageView buildPageView(BuildContext context, Size screenSize) {
    return PageView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      pageSnapping: true,

      onPageChanged: (a) {
        updateState(() {
          selectedSpan = "";
          index = a;
        });

        final readerCubit = context.read<QuranReaderCubit>();
        readerCubit.updateFromPageChange(a);
      },
      controller: _pageController,
      // onPageChanged: _onPageChanged,
      reverse: context.locale.languageCode == "ar" ? false : true,
      itemCount: quran.totalPagesCount + 1 /* specify the total number of pages */,
      itemBuilder: (context, index) {
        final bool isEvenPage = index.isEven;

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
          isEvenPage: isEvenPage,
          // Wrap the page content in RepaintBoundary to avoid unnecessary repaints
          child: RepaintBoundary(
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.transparent,
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
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
                              IconButton(
                                  onPressed: () async {
                                    final pageNumber =
                                        await QuranDetailsPageState.showSurahNavigatorSheet(
                                            context);
                                    if (pageNumber != null) {
                                      final readerCubit = context.read<QuranReaderCubit>();
                                      readerCubit.goToPage(pageNumber);
                                    }
                                  },
                                  icon: Icon(
                                    Icons.menu_book_rounded,
                                    size: 24.sp,
                                    color: secondaryColors[getValue("quranPageolorsIndex")],
                                  )),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ).r,
                            child: Text(
                                widget.jsonData[quran.getPageData(index)[0]["surah"] - 1]["name"],
                                style: TextStyle(
                                    color: secondaryColors[getValue("quranPageolorsIndex")],
                                    fontFamily: "Taha",
                                    fontSize: 20.sp,
                                    letterSpacing: 0.3)),
                          ),
                        ],
                      ),
                    ),
                    MushafDivider(color: secondaryColors[getValue("quranPageolorsIndex")]),
                    // ===== محتوى القرآن (يتكيف مع المساحة المتاحة) =====
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: screenSize.width - 32.w,
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
                                                  wordSpacing: -1.4,
                                                  color: darkWarmBrowns[
                                                      getValue("quranPageolorsIndex")],
                                                  fontSize: 24.sp,
                                                  fontFamily: getValue("selectedFontFamily"),
                                                  backgroundColor: hasLocalBookmark(
                                                    e["surah"] as int,
                                                    i as int,
                                                  )
                                                      ? localBookmarkColor(e["surah"] as int, i)
                                                              ?.withOpacity(.19) ??
                                                          Colors.transparent
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
                                                          " ${convertToArabicNumber((i).toString())} ",
                                                      style: TextStyle(
                                                          color: isVerseStarred(e["surah"], i)
                                                              ? Colors.amber
                                                              : secondaryColors[
                                                                  getValue("quranPageolorsIndex")],
                                                          fontFamily:
                                                              "KFGQPC Uthmanic Script HAFS Regular")),
                                                ],
                                              ));
                                              if (hasLocalBookmark(
                                                e["surah"] as int,
                                                i,
                                              )) {
                                                spans.add(WidgetSpan(
                                                    alignment: PlaceholderAlignment.middle,
                                                    child: Icon(
                                                      Icons.bookmark,
                                                      color: localBookmarkColor(
                                                            e["surah"] as int,
                                                            i,
                                                          ) ??
                                                          secondaryColors[
                                                              getValue("quranPageolorsIndex")],
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
                    // ===== Footer =====
                    SizedBox(height: 4.h),
                    MushafDivider(color: secondaryColors[getValue("quranPageolorsIndex")]),
                    SizedBox(height: 8.h),
                    Center(
                      child: Builder(
                        builder: (context) {
                          final quarterResult = checkIfPageIncludesQuarterAndQuarterIndex(
                              widget.quarterJsonData, quran.getPageData(index), indexes);

                          return quarterResult.includesQuarter
                              ? EasyContainer(
                                  borderRadius: 12.r,
                                  color: secondaryColors[getValue("quranPageolorsIndex")]
                                      .withOpacity(.5),
                                  borderColor: softOffWhites[getValue("quranPageolorsIndex")],
                                  showBorder: true,
                                  height: 30.h,
                                  width: 250.w,
                                  padding: 0,
                                  margin: 0,
                                  child: Center(
                                    child: Text(
                                      "${"page".tr()} ${(index).toString()}  |  ${(quarterResult.quarterIndex + 1) == 1 ? "" : "${(quarterResult.quarterIndex).toString()}/${4.toString()}"} ${"hizb".tr()} ${(quarterResult.hizbIndex + 1).toString()} | ${"juz".tr()} ${getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"])}",
                                      style: TextStyle(
                                        fontFamily: 'aldahabi',
                                        fontSize: 12.sp,
                                        color: softOffWhites[getValue("quranPageolorsIndex")],
                                      ),
                                    ),
                                  ),
                                )
                              : EasyContainer(
                                  borderRadius: 12.r,
                                  color: secondaryColors[getValue("quranPageolorsIndex")]
                                      .withOpacity(.5),
                                  borderColor: softOffWhites[getValue("quranPageolorsIndex")],
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
                                        color: softOffWhites[getValue("quranPageolorsIndex")],
                                      ),
                                    ),
                                  ),
                                );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({super.key, required this.child});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
