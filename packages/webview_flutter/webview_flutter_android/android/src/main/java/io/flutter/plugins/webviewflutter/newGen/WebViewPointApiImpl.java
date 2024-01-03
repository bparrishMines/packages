package io.flutter.plugins.webviewflutter.newGen;

import androidx.annotation.NonNull;

public class WebViewPointApiImpl extends WebViewPoint_Api {
  public WebViewPointApiImpl(@NonNull Pigeon_ProxyApiBaseCodec codec) {
    super(codec);
  }

  @Override
  public long x(@NonNull WebViewPoint pigeon_instance) {
    return pigeon_instance.getX();
  }

  @Override
  public long y(@NonNull WebViewPoint pigeon_instance) {
    return pigeon_instance.getY();
  }
}
