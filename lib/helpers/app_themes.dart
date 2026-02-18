// [CAN_BE_EXTRACTED] -> themes/app_themes.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

ThemeData buildTheme(BuildContext context, bool isDark, String fontType) {
  final fontFamily = _getFontFamily(context, fontType);

  return isDark
      ? ThemeData.dark().copyWith(
          primaryColor: Colors.blue,
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: fontFamily),
          primaryTextTheme: ThemeData.dark().primaryTextTheme.apply(fontFamily: fontFamily),
        )
      : ThemeData.light().copyWith(
          primaryColor: Colors.blue,
          textTheme: ThemeData.light().textTheme.apply(fontFamily: fontFamily),
          primaryTextTheme: ThemeData.light().primaryTextTheme.apply(fontFamily: fontFamily),
        );
}

// [CAN_BE_EXTRACTED] -> themes/app_themes.dart
String? _getFontFamily(BuildContext context, String fontType) {
  if (fontType == "device") return null;
  return context.locale.languageCode == "ar" ? "cairo" : "roboto";
}
