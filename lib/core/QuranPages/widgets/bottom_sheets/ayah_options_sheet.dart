import 'dart:convert';
import 'dart:io';
import 'package:easy_container/easy_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ghaith/blocs/quran_page_player_bloc.dart';
import 'package:ghaith/core/QuranPages/helpers/translation/translation_info.dart';
import 'package:ghaith/core/QuranPages/widgets/bottom_sheets/tafseer_and_translation_sheet.dart';
import 'package:ghaith/core/QuranPages/widgets/dialogs/bookmark_dialog.dart';
import 'package:ghaith/core/QuranPages/widgets/dialogs/share_ayah_dialog.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/models/reciter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:quran/quran.dart' as quran;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';


class AyahOptionsSheet extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final int index; // Page index or similar
  final Set<String> starredVerses;
  final List<dynamic> bookmarks;
  final List<QuranPageReciter> reciters;
  final List<TranslationData> translationDataList;
  final GlobalKey? verseKey;
  final Directory? appDir;
  final dynamic jsonData; // For screenshot preview
  final ItemScrollController? itemScrollController; // For jumping to verse

  // Callbacks
  final VoidCallback onUpdate; // To setState in parent
  final Function(int surah, int verse) onAddStarredVerse;
  final Function(int surah, int verse) onRemoveStarredVerse;
  final VoidCallback onFetchBookmarks;

  const AyahOptionsSheet({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    required this.index,
    required this.starredVerses,
    required this.bookmarks,
    required this.reciters,
    required this.translationDataList,
    this.verseKey,
    this.appDir,
    this.jsonData,
    this.itemScrollController,
    required this.onUpdate,
    required this.onAddStarredVerse,
    required this.onRemoveStarredVerse,
    required this.onFetchBookmarks,
  });

  @override
  State<AyahOptionsSheet> createState() => _AyahOptionsSheetState();
}

class _AyahOptionsSheetState extends State<AyahOptionsSheet> {
  // We use the parent's context for some operations like BlocProvider
  // But since we are in a separate widget tree (bottom sheet), we might need
  // to pass the parent context or rely on local context if BlocProvider is above MaterialApp
  // Usually BlocProvider is at root, so local context works.

  // Local state for downloading
  String isDownloading = "";

