import 'package:flutter/material.dart';

import 'build_widget_params.dart';
import 'camera_platform.dart';
import 'platform_camera_device.dart';

/// Object specifying creation parameters for creating a [PlatformCameraSession].
@immutable
base class PlatformCameraSessionCreationParams {
  /// Used by the platform implementation to create a new [PlatformCameraSession].
  const PlatformCameraSessionCreationParams({
    required this.device,
    this.onCameraClosed,
  });

  /// Called when the battery state changes.
  final PlatformCameraDevice device;

  final void Function()? onCameraClosed;
}

/// Mixin for a platform implementation of a PlatformCameraSession to expose
/// additional features.
mixin PlatformCameraSessionExtension {}

/// Interface for a platform implementation of a class that provides access
/// to battery information.
abstract base class PlatformCameraSession {
  /// Creates a new [PlatformCameraSession]
  factory PlatformCameraSession(PlatformCameraSessionCreationParams params) {
    assert(
      CameraPlatform.instance != null,
      'A platform implementation for `camera` has not been set. '
      'Please ensure that an implementation of `CameraPlatform` '
      'has been set to `CameraPlatform.instance` before use. For '
      'unit testing, `CameraPlatform.instance` can be set with '
      'your own test implementation.',
    );
    final PlatformCameraSession implementation = CameraPlatform.instance!
        .createPlatformCameraSession(params);
    return implementation;
  }

  /// Used by the platform implementation to create a new [PlatformCameraSession].
  ///
  /// Should only be used by platform implementations because they can't extend
  /// a class that only contains a factory constructor.
  @protected
  PlatformCameraSession.implementation(this.params);

  /// The parameters used to initialize the [PlatformCameraSession].
  final PlatformCameraSessionCreationParams params;

  /// Provides access to an implementation platform extension mixin.
  ///
  /// Used by the platform implementation to select which methods to expose when adding
  /// platform-specific features.
  PlatformCameraSessionExtension? get extension => null;

  /// Start the flow of data through the pipeline.
  Future<void> start();

  Future<void> takePicture(TakePictureParams params);

  /// Stop the flow of data through the pipeline.
  Future<void> stop();

  Future<void> setZoomRatio(double ratio) {
    throw UnimplementedError(
      'setZoomRatio is not implemented on the current platform',
    );
  }

  Future<void> supportsSetZoomRatio() async => false;

  Widget buildPreviewWidget(BuildWidgetParams params);
}

@immutable
base class TakePictureParams {
  const TakePictureParams({required this.filename});

  final String filename;
}
