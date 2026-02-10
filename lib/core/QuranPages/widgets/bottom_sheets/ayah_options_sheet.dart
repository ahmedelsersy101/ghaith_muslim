import 'dart:convert';
import 'dart:io';
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
  final int index;
  final Set<String> starredVerses;
  final List<dynamic> bookmarks;
  final List<QuranPageReciter> reciters;
  final List<TranslationData> translationDataList;
  final GlobalKey? verseKey;
  final Directory? appDir;
  final dynamic jsonData;
  final ItemScrollController? itemScrollController;

  final VoidCallback onUpdate;
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

class _AyahOptionsSheetState extends State<AyahOptionsSheet> with TickerProviderStateMixin {
  // ============ Animation Controllers ============
  late AnimationController _animationController;
  late AnimationController _playButtonController;

  // ============ Animations ============
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ============ State Variables ============
  late int _currentColorIndex;
  late int _currentReciterIndex;

  @override
  void initState() {
    super.initState();
    _currentColorIndex = getValue("quranPageolorsIndex");
    _currentReciterIndex = getValue("reciterIndex");

    // Main animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Play button pulse animation
    _playButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _playButtonController.dispose();
    super.dispose();
  }

  // ============ Getters ============
  bool get _isVerseStarred =>
      widget.starredVerses.contains("${widget.surahNumber}:${widget.verseNumber}");

  String get _surahName => context.locale.languageCode == "ar"
      ? quran.getSurahNameArabic(widget.surahNumber)
      : quran.getSurahNameEnglish(widget.surahNumber);

