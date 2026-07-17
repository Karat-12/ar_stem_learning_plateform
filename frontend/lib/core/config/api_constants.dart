/// API configuration constants
class ApiConstants {
  ApiConstants._();

  // Desktop development URL
  // For Android emulator, change to: http://10.0.2.2:8080
  // For iOS simulator, change to: http://localhost:8080
  // For physical device, change to: http://<your-machine-ip>:8080
  static const String baseUrl = 'http://localhost:8080';

  // Endpoints
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String registerEndpoint = '/api/v1/auth/register';
  static const String currentUserEndpoint = '/api/v1/users/me';
  static const String misconceptionsEndpoint = '/api/v1/misconceptions';

  // Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String authorizationHeader = 'Authorization';

  // Timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;

  // Storage keys
  static const String tokenStorageKey = 'jwt_token';
  static const String userStorageKey = 'current_user';
}
