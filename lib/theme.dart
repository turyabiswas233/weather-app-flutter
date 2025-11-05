import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils/const_style.dart';

ThemeData appTheme() {
  return ThemeData(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      foregroundColor: ConstColors.fColor,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ConstColors.fColor,
    ),
  );
}
