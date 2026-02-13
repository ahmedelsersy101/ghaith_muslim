import 'dart:convert';

import 'package:quran/quran.dart' as quran;

import 'package:ghaith/helpers/hive_helper.dart';

class ReadingPosition {
  final int page;
  final int surahNumber;
  final int ayahNumber;
  final String? viewMode;

  const ReadingPosition({
    required this.page,
    required this.surahNumber,
    required this.ayahNumber,
    this.viewMode,
  });

  ReadingPosition copyWith({
    int? page,
    int? surahNumber,
    int? ayahNumber,
    String? viewMode,
  }) {
    return ReadingPosition(
      page: page ?? this.page,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'page': page,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
      'viewMode': viewMode,
    };
  }

  factory ReadingPosition.fromMap(Map<String, dynamic> map) {
    return ReadingPosition(
      page: map['page'] as int,
      surahNumber: map['surahNumber'] as int,
      ayahNumber: map['ayahNumber'] as int,
      viewMode: map['viewMode'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory ReadingPosition.fromJson(String source) =>
      ReadingPosition.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Repository responsible for persisting and restoring the current Quran
/// reading position.
///
/// This wraps the legacy `lastRead` Hive key (which stores only the page
/// number) and introduces a richer `lastReadingPosition` payload that also
/// includes surah and ayah information.
class QuranReadingRepository {
  static const String _legacyLastReadKey = 'lastRead';
  static const String _lastReadingPositionKey = 'lastReadingPosition';

  const QuranReadingRepository();

  /// Load the last reading position.
  ///
  /// Priority:
  /// 1. Structured `lastReadingPosition` (page + surah + ayah)
  /// 2. Legacy `lastRead` page number mapped to (page, first surah/ayah)
  /// 3. Default to Al-Fatiha: page 1, surah 1, ayah 1
  Future<ReadingPosition> loadLastPosition() async {
    final dynamic stored = getValue(_lastReadingPositionKey);
    if (stored is String && stored.isNotEmpty) {
      try {
        return ReadingPosition.fromJson(stored);
      } catch (_) {
        // Fall through to legacy handling.
      }
    } else if (stored is Map<String, dynamic>) {
      try {
        return ReadingPosition.fromMap(stored);
      } catch (_) {
        // Fall through to legacy handling.
      }
    }

    final dynamic legacy = getValue(_legacyLastReadKey);
    if (legacy is int && legacy > 0) {
      final mapped = _mapPageToReadingPosition(legacy);
      await savePosition(mapped);
      return mapped;
    }

    // First-time open → Al-Fatiha (page 1, surah 1, ayah 1)
    final fallback = _mapPageToReadingPosition(1);
    await savePosition(fallback);
    return fallback;
  }

  /// Persist the current reading position.
  Future<void> savePosition(ReadingPosition position) async {
    // Keep legacy `lastRead` updated for backward compatibility
    updateValue(_legacyLastReadKey, position.page);

    // Store the richer representation
    updateValue(_lastReadingPositionKey, position.toJson());
  }

  /// Helper to map a mushaf page number to a concrete surah and ayah
  /// using the `quran` package metadata.
  ReadingPosition _mapPageToReadingPosition(int page) {
    try {
      final pageData = quran.getPageData(page);
      if (pageData.isNotEmpty) {
        final firstSegment = pageData.first;
        final int surah = firstSegment['surah'] as int;
        final int ayah = firstSegment['start'] as int;

        return ReadingPosition(
          page: page,
          surahNumber: surah,
          ayahNumber: ayah,
        );
      }
    } catch (_) {
      // If anything goes wrong, fall back to Al-Fatiha.
    }

    return const ReadingPosition(
      page: 1,
      surahNumber: 1,
      ayahNumber: 1,
    );
  }
}

