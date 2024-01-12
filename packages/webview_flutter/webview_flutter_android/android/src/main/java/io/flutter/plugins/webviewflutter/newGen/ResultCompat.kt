package io.flutter.plugins.webviewflutter.newGen

/**
 * ResultCompat.
 *
 * It is intended to solve the problem of being unable to obtain [kotlin.Result] in java.
 */
@Suppress("UNCHECKED_CAST")
class ResultCompat {
  companion object {
    fun <T> success(value: T, callback: Any) {
      val a: (Result<T>) -> Unit = callback as (Result<T>) -> Unit
      a(Result.success(value))
    }

    fun failureBoolean(throwable: Throwable, callback: (Result<Boolean>) -> Unit) {
      callback(Result.failure(throwable))
    }
  }
}