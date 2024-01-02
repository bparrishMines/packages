package io.flutter.plugins.webviewflutter.newGen;

import android.webkit.WebResourceRequest;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import java.util.Map;

public class WebResourceRequestApiImpl extends WebResourceRequest_Api {
  public WebResourceRequestApiImpl(@NonNull Pigeon_ProxyApiBaseCodec codec) {
    super(codec);
  }

  @NonNull
  @Override
  @RequiresApi(api = 21)
  public String url(@NonNull WebResourceRequest pigeon_instance) {
    return pigeon_instance.getUrl().getPath();
  }

  @Override
  public boolean isForMainFrame(@NonNull WebResourceRequest pigeon_instance) {
    return false;
  }

  @Nullable
  @Override
  public Boolean isRedirect(@NonNull WebResourceRequest pigeon_instance) {
    return null;
  }

  @Override
  public boolean hasGesture(@NonNull WebResourceRequest pigeon_instance) {
    return false;
  }

  @NonNull
  @Override
  public String method(@NonNull WebResourceRequest pigeon_instance) {
    return null;
  }

  @Nullable
  @Override
  public Map<String, String> requestHeaders(@NonNull WebResourceRequest pigeon_instance) {
    return null;
  }
}
