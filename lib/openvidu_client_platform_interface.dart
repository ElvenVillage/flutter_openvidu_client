import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'openvidu_client_method_channel.dart';

abstract class OpenviduClientPlatform extends PlatformInterface {
  /// Constructs a OpenviduClientPlatform.
  OpenviduClientPlatform() : super(token: _token);

  static final Object _token = Object();

  static OpenviduClientPlatform _instance = MethodChannelOpenviduClient();

  /// The default instance of [OpenviduClientPlatform] to use.
  ///
  /// Defaults to [MethodChannelOpenviduClient].
  static OpenviduClientPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OpenviduClientPlatform] when
  /// they register themselves.
  static set instance(OpenviduClientPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
