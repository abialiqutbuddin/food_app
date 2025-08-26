// lib/core/errors/error_handling.dart
class ApiResult<T> {
  final T? data;
  final ApiError? error;
  final int status;
  final Map<String, String>? headers;

  const ApiResult._({this.data, this.error, required this.status, this.headers});

  bool get isOk => error == null;

  static ApiResult<T> ok<T>(T data, {required int status, Map<String, String>? headers}) =>
      ApiResult._(data: data, status: status, headers: headers);

  static ApiResult<T> err<T>(ApiError error, {required int status, Map<String, String>? headers}) =>
      ApiResult._(error: error, status: status, headers: headers);
}

class ApiError implements Exception {
  final String message;
  final Object? cause;

  /// Optional extra context (e.g. { bodyCode: '301', httpStatus: 200 })
  final Map<String, dynamic>? meta;

  const ApiError(this.message, {this.cause, this.meta});

  @override
  String toString() => 'ApiError: $message';
}