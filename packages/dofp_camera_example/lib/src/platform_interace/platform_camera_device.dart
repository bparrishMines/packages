import 'package:flutter/foundation.dart';

import 'camera_facing.dart';

mixin PlatformCameraDeviceExtension {}

base class PlatformCameraDevice {
  @protected
  PlatformCameraDevice({required this.facing});

  final CameraFacing facing;

  PlatformCameraDeviceExtension? get extension => null;
}
