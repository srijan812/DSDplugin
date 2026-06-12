import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'rilgrn_method_channel.dart';

abstract class RilgrnPlatform extends PlatformInterface {
  /// Constructs a RilgrnPlatform.
  RilgrnPlatform() : super(token: _token);

  static final Object _token = Object();

  static RilgrnPlatform _instance = MethodChannelRilgrn();

  /// The default instance of [RilgrnPlatform] to use.
  ///
  /// Defaults to [MethodChannelRilgrn].
  static RilgrnPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RilgrnPlatform] when
  /// they register themselves.
  static set instance(RilgrnPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
