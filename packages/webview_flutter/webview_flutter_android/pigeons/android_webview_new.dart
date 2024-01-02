// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

// TODO: the check in kotlin host methods should also remove api
// TODO: unattached fields dont have the requires api

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/android_webview_new.g.dart',
    dartOptions: DartOptions(
      copyrightHeader: <String>[
        'Copyright 2013 The Flutter Authors. All rights reserved.',
        'Use of this source code is governed by a BSD-style license that can be',
        'found in the LICENSE file.',
      ],
    ),
    kotlinOut:
        'android/src/main/java/io/flutter/plugins/webviewflutter/newGen/GeneratedAndroidWebView.kt',
    kotlinOptions: KotlinOptions(
      package: 'io.flutter.plugins.webviewflutter.newGen',
      errorClassName: 'WebViewAndroidError',
    ),
  ),
)

/// Mode of how to select files for a file chooser.
///
/// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams.
enum FileChooserMode {
  /// Open single file and requires that the file exists before allowing the
  /// user to pick it.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams#MODE_OPEN.
  open,

  /// Similar to [open] but allows multiple files to be selected.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams#MODE_OPEN_MULTIPLE.
  openMultiple,

  /// Allows picking a nonexistent file and saving it.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams#MODE_SAVE.
  save,
}

/// Indicates the type of message logged to the console.
///
/// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel.
enum ConsoleMessageLevel {
  /// Indicates a message is logged for debugging.
  ///
  /// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel#DEBUG.
  debug,

  /// Indicates a message is provided as an error.
  ///
  /// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel#ERROR.
  error,

  /// Indicates a message is provided as a basic log message.
  ///
  /// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel#LOG.
  log,

  /// Indicates a message is provided as a tip.
  ///
  /// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel#TIP.
  tip,

  /// Indicates a message is provided as a warning.
  ///
  /// See https://developer.android.com/reference/android/webkit/ConsoleMessage.MessageLevel#WARNING.
  warning,

  /// Indicates a message with an unknown level.
  ///
  /// This does not represent an actual value provided by the platform and only
  /// indicates a value was provided that isn't currently supported.
  unknown,
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.WebResourceRequest',
  ),
  versionRequirements: VersionRequirements(minAndroidApi: 21),
)
abstract class WebResourceRequest {
  late String url;
  late bool isForMainFrame;
  late bool? isRedirect;
  late bool hasGesture;
  late String method;
  late Map<String, String>? requestHeaders;
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.WebResourceError',
  ),
  versionRequirements: VersionRequirements(minAndroidApi: 23),
)
abstract class WebResourceError {
  late int errorCode;
  late String description;
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'io.flutter.plugins.webviewflutter.newGen.WebViewPoint',
  ),
)
abstract class WebViewPoint {
  late int x;
  late int y;
}

/// Represents a JavaScript console message from WebCore.
///
/// See https://developer.android.com/reference/android/webkit/ConsoleMessage
@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.ConsoleMessage',
  ),
)
abstract class ConsoleMessage {
  late int lineNumber;
  late String message;
  late ConsoleMessageLevel level;
  late String sourceId;
}

/// Host API for `CookieManager`.
///
/// This class may handle instantiating and adding native object instances that
/// are attached to a Dart instance or handle method calls on the associated
/// native class or an instance of the class.
@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.CookieManager',
  ),
)
abstract class CookieManager {
  @static
  late CookieManager instance;

  /// Handles Dart method `CookieManager.setCookie`.
  void setCookie(String url, String value);

  /// Handles Dart method `CookieManager.removeAllCookies`.
  @async
  bool removeAllCookies();

  /// Handles Dart method `CookieManager.setAcceptThirdPartyCookies`.
  void setAcceptThirdPartyCookies(WebView webView, bool accept);
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.WebView',
  ),
)
abstract class WebView extends View {
  WebView();

  @attached
  late WebSettings settings;

  void loadData(String data, String? mimeType, String? encoding);

  void loadDataWithBaseUrl(
    String? baseUrl,
    String data,
    String? mimeType,
    String? encoding,
    String? historyUrl,
  );

