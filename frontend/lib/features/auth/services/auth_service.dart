import '../../../core/config/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/index.dart';

/// Service for handling authentication operations
class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _storageService;

  CurrentUser? _currentUser;

  AuthService({
    required ApiClient apiClient,
    required SecureStorageService storageService,
  }) : _apiClient = apiClient,
       _storageService = storageService;

  /// Getter for current user
  CurrentUser? get currentUser => _currentUser;

  /// Logs in user with email and password
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(email: email, password: password);

      final response = await _apiClient.post<Map<String, dynamic>>(
        path: ApiConstants.loginEndpoint,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );

      final loginResponse = LoginResponse.fromJson(response);

      // Save token
      await _storageService.saveToken(loginResponse.token);

      try {
        _currentUser = await getCurrentUser();
      } catch (e) {
        await logout();
        rethrow;
      }

      return loginResponse;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Login failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Registers a new user account
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final request = RegisterRequest(
        displayName: displayName,
        email: email,
        password: password,
      );

      await _apiClient.post<Map<String, dynamic>>(
        path: ApiConstants.registerEndpoint,
        data: request.toJson(),
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Registration failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Retrieves the current authenticated user
  Future<CurrentUser> getCurrentUser() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        path: ApiConstants.currentUserEndpoint,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      _currentUser = CurrentUser.fromJson(response);
      return _currentUser!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Failed to fetch current user: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Checks if user is currently logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await _storageService.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Attempts to restore session from stored token
  /// Returns true if session was successfully restored
  Future<bool> restoreSession() async {
    try {
      final token = await _storageService.getToken();

      if (token == null || token.isEmpty) {
        _currentUser = null;
        return false;
      }

      // Verify token is still valid by fetching current user
      await getCurrentUser();
      return true;
    } catch (e) {
      // Token is invalid or expired
      await logout();
      return false;
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    try {
      await _storageService.deleteToken();
      _currentUser = null;
    } catch (e) {
      throw ApiException(
        message: 'Logout failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Clears all authentication data
  Future<void> clearAuthData() async {
    try {
      await _storageService.clearAll();
      _currentUser = null;
    } catch (e) {
      throw ApiException(
        message: 'Failed to clear auth data: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
