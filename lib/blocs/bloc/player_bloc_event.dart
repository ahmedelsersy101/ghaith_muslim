part of 'player_bloc_bloc.dart';

@immutable
class PlayerBlocEvent {}

class StartPlaying extends PlayerBlocEvent {
  Moshaf moshaf;
  Reciter reciter;
  int suraNumber;
  BuildContext buildContext;
  // String suraName;
  List jsonData;
  var audioPlayer;
  int initialIndex;

  StartPlaying({
    required this.moshaf,
    required this.reciter,
    required this.suraNumber,
    required this.initialIndex,
    required this.buildContext,
    // required this.suraName,
    required this.jsonData,
  });
}
class PlayFullSurah extends PlayerBlocEvent {
  final String reciterId;
  final int surahNumber;
  final String surahName;
  final Moshaf moshaf;
  final Reciter reciter;
  final List jsonData;

   PlayFullSurah({
    required this.reciterId,
    required this.surahNumber,
    required this.surahName,
    required this.moshaf,
    required this.reciter,
    required this.jsonData,
  });
}
class DownloadSurah extends PlayerBlocEvent {
  final Reciter reciter;
  final Moshaf moshaf;
  final String suraNumber;
  final String url;
  final String? savePath; // 👈 أضف هذا السطر

  DownloadSurah({
    required this.reciter,
    required this.moshaf,
    required this.suraNumber,
    required this.url,
    this.savePath, // 👈 أضف هذا السطر كمان
  });
}


class DownloadAllSurahs extends PlayerBlocEvent {
  Moshaf moshaf;
  Reciter reciter;
  DownloadAllSurahs({
    required this.moshaf,
    required this.reciter,
  });
}

class ClosePlayerEvent extends PlayerBlocEvent {}

class PausePlayer extends PlayerBlocEvent {}