  void loadUrl(String url, Map<String, String> headers);

  void postUrl(String url, Uint8List data);

  String? getUrl();

  bool canGoBack();

  bool canGoForward();

  void goBack();

  void goForward();

  void reload();

  void clearCache(bool includeDiskFiles);

  @async
  String? evaluateJavascript(String javascriptString);

  String? getTitle();

  void scrollTo(int x, int y);

  void scrollBy(int x, int y);

  WebViewPoint getScrollPosition();

  @static
  void setWebContentsDebuggingEnabled(bool enabled);

  void setWebViewClient(WebViewClient? client);

  void addJavaScriptChannel(JavaScriptChannel channel);

  void removeJavaScriptChannel(String name);

  void setDownloadListener(DownloadListener? listener);

  void setWebChromeClient(WebChromeClient? client);

  void setBackgroundColor(int color);
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.WebSettings',
  ),
)
abstract class WebSettings {
  void setDomStorageEnabled(bool flag);

  void setJavaScriptCanOpenWindowsAutomatically(bool flag);

  void setSupportMultipleWindows(bool support);

  void setJavaScriptEnabled(bool flag);

  void setUserAgentString(String? userAgentString);

  void setMediaPlaybackRequiresUserGesture(bool require);

  void setSupportZoom(bool support);

  void setLoadWithOverviewMode(bool overview);

  void setUseWideViewPort(bool use);

  void setDisplayZoomControls(bool enabled);

  void setBuiltInZoomControls(bool enabled);

  void setAllowFileAccess(bool enabled);

  void setTextZoom(int textZoom);

  String getUserAgentString();
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'io.flutter.plugins.webviewflutter.JavaScriptChannel',
  ),
)
abstract class JavaScriptChannel {
  // ignore: avoid_unused_constructor_parameters
  JavaScriptChannel(String channelName);

  late void Function(String message) postMessage;
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.WebViewClient',
  ),
)
abstract class WebViewClient {
  WebViewClient();

  late void Function(WebView webView, String url)? onPageStarted;

  late void Function(WebView webView, String url)? onPageFinished;

  late void Function(
    WebView webView,
    WebResourceRequest request,
    WebResourceError error,
  )? onReceivedRequestError;

  late void Function(
    WebView webView,
    int errorCode,
    String description,
    String failingUrl,
  )? onReceivedError;

  late void Function(
    WebView webView,
    WebResourceRequest request,
  )? requestLoading;

  late void Function(WebView webView, String url)? urlLoading;

  late void Function(
    WebView webView,
    String url,
    bool isReload,
  )? doUpdateVisitedHistory;

  late void Function(
    WebView webView,
    HttpAuthHandler handler,
    String host,
    String realm,
  )? onReceivedHttpAuthRequest;

  void setSynchronousReturnValueForShouldOverrideUrlLoading(bool value);
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.DownloadListener',
  ),
)
abstract class DownloadListener {
  DownloadListener();

  late void Function(
    String url,
    String userAgent,
    String contentDisposition,
    String mimetype,
    int contentLength,
  )? onDownloadStart;
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.WebChromeClient',
  ),
)
abstract class WebChromeClient {
  WebChromeClient();

  late void Function(WebView webView, int progress)? onProgressChanged;

  @async
  late List<String> Function(
    WebView webView,
    FileChooserParams params,
  )? onShowFileChooser;

  /// Callback to Dart function `WebChromeClient.onPermissionRequest`.
  late void Function(PermissionRequest request)? onPermissionRequest;

  /// Callback to Dart function `WebChromeClient.onShowCustomView`.
  late void Function(
    View view,
    CustomViewCallback callback,
  )? onShowCustomView;

  /// Callback to Dart function `WebChromeClient.onHideCustomView`.
  late void Function()? onHideCustomView;

  /// Callback to Dart function `WebChromeClient.onGeolocationPermissionsShowPrompt`.
  late void Function(
    String origin,
    GeolocationPermissionsCallback callback,
  )? onGeolocationPermissionsShowPrompt;

