// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:ghaith/core/hadith/data/books.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';

part 'hadith_event.dart';
part 'hadith_state.dart';

class HadithBloc extends Bloc<HadithEvent, HadithState> {
  HadithBloc() : super(HadithInitial()) {
    on<HadithEvent>((event, emit) async {
      if (event is DownloadHadithBook) {
        var appDir = await path_provider.getTemporaryDirectory();

        // 🧠 طلب صلاحيات التخزين حسب نظام التشغيل
        if (Platform.isAndroid) {
          if (await Permission.manageExternalStorage.isGranted ||
              await Permission.storage.isGranted ||
              await Permission.mediaLibrary.isGranted ||
              await Permission.videos.isGranted ||
              await Permission.photos.isGranted) {
            print('✅ Storage permission already granted');
          } else {
            final statuses = await [
              Permission.manageExternalStorage,
              Permission.storage,
              Permission.mediaLibrary,
            ].request();

            if (statuses.values.any((status) => status.isGranted)) {
              print('✅ Permission granted');
            } else {
              print('❌ Permission denied');
              await openAppSettings();
              return;
            }
          }
        }


        await dio.Dio().download(
          "$baseHadithUrl/${event.filename}",
          "${appDir.path}/${event.filename}",
          options: dio.Options(
              headers: {HttpHeaders.acceptEncodingHeader: "*"}), // disable gzip
          onReceiveProgress: (received, total) {
            if (total != -1) {
              print("${(received / total * 100).toStringAsFixed(0)}%");
              emit(HadithDownloading(
                  "${(received / total * 100).toStringAsFixed(0)}%",
                  event.filename));
            } else {
              emit(HadithInitial());
            }
          },
        );
      } else if (event is GetHadithBook) {
        var book;
        var appDir = await path_provider.getTemporaryDirectory();

        if (File("${appDir.path}/${event.filename}").existsSync()) {
          File file = File("${appDir.path}/${event.filename}");

          String jsonData = await file.readAsString();
          book = json.decode(jsonData);
        }
        emit(HadithFetched(book));
      }
    });
  }
}
