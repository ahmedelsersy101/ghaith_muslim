// ignore_for_file: file_names

part of '../quranDetailsPage.dart';

final Map<int, List<InlineSpan>> _verticalSpansCache = {};

/// متغير لتتبع الجزء الحالي في العرض الرأسي
// int _currentVerticalJuzNotificationIndex = -1;

extension VerticalViewExtension on QuranDetailsPageState {
  /// التحقق من بداية جزء جديد وإظهار إشعار في العرض الرأسي
  // void _checkAndShowVerticalJuzNotification(int currentPageIndex) {
  //   if (currentPageIndex == 0) return; // تجاهل صفحة الغلاف

  //   final currentPageData = quran.getPageData(currentPageIndex);
  //   if (currentPageData.isEmpty) return;

  //   final firstVerseData = currentPageData[0];
  //   final currentJuzNumber = getJuzNumber(
  //     firstVerseData["surah"],
  //     firstVerseData["start"],
  //   );

  //   // إذا كان الجزء الحالي مختلفًا عن السابق
  //   if (currentJuzNumber != _currentVerticalJuzNotificationIndex) {
  //     _currentVerticalJuzNotificationIndex = currentJuzNumber;

  //     // إظهار الإشعار
  //     Fluttertoast.showToast(
  //       msg: "➤ ${"juz".tr()} ${_getArabicOrdinalJuzName(currentJuzNumber)}",
  //       backgroundColor: secondaryColors[getValue("quranPageolorsIndex")],
  //       textColor: softOffWhites[getValue("quranPageolorsIndex")],
  //       gravity: ToastGravity.CENTER,
  //     );
  //   }
  // }

  Scaffold buildVerticalView(Size screenSize, BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: softOffWhites[getValue("quranPageolorsIndex")],
      body: Stack(
        children: [
          ScrollablePositionedList.separated(
            itemCount: quran.totalPagesCount + 1,
            physics: const BouncingScrollPhysics(),
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
                            ? "${"page".tr()} ${_convertNumbersToArabic(index.toString())} | ${(checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex + 1) == 1 ? "" : "${_convertNumbersToArabic((checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).quarterIndex).toString())}/${_convertNumbersToArabic(4.toString())}"} ${"hizb".tr()} ${_convertNumbersToArabic((checkIfPageIncludesQuarterAndQuarterIndex(widget.quarterJsonData, quran.getPageData(index), indexes).hizbIndex + 1).toString())} | ${"juz".tr()} ${_getArabicOrdinalJuzName(getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"]))}"
                            : "${"page".tr()} ${_convertNumbersToArabic(index.toString())} | ${"juz".tr()} ${_getArabicOrdinalJuzName(getJuzNumber(getPageData(index)[0]["surah"], getPageData(index)[0]["start"]))}",
                        style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: softOffWhites[getValue("quranPageolorsIndex")]),
                      ),
                      Text(
                        widget.jsonData[quran.getPageData(index)[0]["surah"] - 1]["name"],
                        style: TextStyle(
                            fontSize: 12.sp,
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
            initialScrollIndex: getInitialPageIndex(context),
            itemPositionsListener: itemPositionsListener,
            itemBuilder: (context, index) {
              // تنظيف التظليل عند تغيير الصفحة في العرض الرأسي
              verseHighlightTimer?.cancel();

              // التحقق من بداية جزء جديد
              // WidgetsBinding.instance.addPostFrameCallback((_) {
              //   _checkAndShowVerticalJuzNotification(index);
              // });

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

              return KeepAlivePage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 12.h),
                    MushafDivider(color: secondaryColors[getValue("quranPageolorsIndex")]),
                    Directionality(
                      textDirection: m.TextDirection.rtl,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        child: SizedBox(
                          width: double.infinity,
                          child: RepaintBoundary(
                            child: RichText(
                              key: richTextKeys[index - 1],
                              textDirection: m.TextDirection.rtl,
                              textAlign: TextAlign.center,
                              softWrap: true, //locale: const Locale("ar"),
                              text: TextSpan(
                                locale: const Locale("ar"),
                                children: _buildVerticalPageSpans(index),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    MushafDivider(color: secondaryColors[getValue("quranPageolorsIndex")]),
                    SizedBox(height: 12.h),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildVerticalPageSpans(int index) {
    if (_verticalSpansCache.containsKey(index)) {
      return _verticalSpansCache[index]!;
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
                _verticalSpansCache.remove(index);
                updateState(() {
                  selectedSpan = "";
                });
              }
            }
            ..onLongPressUp = () {
              verseHighlightTimer?.cancel();
              _verticalSpansCache.remove(index);
              updateState(() {
                selectedSpan = "";
              });
              print("finished long press");
            }
            ..onLongPressCancel = () {
              verseHighlightTimer?.cancel();
              _verticalSpansCache.remove(index);
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

    _verticalSpansCache[index] = spans;
    return spans;
  }
}
