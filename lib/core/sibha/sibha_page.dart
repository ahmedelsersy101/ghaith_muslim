import 'dart:convert';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/core/sibha/models/tasbeh.dart';
import 'package:ghaith/core/sibha/widgets/add_tasbeeh_dialog.dart';
import 'package:ghaith/main.dart';

class SibhaPage extends StatefulWidget {
  const SibhaPage({super.key});

  @override
  State<SibhaPage> createState() => _SibhaPageState();
}

class _SibhaPageState extends State<SibhaPage> with TickerProviderStateMixin {
  List<Tasbeeh> tasbeehList = [
    Tasbeeh(
      id: 0,
      arabic: 'الحمد لله',
      translation: 'Praise be to Allah',
      pronunciation: 'Al-ham-du li-lah',
    ),
    Tasbeeh(
      id: 1,
      arabic: 'الله اكبر',
      translation: 'Allah is the Greatest',
      pronunciation: 'Al-lah-hu Ak-bar',
    ),
    Tasbeeh(
      id: 2,
      arabic: 'استغفر الله',
      translation: 'I seek forgiveness from Allah',
      pronunciation: 'As-tag-fir-ul-lah',
    ),
    Tasbeeh(
      id: 3,
      arabic: 'لا اله الا الله',
      translation: 'There is no god but Allah',
      pronunciation: 'La ila-ha ill-al-lah',
    ),
    Tasbeeh(
      id: 4,
      arabic: 'سبحان الله',
      translation: 'Glory be to Allah',
      pronunciation: 'Sub-han Allah',
    ),
    Tasbeeh(
      id: 5,
      arabic: 'سبحان الله وبحمده سبحان الله العظيم',
      translation: 'Glory be to Allah, and praise is due to Him, glory be to Allah the Great',
      pronunciation: 'Sub-han Allah wa bi-ham-di-hi Sub-han Allah al-a-zeem',
    ),
    Tasbeeh(
      id: 6,
      arabic: 'سبحان الله والحمد لله ولا اله الا الله والله اكبر',
      translation:
          'Glory be to Allah, and praise is due to Allah, and there is no god but Allah, and Allah is the Greatest',
      pronunciation: 'Sub-han Allah wa al-ham-du li-lah wa la ila-ha ill-al-lah wa Al-lah Ak-bar',
    ),
    Tasbeeh(
      id: 7,
      arabic: 'لا إله إلا أنت سبحانك إني كنت من الظالمين',
      translation: 'There is no god but You, glory be to You; surely I am of those who are unjust',
      pronunciation: 'La ila-ha ill-a an-ta Sub-ha-na-ka in-ni ku-n-tu min az-zal-li-meen',
    ),
    Tasbeeh(
      id: 8,
      arabic: 'اللهم أنت السلام ومنك السلام تباركت يا ذا الجلال والإكرام',
      translation:
          'O Allah, You are the Peace, and from You comes peace; Blessed are You, O Possessor of Majesty and Honor',
      pronunciation:
          'Al-lah-ma an-ta as-Sa-laam wa min-ka as-Sa-laam ta-ba-ra-kat ya dha al-ja-la-li wal-i-kraam',
    ),
    Tasbeeh(
      id: 9,
      arabic: 'اللهم صل وسلم وبارك على سيدنا محمد',
      translation: 'O Allah, send peace and blessings upon our Master Muhammad',
      pronunciation: 'Al-lah-ma sal-li wa sal-lim wa ba-rik ala sa-yi-di-na Mu-ham-mad',
    ),
    Tasbeeh(
      id: 10,
      arabic: 'الله أكبر كبيرا  والحمد لله كثيرا  وسبحان الله بكرة وأصيلا',
      translation:
          'Allah is the Greatest, greatly, and praise be to Allah abundantly, and glory be to Allah in the morning and the evening',
      pronunciation:
          'Al-lah Ak-bar kabee-ra wa al-ham-du li-lah ka-thee-ra wa Sub-han Al-lah bu-ka-ra wa a-shee-la',
    ),
    Tasbeeh(
      id: 11,
      arabic: 'لا إله إلا الله وحده لا شريك له له الملك وله الحمد وهو على كل شيء قدير',
      translation:
          'There is no god but Allah alone, He has no partner, His is the sovereignty, and His is the praise, and He has power over everything',
      pronunciation:
          'La ila-ha ill-a al-lah wa-hda-hu la shar-ee-ka la-hu la-hu al-mul-ku wa la-hu al-ham-du wa hu-wa ala ku-l-lee shay-in qa-deer',
    ),
    Tasbeeh(
      id: 12,
      arabic: 'سبحان الله وبحمده  سبحان الله العظيم',
      translation: 'Glory be to Allah, and praise be to Him; glory be to Allah the Great',
      pronunciation: 'Sub-han Al-lah wa bi-ham-di-hi  Sub-han Al-lah al-a-zeem',
    ),
  ];

