import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/library/presentation/screens/library_screen.dart';
import 'package:epub_audio/features/splash/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorageService().init();
  final bool hasSeenOnboarding = HiveStorageService().hasSeenOnboarding();
  runApp(EpubReaderApp(hasSeenOnboarding: hasSeenOnboarding));
}

class EpubReaderApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const EpubReaderApp({
    super.key,
    this.hasSeenOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUB & Audio Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF1D49B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: hasSeenOnboarding ? const LibraryScreen() : const SplashScreen(),
    );
  }
}
