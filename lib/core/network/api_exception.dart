import 'package:dio/dio.dart';

/// Extracts a human-readable message from a failed Dio request, preferring
/// the backend's `{ "error": "..." }` body over generic Dio messages.
String apiErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final details = data['details'];
      if (details is List && details.isNotEmpty && details.first is Map) {
        final detail = details.first as Map;
        final message = detail['message'];
        if (message is String) {
          final path = detail['path'];
          return path is String && path.isNotEmpty
              ? '${_fieldLabel(path)}: $message'
              : message;
        }
      }
      if (data['error'] is String) {
        final message = data['error'] as String;
        final constraint = data['constraint'];
        final column = data['column'];
        final requestId = data['requestId'];
        final diagnostics = <String>[
          if (constraint is String && constraint.isNotEmpty)
            'Constraint: $constraint',
          if (column is String && column.isNotEmpty) 'Column: $column',
          if (requestId is String && requestId.isNotEmpty)
            'Reference: $requestId',
        ];
        return diagnostics.isEmpty
            ? message
            : '$message\n${diagnostics.join('\n')}';
      }
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return error.message ?? fallback;
  }
  return fallback;
}

String _fieldLabel(String path) {
  final field = path.split('.').last;
  return '${field[0].toUpperCase()}${field.substring(1)}';
}
