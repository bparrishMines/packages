import '../platform_interace/platform_interface.dart';
import 'android_camera_session.dart';

export 'android_camera_device.dart';
export 'android_camera_session.dart';

/// Implementation of CameraPlatform for Android.
final class CameraAndroid extends CameraPlatform {
  /// Registers this class as the default instance of [CameraPlatform].
  static void registerWith() {
    CameraPlatform.instance = CameraAndroid();
  }

  @override
  AndroidCameraSession createPlatformCameraSession(
    PlatformCameraSessionCreationParams params,
  ) {
    return AndroidCameraSession(params);
  }

  @override
  List<PlatformCameraDevice> availablePlatformCameraDevices() {
    // query for camera devices
  }
}
