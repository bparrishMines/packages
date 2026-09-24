// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';

import 'file_selector_api.g.dart';
import 'types/native_illegal_argument_exception.dart';

/// An implementation of [FileSelectorPlatform] for Android.
base class FileSelectorAndroid extends FileSelectorPlatform {
  FileSelectorAndroid({@visibleForTesting FileSelectorApi? api}) : _api = api ?? FileSelectorApi();

  final FileSelectorApi _api;

  /// Registers this class as the implementation of the file_selector platform interface.
  static void registerWith() {
    FileSelectorPlatform.instance = FileSelectorAndroid();
  }

  @override
  Future<XFile?> openFile([OpenDialogOptions options = const OpenDialogOptions()]) async {
    final FileResponse? file = await _api.openFile(
      options.initialDirectory,
      _fileTypesFromTypeGroups(options.acceptedTypeGroups),
    );
    return file == null ? null : _xFileFromFileResponse(file);
  }

  @override
  Future<List<XFile>> openFiles([OpenDialogOptions options = const OpenDialogOptions()]) async {
    final List<FileResponse> files = await _api.openFiles(
      options.initialDirectory,
      _fileTypesFromTypeGroups(options.acceptedTypeGroups),
    );
    return files.map<XFile>(_xFileFromFileResponse).toList();
  }

  @override
  Future<String?> getDirectoryPath([FileDialogOptions options = const FileDialogOptions()]) async {
    return _api.getDirectoryPath(options.initialDirectory);
  }

  XFile _xFileFromFileResponse(FileResponse file) {
    if (file.fileSelectorNativeException != null) {
      _resolveErrorCodeAndMaybeThrow(file.fileSelectorNativeException!);
    }
    return XFile.fileSystem(path: file.path);
    // return XFile.fromData(
    //   file.bytes,
    //   // Note: The name parameter is not used by XFile. The XFile.name returns
    //   // the extracted file name from XFile.path.
    //   name: file.name,
    //   length: file.size,
    //   mimeType: file.mimeType,
    //   path: file.path,
    // );
  }

  FileTypes _fileTypesFromTypeGroups(List<XTypeGroup>? typeGroups) {
    if (typeGroups == null) {
      return FileTypes(extensions: <String>[], mimeTypes: <String>[]);
    }

    final mimeTypes = <String>{};
    final extensions = <String>{};

    for (final XTypeGroup group in typeGroups) {
      if (!group.allowsAny && group.mimeTypes == null && group.extensions == null) {
        throw ArgumentError(
          'Provided type group $group does not allow all files, but does not '
          'set any of the Android supported filter categories. At least one of '
          '"extensions" or "mimeTypes" must be non-empty for Android.',
        );
      }

      mimeTypes.addAll(group.mimeTypes ?? <String>{});
      extensions.addAll(group.extensions ?? <String>{});
    }

    return FileTypes(mimeTypes: mimeTypes.toList(), extensions: extensions.toList());
  }

  /// Translates a [FileSelectorExceptionCode] to its corresponding error and
  /// handles throwing.
  void _resolveErrorCodeAndMaybeThrow(FileSelectorNativeException fileSelectorNativeException) {
    switch (fileSelectorNativeException.fileSelectorExceptionCode) {
      case FileSelectorExceptionCode.illegalArgumentException:
        throw NativeIllegalArgumentException(fileSelectorNativeException.message);
      case (FileSelectorExceptionCode.illegalStateException ||
          FileSelectorExceptionCode.ioException ||
          FileSelectorExceptionCode.securityException):
      // unused for now
    }
  }
}
