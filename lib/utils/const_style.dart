import 'package:flutter/material.dart';

class ConstColors {
  ConstColors._();

  static const Color fColor =Color.fromARGB(250,255,255,255);
  static const Color bColor =  Color.fromARGB(255, 2, 13, 30);

  // gradient colors grad
  static const Color grad1 = Color.fromARGB(240, 42, 51, 69);
  static const Color grad2 = Color.fromARGB(255, 22, 22, 34);
  static const Color grad3 = Color.fromARGB(255, 7, 7, 9);

  static const Color bColorTitle = fColor;
  static const Color loadingColor =  Color.fromARGB(255, 41, 106, 227);

  //error code
  static const Color errorFg = Color.fromARGB(255, 224, 224, 255);
  static const Color errorBg = Color.fromARGB(202, 253, 63, 98);
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