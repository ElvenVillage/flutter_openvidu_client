import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'openvidu_client_platform_interface.dart';

/// An implementation of [OpenviduClientPlatform] that uses method channels.
class MethodChannelOpenviduClient extends OpenviduClientPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('openvidu_client');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
