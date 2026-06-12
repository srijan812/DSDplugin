import 'package:flutter_test/flutter_test.dart';
import 'package:rilgrn/rilgrn.dart';
import 'package:rilgrn/rilgrn_platform_interface.dart';
import 'package:rilgrn/rilgrn_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRilgrnPlatform
    with MockPlatformInterfaceMixin
    implements RilgrnPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final RilgrnPlatform initialPlatform = RilgrnPlatform.instance;

  test('$MethodChannelRilgrn is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRilgrn>());
  });

  test('getPlatformVersion', () async {
    Rilgrn rilgrnPlugin = Rilgrn();
    MockRilgrnPlatform fakePlatform = MockRilgrnPlatform();
    RilgrnPlatform.instance = fakePlatform;

    expect(await rilgrnPlugin.getPlatformVersion(), '42');
  });
}
