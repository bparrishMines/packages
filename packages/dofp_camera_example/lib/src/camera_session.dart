import 'package:flutter/widgets.dart';

import 'camera_device.dart';
import 'platform_interace/platform_interface.dart';

@immutable
class CameraSession {
  CameraSession({required CameraDevice device})
    : this.fromPlatformCreationParams(
        PlatformCameraSessionCreationParams(device: device.platform),
      );

  CameraSession.fromPlatformCreationParams(
    PlatformCameraSessionCreationParams params,
  ) : this.fromPlatform(PlatformCameraSession(params));

  const CameraSession.fromPlatform(this.platform);

  final PlatformCameraSession platform;

  CameraDevice get device => CameraDevice.fromPlatform(platform.params.device);

  /// Provides a nonnull platform class extension.
  ///
  /// Will throw an exception if the specified platform extension can not be
  /// returned.
  T getPlatformExtension<T extends PlatformCameraSessionExtension>() {
    return platform.extension! as T;
  }

  /// Attempt to provide the platform class extension.
  ///
  /// Returns null if the specified platform extension cannot be retrieved.
  T? maybeGetPlatformExtension<T extends PlatformCameraSessionExtension>() {
    return platform.extension is T ? platform.extension! as T : null;
  }

  Future<void> start() => platform.start();

  Future<void> takePicture(String filename) =>
      platform.takePicture(TakePictureParams(filename: filename));

  Future<void> setZoomRatio(double ratio) => platform.setZoomRatio(ratio);

  Future<void> supportsSetZoomRatio() => platform.supportsSetZoomRatio();

  Future<void> stop() => platform.stop();

  Widget buildPreviewWidget(BuildContext context) =>
      platform.buildPreviewWidget(BuildWidgetParams(context: context));

  @override
  bool operator ==(Object other) =>
      other is CameraSession && other.platform == platform;

  @override
  int get hashCode => platform.hashCode;
}
