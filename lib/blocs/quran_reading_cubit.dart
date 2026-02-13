import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import 'package:ghaith/core/QuranPages/data/quran_reading_repository.dart';

class QuranReadingState {
  final bool isLoading;
  final ReadingPosition position;
  final bool isChromeVisible;

  const QuranReadingState({
    required this.isLoading,
    required this.position,
    required this.isChromeVisible,
  });

  factory QuranReadingState.initial() {
    return const QuranReadingState(
      isLoading: true,
      position: ReadingPosition(page: 1, surahNumber: 1, ayahNumber: 1),
      isChromeVisible: true,
    );
  }

  QuranReadingState copyWith({
    bool? isLoading,
    ReadingPosition? position,
    bool? isChromeVisible,
  }) {
    return QuranReadingState(
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      isChromeVisible: isChromeVisible ?? this.isChromeVisible,
    );
  }
}

/// Cubit that owns the in-memory Quran reading state for the current session.
///
/// It coordinates between UI (page/scroll controllers) and
/// [QuranReadingRepository] to provide a smooth, continuous reading
/// experience.
class QuranReaderCubit extends Cubit<QuranReadingState> {
  final QuranReadingRepository _repository;

  QuranReaderCubit(this._repository) : super(QuranReadingState.initial());

  QuranReadingRepository get repository => _repository;

  /// Load the initial reading position when the reader is first opened.
  Future<void> loadInitialPosition() async {
    emit(state.copyWith(isLoading: true));

    final position = await _repository.loadLastPosition();

    emit(
      state.copyWith(
        isLoading: false,
        position: position,
      ),
    );
  }

  /// Explicitly persist the current state to storage.
  Future<void> persistCurrentPosition() {
    return _repository.savePosition(state.position);
  }

  /// Update state in response to a page change in the mushaf page view.
  ///
  /// This keeps the repository and the in-memory state in sync.
  Future<void> updateFromPageChange(int page) async {
    final mapped = _mapPageToPosition(page);
    emit(
      state.copyWith(
        position: mapped,
      ),
    );
    await _repository.savePosition(mapped);
  }

  /// Navigate to a specific mushaf page.
  Future<void> goToPage(int page) async {
    final mapped = _mapPageToPosition(page);
    emit(
      state.copyWith(
        position: mapped,
      ),
    );
    await _repository.savePosition(mapped);
  }

  /// Navigate to a specific surah (first ayah by default).
  Future<void> goToSurah(int surahNumber, {int ayahNumber = 1}) async {
    final int page = quran.getPageNumber(surahNumber, ayahNumber);
    final position = ReadingPosition(
      page: page,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      viewMode: state.position.viewMode,
    );

    emit(
      state.copyWith(
        position: position,
      ),
    );
    await _repository.savePosition(position);
  }

  /// Navigate to a specific ayah.
  Future<void> goToAyah(int surahNumber, int ayahNumber) async {
    final int page = quran.getPageNumber(surahNumber, ayahNumber);
    final position = ReadingPosition(
      page: page,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      viewMode: state.position.viewMode,
    );

    emit(
      state.copyWith(
        position: position,
      ),
    );
    await _repository.savePosition(position);
  }

  /// Toggle the visibility of the app chrome (AppBar / controls).
  void toggleChrome() {
    emit(
      state.copyWith(
        isChromeVisible: !state.isChromeVisible,
      ),
    );
  }

  /// Update only the view mode (e.g., page, vertical, verse-by-verse).
  void updateViewMode(String viewMode) {
    emit(
      state.copyWith(
        position: state.position.copyWith(viewMode: viewMode),
      ),
    );
  }

  ReadingPosition _mapPageToPosition(int page) {
    try {
      final pageData = quran.getPageData(page);
      if (pageData.isNotEmpty) {
        final firstSegment = pageData.first;
        final int surah = firstSegment['surah'] as int;
        final int ayah = firstSegment['start'] as int;

        return state.position.copyWith(
          page: page,
          surahNumber: surah,
          ayahNumber: ayah,
        );
      }
    } catch (_) {
      // Fall back to the existing state if mapping fails.
    }

    return state.position.copyWith(page: page);
  }
}

