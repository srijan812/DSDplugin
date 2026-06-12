// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

import 'rilgrn_platform_interface.dart';

/// A web implementation of the RilgrnPlatform of the Rilgrn plugin.
class RilgrnWeb extends RilgrnPlatform {
  /// Constructs a RilgrnWeb
  RilgrnWeb();

  static void registerWith(Registrar registrar) {
    RilgrnPlatform.instance = RilgrnWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Future<List<String>?> scanDocument() async {
    // Fallback for Web platform since it lacks native Document Scanner
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      return [pickedFile.path];
    }
    return null;
  }
}
