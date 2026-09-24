// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.packages.file_selector_android;

import static java.nio.charset.StandardCharsets.UTF_8;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.spy;
import static org.mockito.Mockito.when;
import static org.robolectric.Shadows.shadowOf;

import android.content.ContentProvider;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.webkit.MimeTypeMap;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.test.core.app.ApplicationProvider;
import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.MockedStatic;
import org.mockito.stubbing.Answer;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.shadows.ShadowContentResolver;

@RunWith(RobolectricTestRunner.class)
public class FileUtilsTest {

  private Context context;
  ShadowContentResolver shadowContentResolver;
  ContentResolver contentResolver;

  @Before
  @SuppressWarnings("deprecation") // shadowOf(MimeTypeMap)
  public void before() {
    context = ApplicationProvider.getApplicationContext();
    contentResolver = spy(context.getContentResolver());
    shadowContentResolver = shadowOf(context.getContentResolver());
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
      // On S and higher robolectric does not need this setup because all the mappings are
      // present already.
      //noinspection deprecation
      var mimeTypeMap = shadowOf(MimeTypeMap.getSingleton());
      mimeTypeMap.addExtensionMimeTypeMapping("txt", "text/plain");
      mimeTypeMap.addExtensionMimeTypeMapping("jpg", "image/jpeg");
      mimeTypeMap.addExtensionMimeTypeMapping("png", "image/png");
      mimeTypeMap.addExtensionMimeTypeMapping("webp", "image/webp");
    }
  }

  @Test
  public void getPathFromUri_returnsExpectedPathForExternalDocumentUri() {
    // Uri that represents Documents/test directory on device:
    Uri uri =
        Uri.parse(
            "content://com.android.externalstorage.documents/tree/primary%3ADocuments%2Ftest");
    try (MockedStatic<DocumentsContract> mockedDocumentsContract =
        mockStatic(DocumentsContract.class)) {
      mockedDocumentsContract
          .when(() -> DocumentsContract.getDocumentId(uri))
          .thenAnswer((Answer<String>) invocation -> "primary:Documents/test");
      String path = FileUtils.getPathFromUri(context, uri);
      String externalStorageDirectoryPath = Environment.getExternalStorageDirectory().getPath();
      String expectedPath = externalStorageDirectoryPath + "/Documents/test";
      assertEquals(path, expectedPath);
    }
  }

  @Test
  public void getPathFromUri_throwExceptionForExternalDocumentUriWithNonPrimaryStorageVolume() {
    // Uri that represents Documents/test directory from some external storage volume ("external"
    // for this test):
    Uri uri =
        Uri.parse(
            "content://com.android.externalstorage.documents/tree/external%3ADocuments%2Ftest");
    try (MockedStatic<DocumentsContract> mockedDocumentsContract =
        mockStatic(DocumentsContract.class)) {
      mockedDocumentsContract
          .when(() -> DocumentsContract.getDocumentId(uri))
          .thenAnswer((Answer<String>) invocation -> "external:Documents/test");
      assertThrows(
          UnsupportedOperationException.class, () -> FileUtils.getPathFromUri(context, uri));
    }
  }

  @Test
  public void getPathFromUri_throwExceptionForUriWithUnhandledAuthority() {
    Uri uri = Uri.parse("content://com.unsupported.authority/tree/primary%3ADocuments%2Ftest");
    assertThrows(UnsupportedOperationException.class, () -> FileUtils.getPathFromUri(context, uri));
  }
}
