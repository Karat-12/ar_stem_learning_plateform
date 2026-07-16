import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final secureStorageService = SecureStorageService();
  late final ApiClient apiClient;

  // Create API client with token getter
  apiClient = ApiClient(
    getToken: () async => await secureStorageService.getToken(),
  );

  final authService = AuthService(
    apiClient: apiClient,
    storageService: secureStorageService,
  );

  final authProvider = AuthProvider(authService: authService);

  // Restore session on app startup
  await authProvider.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureStorageService>.value(value: secureStorageService),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: const StemArApp(),
    ),
  );
}
