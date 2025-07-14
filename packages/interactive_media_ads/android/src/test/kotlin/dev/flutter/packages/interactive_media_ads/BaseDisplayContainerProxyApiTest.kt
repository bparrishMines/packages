// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.packages.interactive_media_ads

import android.view.ViewGroup
import com.google.ads.interactivemedia.v3.api.BaseDisplayContainer
import com.google.ads.interactivemedia.v3.api.CompanionAdSlot
import com.google.ads.interactivemedia.v3.api.FriendlyObstruction
import kotlin.test.Test
import kotlin.test.assertEquals
import org.mockito.Mockito
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

class BaseDisplayContainerProxyApiTest {
  @Test
  fun setCompanionSlots() {
    val api = TestProxyApiRegistrar().getPigeonApiBaseDisplayContainer()

    val instance = mock<BaseDisplayContainer>()
    val companionSlots = listOf(mock<CompanionAdSlot>())
    api.setCompanionSlots(instance, companionSlots)

    verify(instance).setCompanionSlots(companionSlots)
  }

  @Test
  fun getAdContainer() {
    val api = TestProxyApiRegistrar().getPigeonApiBaseDisplayContainer()

    val instance = Mockito.mock<BaseDisplayContainer>()
    val adContainer = mock<ViewGroup>()
    whenever(instance.adContainer).thenReturn(adContainer)

    assertEquals(adContainer, api.getAdContainer(instance))
  }

  @Test
  fun getCompanionSlots() {
    val api = TestProxyApiRegistrar().getPigeonApiBaseDisplayContainer()

    val instance = Mockito.mock<BaseDisplayContainer>()
    val companionSlots = listOf(mock<CompanionAdSlot>())
    whenever(instance.companionSlots).thenReturn(companionSlots)

    assertEquals(companionSlots, api.getCompanionSlots(instance))
  }

  @Test
  fun registerFriendlyObstruction() {
    val api = TestProxyApiRegistrar().getPigeonApiBaseDisplayContainer()

    val instance = mock<BaseDisplayContainer>()
    val friendlyObstruction = mock<FriendlyObstruction>()
    api.registerFriendlyObstruction(instance, friendlyObstruction)

    verify(instance).registerFriendlyObstruction(friendlyObstruction)
  }

  @Test
  fun unregisterAllFriendlyObstructions() {
    val api = TestProxyApiRegistrar().getPigeonApiBaseDisplayContainer()

    val instance = mock<BaseDisplayContainer>()
    api.unregisterAllFriendlyObstructions(instance)

    verify(instance).unregisterAllFriendlyObstructions()
  }
}
