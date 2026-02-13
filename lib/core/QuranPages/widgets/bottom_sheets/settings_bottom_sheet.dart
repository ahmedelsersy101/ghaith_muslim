import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:ghaith/core/QuranPages/widgets/bottom_sheets/translation_selection_sheet.dart';
import '../../helpers/translation/translationdata.dart';

/// Settings bottom sheet for Quran page customization
/// Allows users to change themes, fonts, alignment, and translations
class SettingsBottomSheet {
  /// Show the settings modal bottom sheet
  ///
  /// [context] - Build context
  /// [onSettingsChanged] - Callback when settings are changed (triggers setState)
  static void show(
    BuildContext context, {
    required VoidCallback onSettingsChanged,
  }) {
    int tabIndex = 0;

    showMaterialModalBottomSheet(
      enableDrag: true,
      duration: const Duration(milliseconds: 600),
      backgroundColor: Colors.transparent,
      context: context,
      animationCurve: Curves.easeInOutQuart,
      elevation: 0,
      barrierColor: Colors.black.withOpacity(.1),
      bounce: true,
      builder: (a) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setStatee) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tab selector buttons
              Container(
                color: Colors.transparent,
                child: Row(
                  children: [
                    _buildTabButton(
                      isSelected: tabIndex == 0,
                      icon: Icons.color_lens,
                      onTap: () => setStatee(() => tabIndex = 0),
                    ),
                    _buildTabButton(
                      isSelected: tabIndex == 1,
                      icon: Icons.font_download,
                      onTap: () => setStatee(() => tabIndex = 1),
                    ),
                    _buildTabButton(
                      isSelected: tabIndex == 2,
                      icon: Icons.view_agenda,
                      onTap: () => setStatee(() => tabIndex = 2),
                    ),
                    if (getValue("alignmentType") == "versebyverse")
                      _buildTabButton(
                        isSelected: tabIndex == 3,
                        icon: Icons.translate,
                        onTap: () => setStatee(() => tabIndex = 3),
                      ),
                  ],
                ),
              ),

              // Tab content
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                  color: softOffWhites[getValue("quranPageolorsIndex")],
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * .44,
                  child: _buildTabContent(
                    tabIndex,
                    context,
                    setStatee,
                    onSettingsChanged,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build tab selection button
  static Widget _buildTabButton({
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: CircleAvatar(
          backgroundColor:
              isSelected ? secondaryColors[getValue("quranPageolorsIndex")] : Colors.grey,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }

  /// Build tab content based on selected tab
  static Widget _buildTabContent(
    int tabIndex,
    BuildContext context,
    StateSetter setStatee,
    VoidCallback onSettingsChanged,
  ) {
    switch (tabIndex) {
      case 0:
        return _buildThemeTab(context, setStatee, onSettingsChanged);
      case 1:
        return _buildFontTab(context, setStatee, onSettingsChanged);
      case 2:
        return _buildAlignmentTab(context, setStatee, onSettingsChanged);
      case 3:
        return _buildTranslationTab(
          context,
          setStatee,
          onSettingsChanged,
        );
      default:
        return const SizedBox();
    }
  }

  /// Theme selection tab
  static Widget _buildThemeTab(
    BuildContext context,
    StateSetter setStatee,
    VoidCallback onSettingsChanged,
  ) {
    return ListView.builder(
      itemCount: softOffWhites.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: InkWell(
            onTap: () {
              updateValue("quranPageolorsIndex", index);
              setStatee(() {});
              onSettingsChanged();
            },
            child: Container(
              height: 80.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: softOffWhites[index],
                border: Border.all(
                  color: getValue("quranPageolorsIndex") == index
                      ? secondaryColors[index]
                      : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: darkWarmBrowns[index],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: secondaryColors[index],
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Font selection tab
  static Widget _buildFontTab(
    BuildContext context,
    StateSetter setStatee,
    VoidCallback onSettingsChanged,
  ) {
    return Column(
      children: [
        // Font size slider

        (getValue("alignmentType") == "versebyverse") ||
                (getValue("alignmentType") == "verticalview")
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "fontSize".tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            if (getValue("alignmentType") == "versebyverse") {
                              updateValue("verseByVerseFontSize", 24.0);
                            } else if (getValue("alignmentType") == "verticalview") {
                              updateValue("verticalViewFontSize", 22.0);
                            } else {
                              updateValue("pageViewFontSize", 23.0);
                            }
                            setStatee(() {});
                            onSettingsChanged();
                          },
                          icon: Icon(
                            Icons.restore,
                            size: 18.sp,
                            color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                          ),
                          label: Text(
                            "reset".tr(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: getValue("alignmentType") == "versebyverse"
                          ? getValue("verseByVerseFontSize").toDouble()
                          : getValue("alignmentType") == "verticalview"
                              ? getValue("verticalViewFontSize").toDouble()
                              : getValue("pageViewFontSize").toDouble(),
                      min: 14.0,
                      max: 40.0,
                      divisions: 26,
                      label: (getValue("alignmentType") == "versebyverse"
                              ? getValue("verseByVerseFontSize").toDouble()
                              : getValue("alignmentType") == "verticalview"
                                  ? getValue("verticalViewFontSize").toDouble()
                                  : getValue("pageViewFontSize").toDouble())
                          .toString(),
                      activeColor: secondaryColors[getValue("quranPageolorsIndex")],
                      onChanged: (value) {
                        if (getValue("alignmentType") == "versebyverse") {
                          updateValue("verseByVerseFontSize", value);
                        } else if (getValue("alignmentType") == "verticalview") {
                          updateValue("verticalViewFontSize", value);
                        } else {
                          updateValue("pageViewFontSize", value);
                        }
                        setStatee(() {});
                        onSettingsChanged();
                      },
                    ),
                  ],
                ),
              )
            : const SizedBox(),

        (getValue("alignmentType") == "versebyverse") ||
                (getValue("alignmentType") == "verticalview")
            ? const Divider()
            : const SizedBox(),
        // Font family selection
        Expanded(
          child: ListView.builder(
            itemCount: fontFamilies.length,
            itemBuilder: (context, index) {
              final fontFamily = fontFamilies[index];
              final isSelected = getValue("selectedFontFamily") == fontFamily;

              return ListTile(
                selected: isSelected,
                selectedTileColor:
                    secondaryColors[getValue("quranPageolorsIndex")].withOpacity(0.2),
                title: Text(
                  "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ",
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 18.sp,
                    color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                  ),
                  // textDirection: TextDirection.rtl,
                ),
                subtitle: Text(
                  fontFamily,
                  style: TextStyle(fontSize: 12.sp),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: secondaryColors[getValue("quranPageolorsIndex")],
                      )
                    : null,
                onTap: () {
                  updateValue("selectedFontFamily", fontFamily);
                  setStatee(() {});
                  onSettingsChanged();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Alignment/View type selection tab
  static Widget _buildAlignmentTab(
    BuildContext context,
    StateSetter setStatee,
    VoidCallback onSettingsChanged,
  ) {
    return ListView(
      children: [
        _buildAlignmentOption(
          title: "pageview".tr(),
          value: "pageview",
          currentValue: getValue("alignmentType"),
          icon: Icons.book,
          setStatee: setStatee,
          onSettingsChanged: onSettingsChanged,
        ),
        _buildAlignmentOption(
          title: "verticalview".tr(),
          value: "verticalview",
          currentValue: getValue("alignmentType"),
          icon: Icons.view_agenda,
          setStatee: setStatee,
          onSettingsChanged: onSettingsChanged,
        ),
        _buildAlignmentOption(
          title: "versebyverse".tr(),
          value: "versebyverse",
          currentValue: getValue("alignmentType"),
          icon: Icons.format_list_bulleted,
          setStatee: setStatee,
          onSettingsChanged: onSettingsChanged,
        ),
      ],
    );
  }

  /// Build single alignment option
  static Widget _buildAlignmentOption({
    required String title,
    required String value,
    required String currentValue,
    required IconData icon,
    required StateSetter setStatee,
    required VoidCallback onSettingsChanged,
  }) {
    final isSelected = currentValue == value;

    return ListTile(
      selected: isSelected,
      selectedTileColor: secondaryColors[getValue("quranPageolorsIndex")].withOpacity(0.2),
      leading: Icon(
        icon,
        color: isSelected ? secondaryColors[getValue("quranPageolorsIndex")] : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          color: darkWarmBrowns[getValue("quranPageolorsIndex")],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: secondaryColors[getValue("quranPageolorsIndex")],
            )
          : null,
      onTap: () {
        updateValue("alignmentType", value);
        setStatee(() {});
        onSettingsChanged();
      },
    );
  }

  static Widget _buildTranslationTab(
    BuildContext context,
    StateSetter setStatee,
    VoidCallback onSettingsChanged,
  ) {
    final currentTranslation =
        translationDataList[getValue("indexOfTranslationInVerseByVerse") ?? 0];

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Text(
            "selectTranslation".tr(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: darkWarmBrowns[getValue("quranPageolorsIndex")],
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: InkWell(
            onTap: () => TranslationSelectionSheet.show(
              context,
              onSettingsChanged: () {
                setStatee(() {});
                onSettingsChanged();
              },
            ),
            borderRadius: BorderRadius.circular(15.r),
            child: Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: secondaryColors[getValue("quranPageolorsIndex")].withOpacity(0.1),
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(
                  color: secondaryColors[getValue("quranPageolorsIndex")].withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: secondaryColors[getValue("quranPageolorsIndex")],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(Icons.translate, color: Colors.white),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTranslation.typeTextInRelatedLanguage,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: darkWarmBrowns[getValue("quranPageolorsIndex")],
                            fontFamily: currentTranslation.typeInNativeLanguage == "العربية"
                                ? "cairo"
                                : "roboto",
                          ),
                        ),
                        Text(
                          currentTranslation.typeInNativeLanguage,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: darkWarmBrowns[getValue("quranPageolorsIndex")].withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18.sp,
                    color: darkWarmBrowns[getValue("quranPageolorsIndex")].withOpacity(0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.all(20.r),
          child: Text(
            "clickToChangeTranslation".tr(),
            style: TextStyle(
              fontSize: 12.sp,
              fontStyle: FontStyle.italic,
              color: darkWarmBrowns[getValue("quranPageolorsIndex")].withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  // _showTranslationBottomSheet and _downloadTranslation are removed
  // in favor of TranslationSelectionSheet.show
}
