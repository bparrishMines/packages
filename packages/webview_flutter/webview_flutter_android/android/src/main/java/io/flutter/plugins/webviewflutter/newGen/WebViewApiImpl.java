package io.flutter.plugins.webviewflutter.newGen;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.Build;
import android.view.View;
import android.view.ViewParent;
import android.webkit.DownloadListener;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.annotation.ChecksSdkIntAtLeast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;

import java.util.Map;

import io.flutter.embedding.android.FlutterView;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugins.webviewflutter.JavaScriptChannel;
import kotlin.Result;
import kotlin.Unit;
import kotlin.jvm.functions.Function1;

public class WebViewApiImpl extends WebView_Api {
  private Context context;

  /** Implementation of {@link WebView} that can be used as a Flutter {@link PlatformView}s. */
  @SuppressLint("ViewConstructor")
  public static class WebViewPlatformView extends WebView implements PlatformView {
    // To ease adding callback methods, this value is added prematurely.
    @SuppressWarnings("unused")
    private WebViewApiImpl api;

    private WebViewClient currentWebViewClient;
    private SecureWebChromeClient currentWebChromeClient;

    private final @NonNull AndroidSdkChecker sdkChecker;

    // Interface for an injectable SDK version checker.
    @VisibleForTesting
    interface AndroidSdkChecker {
      @ChecksSdkIntAtLeast(parameter = 0)
      boolean sdkIsAtLeast(int version);
    }

    /**
     * Creates a {@link WebViewPlatformView}.
     *
     * @param context an Activity Context to access application assets. This value cannot be null.
     */
    public WebViewPlatformView(@NonNull Context context, WebViewApiImpl api) {
      this(
          context,
          binaryMessenger,
          instanceManager,
          (int version) -> Build.VERSION.SDK_INT >= version);
    }

    @VisibleForTesting
    WebViewPlatformView(
        @NonNull Context context,
        @NonNull BinaryMessenger binaryMessenger,
        @NonNull InstanceManager instanceManager,
        @NonNull AndroidSdkChecker sdkChecker) {
      super(context);
      currentWebViewClient = new WebViewClient();
      currentWebChromeClient = new WebChromeClientHostApiImpl.SecureWebChromeClient();
      api = new WebViewFlutterApiImpl(binaryMessenger, instanceManager);
      this.sdkChecker = sdkChecker;

      setWebViewClient(currentWebViewClient);
      setWebChromeClient(currentWebChromeClient);
    }

    @Nullable
    @Override
    public View getView() {
      return this;
    }

    @Override
    public void dispose() {}

    @Override
    public void setWebViewClient(@NonNull WebViewClient webViewClient) {
      super.setWebViewClient(webViewClient);
      currentWebViewClient = webViewClient;
      currentWebChromeClient.setWebViewClient(webViewClient);
    }

    @Override
    public void setWebChromeClient(@Nullable WebChromeClient client) {
      super.setWebChromeClient(client);
      if (!(client instanceof WebChromeClientHostApiImpl.SecureWebChromeClient)) {
        throw new AssertionError("Client must be a SecureWebChromeClient.");
      }
      currentWebChromeClient = (WebChromeClientHostApiImpl.SecureWebChromeClient) client;
      currentWebChromeClient.setWebViewClient(currentWebViewClient);
    }

    // When running unit tests, the parent `WebView` class is replaced by a stub that returns null
    // for every method. This is overridden so that this returns the current WebChromeClient during
    // unit tests. This should only remain overridden as long as `setWebChromeClient` is overridden.
    @Nullable
    @Override
    public WebChromeClient getWebChromeClient() {
      return currentWebChromeClient;
    }

    /**
     * Flutter API used to send messages back to Dart.
     *
     * <p>This is only visible for testing.
     */
    @SuppressWarnings("unused")
    @VisibleForTesting
    void setApi(WebViewFlutterApiImpl api) {
      this.api = api;
    }
  }

  public WebViewApiImpl(@NonNull Pigeon_ProxyApiBaseCodec codec) {
    super(codec);
  }

  @NonNull
  @Override
  public WebView pigeon_defaultConstructor() {
    return null;
  }

  @NonNull
  @Override
  public WebSettings settings(@NonNull WebView pigeon_instance) {
    return null;
  }

  @Override
  public void loadData(@NonNull WebView pigeon_instance, @NonNull String data, @Nullable String mimeType, @Nullable String encoding) {

  }

  @Override
  public void loadDataWithBaseUrl(@NonNull WebView pigeon_instance, @Nullable String baseUrl, @NonNull String data, @Nullable String mimeType, @Nullable String encoding, @Nullable String historyUrl) {

  }

  @Override
  public void loadUrl(@NonNull WebView pigeon_instance, @NonNull String url, @NonNull Map<String, String> headers) {

  }

  @Override
  public void postUrl(@NonNull WebView pigeon_instance, @NonNull String url, @NonNull byte[] data) {

  }

  @Nullable
  @Override
  public String getUrl(@NonNull WebView pigeon_instance) {
    return null;
  }

  @Override
  public boolean canGoBack(@NonNull WebView pigeon_instance) {
    return false;
  }

  @Override
  public boolean canGoForward(@NonNull WebView pigeon_instance) {
    return false;
  }

  @Override
  public void goBack(@NonNull WebView pigeon_instance) {

  }

  @Override
  public void goForward(@NonNull WebView pigeon_instance) {

  }

  @Override
  public void reload(@NonNull WebView pigeon_instance) {

  }

  @Override
  public void clearCache(@NonNull WebView pigeon_instance, boolean includeDiskFiles) {

  }

  @Override
  public void evaluateJavascript(@NonNull WebView pigeon_instance, @NonNull String javascriptString, @NonNull Function1<? super Result<String>, Unit> callback) {

  }

  @Nullable
  @Override
  public String getTitle(@NonNull WebView pigeon_instance) {
    return null;
  }

  @Override
  public void scrollTo(@NonNull WebView pigeon_instance, long x, long y) {

  }

  @Override
  public void scrollBy(@NonNull WebView pigeon_instance, long x, long y) {

  }

  @NonNull
  @Override
  public WebViewPoint getScrollPosition(@NonNull WebView pigeon_instance) {
    return null;
  }

  @Override
  public void setWebContentsDebuggingEnabled(boolean enabled) {

  }

  @Override
  public void setWebViewClient(@NonNull WebView pigeon_instance, @Nullable WebViewClient client) {

  }

  @Override
  public void addJavaScriptChannel(@NonNull WebView pigeon_instance, @NonNull JavaScriptChannel channel) {

  }

  @Override
  public void removeJavaScriptChannel(@NonNull WebView pigeon_instance, @NonNull String name) {

  }

  @Override
  public void setDownloadListener(@NonNull WebView pigeon_instance, @Nullable DownloadListener listener) {

  }

  @Override
  public void setWebChromeClient(@NonNull WebView pigeon_instance, @Nullable WebChromeClient client) {

  }

  @Override
  public void setBackgroundColor(@NonNull WebView pigeon_instance, long color) {

  }
}
