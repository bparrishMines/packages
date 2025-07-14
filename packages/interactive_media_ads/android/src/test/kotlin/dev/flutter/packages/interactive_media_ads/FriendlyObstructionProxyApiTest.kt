// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.packages.interactive_media_ads

import android.view.View
import com.google.ads.interactivemedia.v3.api.FriendlyObstruction
import com.google.ads.interactivemedia.v3.api.FriendlyObstructionPurpose
import kotlin.test.Test
import kotlin.test.assertEquals
import org.mockito.Mockito
import org.mockito.kotlin.mock
import org.mockito.kotlin.whenever

class FriendlyObstructionProxyApiTest {
  @Test
  fun detailedReason() {
    val api = TestProxyApiRegistrar().getPigeonApiFriendlyObstruction()

    val instance = Mockito.mock<FriendlyObstruction>()
    val detailedReason = "reason"
    whenever(instance.detailedReason).thenReturn(detailedReason)

    assertEquals(detailedReason, api.detailedReason(instance))
  }

  @Test
  fun purpose() {
    val api = TestProxyApiRegistrar().getPigeonApiFriendlyObstruction()

    val instance = Mockito.mock<FriendlyObstruction>()
    whenever(instance.purpose).thenReturn(FriendlyObstructionPurpose.NOT_VISIBLE)

    assertEquals(
        dev.flutter.packages.interactive_media_ads.FriendlyObstructionPurpose.NOT_VISIBLE,
        api.purpose(instance))
  }

  @Test
  fun view() {
    val api = TestProxyApiRegistrar().getPigeonApiFriendlyObstruction()

    val instance = Mockito.mock<FriendlyObstruction>()
    val view = mock<View>()
    whenever(instance.view).thenReturn(view)

    assertEquals(view, api.view(instance))
  }
}
