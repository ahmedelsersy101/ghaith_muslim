import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: library_prefixes
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/helpers/app_themes.dart';
import 'package:ghaith/helpers/home_blocs.dart';
import 'package:ghaith/services/initialization_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:easy_localization/easy_localization.dart' as ez;
import 'package:ghaith/blocs/player_bar_bloc.dart';
import 'package:ghaith/blocs/player_bloc_bloc.dart';
import 'package:ghaith/blocs/quran_page_player_bloc.dart';
import 'package:ghaith/blocs/quran_reading_cubit.dart';
import 'package:ghaith/blocs/bookmark_cubit.dart';
import 'package:ghaith/core/QuranPages/data/quran_reading_repository.dart';
import 'package:ghaith/core/QuranPages/data/bookmark_repository.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/core/splash/splash_screen.dart';

final AudioPlayer audioPlayer = AudioPlayer();
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier(getValue("darkMode") ?? false);

// =============================================
// 🚀 MAIN APPLICATION ENTRY POINT
// =============================================

void main() async {
  await initializeApp();

  runApp(ez.EasyLocalization(
    supportedLocales: const [
      Locale("ar"),
      Locale('en'),
      Locale('de'),
      Locale("am"),
      Locale("ms"),
      Locale("pt"),
      Locale("tr"),
      Locale("ru"),
      Locale("it")
    ],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar'),
    startLocale: const Locale('ar'),
    child: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<QuranReadingRepository>(
          create: (_) => const QuranReadingRepository(),
        ),
        RepositoryProvider<BookmarkRepository>(
          create: (_) => const BookmarkRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => PlayerBlocBloc()),
          BlocProvider(create: (_) => QuranPagePlayerBloc()),
          BlocProvider(create: (_) => PlayerBarBloc()),
          BlocProvider(
            create: (context) => QuranReaderCubit(
              context.read<QuranReadingRepository>(),
            )..loadInitialPosition(),
          ),
          BlocProvider(
            create: (context) => BookmarkCubit(
              context.read<BookmarkRepository>(),
            )..loadBookmarks(),
          ),
        ],
        child: const GhaithMuslimApp(),
      ),
    ),
  ));
}

// =============================================
// 🏗️ MAIN APPLICATION WIDGET
// =============================================

class GhaithMuslimApp extends StatefulWidget {
  const GhaithMuslimApp({super.key});

  @override
  State<GhaithMuslimApp> createState() => _GhaithMuslimAppState();
}

class _GhaithMuslimAppState extends State<GhaithMuslimApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(392.72727272727275, 800.7272727272727),
      builder: (context, child) => BlocProvider(
        create: (context) => playerbarBloc,
        child: ValueListenableBuilder(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDark, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'غيث المسلم',
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: buildTheme(context, false),
              darkTheme: buildTheme(context, true),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
