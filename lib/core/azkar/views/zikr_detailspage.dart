import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ghaith/main.dart';

// =============================================
// 📁 IMPORTS - يمكن نقلها لملف imports منفصل
// =============================================
import 'package:ghaith/GlobalHelpers/constants.dart';
import 'package:ghaith/GlobalHelpers/hive_helper.dart';
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

class _ZikrPageState extends State<ZikrPage> {
  // =============================================
  // 🎛️ STATE VARIABLES
  // =============================================
  int _currentCount = 0;

  // =============================================
  // 🎯 LIFECYCLE METHODS
  // =============================================

  @override
  void initState() {
    super.initState();
    _initializeZikrIndex();
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
      color: _getBackgroundColor(),
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
    return Stack(
      children: [
        _buildZikrTextSection(),
        _buildCounterSection(),
        _buildNavigationButtons(),
      ],
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/zikr_text_section.dart
  Widget _buildZikrTextSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          SizedBox(height: 20.h),
          _buildZikrTextContainer(),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/zikr_text_container.dart
  Widget _buildZikrTextContainer() {
    return SizedBox(
      height: (MediaQuery.of(context).size.height * .78) - 30.h,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _buildZikrText(),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/zikr_text.dart
  Widget _buildZikrText() {
    return SingleChildScrollView(
      key: Key(_getCurrentZikrIndex().toString()),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: GestureDetector(
                onLongPress: _onZikrTextLongPress,
                child: Text(
                  _getCurrentZikr().text, // استخدام النوع الديناميكي
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: _getZikrTextStyle(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/counter_section.dart
  Widget _buildCounterSection() {
    return Positioned(
      bottom: 50.h,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: Column(
          children: [
            _buildCounterButton(),
            SizedBox(height: 22.h),
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/counter_button.dart
  Widget _buildCounterButton() {
    return GestureDetector(
      onTap: _onCounterTap,
      child: Center(
        child: Container(
          height: 150.h,
          width: 150.h,
          decoration: _buildCounterDecoration(),
          child: Center(
            child: Text(
              "$_currentCount",
              style: _getCounterTextStyle(),
            ),
          ),
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/progress_indicator.dart
  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 120.w,
      child: LinearProgressIndicator(
        value: _getProgressValue(),
        backgroundColor: Colors.grey.withOpacity(.3),
        color: Colors.green,
        minHeight: 5.h,
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/navigation_buttons.dart
  Widget _buildNavigationButtons() {
    return Positioned(
      width: MediaQuery.of(context).size.width,
      top: MediaQuery.of(context).size.height * .71,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildPreviousButton(),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/navigation_button.dart
  Widget _buildPreviousButton() {
    return _buildNavigationButton(
      onTap: _onPreviousTap,
      icon: Icons.arrow_back_ios_new_outlined,
      isEnabled: _hasPreviousZikr(),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/navigation_button.dart
  Widget _buildNextButton() {
    return _buildNavigationButton(
      onTap: _onNextTap,
      icon: Icons.arrow_forward_ios_outlined,
      isEnabled: _hasNextZikr(),
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/navigation_button.dart
  Widget _buildNavigationButton({
    required VoidCallback onTap,
    required IconData icon,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        height: 50.h,
        width: 50.w,
        decoration: _buildNavigationButtonDecoration(),
        child: Center(
          child: Icon(
            icon,
            color: _getNavigationIconColor(),
            size: 20.sp,
          ),
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
      backgroundColor: Colors.transparent,
      actions: [
        _buildResetButton(),
      ],
      centerTitle: true,
      elevation: 0,
    );
  }

  // [CAN_BE_EXTRACTED] -> widgets/reset_button.dart
  Widget _buildResetButton() {
    return IconButton(
      onPressed: _onResetTap,
      icon: Icon(
        Icons.replay_outlined,
        color: _getResetIconColor(),
        size: 24.sp,
      ),
    );
  }

  // =============================================
  // 🔧 EVENT HANDLERS
  // =============================================

  void _onCounterTap() {
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
      if (_hasNextZikr()) {
        // 🔹 إذا كان هناك ذكر بعد الحالي → انتقل إليه
        _updateZikrIndex(_getCurrentZikrIndex() + 1);
      } else {
        // 🔹 لا يوجد أذكار أخرى → أظهر رسالة وارجع لأول ذكر
        _showCompletionToast("🎉 تم الانتهاء من الأذكار");
        _updateZikrIndex(0); // ⬅️ إرجاع الفهرس لأول ذكر تلقائي
      }

      _resetCounter(); // إعادة العداد بعد كل انتقال
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

  double _getProgressValue() {
    final requiredCount = _getCurrentZikr().count; // استخدام النوع الديناميكي
    return _currentCount / requiredCount;
  }

  // =============================================
  // 🎨 STYLE HELPER METHODS - يمكن نقلها لملف themes
  // =============================================

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getBackgroundColor() {
    return isDarkModeNotifier.value ? quranPagesColorDark : quranPagesColorLight;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  TextStyle _getZikrTextStyle() {
    return TextStyle(
      color: _getTextColor(),
      locale: const Locale("ar"),
      fontWeight: FontWeight.w700,
      fontSize: 18.sp,
    );
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  TextStyle _getCounterTextStyle() {
    return TextStyle(
      color: _getCounterTextColor(),
      fontSize: 50.sp,
      fontWeight: FontWeight.bold,
      fontFamily: "roboto",
    );
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  TextStyle _getAppBarTitleStyle() {
    return TextStyle(
      fontFamily: "cairo",
      color: _getTextColor(),
      fontSize: 16.sp,
    );
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  BoxDecoration _buildCounterDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(100),
      color: _getCounterBackgroundColor(),
    );
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  BoxDecoration _buildNavigationButtonDecoration() {
    return BoxDecoration(
      color: _getCounterBackgroundColor(),
      borderRadius: BorderRadius.circular(32),
    );
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getTextColor() {
    return isDarkModeNotifier.value ? Colors.white : Colors.black;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getCounterTextColor() {
    return isDarkModeNotifier.value ? Colors.black : Colors.white;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getCounterBackgroundColor() {
    return isDarkModeNotifier.value ? Colors.white.withOpacity(.1) : Colors.black.withOpacity(.2);
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getNavigationIconColor() {
    return isDarkModeNotifier.value ? Colors.black : Colors.white;
  }

  // [CAN_BE_EXTRACTED] -> themes/app_themes.dart
  Color _getResetIconColor() {
    return isDarkModeNotifier.value ? Colors.white : Colors.black;
  }
}
