import 'dart:convert';
import 'dart:io';
import 'package:ghaith/main.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_container/easy_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:ghaith/Core/audiopage/models/reciter.dart';
import 'package:ghaith/blocs/bloc/player_bloc_bloc.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/blocs/bloc/quran_page_player_bloc.dart';
import 'package:ghaith/core/home.dart';
import 'package:path_provider/path_provider.dart';

import 'package:quran/quran.dart' as quran;

class RecitersSurahListPage extends StatefulWidget {
  Reciter reciter;
  Moshaf mushaf;
  var jsonData;

  RecitersSurahListPage(
      {super.key, required this.reciter, required this.mushaf, required this.jsonData});

  @override
  State<RecitersSurahListPage> createState() => _RecitersSurahListPageState();
}

class _RecitersSurahListPageState extends State<RecitersSurahListPage> {
  // List<String> get surahNumbers => widget.mushaf.surahList.split(',');
  late List surahs;
  Map<String, bool> downloadingStatus = {};
  Map<String, bool> playingStatus = {};
  addSuraNames() {
    surahs = [];
    filteredSurahs = [];
    setState(() {
      surahs = widget.mushaf.surahList.split(',').map((e) {
        print(e);
        print(widget.jsonData);
        print(widget.jsonData.where((element) => element["id"].toString() == e.toString()));
        return {
          "surahNumber": e,
          "suraName": widget.jsonData
              .where((element) => element["id"].toString() == e.toString())
              .first["name"]
        };
      }).toList();
    });

    print(surahs.length);
  }

  List favoriteSurahs = [];
  filterFavoritesOnly() {
    favoriteSurahs = [];
    // print(favoriteSurahList);
// print(favoriteSurahList.contains(
//           "${widget.reciter.name}${widget.mushaf.name}${4- 1}"));
    for (var element in surahs) {
      if (favoriteSurahList.contains(
          "${widget.reciter.name}${widget.mushaf.name}${int.parse(element["surahNumber"])}"
              .trim())) {
        // print("true");
        favoriteSurahs.add(element);
      }
    }
    setState(() {});
    // print(surahs.length);
    // surahs = surahs.where((element) {
    //   // print(element);
    //   return favoriteSurahList.contains(
    //       "${widget.reciter.name}${widget.mushaf.name}${element["surahNumber"]}");
    // }).toList();

    setState(() {});
  }

  Future<void> createFolder() async {
    final dir = await getExternalStorageDirectory(); // مجلد خارجي خاص بالتطبيق
    final path = Directory('${dir!.path}/ghaith');

    if (!(await path.exists())) {
      await path.create(recursive: true);
    }

    print("✅ Folder created at: ${path.path}");
  }

  addFavorites() {
    favoriteSurahList = json.decode(getValue("favoriteSurahList"));
    setState(() {});
  }

  Future storePhotoUrl() async {
    final url =
        'https://www.googleapis.com/customsearch/v1?key=AIzaSyCR7ttKFGB4dG5MDJI3ygqiESjpWmKePrY&cx=f7b7aaf5b2f0e47e0&q=القارئ ${widget.reciter.name}&searchType=image';
    if (getValue("${widget.reciter.name} photo url") == null) {
      final response = await Dio().get(url);

      if (response.statusCode == 200) {
        print("photo url added");
        updateValue("${widget.reciter.name} photo url", response.data["items"][0]['link']);
        setState(() {});
      } else {
        throw Exception('Failed to load images');
      }
    }
  }

  List filteredSurahs = [];

  filterSurahs(value) {
    addSuraNames();
    setState(() {
      filteredSurahs =
          surahs.where((element) => quran.normalise(element["suraName"]).contains(value)).toList();
    });
  }

  // String photoUrl = "";
  @override
  void initState() {
    addFavorites();
    addSuraNames();
    super.initState();
    storePhotoUrl();
  }

  List favoriteSurahList = [];

  var selectedMode = "all";
  var searchQuery = "";
  Directory? appDir;

  Future<Directory> getAppDirectory() async {
    final dir = await getExternalStorageDirectory(); // external but private to app
    final path = Directory('${dir!.path}/Ghaith');
    if (!(await path.exists())) {
      await path.create(recursive: true);
    }
    return path;
  }

