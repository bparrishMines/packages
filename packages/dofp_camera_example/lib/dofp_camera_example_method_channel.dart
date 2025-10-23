import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dofp_camera_example_platform_interface.dart';

/// An implementation of [DofpCameraExamplePlatform] that uses method channels.
class MethodChannelDofpCameraExample extends DofpCameraExamplePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('dofp_camera_example');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
