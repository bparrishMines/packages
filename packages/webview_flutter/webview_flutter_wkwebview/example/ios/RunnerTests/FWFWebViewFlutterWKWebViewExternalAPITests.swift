// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit
import XCTest

@testable import webview_flutter_wkwebview

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#else
  #error("Unsupported platform.")
#endif

class FWFWebViewFlutterWKWebViewExternalAPITests: XCTestCase {
  @MainActor func testWebViewForIdentifier() {
    let registry = TestRegistry()
    WebViewFlutterPlugin.register(with: registry.registrar(forPlugin: "")!)

    let plugin = registry.registrar.plugin

    let webView = WKWebView(frame: .zero)
    let webViewIdentifier = 0
    plugin?.proxyApiRegistrar?.instanceManager.addDartCreatedInstance(
      webView, withIdentifier: Int64(webViewIdentifier))

    let result = FWFWebViewFlutterWKWebViewExternalAPI.webView(
      forIdentifier: Int64(webViewIdentifier), with: registry)
    XCTAssertEqual(result, webView)
  }
}

class TestRegistry: NSObject, FlutterPluginRegistry {
  let registrar = TestFlutterPluginRegistrar()

  func registrar(forPlugin pluginKey: String) -> FlutterPluginRegistrar? {
    return registrar
  }

  func hasPlugin(_ pluginKey: String) -> Bool {
    return true
  }

  func valuePublished(byPlugin pluginKey: String) -> NSObject? {
    if pluginKey == "WebViewFlutterPlugin" {
      return registrar.plugin
    }
    return nil
  }
}

class TestFlutterTextureRegistry: NSObject, FlutterTextureRegistry {
  func register(_ texture: FlutterTexture) -> Int64 {
    return 0
  }

  func textureFrameAvailable(_ textureId: Int64) {

  }

  func unregisterTexture(_ textureId: Int64) {

  }
}

class TestFlutterPluginRegistrar: NSObject, FlutterPluginRegistrar {
  var plugin: WebViewFlutterPlugin?

  func messenger() -> FlutterBinaryMessenger {
    return TestBinaryMessenger()
  }

  func textures() -> FlutterTextureRegistry {
    return TestFlutterTextureRegistry()
  }

  func register(_ factory: FlutterPlatformViewFactory, withId factoryId: String) {
  }

  func register(
    _ factory: FlutterPlatformViewFactory, withId factoryId: String,
    gestureRecognizersBlockingPolicy: FlutterPlatformViewGestureRecognizersBlockingPolicy
  ) {
  }

  func publish(_ value: NSObject) {
    plugin = (value as! WebViewFlutterPlugin)
  }

  func addMethodCallDelegate(_ delegate: FlutterPlugin, channel: FlutterMethodChannel) {

  }

  func addApplicationDelegate(_ delegate: FlutterPlugin) {

  }

  func lookupKey(forAsset asset: String) -> String {
    return ""
  }

  func lookupKey(forAsset asset: String, fromPackage package: String) -> String {
    return ""
  }
}