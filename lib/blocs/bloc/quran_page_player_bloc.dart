// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ghaith/main.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart';
import 'package:quran/reciters.dart';
import 'package:http/http.dart' as http;

part 'quran_page_player_event.dart';
part 'quran_page_player_state.dart';

class QuranPagePlayerBloc extends Bloc<QuranPagePlayerEvent, QuranPagePlayerState> {
  QuranPagePlayerBloc() : super(QuranPagePlayerInitial()) {
    on<QuranPagePlayerEvent>((event, emit) async {
      if (event is PlayFromVerse) {
        final player = audioPlayer ?? AudioPlayer();

        try {
          // 🔹 Retrieve stored durations
          final storedJsonString = getValue(
            "${event.reciterIdentifier}-${event.suraName.replaceAll(" ", "")}-durations",
          );

          if (storedJsonString == null) {
            Fluttertoast.showToast(msg: "Durations data not found");
            return;
          }

          final decodedList = json.decode(storedJsonString);
          final durations = List.from(decodedList);

          final verseData = durations.firstWhere(
            (element) => element["verseNumber"] == event.verse,
            orElse: () => null,
          );

          if (verseData == null) {
            Fluttertoast.showToast(msg: "Verse duration not found");
            return;
          }

          final double duration = verseData["startDuration"];

          // 🔹 Verify reciter
          final reciterMatch = reciters.firstWhere(
            (element) => element["identifier"] == event.reciterIdentifier,
            orElse: () => null,
          );
          if (reciterMatch == null) {
            Fluttertoast.showToast(msg: "Reciter not found");
            return;
          }

          // 🔹 Get file path (permanent)
          final appDir = await getApplicationDocumentsDirectory();
          final filePath =
              "${appDir.path}/${event.reciterIdentifier}_${event.suraName.replaceAll(" ", "")}.mp3";
          final file = File(filePath);

          // 🔹 Download if not exists
          if (!await file.exists()) {
            Fluttertoast.showToast(
              msg: "Downloading Surah ${event.suraName}...",
              toastLength: Toast.LENGTH_LONG,
            );

            final url =
                "https://cdn.islamic.network/quran/audio/64/${event.reciterIdentifier}/${event.surahNumber}.mp3";

            print('🎧 Downloading from: $url');
            final response = await http.get(Uri.parse(url));

            if (response.statusCode == 200) {
              await file.writeAsBytes(response.bodyBytes);
              print('💾 Saved to: ${file.path}');
              Fluttertoast.showToast(msg: "✅ Surah downloaded successfully");
            } else {
              print('❌ Download failed: ${response.statusCode}');
              Fluttertoast.showToast(
                msg: "Failed to download (${response.statusCode})",
              );
              return;
            }
          } else {
            print("✅ Surah already exists locally: ${file.path}");
          }

          // 🔹 Configure audio session
          final session = await AudioSession.instance;
          await session.configure(const AudioSessionConfiguration.music());

          // 🔹 Handle playback
          player.playbackEventStream.listen(
            (event) {},
            onError: (Object e, StackTrace stackTrace) {
              print('❌ Playback error: $e');
              Fluttertoast.showToast(msg: "Playback error: $e");
            },
          );

          // 🔹 Load local audio
          await player.setAudioSource(
            AudioSource.file(
              filePath,
              tag: MediaItem(
                id: event.suraName,
                album: reciterMatch["englishName"],
                title: getSurahNameArabic(event.surahNumber),
                artUri: Uri.parse(
                  "https://images.pexels.com/photos/318451/pexels-photo-318451.jpeg",
                ),
              ),
            ),
          );

          // 🔹 Seek to verse and play
          print("⏩ Seeking to: ${duration.toInt()} ms");
          await player.seek(Duration(milliseconds: duration.toInt()));
          await player.play();
          print("▶️ Now playing from local file");

          Fluttertoast.showToast(
            msg: "▶️ Playing ${event.suraName}",
            toastLength: Toast.LENGTH_SHORT,
          );

          emit(QuranPagePlayerPlaying(
            player: player,
            audioPlayerStream: player.positionStream,
            suraNumber: event.surahNumber,
            reciter: reciterMatch,
            durations: durations,
          ));
        } catch (e) {
          print("🔥 Error in PlayFromVerse: $e");
          Fluttertoast.showToast(msg: "Error: $e");
        }
      }

      // 🔹 Stop
      else if (event is StopPlaying) {
        if (audioPlayer != null) {
          await audioPlayer.stop();
          Fluttertoast.showToast(msg: "⏹ Playback stopped");
        }
        emit(QuranPagePlayerInitial());
      }

      // 🔹 Kill player
      else if (event is KillPlayerEvent) {
        if (audioPlayer != null) {
          await audioPlayer.stop();
          Fluttertoast.showToast(msg: "🛑 Player killed");
        }
        emit(QuranPagePlayerInitial());
      }
    });
  }
}
