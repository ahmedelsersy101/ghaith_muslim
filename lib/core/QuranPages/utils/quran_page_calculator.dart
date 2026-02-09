/// Helper class to return quarter calculation results
class QuarterResult {
  final bool includesQuarter;
  final int quarterDataIndex;
  final int hizbIndex;
  final int quarterIndex;

  QuarterResult({
    required this.includesQuarter,
    required this.quarterDataIndex,
    required this.hizbIndex,
    required this.quarterIndex,
  });

  factory QuarterResult.notFound() {
    return QuarterResult(
      includesQuarter: false,
      quarterDataIndex: -1,
      hizbIndex: -1,
      quarterIndex: -1,
    );
  }
}

/// Calculate if a page includes a quarter (hizb quarter) and return its indices
QuarterResult checkIfPageIncludesQuarterAndQuarterIndex(
  List<dynamic> quarterJsonData,
  List<dynamic> pageData,
  List<List<int>> indexes,
) {
  for (int i = 0; i < quarterJsonData.length; i++) {
    int surah = quarterJsonData[i]['surah'];
    int ayah = quarterJsonData[i]['ayah'];

    for (int j = 0; j < pageData.length; j++) {
      int pageSurah = pageData[j]['surah'];
      int start = pageData[j]['start'];
      int end = pageData[j]['end'];

      if ((surah == pageSurah) && (ayah >= start) && (ayah <= end)) {
        int targetIndex = i + 1;

        for (int hizbIndex = 0; hizbIndex < indexes.length; hizbIndex++) {
          List<int> hizb = indexes[hizbIndex];

          for (int quarterIndex = 0; quarterIndex < hizb.length; quarterIndex++) {
            if (hizb[quarterIndex] == targetIndex) {
              return QuarterResult(
                includesQuarter: true,
                quarterDataIndex: i,
                hizbIndex: hizbIndex,
                quarterIndex: quarterIndex,
              );
            }
          }
        }
      }
    }
  }

  return QuarterResult.notFound();
}
