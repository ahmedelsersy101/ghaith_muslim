// ignore_for_file: file_names

part of '../quranDetailsPage.dart';

final Map<int, List<InlineSpan>> _pageSpansCache = {};

/// تحويل رقم الجزء (1-30) إلى صيغة ترتيبية بالعربية
String _getArabicOrdinalJuzName(int juzNumber) {
  const arabicOrdinals = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
    'الخامس عشر',
    'السادس عشر',
    'السابع عشر',
    'الثامن عشر',
    'التاسع عشر',
    'العشرون',
    'الحادي والعشرون',
    'الثاني والعشرون',
    'الثالث والعشرون',
    'الرابع والعشرون',
    'الخامس والعشرون',
    'السادس والعشرون',
    'السابع والعشرون',
    'الثامن والعشرون',
    'التاسع والعشرون',
    'الثلاثون',
  ];

  if (juzNumber >= 1 && juzNumber <= 30) {
    return arabicOrdinals[juzNumber - 1];
  }
  return juzNumber.toString();
}

/// تحويل الأرقام الإنجليزية إلى العربية
String _convertNumbersToArabic(String input) {
  const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  String result = input;
  for (int i = 0; i < englishDigits.length; i++) {
    result = result.replaceAll(englishDigits[i], arabicDigits[i]);
  }
  return result;
}

/// متغير لتتبع الجزء الحالي
int _currentJuzNotificationIndex = -1;

extension PageViewExtension on QuranDetailsPageState {
  /// التحقق من بداية جزء جديد وإظهار إشعار
  void _checkAndShowJuzNotification(BuildContext context, int currentPageIndex) {
    if (currentPageIndex == 0) return; // تجاهل صفحة الغلاف

    final currentPageData = quran.getPageData(currentPageIndex);
    if (currentPageData.isEmpty) return;

    final firstVerseData = currentPageData[0];
    final currentJuzNumber = getJuzNumber(
      firstVerseData["surah"],
      firstVerseData["start"],
    );

    // إذا كان الجزء الحالي مختلفًا عن السابق
    if (currentJuzNumber != _currentJuzNotificationIndex) {
      _currentJuzNotificationIndex = currentJuzNumber;

      // إظهار الإشعار
      Fluttertoast.showToast(
        msg: "➤ ${"juz".tr()} ${_getArabicOrdinalJuzName(currentJuzNumber)}",
        backgroundColor: secondaryColors[getValue("quranPageolorsIndex")],
        textColor: softOffWhites[getValue("quranPageolorsIndex")],
        gravity: ToastGravity.CENTER,
      );
    }
  }

