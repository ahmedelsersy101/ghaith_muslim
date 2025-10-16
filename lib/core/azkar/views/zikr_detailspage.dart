import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
import 'package:ghaith/core/azkar/model/dua_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/main.dart';

class ZikrPage extends StatefulWidget {
  DuaModel zikr;
  ZikrPage({super.key, required this.zikr});

  @override
  State<ZikrPage> createState() => _ZikrPageState();
}

class _ZikrPageState extends State<ZikrPage> {
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    if (getValue("${widget.zikr.category}zikrIndex") == null) {
      updateValue("${widget.zikr.category}zikrIndex", 0);
    }
  }

  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          color: isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight,
          image: const DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage(
                "assets/images/mosquepnggold.png",
              ),
              alignment: Alignment.center,
              opacity: .15)),
      child: Scaffold(
        body: Stack(
          children: [
            SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    SizedBox(
                      height: 20.h,
                    ),
                    SizedBox(
                        height: (MediaQuery.of(context).size.height * .78) - 30.h,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: SingleChildScrollView(
                            key: Key(getValue("${widget.zikr.category}zikrIndex").toString()),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                                    child: GestureDetector(
                                      onLongPress: () {
                                        Clipboard.setData(ClipboardData(
                                                text: widget
                                                    .zikr
                                                    .array[getValue(
                                                        "${widget.zikr.category}zikrIndex")]
                                                    .text))
                                            .then((value) =>
                                                Fluttertoast.showToast(msg: "Copied to Clipboard"));
                                      },
                                      child: Text(
                                        widget
                                            .zikr
                                            .array[getValue("${widget.zikr.category}zikrIndex")]
                                            .text,
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: isDarkModeNotifier.value
                                                ? Colors.white
                                                : Colors.black,
                                            locale: const Locale("ar"),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18.sp),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                    SizedBox(
                      height: 10.h,
                    ),
                  ],
                )),
            Positioned(
                bottom: 50.h,
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            count++;

                            // عدد التكرارات المطلوبة للذكر الحالي
                            int requiredCount = widget
                                .zikr.array[getValue("${widget.zikr.category}zikrIndex")].count;

                            // ✅ لو وصل للعدد المطلوب.. اقلب للذكر اللي بعده
                            if (count >= requiredCount) {
                              // لو لسه في أذكار تانية
                              if (getValue("${widget.zikr.category}zikrIndex") + 1 <
                                  widget.zikr.array.length) {
                                updateValue(
                                  "${widget.zikr.category}zikrIndex",
                                  getValue("${widget.zikr.category}zikrIndex") + 1,
                                );
                              } else {
                                // لو وصلنا لنهاية الأذكار
                                Fluttertoast.showToast(msg: "🎉 تم الانتهاء من الأذكار");
                              }

                              // رجع العدّاد للصفر
                              count = 0;
                            }
                          });
                        },
                        child: Center(
                          child: Container(
                            height: 150.h,
                            width: 150.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: isDarkModeNotifier.value
                                  ? Colors.white.withOpacity(.1)
                                  : Colors.black.withOpacity(.2),
                            ),
                            child: Center(
                              child: Text(
                                "$count",
                                style: TextStyle(
                                  color: isDarkModeNotifier.value ? Colors.black : Colors.white,
                                  fontSize: 50.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "roboto",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 22.h,
                      ),
                      SizedBox(
                        width: 120.w,
                        child: LinearProgressIndicator(
                          value: count /
                              widget.zikr.array[getValue("${widget.zikr.category}zikrIndex")].count,
                          backgroundColor: Colors.grey.withOpacity(.3),
                          color: Colors.green,
                          minHeight: 5.h,
                        ),
                      ),
                    ],
                  ),
                )),
            Positioned(
                width: MediaQuery.of(context).size.width,
                top: MediaQuery.of(context).size.height * .71,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (getValue("${widget.zikr.category}zikrIndex") != 0) {
                            updateValue("${widget.zikr.category}zikrIndex",
                                getValue("${widget.zikr.category}zikrIndex") - 1);
                          }
                          setState(() {
                            count = 0;
                          });
                        },
                        child: Container(
                          height: 50.h,
                          width: 50.w,
                          decoration: BoxDecoration(
                              color: isDarkModeNotifier.value
                                  ? Colors.white.withOpacity(.1)
                                  : Colors.black.withOpacity(.2),
                              borderRadius: BorderRadius.circular(32)),
                          child: Center(
                            child: Icon(
                              Icons.arrow_back_ios_new_outlined,
                              color: isDarkModeNotifier.value ? Colors.black : Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (getValue("${widget.zikr.category}zikrIndex") + 1 !=
                              widget.zikr.array.length) {
                            updateValue("${widget.zikr.category}zikrIndex",
                                getValue("${widget.zikr.category}zikrIndex") + 1);
                            count = 0;
                          }

                          setState(() {});
                        },
                        child: Container(
                          height: 50.h,
                          width: 50.w,
                          decoration: BoxDecoration(
                              color: isDarkModeNotifier.value
                                  ? Colors.white.withOpacity(.1)
                                  : Colors.black.withOpacity(.2),
                              borderRadius: BorderRadius.circular(32)),
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_ios_outlined,
                              color: isDarkModeNotifier.value ? Colors.black : Colors.white,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
          ],
        ),
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.zikr.category,
            style: TextStyle(
                fontFamily: "cairo",
                color: isDarkModeNotifier.value ? Colors.white : Colors.black,
                fontSize: 16.sp),
          ),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
                onPressed: () {
                  updateValue("${widget.zikr.category}zikrIndex", 0);
                  count = 0;
                  setState(() {});
                },
                icon: Icon(
                  Icons.replay_outlined,
                  color: isDarkModeNotifier.value ? Colors.white : Colors.black,
                  size: 24.sp,
                ))
          ],
          centerTitle: true,
          elevation: 0,
        ),
      ),
    );
  }
}
