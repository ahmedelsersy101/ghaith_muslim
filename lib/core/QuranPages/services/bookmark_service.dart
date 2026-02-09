import 'dart:convert';
import 'package:ghaith/helpers/hive_helper.dart';
import '../models/bookmark_model.dart';

/// Service for managing bookmarks
class BookmarkService {
  List<BookmarkModel> _bookmarks = [];

  /// Get all bookmarks
  List<BookmarkModel> get bookmarks => _bookmarks;

  /// Load bookmarks from storage
  void loadBookmarks() {
    try {
      final List<dynamic> bookmarksJson = json.decode(getValue('bookmarks'));
      _bookmarks =
          bookmarksJson.map((item) => BookmarkModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      _bookmarks = [];
    }
  }

  /// Save bookmarks to storage
  void saveBookmarks() {
    final bookmarksJson = json.encode(_bookmarks.map((b) => b.toMap()).toList());
    updateValue('bookmarks', bookmarksJson);
  }

  /// Add a new bookmark
  void addBookmark(BookmarkModel bookmark) {
    _bookmarks.add(bookmark);
    saveBookmarks();
  }

  /// Remove a bookmark by index
  void removeBookmarkAt(int index) {
    if (index >= 0 && index < _bookmarks.length) {
      _bookmarks.removeAt(index);
      saveBookmarks();
    }
  }

  /// Remove a bookmark by color
  void removeBookmarkByColor(String color) {
    _bookmarks.removeWhere((b) => b.color == color);
    saveBookmarks();
  }

  /// Update bookmark verse position
  void updateBookmarkVerse(int index, int surahNumber, int verseNumber) {
    if (index >= 0 && index < _bookmarks.length) {
      final bookmark = _bookmarks[index];
      _bookmarks[index] = BookmarkModel(
        name: bookmark.name,
        suraNumber: surahNumber,
        verseNumber: verseNumber,
        color: bookmark.color,
      );
      saveBookmarks();
    }
  }

  /// Check if a verse has a bookmark
  bool hasBookmark(int surahNumber, int verseNumber) {
    return _bookmarks.any(
      (b) => b.suraNumber == surahNumber && b.verseNumber == verseNumber,
    );
  }

  /// Get bookmark for a specific verse
  BookmarkModel? getBookmarkForVerse(int surahNumber, int verseNumber) {
    try {
      return _bookmarks.firstWhere(
        (b) => b.suraNumber == surahNumber && b.verseNumber == verseNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get bookmarks for a specific surah
  List<BookmarkModel> getBookmarksForSurah(int surahNumber) {
    return _bookmarks.where((b) => b.suraNumber == surahNumber).toList();
  }
}
