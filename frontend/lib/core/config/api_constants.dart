/// API configuration constants
class ApiConstants {
  ApiConstants._();

  // ── Backend base URL ──────────────────────────────────────────────────────
  // This is the SINGLE source of truth for the backend host.
  // Change only this line when switching environments:
  //
  //   Laptop browser / desktop run : http://localhost:8080
  //   Android emulator             : http://10.0.2.2:8080
  //   iOS simulator                : http://localhost:8080
  //   Physical Android device (LAN): http://192.168.1.5:8080  ← current
  //   Deployed backend             : https://api.yourdomain.com
  static const String baseUrl = 'http://192.168.0.31:8080';

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
