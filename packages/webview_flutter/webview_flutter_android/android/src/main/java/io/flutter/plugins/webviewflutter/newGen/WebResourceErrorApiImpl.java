package io.flutter.plugins.webviewflutter.newGen;

import android.os.Build;
import android.webkit.WebResourceError;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

@RequiresApi(api = Build.VERSION_CODES.M)
public class WebResourceErrorApiImpl extends WebResourceError_Api {
  public WebResourceErrorApiImpl(@NonNull Pigeon_ProxyApiBaseCodec codec) {
    super(codec);
  }

  @Override
  public long errorCode(@NonNull WebResourceError pigeon_instance) {
    return pigeon_instance.getErrorCode();
  }

  @NonNull
  @Override
  public String description(@NonNull WebResourceError pigeon_instance) {
    return pigeon_instance.getDescription().toString();
  }
}
