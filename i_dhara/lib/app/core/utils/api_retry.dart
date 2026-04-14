import 'package:flutter/foundation.dart';

/// Calls [call] up to [maxAttempts] times.
///
/// Retries when:
/// - the result satisfies [isSuccess] returning `false` (default: result == null)
/// - the call throws an exception
///
/// Between attempts it waits [retryDelay] × attempt-number (linear back-off):
///   attempt 1 fails → wait 3 s → attempt 2 fails → wait 6 s → attempt 3.
///
/// Returns the first successful result, or `null` after all attempts fail.
Future<T?> withRetry<T>({
  required Future<T?> Function() call,
  bool Function(T?)? isSuccess,
  int maxAttempts = 3,
  Duration retryDelay = const Duration(seconds: 3),
}) async {
  isSuccess ??= (r) => r != null;

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final result = await call();
      if (isSuccess(result)) return result;
      debugPrint('withRetry: attempt $attempt/$maxAttempts – empty/null result');
    } catch (e) {
      debugPrint('withRetry: attempt $attempt/$maxAttempts – error: $e');
    }
    if (attempt < maxAttempts) {
      await Future.delayed(retryDelay * attempt);
    }
  }
  return null;
}
