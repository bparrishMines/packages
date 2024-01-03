package io.flutter.plugins.webviewflutter.newGen;

import android.os.Build;
import android.webkit.WebResourceRequest;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import java.util.Map;

@RequiresApi(api = 21)
public class WebResourceRequestApiImpl extends WebResourceRequest_Api {
  public WebResourceRequestApiImpl(@NonNull Pigeon_ProxyApiBaseCodec codec) {
    super(codec);
  }

  @NonNull
  @Override
  public String url(@NonNull WebResourceRequest pigeon_instance) {
    return pigeon_instance.getUrl().getPath();
  }

  @Override
  public boolean isForMainFrame(@NonNull WebResourceRequest pigeon_instance) {
    return pigeon_instance.isForMainFrame();
  }

  @Nullable
  @Override
  public Boolean isRedirect(@NonNull WebResourceRequest pigeon_instance) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      return pigeon_instance.isRedirect();
    }

    return null;
  }

  @Override
  public boolean hasGesture(@NonNull WebResourceRequest pigeon_instance) {
    return pigeon_instance.hasGesture();
  }

  @NonNull
  @Override
  public String method(@NonNull WebResourceRequest pigeon_instance) {
    return pigeon_instance.getMethod();
  }

  @Nullable
  @Override
  public Map<String, String> requestHeaders(@NonNull WebResourceRequest pigeon_instance) {
    return pigeon_instance.getRequestHeaders();
  }
}
