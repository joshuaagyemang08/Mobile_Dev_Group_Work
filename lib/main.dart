// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'providers/lecture_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for all supported locales
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('fr', null);
  await initializeDateFormatting('es', null);
  await initializeDateFormatting('de', null);
  await initializeDateFormatting('zh', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LectureProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const ScribApp(),
    ),
  );
}

class ScribApp extends StatelessWidget {
  const ScribApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        return MaterialApp(
          title: 'Scrib',
          debugShowCheckedModeBanner: false,
          theme: ScribTheme.light,
          darkTheme: ScribTheme.dark,
          themeMode: themeProvider.themeMode,
          locale: languageProvider.locale,
          home: const SplashScreen(),
        );
      },
    );
  }
}
