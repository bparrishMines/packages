import 'package:flutter/foundation.dart';

import 'platform_interace/platform_interface.dart';

@immutable
class CameraDevice {
  const CameraDevice.fromPlatform(this.platform);

  final PlatformCameraDevice platform;

  CameraFacing get facing => platform.facing;

  T getPlatformExtension<T extends PlatformCameraDeviceExtension>() {
    return platform.extension! as T;
  }

  T? maybeGetPlatformExtension<T extends PlatformCameraDeviceExtension>() {
    return platform.extension is T ? platform.extension! as T : null;
  }

  @override
  bool operator ==(Object other) =>
      other is CameraDevice && other.platform == platform;

  @override
  int get hashCode => platform.hashCode;
}
