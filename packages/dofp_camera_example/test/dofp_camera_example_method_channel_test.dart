import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dofp_camera_example/dofp_camera_example_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelDofpCameraExample platform = MethodChannelDofpCameraExample();
  const MethodChannel channel = MethodChannel('dofp_camera_example');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