  Color get _primaryColor => darkWarmBrowns[_currentColorIndex];
  Color get _backgroundColor => softOffWhites[_currentColorIndex];
  Color get _secondaryColor => secondaryColors[_currentColorIndex];
  Color get _accentColor => highlightColors[_currentColorIndex];

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28.r),
              topRight: Radius.circular(28.r),
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(),
              _buildHeader(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    _buildQuickActions(),
                    SizedBox(height: 20.h),
                    _buildBookmarksSection(),
                    SizedBox(height: 16.h),
                    _buildActionButtons(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ Drag Handle ============
  Widget _buildDragHandle() {
    return Container(
      margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }

  // ============ Header Section ============
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          // Surah Icon
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.1),
                  _secondaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              FontAwesome5.quran,
              color: _primaryColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          // Surah Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _surahName,
                  style: TextStyle(
                    fontFamily: "cairo",
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                Text(
                  "${"verse".tr()} ${widget.verseNumber}",
                  style: TextStyle(
                    fontFamily: "cairo",
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: _primaryColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ Quick Actions ============
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: _isVerseStarred ? FontAwesome.star : FontAwesome.star_empty,
            label: _isVerseStarred ? "starred".tr() : "star".tr(),
            onTap: _handleStarToggle,
            color: Colors.amber.shade600,
            isActive: _isVerseStarred,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.share_rounded,
            label: "share".tr(),
            onTap: _handleShare,
            color: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : _primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isActive ? color.withOpacity(0.3) : _primaryColor.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? color : _primaryColor,
              size: 24.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: "cairo",
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isActive ? color : _primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Bookmarks Section ============
  Widget _buildBookmarksSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _primaryColor.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Icon(
                  Icons.bookmark_rounded,
                  color: _secondaryColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  "bookmarks".tr(),
                  style: TextStyle(
                    fontFamily: "cairo",
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _secondaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    "${widget.bookmarks.length}",
                    style: TextStyle(
                      fontFamily: "cairo",
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: _secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.bookmarks.isNotEmpty) ...[
            Divider(
              color: _primaryColor.withOpacity(0.1),
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            _buildBookmarksList(),
            Divider(
              color: _primaryColor.withOpacity(0.1),
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
          ],
          _buildAddBookmarkButton(),
        ],
      ),
    );
  }

  Widget _buildBookmarksList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.bookmarks.length,
      itemBuilder: (context, index) {
        return _ModernBookmarkItem(
          bookmark: widget.bookmarks[index],
          primaryColor: _primaryColor,
          onTap: () => _handleBookmarkUpdate(index),
          onDelete: () => _handleBookmarkDelete(index),
          index: index,
        );
      },
    );
  }

  Widget _buildAddBookmarkButton() {
    return InkWell(
      onTap: _handleAddBookmark,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20.r),
        bottomRight: Radius.circular(20.r),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: _secondaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.add_rounded,
                color: _secondaryColor,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              "newBookmark".tr(),
              style: TextStyle(
                fontFamily: "cairo",
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: _secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Action Buttons ============
  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildTafseerButton(),
        SizedBox(height: 12.h),
        _buildPlayButton(),
      ],
    );
  }

  Widget _buildTafseerButton() {
    return InkWell(
      onTap: handleTafseer,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _primaryColor.withOpacity(0.08),
              _secondaryColor.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _primaryColor.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                FontAwesome5.book_open,
                color: _currentColorIndex == 0 ? _secondaryColor : _accentColor,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${"tafseer".tr()} & ${"translation".tr()}",
                    style: TextStyle(
                      fontFamily: "cairo",
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    "exploreVerseDetails".tr(),
                    style: TextStyle(
                      fontFamily: "cairo",
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: _primaryColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _primaryColor.withOpacity(0.4),
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  // ============ Enhanced Play Button ============
  Widget _buildPlayButton() {
    return InkWell(
      onTap: _handlePlay,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _primaryColor,
              _primaryColor.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: _primaryColor.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 12),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Row(
          children: [
            // Play Icon with animated background
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: _primaryColor,
                    size: 28.sp,
                  ),
                ),
              ],
            ),

            SizedBox(width: 16.w),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "playVerse".tr(),
                        style: TextStyle(
                          fontFamily: "cairo",
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.headphones_rounded,
                              color: Colors.white,
                              size: 12.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "HD",
                              style: TextStyle(
                                fontFamily: "cairo",
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          context.locale.languageCode == "ar"
                              ? widget.reciters[_currentReciterIndex].name
                              : widget.reciters[_currentReciterIndex].englishName,
                          style: TextStyle(
                            fontFamily: "cairo",
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 8.w),

            // Enhanced Dropdown
            _buildEnhancedReciterDropdown(),
          ],
        ),
      ),
    );
  }

  // Enhanced Reciter Dropdown
  Widget _buildEnhancedReciterDropdown() {
    return GestureDetector(
      onTap: _showReciterPicker,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              color: Colors.white,
              size: 18.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              "change".tr(),
              style: TextStyle(
                fontFamily: "cairo",
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Reciter Picker Bottom Sheet
  void _showReciterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r),
            topRight: Radius.circular(28.r),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: _primaryColor,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "selectReciter".tr(),
                        style: TextStyle(
                          fontFamily: "cairo",
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: _primaryColor,
                        ),
                      ),
                      Text(
                        "${widget.reciters.length} ${"reciters".tr()}",
                        style: TextStyle(
                          fontFamily: "cairo",
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: _primaryColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: _primaryColor.withOpacity(0.1), height: 1),

            // Reciters List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: widget.reciters.length,
                itemBuilder: (context, index) {
                  final reciter = widget.reciters[index];
                  final isSelected = index == _currentReciterIndex;

                  return _ReciterCard(
                    reciter: reciter,
                    isSelected: isSelected,
                    primaryColor: _primaryColor,
                    secondaryColor: _secondaryColor,
                    onTap: () {
                      _handleReciterChange(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ Event Handlers ============
  void _handleStarToggle() {
    if (_isVerseStarred) {
      widget.onRemoveStarredVerse(widget.surahNumber, widget.verseNumber);
    } else {
      widget.onAddStarredVerse(widget.surahNumber, widget.verseNumber);
    }
    setState(() {});
    widget.onUpdate();
    widget.verseKey?.currentState?.setState(() {});
  }

  void _handleShare() {
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
  }

  Future<void> _handleBookmarkUpdate(int index) async {
    try {
      final bookmarks = json.decode(getValue("bookmarks")) as List;
      bookmarks[index]["verseNumber"] = widget.verseNumber;
      bookmarks[index]["suraNumber"] = widget.surahNumber;
      updateValue("bookmarks", json.encode(bookmarks));

      widget.onUpdate();
      widget.onFetchBookmarks();

      if (mounted) {
        Navigator.of(context).pop();
        Fluttertoast.showToast(
          msg: "✓ ${"bookmarkUpdated".tr()}",
          backgroundColor: Colors.green.shade600,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      _showError("errorUpdatingBookmark".tr());
    }
  }

  Future<void> _handleBookmarkDelete(int index) async {
    try {
      final bookmarks = json.decode(getValue("bookmarks")) as List;
      final bookmarkName = widget.bookmarks[index]["name"];

      bookmarks.removeWhere(
        (e) => e["color"] == widget.bookmarks[index]["color"],
      );
      updateValue("bookmarks", json.encode(bookmarks));

      Fluttertoast.showToast(
        msg: "✓ $bookmarkName ${"removed".tr()}",
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );

      widget.onUpdate();
      widget.onFetchBookmarks();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError("errorDeletingBookmark".tr());
    }
  }

  Future<void> _handleAddBookmark() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => BookmarksDialog(
        suraNumber: widget.surahNumber,
        verseNumber: widget.verseNumber,
      ),
    );
    widget.onFetchBookmarks();
  }

  void handleTafseer() {
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
          topRight: Radius.circular(28.r),
          topLeft: Radius.circular(28.r),
        ),
      ),
      isDismissible: true,
      builder: (context) => TafseerAndTranslateSheet(
        surahNumber: widget.surahNumber,
        isVerseByVerseSelection: false,
        verseNumber: widget.verseNumber,
      ),
    );
  }

  Future<void> _handlePlay() async {
    try {
      Navigator.pop(context);

      final quranPagePlayerBloc = BlocProvider.of<QuranPagePlayerBloc>(context, listen: false);

      if (quranPagePlayerBloc.state is QuranPagePlayerPlaying) {
        quranPagePlayerBloc.add(KillPlayerEvent());
      }

      quranPagePlayerBloc.add(
        PlayFromVerse(
          widget.verseNumber,
          widget.reciters[_currentReciterIndex].identifier,
          widget.surahNumber,
          quran.getSurahNameEnglish(widget.surahNumber),
        ),
      );

      await _handleScrollIfNeeded();
    } catch (e) {
      _showError("errorPlayingVerse".tr());
    }
  }

  Future<void> _handleScrollIfNeeded() async {
    if (getValue("alignmentType") == "verticalview" &&
        quran.getPageNumber(widget.surahNumber, widget.verseNumber) > 600) {
      await Future.delayed(const Duration(milliseconds: 1000));
      widget.itemScrollController?.jumpTo(
        index: quran.getPageNumber(widget.surahNumber, widget.verseNumber),
      );
    }
  }

  void _handleReciterChange(int? newIndex) {
    if (newIndex != null) {
      setState(() {
        _currentReciterIndex = newIndex;
      });
      updateValue("reciterIndex", newIndex);
      widget.onUpdate();
    }
  }

  void _showError(String message) {
    if (mounted) {
      Fluttertoast.showToast(
        msg: "✗ $message",
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
      );
    }
  }
}

// ============ Modern Bookmark Item Widget ============
class _ModernBookmarkItem extends StatefulWidget {
  final Map<String, dynamic> bookmark;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int index;

  const _ModernBookmarkItem({
    required this.bookmark,
    required this.primaryColor,
    required this.onTap,
    required this.onDelete,
    required this.index,
  });

  @override
  State<_ModernBookmarkItem> createState() => _ModernBookmarkItemState();
}

class _ModernBookmarkItemState extends State<_ModernBookmarkItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkColor = Color(int.parse("0x${widget.bookmark["color"]}"));

    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: () {
          _controller.forward().then((_) => _controller.reverse());
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: bookmarkColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: bookmarkColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: bookmarkColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  color: bookmarkColor,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bookmark["name"],
                      style: TextStyle(
                        fontFamily: "cairo",
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: widget.primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "${"surah".tr()} ${widget.bookmark["suraNumber"]} - ${"verse".tr()} ${widget.bookmark["verseNumber"]}",
                      style: TextStyle(
                        fontFamily: "cairo",
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: widget.primaryColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 3,
                child: Text(
                  quran.getVerse(
                    int.parse(widget.bookmark["suraNumber"].toString()),
                    int.parse(widget.bookmark["verseNumber"].toString()),
                  ),
                  textDirection: m.TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: fontFamilies[0],
                    fontSize: 11.sp,
                    color: widget.primaryColor.withOpacity(0.8),
                    height: 1.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade600,
                    size: 18.sp,
                  ),
                ),
                tooltip: "delete".tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ Reciter Card Widget ============
class _ReciterCard extends StatelessWidget {
  final QuranPageReciter reciter;
  final bool isSelected;
  final Color primaryColor;
  final Color secondaryColor;
  final VoidCallback onTap;

  const _ReciterCard({
    required this.reciter,
    required this.isSelected,
    required this.primaryColor,
    required this.secondaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isSelected ? secondaryColor.withOpacity(0.15) : primaryColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? secondaryColor.withOpacity(0.5) : primaryColor.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color:
                    isSelected ? secondaryColor.withOpacity(0.2) : primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.person_rounded,
                color: isSelected ? secondaryColor : primaryColor,
                size: 24.sp,
              ),
            ),

            SizedBox(width: 14.w),

            // Names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reciter.name,
                    style: TextStyle(
                      fontFamily: "cairo",
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    reciter.englishName,
                    style: TextStyle(
                      fontFamily: "cairo",
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: primaryColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Check icon
            if (isSelected)
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
