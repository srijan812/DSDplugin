import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'rilgrn_platform_interface.dart';

/// An implementation of [RilgrnPlatform] that uses method channels.
class MethodChannelRilgrn extends RilgrnPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('rilgrn');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
