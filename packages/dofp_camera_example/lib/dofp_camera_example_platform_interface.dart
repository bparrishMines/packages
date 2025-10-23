import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'dofp_camera_example_method_channel.dart';

abstract class DofpCameraExamplePlatform extends PlatformInterface {
  /// Constructs a DofpCameraExamplePlatform.
  DofpCameraExamplePlatform() : super(token: _token);

  static final Object _token = Object();

  static DofpCameraExamplePlatform _instance = MethodChannelDofpCameraExample();

  /// The default instance of [DofpCameraExamplePlatform] to use.
  ///
  /// Defaults to [MethodChannelDofpCameraExample].
  static DofpCameraExamplePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DofpCameraExamplePlatform] when
  /// they register themselves.
  static set instance(DofpCameraExamplePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
