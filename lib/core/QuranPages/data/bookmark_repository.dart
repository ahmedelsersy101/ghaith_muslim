import 'dart:convert';

import 'package:ghaith/core/QuranPages/models/bookmark_model.dart';
import 'package:ghaith/helpers/hive_helper.dart';

/// Repository responsible for persisting and retrieving Quran bookmarks.
///
/// This wraps Hive access behind a simple, typed API and keeps the existing
/// `"bookmarks"` storage format for backwards compatibility.
class BookmarkRepository {
  static const String _bookmarksKey = 'bookmarks';

  const BookmarkRepository();

  /// Load all bookmarks from storage.
  Future<List<BookmarkModel>> loadBookmarks() async {
    try {
      final dynamic raw = getValue(_bookmarksKey);
      if (raw == null) return <BookmarkModel>[];

      if (raw is String) {
        if (raw.isEmpty) return <BookmarkModel>[];
        final decoded = json.decode(raw) as List<dynamic>;
        return _decodeList(decoded);
      }

      if (raw is List) {
        return _decodeList(raw);
      }
    } catch (_) {
      // Fall through to empty list on any parsing issues.
    }
    return <BookmarkModel>[];
  }

  /// Persist a new list of bookmarks to storage.
  Future<void> saveBookmarks(List<BookmarkModel> bookmarks) async {
    final encoded = json.encode(bookmarks.map((b) => b.toMap()).toList(growable: false));
    updateValue(_bookmarksKey, encoded);
  }

  /// Append a single bookmark and persist.
  Future<List<BookmarkModel>> addBookmark(BookmarkModel bookmark) async {
    final current = await loadBookmarks();
    if (!current.contains(bookmark)) {
      current.add(bookmark);
      await saveBookmarks(current);
    }
    return current;
  }

  /// Remove a bookmark (by surah/ayah) and persist.
  Future<List<BookmarkModel>> removeBookmark(BookmarkModel bookmark) async {
    final current = await loadBookmarks();
    current.remove(bookmark);
    await saveBookmarks(current);
    return current;
  }

  List<BookmarkModel> _decodeList(List<dynamic> rawList) {
    return rawList
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .map(BookmarkModel.fromMap)
        .toList();
  }
}
