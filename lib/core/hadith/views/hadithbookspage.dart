import 'dart:convert';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/main.dart';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:fluttericon/mfg_labs_icons.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/core/hadith/models/category.dart';
import 'package:ghaith/core/hadith/views/booklistpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HadithBooksPage extends StatefulWidget {
  String locale;
  HadithBooksPage({super.key, required this.locale});

  @override
  State<HadithBooksPage> createState() => _HadithBooksPageState();
}

class _HadithBooksPageState extends State<HadithBooksPage> {
  List<Category> categories = [];
  bool isLoading = true;
  getCategories() async {
    categories = [];
    categories.add(Category(
        id: "100000", title: "allHadith".tr(), hadeethsCount: "2000+", parentId: "parentId"));
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString("categories-${widget.locale}") == null) {
      Response response = await Dio()
          .get("https://hadeethenc.com/api/v1/categories/roots/?language=${widget.locale}");
      print(response.data);
      await response.data.forEach((cat) => categories.add(Category.fromJson(cat)));
      print(categories.length);
      isLoading = false;
    } else {
      print("stored offline");
      final jsonData = prefs.getString("categories-${widget.locale}");

      if (jsonData != null) {
        final data = json.decode(jsonData) as List<dynamic>;
        for (var cat in data) {
          categories.add(Category.fromJson(cat));
        }

        // starredRadios = json.decode(getValue("starredRadios"));
        setState(() {
          // radiosData = data;
          isLoading = false;
        });
      }
    }

    setState(() {});
  }

  @override
  void initState() {
    getCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkModeNotifier.value ? quranPagesColorDark.withOpacity(0.4) : quranPagesColorLight,
      appBar: AppBar(
        backgroundColor: isDarkModeNotifier.value ? darkModeSecondaryColor  : quranPagesColorLight.withOpacity(0.4),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black,
        ),
        title: Text(
          "Hadith".tr(),
          style: TextStyle(
            color: isDarkModeNotifier.value ? Colors.white.withOpacity(.87) : Colors.black,
            fontFamily: "cairo",
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight,
              ),
            )
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (builder) => HadithList(
                                  title: categories[index].title,
                                  count: categories[index].hadeethsCount,
                                  locale: context.locale.languageCode,
                                  id: categories[index].id)));
                    },
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isDarkModeNotifier.value
                                ? darkModeSecondaryColor
                                : const Color(0xffF5EFE8).withOpacity(.9),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Icon(
                              MfgLabs.folder_empty,
                              size: 30.sp,
                              color: isDarkModeNotifier.value
                                  ? Colors.white.withOpacity(.87)
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 15.w,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categories[index].title,
                              style: TextStyle(
                                color: getValue("darkMode") ? Colors.white70 : Colors.black,
                                fontSize: 14.sp,
                              ),
                            ),
                            Text(
                              "Hadith Count: ${categories[index].hadeethsCount}",
                              style: TextStyle(
                                  color:  isDarkModeNotifier.value ? Colors.white : Colors.black38,
                              ),
                            )
                          ],
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                context.locale.languageCode == "ar"
                                    ? Entypo.left_open
                                    : Entypo.right_open,
                                color:  getValue("darkMode") ? Colors.white70 : Colors.black,
                                size: 26.sp,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
