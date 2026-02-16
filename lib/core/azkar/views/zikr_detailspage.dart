import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/main.dart';
import 'package:vibration/vibration.dart';

// =============================================
// 📁 IMPORTS - يمكن نقلها لملف imports منفصل
// =============================================
import 'package:ghaith/helpers/constants.dart';
import 'package:ghaith/helpers/hive_helper.dart';
import 'package:ghaith/core/azkar/model/dua_model.dart';

// =============================================
// 🏗️ MAIN WIDGET - Zikr Page
// =============================================

class ZikrPage extends StatefulWidget {
  final DuaModel zikr;

  const ZikrPage({super.key, required this.zikr});

  @override
  State<ZikrPage> createState() => _ZikrPageState();
}

// =============================================
// 🔧 STATE CLASS - Zikr Page Logic
// =============================================

class _ZikrPageState extends State<ZikrPage> with SingleTickerProviderStateMixin {
  // =============================================
  // 🎛️ STATE VARIABLES
  // =============================================
  int _currentCount = 0;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // =============================================
  // 🎯 LIFECYCLE METHODS
  // =============================================

  @override
  void initState() {
    super.initState();
    _initializeZikrIndex();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  // =============================================
  // 🎬 ANIMATION SETUP
  // =============================================

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  // تأثير الضغط
  void _playTapAnimation() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  // اهتزاز خفيف
  Future<void> _playVibration() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 100);
    }
  }

  // =============================================
  // 💾 DATA MANAGEMENT - يمكن نقلها لملف service منفصل
  // =============================================

  // [CAN_BE_EXTRACTED] -> services/zikr_service.dart
  void _initializeZikrIndex() {
    if (getValue("${widget.zikr.category}zikrIndex") == null) {
      updateValue("${widget.zikr.category}zikrIndex", 0);
    }
  }

  // [CAN_BE_EXTRACTED] -> services/zikr_service.dart
  int _getCurrentZikrIndex() {
    return getValue("${widget.zikr.category}zikrIndex") ?? 0;
  }

  // [CAN_BE_EXTRACTED] -> services/zikr_service.dart
  void _updateZikrIndex(int newIndex) {
    updateValue("${widget.zikr.category}zikrIndex", newIndex);
  }

  // [CAN_BE_EXTRACTED] -> services/zikr_service.dart
  dynamic _getCurrentZikr() {
    return widget.zikr.array[_getCurrentZikrIndex()];
  }

  // [CAN_BE_EXTRACTED] -> services/zikr_service.dart
  bool _hasNextZikr() {
    return _getCurrentZikrIndex() + 1 < widget.zikr.array.length;
  }

  // [CAN_BE_EXTRACTED] -> services/zikr_service.dart
  bool _hasPreviousZikr() {
    return _getCurrentZikrIndex() > 0;
  }

  // =============================================
  // 🧩 UI BUILD METHODS
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: _buildBackgroundDecoration(),
      child: Scaffold(
        body: _buildContent(),
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
      ),
    );
  }

  // =============================================
  // 🎨 UI COMPONENTS - يمكن نقلها لملف widgets منفصل
  // =============================================

  // [CAN_BE_EXTRACTED] -> widgets/background_decoration.dart
  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      color: _getsoftOffWhite(),
      image: const DecorationImage(
        fit: BoxFit.contain,
        image: AssetImage("assets/images/mosquepnggold.png"),
        alignment: Alignment.bottomCenter,
        opacity: .15,
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/zikr_content.dart
  Widget _buildContent() {
    return Column(
      children: [
        // عداد الأذكار في الأعلى
        SizedBox(height: 16.h),
        _buildZikrCounter(),
        SizedBox(height: 16.h),

        // محتوى الذكر
        Expanded(
          child: _buildZikrCard(),
        ),

        // أزرار التنقل
        SizedBox(height: 32.h),
        _buildNavigationButtons(),
        SizedBox(height: 32.h),

        // زر العد في الأسفل
        _buildCounterButton(),
        SizedBox(height: 80.h),
      ],
    );
  }

  Widget _buildZikrCounter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDarkModeNotifier.value ? deepNavyBlack.withOpacity(.8) : wineRed,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.copy_outlined, color: Colors.white, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            "${_getCurrentZikrIndex() + 1} / ${widget.zikr.array.length}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة الذكر الرئيسية
  Widget _buildZikrCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDarkModeNotifier.value ? deepNavyBlack.withOpacity(.8) : wineRed,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _buildZikrText(),
      ),
    );
  }

  // نص الذكر
  Widget _buildZikrText() {
    return SingleChildScrollView(
      key: Key(_getCurrentZikrIndex().toString()),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onLongPress: _onZikrTextLongPress,
            child: Column(
              children: [
                // النص العربي
                Text(
                  _getCurrentZikr().text,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.8,
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // أزرار التنقل (السابق - إعادة - التالي)
  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavigationButton(
            onTap: _onPreviousTap,
            icon: Icons.arrow_back_ios_new,
            isEnabled: _hasPreviousZikr(),
          ),
          _buildResetButton(),
          _buildNavigationButton(
            onTap: _onNextTap,
            icon: Icons.arrow_forward_ios,
            isEnabled: _hasNextZikr(),
          ),
        ],
      ),
    );
  }

  // زر التنقل (سابق/تالي)
  Widget _buildNavigationButton({
    required VoidCallback onTap,
    required IconData icon,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        height: 55.h,
        width: 55.w,
        decoration: BoxDecoration(
          color: isDarkModeNotifier.value ? deepNavyBlack.withOpacity(.8) : wineRed,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
      ),
    );
  }

  // زر إعادة التعيين
  Widget _buildResetButton() {
    return GestureDetector(
      onTap: _onResetTap,
      child: Container(
        height: 55.h,
        width: 55.w,
        decoration: BoxDecoration(
          color: isDarkModeNotifier.value ? deepNavyBlack.withOpacity(.8) : wineRed,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Center(
          child: Icon(
            Icons.replay_outlined,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
      ),
    );
  }

  // زر العد الكبير مع تأثير الضغط
  Widget _buildCounterButton() {
    return GestureDetector(
      onTap: _onCounterTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // الدائرة الخارجية
            Container(
              height: 140.h,
              width: 140.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkModeNotifier.value ? deepNavyBlack.withOpacity(.8) : wineRed,
                boxShadow: [
                  BoxShadow(
                    color: (isDarkModeNotifier.value ? deepNavyBlack : wineRed).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),

            // العدد
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$_currentCount",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 50.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/zikr_app_bar.dart
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        widget.zikr.category,
        style: _getAppBarTitleStyle(),
      ),
      backgroundColor: isDarkModeNotifier.value ? deepNavyBlack.withOpacity(.8) : wineRed,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      elevation: 0,
    );
  }

  // =============================================
  // 🔧 EVENT HANDLERS
  // =============================================

  void _onCounterTap() {
    _playTapAnimation();

    setState(() {
      _currentCount++;
      _checkZikrCompletion();
    });
  }

  void _onPreviousTap() {
    if (_hasPreviousZikr()) {
      _updateZikrIndex(_getCurrentZikrIndex() - 1);
      _resetCounter();
    }
  }

  void _onNextTap() {
    if (_hasNextZikr()) {
      _updateZikrIndex(_getCurrentZikrIndex() + 1);
      _resetCounter();
    }
  }

  void _onResetTap() {
    _updateZikrIndex(0);
    _resetCounter();
  }

  void _onZikrTextLongPress() {
    Clipboard.setData(ClipboardData(text: _getCurrentZikr().text))
        .then((value) => Fluttertoast.showToast(msg: "Copied to Clipboard"));
  }

  // =============================================
  // 🔧 HELPER METHODS
  // =============================================

  void _checkZikrCompletion() {
    final requiredCount = _getCurrentZikr().count;

    if (_currentCount >= requiredCount) {
      // تشغيل الاهتزاز عند الانتهاء من الذكر
      _playVibration();

      if (_hasNextZikr()) {
        _updateZikrIndex(_getCurrentZikrIndex() + 1);
      } else {
        _showCompletionToast("🎉 تم الانتهاء من الأذكار");
        _updateZikrIndex(0);
      }

      _resetCounter();
    }
  }

  void _resetCounter() {
    setState(() {
      _currentCount = 0;
    });
  }

  void _showCompletionToast(String message) {
    Fluttertoast.showToast(msg: message);
  }

  // =============================================
  // 🎨 STYLE HELPER METHODS
  // =============================================

  Color _getsoftOffWhite() {
    return isDarkModeNotifier.value ? darkSlateGray : paperBeige;
  }

  TextStyle _getAppBarTitleStyle() {
    return TextStyle(
      fontFamily: "cairo",
      color: Colors.white,
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
    );
  }
}
