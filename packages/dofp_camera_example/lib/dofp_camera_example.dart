
import 'dofp_camera_example_platform_interface.dart';

class DofpCameraExample {
  Future<String?> getPlatformVersion() {
    return DofpCameraExamplePlatform.instance.getPlatformVersion();
  }
}