  /// Callback to Dart function `WebChromeClient.onGeolocationPermissionsHidePrompt`.
  late void Function()? onGeolocationPermissionsHidePrompt;

  /// Callback to Dart function `WebChromeClient.onConsoleMessage`.
  late void Function(ConsoleMessage message)? onConsoleMessage;

  void setSynchronousReturnValueForOnShowFileChooser(bool value);

  void setSynchronousReturnValueForOnConsoleMessage(bool value);
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'io.flutter.plugins.webviewflutter.FlutterAssetManager',
  ),
)
abstract class FlutterAssetManager {
  @static
  late FlutterAssetManager instance;

  List<String> list(String path);

  String getAssetFilePathByName(String name);
}

@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.WebStorage',
  ),
)
abstract class WebStorage {
  @static
  late WebStorage instance;

  void deleteAllData();
}

/// Handles callbacks methods for the native Java FileChooserParams class.
///
/// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams.
@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.WebChromeClient.FileChooserParams',
  ),
  versionRequirements: VersionRequirements(minAndroidApi: 21),
)
abstract class FileChooserParams {
  late bool isCaptureEnabled;
  late List<String> acceptTypes;
  late FileChooserMode mode;
  late String? filenameHint;
}

/// Host API for `PermissionRequest`.
///
/// This class may handle instantiating and adding native object instances that
/// are attached to a Dart instance or handle method calls on the associated
/// native class or an instance of the class.
///
/// See https://developer.android.com/reference/android/webkit/PermissionRequest.
@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.PermissionRequest',
  ),
  versionRequirements: VersionRequirements(minAndroidApi: 21),
)
abstract class PermissionRequest {
  late List<String> resources;

  /// Handles Dart method `PermissionRequest.grant`.
  void grant(List<String> resources);

  /// Handles Dart method `PermissionRequest.deny`.
  void deny();
}

/// Host API for `CustomViewCallback`.
///
/// This class may handle instantiating and adding native object instances that
/// are attached to a Dart instance or handle method calls on the associated
/// native class or an instance of the class.
///
/// See https://developer.android.com/reference/android/webkit/WebChromeClient.CustomViewCallback.
@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.WebChromeClient.CustomViewCallback',
  ),
)
abstract class CustomViewCallback {
  /// Handles Dart method `CustomViewCallback.onCustomViewHidden`.
  void onCustomViewHidden();
}

/// Flutter API for `View`.
///
/// This class may handle instantiating and adding Dart instances that are
/// attached to a native instance or receiving callback methods from an
/// overridden native class.
///
/// See https://developer.android.com/reference/android/view/View.
@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.view.View',
  ),
)
abstract class View {}

/// Host API for `GeolocationPermissionsCallback`.
///
/// This class may handle instantiating and adding native object instances that
/// are attached to a Dart instance or handle method calls on the associated
/// native class or an instance of the class.
///
/// See https://developer.android.com/reference/android/webkit/GeolocationPermissions.Callback.
@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.GeolocationPermissions.Callback',
  ),
)
abstract class GeolocationPermissionsCallback {
  /// Handles Dart method `GeolocationPermissionsCallback.invoke`.
  void invoke(String origin, bool allow, bool retain);
}

/// Host API for `HttpAuthHandler`.
///
/// This class may handle instantiating and adding native object instances that
/// are attached to a Dart instance or handle method calls on the associated
/// native class or an instance of the class.
///
/// See https://developer.android.com/reference/android/webkit/HttpAuthHandler.
@ProxyApi(
  kotlinOptions: KotlinProxyApiOptions(
    fullClassName: 'android.webkit.HttpAuthHandler',
  ),
)
abstract class HttpAuthHandler {
  /// Handles Dart method `HttpAuthHandler.useHttpAuthUsernamePassword`.
  bool useHttpAuthUsernamePassword();

  /// Handles Dart method `HttpAuthHandler.cancel`.
  void cancel();

  /// Handles Dart method `HttpAuthHandler.proceed`.
  void proceed(String username, String password);
}
