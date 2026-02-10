// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';

import 'file_selector_api.g.dart';

/// An implementation of [FileSelectorPlatform] for Android.
class FileSelectorAndroid extends FileSelectorPlatform {
  FileSelectorAndroid({@visibleForTesting FileSelectorApi? api})
    : _api = api ?? FileSelectorApi();

  final FileSelectorApi _api;

  /// Registers this class as the implementation of the file_selector platform interface.
  static void registerWith() {
    FileSelectorPlatform.instance = FileSelectorAndroid();
  }

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final String? path = await _api.openFile(
      initialDirectory,
      _fileTypesFromTypeGroups(acceptedTypeGroups),
    );

    if (path case final String path) {
      return ScopedStorageXFile(path);
    }

    return null;
  }

  @override
  Future<List<XFile>> openFiles({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final List<String> files = await _api.openFiles(
      initialDirectory,
      _fileTypesFromTypeGroups(acceptedTypeGroups),
    );
    return files.map<XFile>(ScopedStorageXFile.new).toList();
  }

  @override
  Future<XDirectory?> getDirectoryPath({
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    final String? uri = await _api.getDirectoryPath(initialDirectory);
    if (uri != null) {
      return ScopedStorageXDirectory(uri);
    } else {
      return null;
    }
  }

  FileTypes _fileTypesFromTypeGroups(List<XTypeGroup>? typeGroups) {
    if (typeGroups == null) {
      return FileTypes(extensions: <String>[], mimeTypes: <String>[]);
    }

    final mimeTypes = <String>{};
    final extensions = <String>{};

    for (final XTypeGroup group in typeGroups) {
      if (!group.allowsAny &&
          group.mimeTypes == null &&
          group.extensions == null) {
        throw ArgumentError(
          'Provided type group $group does not allow all files, but does not '
          'set any of the Android supported filter categories. At least one of '
          '"extensions" or "mimeTypes" must be non-empty for Android.',
        );
      }

      mimeTypes.addAll(group.mimeTypes ?? <String>{});
      extensions.addAll(group.extensions ?? <String>{});
    }

    return FileTypes(
      mimeTypes: mimeTypes.toList(),
      extensions: extensions.toList(),
    );
  }
}
