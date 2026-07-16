import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'navigation/app_shell.dart';

class StemArApp extends StatelessWidget {
  const StemArApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive AR STEM Framework',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkCyberpunk,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Show loading while restoring session
          if (authProvider.isRestoring) {
            return const _LoadingScreen();
          }

          // Navigate based on authentication state
          if (authProvider.isAuthenticated) {
            return const AppShell();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
