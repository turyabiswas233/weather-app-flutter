import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme.dart';
import 'weather_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await permissionHandler();
  runApp(MyApp());
}

Future<void> permissionHandler() async {
  if (Platform.isAndroid) {
    final locStatus = await Permission.location.request();
    if (locStatus.isGranted) {
      debugPrint('Location Only When in Use is granted');
    } else {
      debugPrint('No permission for location is granted');
    }
  }
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
