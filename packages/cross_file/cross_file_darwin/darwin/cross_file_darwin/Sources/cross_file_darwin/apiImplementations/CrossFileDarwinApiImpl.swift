// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Photos

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#else
  #error("Unsupported platform.")
#endif

/// Implementation of `CrossFileDarwinApi`.
class CrossFileDarwinApiImpl: CrossFileDarwinApi {
  func startAccessingSecurityScopedResource(url: String) throws -> Bool {
    return URL(string: url)!.startAccessingSecurityScopedResource()
  }

  func stopAccessingSecurityScopedResource(url: String) throws {
    URL(string: url)!.stopAccessingSecurityScopedResource()
  }

  func isReadableFile(url: String) throws -> Bool {
    return FileManager.default.isReadableFile(atPath: URL(string: url)!.path)
  }

  func lastModified(identifier: String, completion: @escaping (Result<Int64?, any Error>) -> Void) {
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
    if let asset = fetchResult.firstObject {
      if let modificationDate = asset.modificationDate {
        completion(.success(Int64(modificationDate.timeIntervalSince1970 * 1000.0)))
      } else {
        completion(.success(nil))
      }
    } else {
      completion(.success(nil))
    }
  }

  func readAsBytes(
    identifier: String, completion: @escaping (Result<FlutterStandardTypedData, any Error>) -> Void
  ) {
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
    if let asset = fetchResult.firstObject {
      // 3. Request the actual image data from the asset
      let manager = PHImageManager.default()
      let options = PHImageRequestOptions()
      options.isNetworkAccessAllowed = true  // In case it's stored in iCloud

      manager.requestImageDataAndOrientation(
        for: asset, options: options,
      ) { imageData, dataUTI, orientation, info in

        if let imageData = imageData {
          completion(.success(FlutterStandardTypedData(bytes: imageData)))
        } else {
          completion(.failure(NSError()))
        }
      }
    } else {
      completion(.failure(NSError()))
    }
  }

  func name(identifier: String, completion: @escaping (Result<String?, any Error>) -> Void) {
    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
    if let asset = fetchResult.firstObject {
      let resources = PHAssetResource.assetResources(for: asset)
      completion(.success(resources.first!.originalFilename))
    } else {
      completion(.success(nil))
    }
  }
}
