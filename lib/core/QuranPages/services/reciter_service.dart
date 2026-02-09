import 'package:quran/quran.dart' as quran;
import '../models/reciter_model.dart';

/// Service for managing Quran reciters
class ReciterService {
  final List<QuranPageReciter> _reciters = [];

  /// Get all reciters
  List<QuranPageReciter> get reciters => _reciters;

  /// Load reciters from quran package
  void loadReciters() {
    _reciters.clear();

    quran.getReciters().forEach((element) {
      _reciters.add(QuranPageReciter(
        identifier: element['identifier'],
        language: element['language'],
        name: element['name'],
        englishName: element['englishName'],
        format: element['format'],
        type: element['type'],
        direction: element['direction'],
      ));
    });
  }

  /// Get reciter by identifier
  QuranPageReciter? getReciterByIdentifier(String identifier) {
    try {
      return _reciters.firstWhere((r) => r.identifier == identifier);
    } catch (e) {
      return null;
    }
  }

  /// Get reciter by index
  QuranPageReciter? getReciterByIndex(int index) {
    if (index >= 0 && index < _reciters.length) {
      return _reciters[index];
    }
    return null;
  }

  /// Get reciters by language
  List<QuranPageReciter> getRecitersByLanguage(String language) {
    return _reciters.where((r) => r.language == language).toList();
  }
}