  PageView buildPageView(BuildContext context, Size screenSize) {
    return PageView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      allowImplicitScrolling: true,
      pageSnapping: true,
      padEnds: false,

      onPageChanged: (a) {
        // إلغاء أي مؤقت تظليل قيد التشغيل
        verseHighlightTimer?.cancel();

        if (selectedSpan != "") {
          _pageSpansCache.remove(index);
        }
        updateState(() {
          selectedSpan = "";
          highlightVerse = ""; // تنظيف التظليل السابق
          index = a;
        });

        final readerCubit = context.read<QuranReaderCubit>();
        readerCubit.updateFromPageChange(a);

        // التحقق من بداية جزء جديد وإظهار الإشعار
        _checkAndShowJuzNotification(context, a);
      },
      controller: _pageController,
      // onPageChanged: _onPageChanged,
      reverse: context.locale.languageCode == "ar" ? false : true,
      itemCount: quran.totalPagesCount + 1 /* specify the total number of pages */,
      itemBuilder: (context, idx) {
        // Preload next and prev pages spans when scrolling
        // if (_pageController.hasClients && _pageController.position.isScrollingNotifier.value) {
        //   if (idx < quran.totalPagesCount) _buildPageSpans(idx + 1);
        //   if (idx > 1) _buildPageSpans(idx - 1);
        // }

        final bool isEvenPage = idx.isEven;

        if (idx == 0) {
          return Container(
            color: const Color(0xffFFFCE7),
            child: Image.asset(
              "assets/images/quran.jpg",
              fit: BoxFit.fill,
            ),
          );
        }

        return KeepAlivePage(
          child: _buildQuranPage(idx, isEvenPage, screenSize, context),
        );
      },
    );
  }

  Widget _buildQuranPage(int index, bool isEvenPage, Size screenSize, BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  right: 12.0.w,
                  left: 12.w,
                ),
                child: CustomBodyPageView(index, screenSize),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(right: 12.w, left: 12.w, top: 2.h),
                child: MushafDivider(color: secondaryColors[getValue("quranPageolorsIndex")]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  right: 20.w,
                ),
                child: CustomFooterPageView(index),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Center CustomFooterPageView(int index) {
    return Center(
      child: Builder(
        builder: (context) {
          final quarterResult = checkIfPageIncludesQuarterAndQuarterIndex(
              widget.quarterJsonData, quran.getPageData(index), indexes);

          return quarterResult.includesQuarter
              ? Align(
                  alignment: Alignment.centerRight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/numberP.png',
                        height: 27.h,
                      ),
                      Text(
                        "${"page".tr()} ${_convertNumbersToArabic(index.toString())}  |  ${(quarterResult.quarterIndex + 1) == 1 ? "" : "${_convertNumbersToArabic((quarterResult.quarterIndex).toString())}/${_convertNumbersToArabic(4.toString())}"} ${"hizb".tr()} ${_convertNumbersToArabic((quarterResult.hizbIndex + 1).toString())}",
                        style: TextStyle(
                          fontFamily: 'aldahabi',
                          fontSize: 10.sp,
                          color: secondaryColors[getValue("quranPageolorsIndex")],
                        ),
                      ),
                    ],
                  ),
                )
              : Align(
                  alignment: Alignment.centerRight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/numberP.png',
                        height: 20.h,
                      ),
                      Text(
                        "${"page".tr()} ${_convertNumbersToArabic(index.toString())}",
                        style: TextStyle(
                          fontFamily: 'aldahabi',
                          fontSize: 11.sp,
                          color: secondaryColors[getValue("quranPageolorsIndex")],
                        ),
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }

  SizedBox CustomBodyPageView(int index, Size screenSize) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          if ((index == 1 || index == 2))
            SizedBox(
              height: (screenSize.height * .24),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ).r,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${"juz".tr()} ${_getArabicOrdinalJuzName(getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"]))}",
                  style: TextStyle(
                    fontFamily: 'aldahabi',
                    fontSize: 14.sp,
                    color: secondaryColors[getValue("quranPageolorsIndex")],
                  ),
                ),
                Text(widget.jsonData[quran.getPageData(index)[0]["surah"] - 1]["name"],
                    style: TextStyle(
                        color: secondaryColors[getValue("quranPageolorsIndex")],
                        fontFamily: "Taha",
                        fontSize: 16.sp,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
          MushafDivider(color: secondaryColors[getValue("quranPageolorsIndex")]),
          Directionality(
            textDirection: m.TextDirection.rtl,
            child: SizedBox(
              width: double.infinity,
              child: RepaintBoundary(
                child: RichText(
                  key: richTextKeys[index - 1],
                  textDirection: m.TextDirection.rtl,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  text: TextSpan(
                    locale: const Locale("ar"),
                    children: _buildPageSpans(index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildPageSpans(int index) {
    if (_pageSpansCache.containsKey(index)) {
      return _pageSpansCache[index]!;
    }

    List<InlineSpan> spans = quran.getPageData(index).expand((e) {
      List<InlineSpan> iterSpans = [];
      for (var i = e["start"]; i <= e["end"]; i++) {
        // Header
        if (i == 1) {
          iterSpans.add(WidgetSpan(
            child: HeaderWidget(e: e, jsonData: widget.jsonData),
          ));

          if (index != 187 && index != 1) {
            iterSpans.add(WidgetSpan(
                child: Basmallah(
              index: getValue("quranPageolorsIndex"),
            )));
          }
          if (index == 187 || index == 1) {
            iterSpans.add(WidgetSpan(
                child: Container(
              height: 10.h,
            )));
          }
        }

        // Verses
        iterSpans.add(TextSpan(
          locale: const Locale("ar"),
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
                _pageSpansCache.remove(index);
                updateState(() {
                  selectedSpan = "";
                });
              }
            }
            ..onLongPressUp = () {
              verseHighlightTimer?.cancel();
              _pageSpansCache.remove(index);
              updateState(() {
                selectedSpan = "";
              });
              print("finished long press");
            }
            ..onLongPressCancel = () {
              verseHighlightTimer?.cancel();
              _pageSpansCache.remove(index);
              updateState(() {
                selectedSpan = "";
              });
            },
          text: i == e["start"]
              ? "${quran.getVerseQCF(e["surah"], i).replaceAll(" ", "").substring(0, 1)}\u200A${quran.getVerseQCF(e["surah"], i).replaceAll(" ", "").substring(1)}"
              : quran.getVerseQCF(e["surah"], i).replaceAll(' ', ''),
          style: TextStyle(
            height: (index == 1 || index == 2) ? 2.h : 1.95.h,
            letterSpacing: 0.w,
            wordSpacing: 0,
            color: darkWarmBrowns[getValue("quranPageolorsIndex")],
            fontSize: index == 1 || index == 2
                ? 28.sp
                : index == 145 || index == 201
                    ? index == 532 || index == 533
                        ? 22.5.sp
                        : 22.4.sp
                    : 22.9.sp,
            fontFamily: "QCF_P${index.toString().padLeft(3, "0")}",
            backgroundColor: selectedSpan == "${e["surah"]}:$i"
                ? secondaryColors[getValue("quranPageolorsIndex")].withOpacity(0.3)
                : hasLocalBookmark(
                    e["surah"] as int,
                    i as int,
                  )
                    ? localBookmarkColor(e["surah"] as int, i)?.withOpacity(.19) ??
                        Colors.transparent
                    : Colors.transparent,
          ),
        ));
        if (hasLocalBookmark(
          e["surah"] as int,
          i,
        )) {
          iterSpans.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                Icons.bookmark,
                color: localBookmarkColor(
                      e["surah"] as int,
                      i,
                    ) ??
                    secondaryColors[getValue("quranPageolorsIndex")],
              )));
        }
      }
      return iterSpans;
    }).toList();

    _pageSpansCache[index] = spans;
    return spans;
  }

  Container CustomHeaderPageView(Size screenSize, BuildContext context, int index) {
    return Container(
      decoration: BoxDecoration(
        color: secondaryColors[getValue("quranPageolorsIndex")],
      ),
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(
          right: 8.0.w,
          left: 8.w,
        ),
        child: Row(
          mainAxisAlignment: m.MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 24.sp,
                  color: softOffWhites[getValue("quranPageolorsIndex")],
                )),
            Row(
              mainAxisAlignment: m.MainAxisAlignment.start,
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
                      size: 24.sp,
                      color: softOffWhites[getValue("quranPageolorsIndex")],
                    )),
                IconButton(
                    onPressed: () {
                      SettingsBottomSheet.show(context, onSettingsChanged: () {
                        _pageSpansCache.clear();
                        getTranslationData();
                        updateState(() {});
                      });
                    },
                    icon: Icon(
                      Icons.settings,
                      size: 24.sp,
                      color: softOffWhites[getValue("quranPageolorsIndex")],
                    )),
              ],
            ),
          ],
        ),
      ),
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
