import 'camera_device.dart';
import 'platform_interace/platform_interface.dart';

class Camera {
  static List<CameraDevice> availableCameraDevices() {
    assert(
      CameraPlatform.instance != null,
      'A platform implementation for `camera` has not been set. '
      'Please ensure that an implementation of `CameraPlatform` '
      'has been set to `CameraPlatform.instance` before use. For '
      'unit testing, `CameraPlatform.instance` can be set with '
      'your own test implementation.',
    );
    return CameraPlatform.instance!
        .availablePlatformCameraDevices()
        .map(
          (PlatformCameraDevice platform) =>
              CameraDevice.fromPlatform(platform),
        )
        .toList();
  }
}