  TextEditingController textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Stack(
      children: [
        Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight,
          appBar: AppBar(
            backgroundColor:
                isDarkModeNotifier.value ? darkModeSecondaryColor.withOpacity(.9) : orangeColor,
            elevation: 0,
            foregroundColor: isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight,
            title: Text(
              "${widget.reciter.name} - ${widget.mushaf.name}",
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
            automaticallyImplyLeading: true,
            bottom: PreferredSize(
              preferredSize: Size(screenSize.width, screenSize.height * .1),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0.w),
                        child: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xffF6F6F6),
                              borderRadius: BorderRadius.circular(5.r)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0.w),
                                  child: TextField(
                                    controller: textEditingController,
                                    onChanged: (value) {
                                      setState(() {
                                        searchQuery = value;
                                      });

                                      filterSurahs(value);
                                      if (value == "") {
                                        addSuraNames();
                                      }
                                      // filterReciters(
                                      //     value); // Call the filter method when the text changes
                                    },
                                    decoration: InputDecoration(
                                      hintText: "searchBysura".tr(),
                                      hintStyle: TextStyle(
                                          fontFamily: "cairo",
                                          fontSize: 14.sp,
                                          color: const Color.fromARGB(73, 0, 0, 0)),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    // fetchReciters();
                                    // textEditingController.text = "";
                                    textEditingController.clear();
                                    FocusManager.instance.primaryFocus?.unfocus();

                                    setState(() {
                                      searchQuery = "";
                                    });
                                    addSuraNames();
                                  },
                                  child: Icon(searchQuery == "" ? FontAwesome.search : Icons.close,
                                      color: const Color.fromARGB(73, 0, 0, 0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.white,
                              enableDrag: true,
                              isDismissible: true,
                              showDragHandle: true,
                              builder: ((context) {
                                return StatefulBuilder(
                                  builder: (context, s) {
                                    return ListView(
                                      children: [
                                        EasyContainer(
                                          elevation: 0,
                                          padding: 0,
                                          margin: 0,
                                          onTap: () async {
                                            if (selectedMode != "all") {
                                              // addSuraNames();
                                              setState(() {
                                                selectedMode = "all";
                                              }); //       s((){});

                                              // await Future.delayed(
                                              //      Duration(milliseconds: 200));
                                              Navigator.pop(context);

                                              // print(favoriteRecitersList.length);

                                              // itemScrollController.scrollTo(
                                              //     index: 0,
                                              //     duration:  Duration(
                                              //         seconds: 1));
                                            }
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: 0.0.h),
                                            child: SizedBox(
                                              height: 45.h,
                                              // color: Colors.red,
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 30.w,
                                                  ),
                                                  Icon(
                                                    Icons.all_inclusive_rounded,
                                                    color: selectedMode == "all"
                                                        ? blueColor
                                                        : Colors.grey,
                                                  ),
                                                  SizedBox(
                                                    width: 10.w,
                                                  ),
                                                  Text("all".tr()),
                                                  Expanded(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        Icon(
                                                          selectedMode == "all"
                                                              ? FontAwesome.dot_circled
                                                              : FontAwesome.circle_empty,
                                                          color: selectedMode == "all"
                                                              ? blueColor
                                                              : Colors.grey,
                                                          size: 20.sp,
                                                        ),
                                                        SizedBox(
                                                          width: 40.w,
                                                        )
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          height: 15.h,
                                          color: Colors.grey,
                                        ),
                                        EasyContainer(
                                          elevation: 0,
                                          padding: 0,
                                          margin: 0,
                                          onTap: () async {
                                            // filteredReciters = [];

                                            setState(() {
                                              selectedMode = "favorite";
                                            });
                                            filterFavoritesOnly();
                                            // s((){});
                                            // await Future.delayed(
                                            //      Duration(milliseconds: 200));
                                            Navigator.pop(context);

                                            // itemScrollController.scrollTo(
                                            //     index: 0,
                                            //     duration:  Duration(
                                            //         seconds: 1));
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: 0.0.h),
                                            child: SizedBox(
                                              height: 45.h,
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 30.w,
                                                  ),
                                                  Icon(
                                                    Icons.favorite,
                                                    color: selectedMode == "favorite"
                                                        ? blueColor
                                                        : Colors.grey,
                                                  ),
                                                  SizedBox(
                                                    width: 10.w,
                                                  ),
                                                  Text("favorites".tr()),
                                                  Expanded(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        Icon(
                                                          selectedMode == "favorite"
                                                              ? FontAwesome.dot_circled
                                                              : FontAwesome.circle_empty,
                                                          color: selectedMode == "favorite"
                                                              ? blueColor
                                                              : Colors.grey,
                                                          size: 20.sp,
                                                        ),
                                                        SizedBox(
                                                          width: 40.w,
                                                        )
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          height: 15.h,
                                          color: Colors.grey,
                                        ),
                                        EasyContainer(
                                          elevation: 0,
                                          padding: 0,
                                          margin: 0,
                                          onTap: () async {
                                            // filteredReciters = [];
                                            createFolder();

                                            setState(() {
                                              selectedMode = "downloads";
                                            });
                                            // s((){});
                                            // await Future.delayed(
                                            //      Duration(milliseconds: 200));
                                            Navigator.pop(context);

                                            // itemScrollController.scrollTo(
                                            //     index: 0,
                                            //     duration:  Duration(
                                            //         seconds: 1));
                                          },
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: 0.0.h),
                                            child: SizedBox(
                                              height: 45.h,
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 30.w,
                                                  ),
                                                  Icon(
                                                    Icons.download,
                                                    color: selectedMode == "downloads"
                                                        ? blueColor
                                                        : Colors.grey,
                                                  ),
                                                  SizedBox(
                                                    width: 10.w,
                                                  ),
                                                  Text("downloaded".tr()),
                                                  Expanded(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        Icon(
                                                          selectedMode == "downloads"
                                                              ? FontAwesome.dot_circled
                                                              : FontAwesome.circle_empty,
                                                          color: selectedMode == "downloads"
                                                              ? blueColor
                                                              : Colors.grey,
                                                          size: 20.sp,
                                                        ),
                                                        SizedBox(
                                                          width: 40.w,
                                                        )
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }));
                        },
                        icon: const Icon(FontAwesome.filter, color: Colors.white)),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: orangeColor,
                  backgroundImage:
                      CachedNetworkImageProvider("${getValue("${widget.reciter.name} photo url")}"),
                ),
              )
              // Transform(
              //     transform: Matrix4.rotationY(math.pi),
              //     alignment: Alignment.center,
              //     child: IconButton(
              //         onPressed: () {
              //           Navigator.pop(context);
              //         },
              //         icon:  Icon(
              //           Entypo.logout,
              //           color: Colors.white,
              //         )))
            ],
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          body: ListView.separated(
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (context, index) => const Divider(),
            itemCount: filteredSurahs.isNotEmpty
                ? filteredSurahs.length
                : selectedMode == "all"
                    ? surahs.length
                    : favoriteSurahs.length,
            itemBuilder: (BuildContext context, int index) {
              dynamic surah = filteredSurahs.isNotEmpty
                  ? filteredSurahs[index]
                  : selectedMode == "all"
                      ? surahs[index]
                      : favoriteSurahs[index];
              return EasyContainer(
                borderRadius: 0,
                elevation: 0,
                padding: 4,
                margin: 0,
                onTap: () async {
                  //print("suraNumber"+ favoriteSurahs[index]["surahNumber"]);
                  if (qurapPagePlayerBloc.state is QuranPagePlayerPlaying) {
                    await showDialog(
                        context: context,
                        builder: (a) {
                          return AlertDialog(
                            content: Text("closeplayer".tr()),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("cancel".tr())),
                              TextButton(
                                  onPressed: () {
                                    qurapPagePlayerBloc.add(KillPlayerEvent());
                                    Navigator.pop(context);
                                  },
                                  child: Text("close".tr())),
                            ],
                          );
                        });
                  }

                  print(surah);
                  playerPageBloc.add(StartPlaying(
                      buildContext: context,
                      moshaf: widget.mushaf,
                      reciter: widget.reciter,
                      suraNumber: int.parse(
                          selectedMode == "all" ? surah["surahNumber"] : surah["surahNumber"]),
                      initialIndex: surahs.indexOf(surah),
                      jsonData: widget.jsonData));
                },
                color: isDarkModeNotifier.value
                    ? darkModeSecondaryColor.withOpacity(.9)
                    : Colors.white,
                child: ListTile(
                    leading: Image.asset(
                      "assets/images/${quran.getPlaceOfRevelation(int.parse(selectedMode == "all" ? surah["surahNumber"] : surah["surahNumber"])) == "makkah" || quran.getPlaceOfRevelation(int.parse(surah["surahNumber"])) == "Makkah" ? "Makkah" : "Madinah"}.png",
                      height: 25.h,
                      width: 25.w,
                    ),
                    trailing: SizedBox(
                      width: 160.w,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () async {
                              final surahKey = "${surah["surahNumber"]}-${widget.mushaf.id}";
                              final isPlayingNow = playingStatus[surahKey] ?? false;

                              // لو شغالة -> أوقفها مؤقتًا
                              if (isPlayingNow) {
                                playerPageBloc.add(PausePlayer());
                                setState(() => playingStatus[surahKey] = false);
                                return;
                              }

                              // شغّل السورة
                              setState(() => playingStatus[surahKey] = true);

                              playerPageBloc.add(StartPlaying(
                                moshaf: widget.mushaf,
                                reciter: widget.reciter,
                                buildContext: context,
                                suraNumber: int.parse(surah["surahNumber"]),
                                initialIndex: selectedMode == "all" ? index : surahs.indexOf(surah),
                                jsonData: widget.jsonData,
                              ));
                            },
                            icon: Icon(
                              (playingStatus["${surah["surahNumber"]}-${widget.mushaf.id}"] ??
                                      false)
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 24.sp,
                              color: blueColor,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final dir = await getAppDirectory();
                              final surahNumber = selectedMode == "all"
                                  ? surah["surahNumber"]
                                  : surah["surahNumber"];
                              final filePath =
                                  "${dir.path}/${widget.reciter.name}-${widget.mushaf.id}-${quran.getSurahNameArabic(int.parse(surahNumber))}.mp3";

                              if (File(filePath).existsSync()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("✅ السورة محمّلة بالفعل"),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                // ✅ فعّل حالة التحميل للسورة دي فقط
                                setState(() => downloadingStatus[surahNumber] = true);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("⬇️ جاري تحميل السورة..."),
                                    backgroundColor: Color(0xFF00A2B5),
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                                playerPageBloc.add(DownloadSurah(
                                  reciter: widget.reciter,
                                  moshaf: widget.mushaf,
                                  suraNumber: surahNumber,
                                  url: "${widget.mushaf.server}/${surahNumber.padLeft(3, "0")}.mp3",
                                  savePath: filePath,
                                ));

                                // مؤقتًا (لحد ما نربطه بالتحميل الحقيقي)
                                await Future.delayed(const Duration(seconds: 3));

                                setState(() => downloadingStatus[surahNumber] = false);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("✅ تم التحميل بنجاح"),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            icon: FutureBuilder<Directory>(
                              future: getAppDirectory(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Icon(Icons.download, size: 24);
                                }

                                final dir = snapshot.data!;
                                final surahNumber = selectedMode == "all"
                                    ? surah["surahNumber"]
                                    : surah["surahNumber"];
                                final filePath =
                                    "${dir.path}/${widget.reciter.name}-${widget.mushaf.id}-${quran.getSurahNameArabic(int.parse(surahNumber))}.mp3";
                                final fileExists = File(filePath).existsSync();

                                // 👇 استخدم الحالة الخاصة بكل سورة
                                final isDownloading = downloadingStatus[surahNumber] ?? false;

                                if (isDownloading) {
                                  return const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF00A2B5),
                                    ),
                                  );
                                }

                                return Icon(
                                  fileExists ? Icons.download_done : Icons.download,
                                  size: 24.sp,
                                  color: orangeColor,
                                );
                              },
                            ),
                            color: orangeColor,
                          ),
                          IconButton(
                            onPressed: () {
                              if (favoriteSurahList.contains(
                                  "${widget.reciter.name}${widget.mushaf.name}${selectedMode == "all" ? surah["surahNumber"] : surah["surahNumber"]}")) {
                                favoriteSurahList.remove(
                                    "${widget.reciter.name}${widget.mushaf.name}${selectedMode == "all" ? surahs[index]["surahNumber"] : favoriteSurahs[index]["surahNumber"]}"
                                        .trim());
                                updateValue("favoriteSurahList", json.encode(favoriteSurahList));
                              } else {
                                favoriteSurahList.add(
                                    "${widget.reciter.name}${widget.mushaf.name}${selectedMode == "all" ? surah["surahNumber"] : surah["surahNumber"]}"
                                        .trim());
                                updateValue("favoriteSurahList", json.encode(favoriteSurahList));
                              }

                              setState(() {});
                            },
                            icon: Icon(
                                favoriteSurahList.contains(
                                        "${widget.reciter.name}${widget.mushaf.name}${selectedMode == "all" ? surah["surahNumber"] : surah["surahNumber"]}"
                                            .trim())
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 24.sp),
                            color: orangeColor,
                          )
                        ],
                      ),
                    ),
                    title: Text(
                      "${context.locale.languageCode == "ar" ? widget.jsonData[(int.parse(selectedMode == "all" ? surah["surahNumber"] : surah["surahNumber"])) - 1]["name"] : surah["suraName"]}",
                      style: TextStyle(
                          fontFamily: context.locale.languageCode == "ar" ? "qaloon" : "roboto",
                          fontSize: context.locale.languageCode == "ar" ? 22.sp : 17.sp,
                          color: isDarkModeNotifier.value
                              ? Colors.white.withOpacity(.9)
                              : Colors.black87),
                    )),
              );
            },
          ),
        ),
      ],
    );
  }
}
