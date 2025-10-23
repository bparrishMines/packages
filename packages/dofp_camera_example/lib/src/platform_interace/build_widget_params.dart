import 'package:flutter/material.dart';

/// Object specifying creation parameters for creating a native view.
@immutable
base class BuildWidgetParams {
  /// Used by the platform implementation to create a new
  /// [BuildWidgetParams].
  const BuildWidgetParams({
    this.key,
    required this.context,
    this.layoutDirection = TextDirection.ltr,
  });

  /// The [Key] passed to a Widget that represents the native view.
  ///
  /// See also:
  ///  * The discussions at [Key] and [GlobalKey].
  final Key? key;

  /// A handle to the location of a widget in the widget tree.
  final BuildContext context;

  /// The layout direction to use for the native view.
  final TextDirection layoutDirection;
}
