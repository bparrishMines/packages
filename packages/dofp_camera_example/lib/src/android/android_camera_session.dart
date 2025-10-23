import 'package:flutter/widgets.dart';

import '../platform_interace/platform_interface.dart';

/// Implementation of [PlatformCameraSessionCreationParams] for Android.
@immutable
final class AndroidCameraSessionCreationParams
    extends PlatformCameraSessionCreationParams {
  const AndroidCameraSessionCreationParams({
    required super.device,
    super.onCameraClosed,
    this.androidSpecificFlag,
  });

  factory AndroidCameraSessionCreationParams.fromCreationParams(
    PlatformCameraSessionCreationParams params, {
    Object? androidSpecificFlag,
  }) {
    return AndroidCameraSessionCreationParams(
      device: params.device,
      onCameraClosed: params.onCameraClosed,
      androidSpecificFlag: androidSpecificFlag,
    );
  }

  final Object? androidSpecificFlag;
}

/// Implementation of [PlatformCameraSessionExtension] for Android.
mixin AndroidCameraSessionExtension implements PlatformCameraSessionExtension {
  Future<void> androidSpecificMethod();
}

/// Implementation of [PlatformCameraSession] for Android.
final class AndroidCameraSession extends PlatformCameraSession
    with AndroidCameraSessionExtension {
  AndroidCameraSession(super.params) : super.implementation();

  @override
  AndroidCameraSessionExtension get extension => this;

  @override
  Future<void> start() async {
    // start camera
  }

  @override
  Future<void> stop() async {
    // stop camera
  }

  @override
  Future<void> takePicture(TakePictureParams params) async {
    // take picture
  }

  @override
  Future<void> setZoomRatio(double ratio) async {
    // set zoom ratio if [supportsSetZoomRatio] returns true
  }

  @override
  Future<void> supportsSetZoomRatio() async {
    // check if zoom is supported on device
  }

  // Additional method required from [AndroidCameraSessionExtension].
  @override
  Future<void> androidSpecificMethod() async {
    //...
  }

  @override
  Widget buildPreviewWidget(BuildWidgetParams params) {
    return AndroidView(
      //...
    );
  }
}
