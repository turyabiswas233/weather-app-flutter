import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/const_style.dart';

ThemeData appTheme() {
  return ThemeData(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(color: ConstColors.grad1),
      foregroundColor: ConstColors.fColor,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    fontFamily: GoogleFonts.poppins().fontFamily,
    fontFamilyFallback: GoogleFonts.poppins().fontFamilyFallback,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ConstColors.fColor,
    ),
  );
}
