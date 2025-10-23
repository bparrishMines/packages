import '../platform_interace/platform_interface.dart';

/// Implementation of [PlatformCameraDeviceExtension] for Android.
mixin AndroidCameraDeviceExtension implements PlatformCameraDeviceExtension {
  int get sensorRotationDegrees;
}

/// Implementation of [PlatformCameraDevice] for Android.
final class AndroidCameraDevice extends PlatformCameraDevice
    with AndroidCameraDeviceExtension {
  AndroidCameraDevice({
    required super.facing,
    required this.sensorRotationDegrees,
  });

  @override
  AndroidCameraDeviceExtension get extension => this;

  /// The sensor rotation in degrees, relative to the device's "natural"
  /// (default) orientation.
  @override
  final int sensorRotationDegrees;
}
