package io.flutter.plugins.webviewflutter.newGen

/**
 * ResultCompat.
 *
 * It is intended to solve the problem of being unable to obtain [kotlin.Result] in java.
 */
class ResultCompat {
  companion object {
    fun successBoolean(value: Boolean, callback: (Result<Boolean>) -> Unit) {
      callback(Result.success(value))
    }

    fun failureBoolean(throwable: Throwable, callback: (Result<Boolean>) -> Unit) {
      callback(Result.failure(throwable))
    }
  }
}