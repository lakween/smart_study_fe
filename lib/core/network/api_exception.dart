import 'package:dio/dio.dart';

/// Extracts a human-readable message from a failed Dio request, preferring
/// the backend's `{ "error": "..." }` body over generic Dio messages.
String apiErrorMessage(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return error.message ?? fallback;
  }
  return fallback;
}
