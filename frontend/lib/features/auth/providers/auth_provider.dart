import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../models/index.dart';
import '../services/auth_service.dart';

/// State enumeration for authentication
enum AuthState { idle, loading, authenticated, unauthenticated, error }

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthState _state = AuthState.idle;
  CurrentUser? _currentUser;
  String? _errorMessage;
  bool _isRestoring = true;

  AuthProvider({required AuthService authService}) : _authService = authService;

  // Getters
  AuthState get state => _state;
  CurrentUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _state == AuthState.authenticated && _currentUser != null;
  bool get isLoading => _state == AuthState.loading;
  bool get isRestoring => _isRestoring;

  /// Attempts to restore session on app startup
  Future<void> restoreSession() async {
    _isRestoring = true;
    notifyListeners();

    try {
      final restored = await _authService.restoreSession();

      if (restored) {
        _state = AuthState.authenticated;
        _currentUser = _authService.currentUser;
        _errorMessage = null;
      } else {
        _state = AuthState.unauthenticated;
        _currentUser = null;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      _currentUser = null;
    }

    _isRestoring = false;
    notifyListeners();
  }

  /// Logs in user with email and password
  Future<void> login({required String email, required String password}) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(
        email: email,
        password: password,
      );

      _state = AuthState.authenticated;
      _currentUser = _authService.currentUser;
      _errorMessage = null;
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = e.message;
      _currentUser = null;
      rethrow;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'An unexpected error occurred';
      _currentUser = null;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Registers a new user account
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        displayName: displayName,
        email: email,
        password: password,
      );

      _state = AuthState.unauthenticated;
      _currentUser = null;
      _errorMessage = null;
    } on ApiException catch (e) {
      _state = AuthState.error;
      _errorMessage = e.message;
      _currentUser = null;
      rethrow;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'An unexpected error occurred';
      _currentUser = null;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    try {
      await _authService.logout();
      _state = AuthState.unauthenticated;
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Logout failed';
    }

    notifyListeners();
  }

  /// Clears all authentication data
  Future<void> clearAuthData() async {
    try {
      await _authService.clearAuthData();
      _state = AuthState.unauthenticated;
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to clear authentication data';
    }

    notifyListeners();
  }

  /// Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
