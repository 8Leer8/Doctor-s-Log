import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/local/cover_store.dart';
import 'theme/app_theme.dart';
import 'ui/screens/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android: white icons
      statusBarBrightness: Brightness.dark, // iOS hint: dark bg
      systemNavigationBarColor: Color(0xFF15181F), // AppColors.background
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Load the bundled covers into memory so the first frame already has them.
  await CoverStore.warmUp();

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
