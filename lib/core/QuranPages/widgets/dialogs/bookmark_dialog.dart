// ignore_for_file: library_private_types_in_public_api

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:quran/quran.dart' as quran;
import 'package:ghaith/blocs/bookmark_cubit.dart';
import 'package:ghaith/core/QuranPages/models/bookmark_model.dart';

class BookmarksDialog extends StatefulWidget {
  final int verseNumber;
  final int suraNumber;

  const BookmarksDialog({
    super.key,
    required this.suraNumber,
    required this.verseNumber,
  });

  @override
  _BookmarksDialogState createState() => _BookmarksDialogState();
}

class _BookmarksDialogState extends State<BookmarksDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _nameController = TextEditingController();
  int _selectedColorIndex = 0;

  // مجموعة ألوان احترافية للـ bookmarks
  final List<Color> _bookmarkColors = [
    const Color(0xFFE74C3C), // Red
    const Color(0xFF3498DB), // Blue
    const Color(0xFF2ECC71), // Green
    const Color(0xFFF39C12), // Orange
    const Color(0xFF9B59B6), // Purple
    const Color(0xFF1ABC9C), // Turquoise
    const Color(0xFFE91E63), // Pink
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF4CAF50), // Light Green
    const Color(0xFFFF9800), // Amber
    const Color(0xFF673AB7), // Deep Purple
  ];

  late int _currentColorIndex;

  @override
  void initState() {
    super.initState();
    _currentColorIndex = getValue("quranPageolorsIndex");

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Color get _primaryColor => darkWarmBrowns[_currentColorIndex];
  Color get _backgroundColor => softOffWhites[_currentColorIndex];
  Color get _secondaryColor => secondaryColors[_currentColorIndex];
  Color get _accentColor => highlightColors[_currentColorIndex];

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500.w),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildContent(),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============ Header ============
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.08),
            _secondaryColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _secondaryColor.withOpacity(0.2),
                  _accentColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _secondaryColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _secondaryColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.bookmark_add_rounded,
              color: _secondaryColor,
              size: 28.sp,
            ),
          ),

          SizedBox(width: 16.w),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "newBookmark".tr(),
                  style: TextStyle(
                    fontFamily: "cairo",
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: _secondaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        context.locale.languageCode == "ar"
                            ? quran.getSurahNameArabic(widget.suraNumber)
                            : quran.getSurahNameEnglish(widget.suraNumber),
                        style: TextStyle(
                          fontFamily: "cairo",
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: _secondaryColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "${"verse".tr()} ${widget.verseNumber}",
                      style: TextStyle(
                        fontFamily: "cairo",
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close Button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.close_rounded,
                color: _primaryColor,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ Content ============
  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.r, 20.r, 24.r, 16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_rounded,
                color: _secondaryColor,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "selectColor".tr(),
                style: TextStyle(
                  fontFamily: "cairo",
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: _bookmarkColors[_selectedColorIndex].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: _bookmarkColors[_selectedColorIndex].withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12.r,
                      height: 12.r,
                      decoration: BoxDecoration(
                        color: _bookmarkColors[_selectedColorIndex],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "selected".tr(),
                      style: TextStyle(
                        fontFamily: "cairo",
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: _bookmarkColors[_selectedColorIndex],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Color Picker
          _buildColorPicker(),
          // Preview
        ],
      ),
    );
  }

  // ============ Color Picker ============
  Widget _buildColorPicker() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: _bookmarkColors.length,
        itemBuilder: (context, index) => _buildColorOption(index),
      ),
    );
  }

  Widget _buildColorOption(int index) {
    final isSelected = _selectedColorIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColorIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _bookmarkColors[index],
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? _primaryColor : _bookmarkColors[index].withOpacity(0.3),
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _bookmarkColors[index].withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20.sp,
              )
            : null,
      ),
    );
  }

  // ============ Actions ============
  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
      ),
      child: InkWell(
        onTap: _handleSaveBookmark,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _secondaryColor,
                _secondaryColor.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: _secondaryColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "saveBookmark".tr(),
                style: TextStyle(
                  fontFamily: "cairo",
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ Save Bookmark Handler ============
  Future<void> _handleSaveBookmark() async {
    try {
      String bookmarkName = _nameController.text.trim();
      if (bookmarkName.isEmpty) {
        bookmarkName = "bookmark".tr();
      }

      final String hexCode =
          _bookmarkColors[_selectedColorIndex].value.toRadixString(16).padLeft(8, '0');

      final bookmark = BookmarkModel(
        name: bookmarkName,
        suraNumber: widget.suraNumber,
        verseNumber: widget.verseNumber,
        color: hexCode,
      );

      await context.read<BookmarkCubit>().addBookmark(bookmark);

      Fluttertoast.showToast(
        msg: "✓ ${"bookmarkSaved".tr()}",
        backgroundColor: Colors.green.shade600,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "✗ ${"errorSavingBookmark".tr()}",
        backgroundColor: Colors.red.shade600,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }
}
