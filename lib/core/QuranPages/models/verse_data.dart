class VerseData {
  final int surahNumber;
  final int verseNumber;
  final int pageNumber;
  final String verseText;

  VerseData({
    required this.surahNumber,
    required this.verseNumber,
    required this.pageNumber,
    required this.verseText,
  });

  String get verseKey => '$surahNumber-$verseNumber';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VerseData &&
        other.surahNumber == surahNumber &&
        other.verseNumber == verseNumber;
  }

  @override
  int get hashCode => surahNumber.hashCode ^ verseNumber.hashCode;

  @override
  String toString() {
    return 'VerseData(surah: $surahNumber, verse: $verseNumber, page: $pageNumber)';
  }
}
