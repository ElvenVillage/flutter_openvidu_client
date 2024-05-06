// ignore: avoid_web_libraries_in_flutter, library_prefixes
import 'dart:html' as HTML;

class DeviceInfo {
  static String get label {
    return 'Flutter Web';
  }

  static String get userAgent {
    return HTML.window.navigator.userAgent;
  }
}
