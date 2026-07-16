import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_constants.dart';

/// Service for handling secure token storage
class SecureStorageService {
  late final FlutterSecureStorage _storage;

  SecureStorageService() {
    _storage = const FlutterSecureStorage();
  }

  /// Saves JWT token securely
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: ApiConstants.tokenStorageKey, value: token);
    } catch (e) {
      throw Exception('Failed to save token: $e');
    }
  }

  /// Retrieves saved JWT token
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: ApiConstants.tokenStorageKey);
    } catch (e) {
      throw Exception('Failed to retrieve token: $e');
    }
  }

  /// Checks if token exists
  Future<bool> hasToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Deletes JWT token
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: ApiConstants.tokenStorageKey);
    } catch (e) {
      throw Exception('Failed to delete token: $e');
    }
  }

  /// Clears all stored data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear storage: $e');
    }
  }
}
