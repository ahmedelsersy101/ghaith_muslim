class QuranPageConfig {
  final String alignmentType;
  final double fontSize;
  final String selectedFontFamily;
  final int themeIndex;
  final bool addAppSlogan;
  final bool showSuraHeader;
  final double currentHeight;
  final double currentLetterSpacing;

  QuranPageConfig({
    required this.alignmentType,
    required this.fontSize,
    required this.selectedFontFamily,
    required this.themeIndex,
    this.addAppSlogan = true,
    this.showSuraHeader = true,
    this.currentHeight = 2.0,
    this.currentLetterSpacing = 0.0,
  });

  QuranPageConfig copyWith({
    String? alignmentType,
    double? fontSize,
    String? selectedFontFamily,
    int? themeIndex,
    bool? addAppSlogan,
    bool? showSuraHeader,
    double? currentHeight,
    double? currentLetterSpacing,
  }) {
    return QuranPageConfig(
      alignmentType: alignmentType ?? this.alignmentType,
      fontSize: fontSize ?? this.fontSize,
      selectedFontFamily: selectedFontFamily ?? this.selectedFontFamily,
      themeIndex: themeIndex ?? this.themeIndex,
      addAppSlogan: addAppSlogan ?? this.addAppSlogan,
      showSuraHeader: showSuraHeader ?? this.showSuraHeader,
      currentHeight: currentHeight ?? this.currentHeight,
      currentLetterSpacing: currentLetterSpacing ?? this.currentLetterSpacing,
    );
  }
}
