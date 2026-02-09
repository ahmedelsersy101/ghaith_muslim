import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Service for managing starred verses
class StarredVersesService {
  static const String _storageKey = 'starredVerses';

  Set<String> _starredVerses = {};

  /// Get all starred verses
  Set<String> get starredVerses => _starredVerses;

  /// Load starred verses from storage
  Future<void> loadStarredVerses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_storageKey);

    if (savedData != null) {
      _starredVerses = Set<String>.from(json.decode(savedData));
    }
  }

  /// Add a verse to starred verses
  Future<void> addStarredVerse(int surahNumber, int verseNumber) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load current data
    final String? savedData = prefs.getString(_storageKey);
    if (savedData != null) {
      _starredVerses = Set<String>.from(json.decode(savedData));
    }

    final verseKey = '$surahNumber-$verseNumber';
    _starredVerses.add(verseKey);

    final jsonData = json.encode(_starredVerses.toList());
    await prefs.setString(_storageKey, jsonData);

    Fluttertoast.showToast(msg: 'Added to Starred verses');
  }

  /// Remove a verse from starred verses
  Future<void> removeStarredVerse(int surahNumber, int verseNumber) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load current data
    final String? savedData = prefs.getString(_storageKey);
    if (savedData != null) {
      _starredVerses = Set<String>.from(json.decode(savedData));
    }

    final verseKey = '$surahNumber-$verseNumber';
    _starredVerses.remove(verseKey);

    final jsonData = json.encode(_starredVerses.toList());
    await prefs.setString(_storageKey, jsonData);

    Fluttertoast.showToast(msg: 'Removed from Starred verses');
  }

  /// Check if a verse is starred
  bool isVerseStarred(int surahNumber, int verseNumber) {
    final verseKey = '$surahNumber-$verseNumber';
    return _starredVerses.contains(verseKey);
  }

  /// Toggle verse starred status
  Future<void> toggleStarredVerse(int surahNumber, int verseNumber) async {
    if (isVerseStarred(surahNumber, verseNumber)) {
      await removeStarredVerse(surahNumber, verseNumber);
    } else {
      await addStarredVerse(surahNumber, verseNumber);
    }
  }
}
