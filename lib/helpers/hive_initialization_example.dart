// 📦 hive_initialization_example.dart
// ملف مثال لتهيئة القيم الافتراضية في Hive

import 'package:hive/hive.dart';

/// ⚙️ تهيئة القيم الافتراضية للإشعارات الجديدة
///
/// يجب استدعاء هذه الدالة عند بدء التطبيق لأول مرة
/// أو في ملف main.dart بعد تهيئة Hive
Future<void> initializeNotificationDefaults() async {
  final box = await Hive.openBox('settings'); // أو اسم الـ box المستخدم

  // ========================================
  // 1️⃣ الصلاة على النبي (محدث)
  // ========================================

  // إذا لم يكن موجود، ضع القيمة الافتراضية
  if (!box.containsKey('shouldShowSallyNotification')) {
    await box.put('shouldShowSallyNotification', false);
  }

  // ⭐ جديد: تردد إشعار الصلاة على النبي
  if (!box.containsKey('timesForShowingSallyNotifications')) {
    await box.put('timesForShowingSallyNotifications', 3); // 3 = ساعة واحدة
  }

  // ========================================
  // 2️⃣ الورد القرآني اليومي
  // ========================================

  if (!box.containsKey('shouldShowQuranDailyReading')) {
    await box.put('shouldShowQuranDailyReading', false);
  }

  if (!box.containsKey('quranDailyReadingTime')) {
    await box.put('quranDailyReadingTime', '08:00'); // 8 صباحاً
  }

  // ========================================
  // 3️⃣ أذكار الصباح
  // ========================================

  if (!box.containsKey('shouldShowMorningAzkar')) {
    await box.put('shouldShowMorningAzkar', false);
  }

  if (!box.containsKey('morningAzkarTime')) {
    await box.put('morningAzkarTime', '06:00'); // 6 صباحاً
  }

  // ========================================
  // 4️⃣ أذكار المساء
  // ========================================

  if (!box.containsKey('shouldShowEveningAzkar')) {
    await box.put('shouldShowEveningAzkar', false);
  }

  if (!box.containsKey('eveningAzkarTime')) {
    await box.put('eveningAzkarTime', '18:00'); // 6 مساءً
  }

  print('✅ تم تهيئة القيم الافتراضية للإشعارات الجديدة');
}

/// 📝 مثال على كيفية الاستخدام في main.dart:
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // تهيئة Hive
///   await Hive.initFlutter();
///   await Hive.openBox('settings');
///
///   // تهيئة القيم الافتراضية للإشعارات
///   await initializeNotificationDefaults();
///
///   runApp(MyApp());
/// }
/// ```

// ========================================
// 🔧 دوال مساعدة للوصول للقيم
// ========================================

/// الحصول على قيمة من Hive مع قيمة افتراضية
T getValueWithDefault<T>(String key, T defaultValue) {
  final box = Hive.box('settings');
  return box.get(key, defaultValue: defaultValue) as T;
}

/// مثال على الاستخدام:
/// ```dart
/// bool isEnabled = getValueWithDefault('shouldShowQuranDailyReading', false);
/// String time = getValueWithDefault('quranDailyReadingTime', '08:00');
/// int frequency = getValueWithDefault('timesForShowingSallyNotifications', 3);
/// ```

// ========================================
// 📊 دالة لطباعة جميع إعدادات الإشعارات
// ========================================

void printAllNotificationSettings() {
  final box = Hive.box('settings');

  print('📱 إعدادات الإشعارات الحالية:');
  print('─' * 50);

  // الصلاة على النبي
  print('🕌 الصلاة على النبي:');
  print('   مفعّل: ${box.get('shouldShowSallyNotification')}');
  print('   التردد: ${box.get('timesForShowingSallyNotifications')}');

  // الورد القرآني
  print('\n📖 الورد القرآني:');
  print('   مفعّل: ${box.get('shouldShowQuranDailyReading')}');
  print('   الوقت: ${box.get('quranDailyReadingTime')}');

  // أذكار الصباح
  print('\n🌅 أذكار الصباح:');
  print('   مفعّل: ${box.get('shouldShowMorningAzkar')}');
  print('   الوقت: ${box.get('morningAzkarTime')}');

  // أذكار المساء
  print('\n🌙 أذكار المساء:');
  print('   مفعّل: ${box.get('shouldShowEveningAzkar')}');
  print('   الوقت: ${box.get('eveningAzkarTime')}');

  print('─' * 50);
}

// ========================================
// 🔄 دالة لإعادة تعيين جميع الإعدادات
// ========================================

Future<void> resetAllNotificationSettings() async {
  final box = Hive.box('settings');

  await box.put('shouldShowSallyNotification', false);
  await box.put('timesForShowingSallyNotifications', 3);
  await box.put('shouldShowQuranDailyReading', false);
  await box.put('quranDailyReadingTime', '08:00');
  await box.put('shouldShowMorningAzkar', false);
  await box.put('morningAzkarTime', '06:00');
  await box.put('shouldShowEveningAzkar', false);
  await box.put('eveningAzkarTime', '18:00');

  print('🔄 تم إعادة تعيين جميع إعدادات الإشعارات للقيم الافتراضية');
}

// ========================================
// 📋 جدول مرجعي للمفاتيح المستخدمة
// ========================================

/// **جدول المفاتيح (Keys) والقيم الافتراضية:**
///
/// | المفتاح (Key)                         | النوع    | القيمة الافتراضية | الوصف                           |
/// |---------------------------------------|----------|-------------------|---------------------------------|
/// | shouldShowSallyNotification           | bool     | false             | تفعيل الصلاة على النبي         |
/// | timesForShowingSallyNotifications     | int      | 3                 | تردد الصلاة على النبي (ساعة)   |
/// | shouldShowQuranDailyReading           | bool     | false             | تفعيل الورد القرآني            |
/// | quranDailyReadingTime                 | String   | "08:00"           | وقت الورد القرآني              |
/// | shouldShowMorningAzkar                | bool     | false             | تفعيل أذكار الصباح             |
/// | morningAzkarTime                      | String   | "06:00"           | وقت أذكار الصباح               |
/// | shouldShowEveningAzkar                | bool     | false             | تفعيل أذكار المساء             |
/// | eveningAzkarTime                      | String   | "18:00"           | وقت أذكار المساء               |

// ========================================
// 🎯 مثال شامل للاستخدام
// ========================================

class NotificationSettingsExample {
  final Box settingsBox = Hive.box('settings');

  // الحصول على حالة الورد القرآني
  bool get isQuranDailyReadingEnabled {
    return settingsBox.get('shouldShowQuranDailyReading', defaultValue: false);
  }

  // تعيين حالة الورد القرآني
  Future<void> setQuranDailyReadingEnabled(bool value) async {
    await settingsBox.put('shouldShowQuranDailyReading', value);
  }

  // الحصول على وقت الورد القرآني
  String get quranDailyReadingTime {
    return settingsBox.get('quranDailyReadingTime', defaultValue: '08:00');
  }

  // تعيين وقت الورد القرآني
  Future<void> setQuranDailyReadingTime(String time) async {
    await settingsBox.put('quranDailyReadingTime', time);
  }

  // مثال على الاستخدام في Widget:
  /*
  void toggleQuranReading() async {
    final settings = NotificationSettingsExample();
    await settings.setQuranDailyReadingEnabled(!settings.isQuranDailyReadingEnabled);
  }
  */
}
