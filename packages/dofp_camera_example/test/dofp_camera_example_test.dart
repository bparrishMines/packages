import 'package:flutter_test/flutter_test.dart';
import 'package:dofp_camera_example/dofp_camera_example.dart';
import 'package:dofp_camera_example/dofp_camera_example_platform_interface.dart';
import 'package:dofp_camera_example/dofp_camera_example_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDofpCameraExamplePlatform
    with MockPlatformInterfaceMixin
    implements DofpCameraExamplePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DofpCameraExamplePlatform initialPlatform = DofpCameraExamplePlatform.instance;

  test('$MethodChannelDofpCameraExample is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDofpCameraExample>());
  });

  test('getPlatformVersion', () async {
    DofpCameraExample dofpCameraExamplePlugin = DofpCameraExample();
    MockDofpCameraExamplePlatform fakePlatform = MockDofpCameraExamplePlatform();
    DofpCameraExamplePlatform.instance = fakePlatform;

    expect(await dofpCameraExamplePlugin.getPlatformVersion(), '42');
  });
}