  late AnimationController _counterAnimationController;
  late AnimationController _rippleAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    customTasbeehFetcher();

    _counterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rippleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _counterAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleAnimationController,
        curve: Curves.easeOut,
      ),
    );

    super.initState();
  }

  @override
  void dispose() {
    _counterAnimationController.dispose();
    _rippleAnimationController.dispose();
    super.dispose();
  }

  customTasbeehFetcher() {
    var customTasbeehs = getValue("customTasbeehs");
    if (customTasbeehs != null) {
      json.decode(customTasbeehs).forEach((t) {
        tasbeehList.add(Tasbeeh(
          id: t["id"],
          arabic: t["arabic"],
          translation: "",
          pronunciation: "",
        ));
      });
      setState(() {});
    }
  }

  addCustomTasbeeh(arabic) async {
    var customTasbeehs = getValue("customTasbeehs");
    if (customTasbeehs != null) {
      var tasbeehs = json.decode(customTasbeehs);
      tasbeehs.add({
        "id": Random().nextInt(665656),
        "arabic": arabic,
      });
      tasbeehList.add(Tasbeeh(
          id: tasbeehs[tasbeehs.length - 1]["id"],
          arabic: tasbeehs[tasbeehs.length - 1]["arabic"],
          translation: "",
          pronunciation: ""));
      updateValue("customTasbeehs", json.encode(tasbeehs));
    } else {
      List tasbeehs = [];
      tasbeehs.add({
        "id": Random().nextInt(665656),
        "arabic": arabic,
      });
      setState(() {});
      tasbeehList.add(Tasbeeh(
          id: tasbeehs[0]["id"],
          arabic: tasbeehs[0]["arabic"],
          translation: "",
          pronunciation: ""));
      setState(() {});
      updateValue("customTasbeehs", json.encode(tasbeehs));
    }
    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 150));
    tasbeehScrollController.animateToPage(tasbeehList.length - 1,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  PageController tasbeehScrollController =
      PageController(initialPage: getValue("tasbeehLastIndex") ?? 0);

  void _onCounterTap() {
    final index = getValue("tasbeehLastIndex") ?? 0; // ✅ خزّنها في متغير
    updateValue("${index}number", (getValue("${index}number") ?? 0) + 1);

    _counterAnimationController.forward().then((_) {
      _counterAnimationController.reverse();
    });
    _rippleAnimationController.forward().then((_) {
      _rippleAnimationController.reset();
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = isDarkModeNotifier.value;
    final currentIndex = getValue("tasbeehLastIndex") ?? 0;
    final currentCount = getValue("${currentIndex}number") ?? 0;

    // App color palette
    final primaryGradient = isDark
        ? [const Color(0xFF6a1e2c), const Color(0xFF8C2F3A)]
        : [const Color(0xFF5D9566), const Color(0xFF87669A)];

    final cardColor = isDark ? darkSlateGray : paperBeige;

    final textPrimary = isDark ? Colors.white : charcoalDarkGray;
    final textSecondary = isDark ? Colors.white.withOpacity(0.7) : mediumGray;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? [deepNavyBlack, deepNavyBlack] : [paperBeige, paperBeige],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70.h),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AppBar(
              elevation: 0,
              backgroundColor: isDarkModeNotifier.value ? darkSlateGray : wineRed,
              toolbarHeight: 70.h,
              foregroundColor: Colors.white,
              actions: [
                Container(
                  margin: EdgeInsets.only(right: 8.w, left: 8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (c) => AddTasbeehDialog(
                          function: addCustomTasbeeh,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 28),
                    color: Colors.white,
                  ),
                ),
              ],
              title: Text(
                "sibha".tr(),
                style: TextStyle(
                  fontFamily: 'cairo',
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 20.h),

              // Page Indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isDarkModeNotifier.value ? darkSlateGray : wineRed,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      "${currentIndex + 1} / ${tasbeehList.length}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: "roboto",
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Tasbeeh Card
              Expanded(
                flex: 3,
                child: PageView.builder(
                  onPageChanged: ((value) {
                    updateValue("tasbeehLastIndex", value);
                    setState(() {});
                  }),
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkModeNotifier.value ? darkSlateGray : wineRed,
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGradient[0].withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Decorative pattern
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30.r),
                                child: CustomPaint(
                                  painter: IslamicPatternPainter(
                                    color: primaryGradient[0].withOpacity(0.05),
                                  ),
                                ),
                              ),
                            ),

                            // Content
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.w),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Arabic Text
                                    Text(
                                      tasbeehList[i].arabic,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "cairo",
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        height: 1.8,
                                        shadows: [
                                          Shadow(
                                            color: primaryGradient[0].withOpacity(0.1),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),

                                    if (tasbeehList[i].pronunciation != "") ...[
                                      SizedBox(height: 20.h),
                                      Container(
                                        height: 1,
                                        width: 100.w,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              primaryGradient[0].withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 20.h),
                                      Text(
                                        tasbeehList[i].pronunciation,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "roboto",
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],

                                    if (tasbeehList[i].translation != "") ...[
                                      SizedBox(height: 16.h),
                                      Text(
                                        tasbeehList[i].translation,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: "roboto",
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: tasbeehList.length,
                  scrollDirection: Axis.horizontal,
                  controller: tasbeehScrollController,
                ),
              ),

              SizedBox(height: 30.h),

              // Navigation Controls
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button
                    _buildNavButton(
                      icon: Icons.arrow_back_ios_rounded,
                      onTap: () {
                        if (currentIndex > 0) {
                          tasbeehScrollController.animateToPage(
                            currentIndex - 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      enabled: currentIndex > 0,
                      darkWarmBrown: primaryGradient[0],
                    ),

                    // Reset Button
                    _buildResetButton(
                      onTap: () {
                        updateValue("${currentIndex}number", 0);
                        setState(() {});
                      },
                      darkWarmBrown: primaryGradient[0],
                    ),

                    // Next Button
                    _buildNavButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        if (currentIndex < tasbeehList.length - 1) {
                          tasbeehScrollController.animateToPage(
                            currentIndex + 1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      enabled: currentIndex < tasbeehList.length - 1,
                      darkWarmBrown: primaryGradient[0],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),

              // Counter Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple Effect
                      AnimatedBuilder(
                        animation: _rippleAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 200.w * (1 + _rippleAnimation.value * 0.5),
                            height: 200.w * (1 + _rippleAnimation.value * 0.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDarkModeNotifier.value ? darkSlateGray : wineRed,
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),

                      // Counter Button
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: GestureDetector(
                          onTap: _onCounterTap,
                          child: Container(
                            width: 200.w,
                            height: 200.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDarkModeNotifier.value ? darkSlateGray : wineRed,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryGradient[0].withOpacity(0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$currentCount",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 56.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "roboto",
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.2),
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
    required Color darkWarmBrown,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: isDarkModeNotifier.value ? darkSlateGray : wineRed,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDarkModeNotifier.value ? darkSlateGray : wineRed,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.grey,
            size: 24.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton({
    required VoidCallback onTap,
    required Color darkWarmBrown,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            color: isDarkModeNotifier.value ? darkSlateGray : wineRed,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDarkModeNotifier.value ? darkSlateGray : wineRed,
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 28.sp,
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Islamic Pattern
class IslamicPatternPainter extends CustomPainter {
  final Color color;

  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Draw small decorative circles
        canvas.drawCircle(
          Offset(x, y),
          8,
          paint,
        );

        // Draw connecting lines
        if (x + spacing < size.width) {
          canvas.drawLine(
            Offset(x + 8, y),
            Offset(x + spacing - 8, y),
            paint..strokeWidth = 0.8,
          );
        }
        if (y + spacing < size.height) {
          canvas.drawLine(
            Offset(x, y + 8),
            Offset(x, y + spacing - 8),
            paint..strokeWidth = 0.8,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
