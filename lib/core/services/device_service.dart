import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DeviceService {
  const DeviceService();

  Future<String> getDeviceId() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return _hash(
        'android:${info.brand}:${info.model}:${info.id}:${info.fingerprint}',
      );
    }
    if (Platform.isWindows) {
      final info = await plugin.windowsInfo;
      return _hash(
        'windows:${info.computerName}:${info.numberOfCores}:${info.systemMemoryInMegabytes}',
      );
    }
    return _hash('unknown-device');
  }

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();
}
