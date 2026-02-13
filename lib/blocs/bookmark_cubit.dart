import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ghaith/core/QuranPages/data/bookmark_repository.dart';
import 'package:ghaith/core/QuranPages/models/bookmark_model.dart';

class BookmarkState {
  final bool isLoading;
  final List<BookmarkModel> bookmarks;
  final String? errorMessage;

  const BookmarkState({
    required this.isLoading,
    required this.bookmarks,
    this.errorMessage,
  });

  factory BookmarkState.initial() {
    return const BookmarkState(
      isLoading: true,
      bookmarks: <BookmarkModel>[],
    );
  }

  BookmarkState copyWith({
    bool? isLoading,
    List<BookmarkModel>? bookmarks,
    String? errorMessage,
  }) {
    return BookmarkState(
      isLoading: isLoading ?? this.isLoading,
      bookmarks: bookmarks ?? this.bookmarks,
      errorMessage: errorMessage,
    );
  }
}

/// Cubit that owns the single source of truth for all bookmarks in memory.
///
/// UI layers (Surah list, Quran reader, dialogs) should depend on this cubit
/// instead of reading from Hive directly.
class BookmarkCubit extends Cubit<BookmarkState> {
  final BookmarkRepository _repository;

  BookmarkCubit(this._repository) : super(BookmarkState.initial());

  BookmarkRepository get repository => _repository;

  Future<void> loadBookmarks() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final bookmarks = await _repository.loadBookmarks();
      emit(
        state.copyWith(
          isLoading: false,
          bookmarks: bookmarks,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> addBookmark(BookmarkModel bookmark) async {
    final updated = List<BookmarkModel>.from(state.bookmarks)..add(bookmark);
    emit(state.copyWith(bookmarks: updated));
    await _repository.saveBookmarks(updated);
  }

  Future<void> removeBookmark(BookmarkModel bookmark) async {
    final updated = List<BookmarkModel>.from(state.bookmarks)
      ..remove(bookmark);
    emit(state.copyWith(bookmarks: updated));
    await _repository.saveBookmarks(updated);
  }

  bool hasBookmark(int surahNumber, int verseNumber) {
    return state.bookmarks.any(
      (b) => b.suraNumber == surahNumber && b.verseNumber == verseNumber,
    );
  }

  BookmarkModel? getBookmarkForVerse(int surahNumber, int verseNumber) {
    try {
      return state.bookmarks.firstWhere(
        (b) => b.suraNumber == surahNumber && b.verseNumber == verseNumber,
      );
    } catch (_) {
      return null;
    }
  }
}

