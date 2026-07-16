/// Custom exception for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({required this.message, this.statusCode, this.originalError});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';

  /// Determines if the error is due to authentication failure
  bool get isAuthenticationError =>
      statusCode == 401 || message.contains('Unauthorized');

  /// Determines if the error is due to invalid credentials
  bool get isInvalidCredentials =>
      statusCode == 401 || message.contains('Invalid credentials');

  /// Determines if the error is a network error
  bool get isNetworkError =>
      originalError.toString().contains('SocketException') ||
      message.contains('Network');
}
