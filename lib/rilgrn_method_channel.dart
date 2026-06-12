import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  Future<List<String>?> scanDocument() async {
    try {
      final result = await methodChannel.invokeListMethod<String>('scanDocument');
      return result;
    } on MissingPluginException {
      // Fallback for desktop platforms missing a native scanner implementation
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        return [pickedFile.path];
      }
      return null;
    }
  }
}
