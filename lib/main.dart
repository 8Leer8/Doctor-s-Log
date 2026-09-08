import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'ui/screens/app_shell.dart';

void main() {
  runApp(const ArknightReaderApp());
}

class ArknightReaderApp extends StatelessWidget {
  const ArknightReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arknight Reader',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}