  bool isVerseStarred(int surah, int ayah) {
    return widget.starredVerses.contains("$surah:$ayah");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Container(
        decoration: BoxDecoration(
          color: softOffWhites[getValue("quranPageolorsIndex")],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                "${context.locale.languageCode == "ar" ? quran.getSurahNameArabic(widget.surahNumber) : quran.getSurahNameEnglish(widget.surahNumber)}: ${widget.verseNumber}",
                style: TextStyle(color: darkWarmBrowns[getValue("quranPageolorsIndex")]),
              ),
              trailing: SizedBox(
                width: 200.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        isVerseStarred(widget.surahNumber, widget.verseNumber)
                            ? widget.onRemoveStarredVerse(widget.surahNumber, widget.verseNumber)
                            : widget.onAddStarredVerse(widget.surahNumber, widget.verseNumber);

                        setState(() {}); // Update local sheet state
                        widget.onUpdate(); // Update parent state
                        widget.verseKey?.currentState?.build(context);
                      },
                      icon: Icon(
                        isVerseStarred(widget.surahNumber, widget.verseNumber)
                            ? FontAwesome.star
                            : FontAwesome.star_empty,
                        color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => ShareAyahDialog(
                              surahNumber: widget.surahNumber,
                              verseNumber: widget.verseNumber,
                              index: widget.index,
                              jsonData: widget.jsonData,
                              translationDataList: widget.translationDataList,
                            ),
                          );
                        },
                        icon: Icon(Icons.share,
                            color: darkWarmBrowns[getValue("quranPageolorsIndex")])),
                  ],
                ),
              ),
            ),
            Divider(
              height: 10.h,
              color: darkWarmBrowns[getValue("quranPageolorsIndex")],
            ),
            SizedBox(height: 10.h),

            // Bookmarks List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: darkWarmBrowns[getValue("quranPageolorsIndex")].withOpacity(.05),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (widget.bookmarks.isNotEmpty)
                        ListView.separated(
                          separatorBuilder: (context, index) => const Divider(),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.bookmarks.length,
                          itemBuilder: (c, i) {
                            return GestureDetector(
                              onTap: () async {
                                List bookmarks = json.decode(getValue("bookmarks"));
                                bookmarks[i]["verseNumber"] = widget.verseNumber;
                                bookmarks[i]["suraNumber"] = widget.surahNumber;
                                updateValue("bookmarks", json.encode(bookmarks));

                                widget.onUpdate();
                                widget.onFetchBookmarks();
                                Navigator.of(context).pop();
                              },
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Row(
                                  children: [
                                    SizedBox(width: 20.w),
                                    Icon(Icons.bookmark,
                                        color:
                                            Color(int.parse("0x${widget.bookmarks[i]["color"]}"))),
                                    SizedBox(width: 20.w),
                                    Text(
                                      widget.bookmarks[i]["name"],
                                      style: TextStyle(
                                        fontFamily: "cairo",
                                        fontSize: 14.sp,
                                        color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                                      ),
                                    ),
                                    const Spacer(),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          quran.getVerse(
                                            int.parse(widget.bookmarks[i]["suraNumber"].toString()),
                                            int.parse(
                                                widget.bookmarks[i]["verseNumber"].toString()),
                                          ),
                                          textDirection: m.TextDirection.rtl,
                                          style: TextStyle(
                                            fontFamily: fontFamilies[0],
                                            fontSize: 13.sp,
                                            color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        List bookmarks = json.decode(getValue("bookmarks"));
                                        Fluttertoast.showToast(
                                          msg: "${widget.bookmarks[i]["name"]} removed",
                                        );
                                        bookmarks.removeWhere(
                                            (e) => e["color"] == widget.bookmarks[i]["color"]);
                                        updateValue("bookmarks", json.encode(bookmarks));

                                        widget.onUpdate();
                                        widget.onFetchBookmarks();
                                        Navigator.of(context).pop();
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color:
                                            Color(int.parse("0x${widget.bookmarks[i]["color"]}")),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      if (widget.bookmarks.isNotEmpty) const Divider(),
                      EasyContainer(
                        color: Colors.transparent,
                        onTap: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => BookmarksDialog(
                              suraNumber: widget.surahNumber,
                              verseNumber: widget.verseNumber,
                            ),
                          );
                          widget.onFetchBookmarks();
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
                                  color: darkWarmBrowns[getValue("quranPageolorsIndex")],
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

            // Tafseer and Translation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: EasyContainer(
                color: darkWarmBrowns[getValue("quranPageolorsIndex")].withOpacity(.05),
                borderRadius: 12,
                onTap: () {
                  showMaterialModalBottomSheet(
                    enableDrag: true,
                    context: context,
                    animationCurve: Curves.easeInOutQuart,
                    elevation: 0,
                    bounce: true,
                    duration: const Duration(milliseconds: 400),
                    backgroundColor: softOffWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(13.r),
                        topLeft: Radius.circular(13.r),
                      ),
                    ),
                    isDismissible: true,
                    builder: (d) {
                      return TafseerAndTranslateSheet(
                        surahNumber: widget.surahNumber,
                        isVerseByVerseSelection: false,
                        verseNumber: widget.verseNumber,
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
                          color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // Play Verse
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: EasyContainer(
                borderRadius: 10,
                color: darkWarmBrowns[getValue("quranPageolorsIndex")].withOpacity(.06),
                onTap: () async {
                  Navigator.pop(context);

                  final quranPagePlayerBloc =
                      BlocProvider.of<QuranPagePlayerBloc>(context, listen: false);

                  if (quranPagePlayerBloc.state is QuranPagePlayerPlaying) {
                    quranPagePlayerBloc.add(KillPlayerEvent());
                  }

                  quranPagePlayerBloc.add(
                    PlayFromVerse(
                      widget.verseNumber,
                      widget.reciters[getValue("reciterIndex")].identifier,
                      widget.surahNumber,
                      quran.getSurahNameEnglish(widget.surahNumber),
                    ),
                  );

                  if (getValue("alignmentType") == "verticalview" &&
                      quran.getPageNumber(widget.surahNumber, widget.verseNumber) > 600) {
                    await Future.delayed(const Duration(milliseconds: 1000));
                    widget.itemScrollController?.jumpTo(
                      index: quran.getPageNumber(widget.surahNumber, widget.verseNumber),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "play".tr(),
                        style: TextStyle(
                          fontFamily: "cairo",
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: darkWarmBrowns[getValue("quranPageolorsIndex")].withOpacity(.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: getValue("reciterIndex"),
                            dropdownColor: softOffWhites[getValue("quranPageolorsIndex")],
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                              size: 18.sp,
                            ),
                            isDense: true,
                            onChanged: (int? newIndex) {
                              updateValue("reciterIndex", newIndex);
                              setState(() {});
                              widget.onUpdate();
                            },
                            items: widget.reciters.map((reciter) {
                              return DropdownMenuItem<int>(
                                value: widget.reciters.indexOf(reciter),
                                child: Text(
                                  context.locale.languageCode == "ar"
                                      ? reciter.name
                                      : reciter.englishName,
                                  style: TextStyle(
                                    fontFamily: "cairo",
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
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
  }
}
