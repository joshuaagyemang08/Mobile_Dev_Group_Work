// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/supabase_config.dart';
import 'providers/lecture_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await NotificationService.init();
  runApp(const ScribApp());
}

class ScribApp extends StatelessWidget {
  const ScribApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LectureProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Scrib',
          debugShowCheckedModeBanner: false,
          theme: ScribTheme.light,
          darkTheme: ScribTheme.dark,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}