import 'package:flutter/material.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class MacId extends StatefulWidget {
  const MacId({super.key});

  @override
  _MacIdState createState() => _MacIdState();
}

class _MacIdState extends State<MacId> {
  String _macAddress = 'Reload';

  Future<String?> getUniqueDeviceId() async {
    String _devInfo = "";

    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _devInfo = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _devInfo = iosInfo.identifierForVendor ?? "No information available";
      }
    } on PlatformException {
      debugPrint("Failed to get device info:");
    }
    return _devInfo;
  }

  Future<void> getDeviceMacAddress() async {
    String? deviceId = await getUniqueDeviceId();
    setState(() {
      _macAddress = deviceId ?? 'Failed to get Device ID';
      debugPrint('Device ID: $_macAddress');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(10),
      child: ElevatedButton(
          onPressed: getDeviceMacAddress,
          child: Text(_macAddress)
      ),
    );
  }
}
