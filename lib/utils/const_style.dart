import 'package:flutter/material.dart';

class ConstColors {
  ConstColors._();

  static const Color fColor = Color.fromARGB(189, 255, 255, 255);
  static const bColor = Color.fromARGB(237, 2, 13, 30);

  // gradient colors grad
  static const grad1 = Color.fromARGB(249, 4, 81, 53);
  static const grad2 = Color.fromARGB(181, 10, 151, 89);
  static const grad3 = Color.fromARGB(181, 2, 246, 124);

  static const bColorTitle = grad1;
  static const loadingColor = Color.fromARGB(249, 205, 229, 255);

  // input field
  static const Color boxColor = Color.fromARGB(184, 1, 3, 35);
  static const Color textColor = Color.fromARGB(255, 200, 210, 234);

  //error code
  static const Color errorFg = Color.fromARGB(255, 255, 67, 67);
  static const Color errorBg = Color.fromARGB(255, 255, 231, 228);
}

class ConstSizes {
  ConstSizes._();

  // Use static const so values are available at compile-time and
  // can be referenced publicly as `ConstSizes.xs` etc.
  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 18.0;
  static const double lg = 24.0;
  static const double xl = 30.0;
}


class ConstPadding {
  ConstPadding._();
  // Padding values as static const so they are accessible via
  // `ConstPadding.xs` etc.
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
}