import 'dart:io';

class DeviceInfo {
  static String get label {
    return '${Platform.operatingSystem} - ${Platform.localHostname}';
  }

  static String get userAgent {
    return Platform.operatingSystem;
  }
}
