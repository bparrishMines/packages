package io.flutter.plugins.webviewflutter.newGen;

import android.os.Build;
import android.webkit.CookieManager;
import android.webkit.ValueCallback;
import android.webkit.WebView;

import androidx.annotation.NonNull;

import kotlin.Result;
import kotlin.Unit;
import kotlin.jvm.functions.Function1;

public class CookieManagerApiImpl extends CookieManager_Api {
  public CookieManagerApiImpl(@NonNull Pigeon_ProxyApiBaseCodec codec) {
    super(codec);
  }

  @NonNull
  @Override
  public CookieManager instance() {
    return CookieManager.getInstance();
  }

  @Override
  public void setCookie(@NonNull CookieManager pigeon_instance, @NonNull String url, @NonNull String value) {
    pigeon_instance.setCookie(url, value);
  }

  @Override
  @SuppressWarnings("deprecation")
  public void removeAllCookies(@NonNull CookieManager pigeon_instance, @NonNull Function1<? super Result<Boolean>, Unit> callback) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      pigeon_instance.removeAllCookies(aBoolean -> {
        ResultCompat.Companion.successBoolean(aBoolean, callback);
      });
    } else {
      final boolean hasCookies = pigeon_instance.hasCookies();
      if (hasCookies) {
        pigeon_instance.removeAllCookie();
      }
      ResultCompat.Companion.successBoolean(hasCookies, callback);
    }
  }

  @Override
  public void setAcceptThirdPartyCookies(@NonNull CookieManager pigeon_instance, @NonNull WebView webView, boolean accept) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      pigeon_instance.setAcceptThirdPartyCookies(webView, accept);
    } else {
      throw new UnsupportedOperationException(
          "`setAcceptThirdPartyCookies` is unsupported on versions below `Build.VERSION_CODES.LOLLIPOP`.");
    }
  }
}
