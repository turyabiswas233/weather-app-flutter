import 'package:flutter/material.dart';
import 'theme.dart';
import 'weather_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: appTheme(),
      home: WeatherScreen(),
    );
  }
}