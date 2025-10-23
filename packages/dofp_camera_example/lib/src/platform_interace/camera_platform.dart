import 'platform_camera_device.dart';
import 'platform_camera_session.dart';

abstract base class CameraPlatform {
  /// The instance of [CameraPlatform] to use.
  ///
  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [CameraPlatform] when they register
  /// themselves.
  static CameraPlatform? instance;

  /// Creates a new [PlatformCameraSession].
  PlatformCameraSession createPlatformCameraSession(
    PlatformCameraSessionCreationParams params,
  );

  List<PlatformCameraDevice> availablePlatformCameraDevices();
}
