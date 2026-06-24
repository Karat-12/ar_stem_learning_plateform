import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'navigation/app_shell.dart';

class StemArApp extends StatelessWidget {
  const StemArApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive AR STEM Framework',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkCyberpunk,
      home: const AppShell(),
    );
  }
}
