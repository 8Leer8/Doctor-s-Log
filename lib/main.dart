import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'ui/screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android: white icons
      statusBarBrightness: Brightness.dark,        // iOS hint: dark bg
      systemNavigationBarColor: Color(0xFF15181F), // AppColors.background
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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