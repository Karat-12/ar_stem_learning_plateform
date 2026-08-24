import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/ai_coach/providers/ai_coach_provider.dart';
import 'features/ai_coach/services/ai_coach_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/progress/providers/progress_provider.dart';
import 'features/progress/services/progress_service.dart';
import 'features/sessions/providers/session_provider.dart';
import 'features/sessions/services/session_service.dart';

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
  final sessionService = SessionService(apiClient: apiClient);
  final sessionProvider = SessionProvider(sessionService: sessionService);
  final progressService = ProgressService(apiClient: apiClient);
  final progressProvider = ProgressProvider(progressService: progressService);
  final aiCoachService = AiCoachService(apiClient: apiClient);
  final aiCoachProvider = AiCoachProvider(service: aiCoachService);

  // Restore session on app startup
  await authProvider.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        Provider<SecureStorageService>.value(value: secureStorageService),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
        Provider<SessionService>.value(value: sessionService),
        Provider<ProgressService>.value(value: progressService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<SessionProvider>.value(value: sessionProvider),
        ChangeNotifierProvider<ProgressProvider>.value(value: progressProvider),
        ChangeNotifierProvider<AiCoachProvider>.value(value: aiCoachProvider),
      ],
      child: const StemArApp(),
    ),
  );
}
