import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/local/cover_store.dart';
import 'data/local/downloaded_index.dart';
import 'data/local/library_filter_store.dart';
import 'data/local/reader_settings_store.dart';
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

  // Saved reading preferences, so the reader opens in your theme at once.
  await ReaderSettingsStore.load();

  // Load saved library filters and initialize the downloaded parts index.
  await LibraryFilterStore.load();
  await DownloadedIndex.instance.init();

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
