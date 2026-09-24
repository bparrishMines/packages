// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/*
 * Copyright (C) 2007-2008 OpenIntents.org
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * This file was modified by the Flutter authors from the following original file:
 * https://raw.githubusercontent.com/iPaulPro/aFileChooser/master/aFileChooser/src/com/ipaulpro/afilechooser/utils/FileUtils.java
 */

package dev.flutter.packages.file_selector_android;

import android.content.Context;
import android.net.Uri;
import android.os.Environment;
import android.provider.DocumentsContract;
import androidx.annotation.NonNull;

public class FileUtils {

  /** URI authority that represents access to external storage providers. */
  public static final String EXTERNAL_DOCUMENT_AUTHORITY = "com.android.externalstorage.documents";

  /**
   * Retrieves path of directory represented by the specified {@code Uri}.
   *
   * <p>Intended to handle any cases needed to return paths from URIs retrieved from open
   * documents/directories by starting one of {@code Intent.ACTION_OPEN_FILE}, {@code
   * Intent.ACTION_OPEN_FILES}, or {@code Intent.ACTION_OPEN_DOCUMENT_TREE}.
   *
   * <p>Will return the path for on-device directories, but does not handle external storage
   * volumes.
   */
  @NonNull
  public static String getPathFromUri(@NonNull Context context, @NonNull Uri uri) {
    String uriAuthority = uri.getAuthority();

    if (EXTERNAL_DOCUMENT_AUTHORITY.equals(uriAuthority)) {
      String uriDocumentId = DocumentsContract.getDocumentId(uri);
      String[] uriDocumentIdSplit = uriDocumentId.split(":");

      if (uriDocumentIdSplit.length < 2) {
        // We expect the URI document ID to contain its storage volume and name to
        // determine its path.
        throw new UnsupportedOperationException(
            "Retrieving the path of a document with an unknown storage volume or name is"
                + " unsupported by this plugin.");
      }

      String documentStorageVolume = uriDocumentIdSplit[0];

      // Non-primary storage volumes come from SD cards, USB drives, etc. and are
      // not handled here.
      //
      // Constant for primary storage volumes found at
      // https://cs.android.com/android/platform/superproject/main/+/main:frameworks/base/core/java/android/provider/DocumentsContract.java;l=255?q=Documentscont&ss=android%2Fplatform%2Fsuperproject%2Fmain.
      if (!documentStorageVolume.equals("primary")) {
        throw new UnsupportedOperationException(
            "Retrieving the path of a document from storage volume "
                + documentStorageVolume
                + " is unsupported by this plugin.");
      }
      String innermostDirectoryName = uriDocumentIdSplit[1];
      String externalStorageDirectory = Environment.getExternalStorageDirectory().getPath();

      return externalStorageDirectory + "/" + innermostDirectoryName;
    } else {
      throw new UnsupportedOperationException(
          "Retrieving the path from URIs with authority "
              + uriAuthority.toString()
              + " is unsupported by this plugin.");
    }
  }
}
