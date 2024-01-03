package io.flutter.plugins.webviewflutter.newGen;

import android.webkit.ConsoleMessage;

import androidx.annotation.NonNull;

public class ConsoleMessageApiImpl extends ConsoleMessage_Api {
  public ConsoleMessageApiImpl(@NonNull Pigeon_ProxyApiBaseCodec codec) {
    super(codec);
  }

  @Override
  public long lineNumber(@NonNull ConsoleMessage pigeon_instance) {
    return pigeon_instance.lineNumber();
  }

  @NonNull
  @Override
  public String message(@NonNull ConsoleMessage pigeon_instance) {
    return pigeon_instance.message();
  }

  @NonNull
  @Override
  public ConsoleMessageLevel level(@NonNull ConsoleMessage pigeon_instance) {
    switch (pigeon_instance.messageLevel()) {
      case TIP:
        return ConsoleMessageLevel.TIP;
      case LOG:
        return ConsoleMessageLevel.LOG;
      case WARNING:
        return ConsoleMessageLevel.WARNING;
      case ERROR:
        return ConsoleMessageLevel.ERROR;
      case DEBUG:
        return ConsoleMessageLevel.DEBUG;
      default:
        return ConsoleMessageLevel.WARNING;
    }
  }

  @NonNull
  @Override
  public String sourceId(@NonNull ConsoleMessage pigeon_instance) {
    return pigeon_instance.sourceId();
  }
}
