// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import WebKit

/// Implementation of `WKUIDelegate` that calls to Dart in callback methods.
class UIDelegateImpl: NSObject, WKUIDelegate {
  let api: PigeonApiProtocolWKUIDelegate
  let apiDelegate: ProxyAPIDelegate

  init(api: PigeonApiProtocolWKUIDelegate) {
    self.api = api
    self.apiDelegate = ((api as! PigeonApiWKUIDelegate).pigeonRegistrar.apiDelegate
                        as! ProxyAPIDelegate)
  }

  func webView(
    _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    apiDelegate.dispatchOnMainThread { onFailure in
      self.api.onCreateWebView(
        pigeonInstance: self, webView: webView, configuration: configuration,
        navigationAction: navigationAction
      ) { result in
        if case .failure(let error) = result {
          onFailure("WKUIDelegate.onCreateWebView", error)
        }
      }
    }
    return nil
  }

  @available(iOS 15.0, macOS 12.0, *)
  func webView(
    _ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
    initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
    decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
  ) {
    let wrapperCaptureType: MediaCaptureType
    switch type {
    case .camera:
      wrapperCaptureType = .camera
    case .microphone:
      wrapperCaptureType = .microphone
    case .cameraAndMicrophone:
      wrapperCaptureType = .cameraAndMicrophone
    @unknown default:
      wrapperCaptureType = .unknown
    }
    
    apiDelegate.dispatchOnMainThread { onFailure in
      self.api.requestMediaCapturePermission(
        pigeonInstance: self, webView: webView, origin: origin, frame: frame, type: wrapperCaptureType
      ) { result in
        switch result {
        case .success(let decision):
          switch decision {
          case .deny:
            decisionHandler(.deny)
          case .grant:
            decisionHandler(.grant)
          case .prompt:
            decisionHandler(.prompt)
          }
        case .failure(let error):
          decisionHandler(.deny)
          onFailure("WKUIDelegate.requestMediaCapturePermission", error)
        }
      }
    }
  }

  func webView(
    _ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor () -> Void
  ) {
    apiDelegate.dispatchOnMainThread { onFailure in
      self.api.runJavaScriptAlertPanel(pigeonInstance: self, webView: webView, message: message, frame: frame) { result in
        if case .failure(let error) = result {
          onFailure("WKUIDelegate.runJavaScriptAlertPanel", error)
        }
        completionHandler()
      }
    }
  }

  func webView(
    _ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping @MainActor (Bool) -> Void
  ) {
    apiDelegate.dispatchOnMainThread { onFailure in
      self.api.runJavaScriptConfirmPanel(pigeonInstance: self, webView: webView, message: message, frame: frame) { result in
        switch result {
        case .success(let confirmed):
          completionHandler(confirmed)
        case .failure(let error):
          completionHandler(false)
          onFailure("WKUIDelegate.runJavaScriptConfirmPanel", error)
        }
      }
    }
  }

  func webView(
    _ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
    defaultText: String?, initiatedByFrame frame: WKFrameInfo,
    completionHandler: @escaping @MainActor (String?) -> Void
  ) {
    apiDelegate.dispatchOnMainThread { onFailure in
      self.api.runJavaScriptTextInputPanel(
        pigeonInstance: self, webView: webView, prompt: prompt, defaultText: defaultText, frame: frame
      ) { result in
        switch result {
        case .success(let response):
          completionHandler(response)
        case .failure(let error):
          completionHandler(nil)
          onFailure("WKUIDelegate.runJavaScriptTextInputPanel", error)
        }
      }
    }
  }
}

/// ProxyApi implementation for `WKUIDelegate`.
///
/// This class may handle instantiating native object instances that are attached to a Dart instance
/// or handle method calls on the associated native class or an instance of that class.
class UIDelegateProxyAPIDelegate: PigeonApiDelegateWKUIDelegate {
  func pigeonDefaultConstructor(pigeonApi: PigeonApiWKUIDelegate) throws -> WKUIDelegate {
    return UIDelegateImpl(api: pigeonApi)
  }
}