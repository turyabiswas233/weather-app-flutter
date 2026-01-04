import 'dart:io';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme.dart';
import 'location_manager_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void splashScreen() async {
    debugPrint('ready in 3...');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('ready in 2...');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('ready in 1...');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('go!');
    FlutterNativeSplash.remove();
    await permissionHandler();
  }

  @override
  void initState() {
    super.initState();
    splashScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TB Weather',
      theme: appTheme(),
      home: const LocationManagerScreen(),
    );
  }
}
