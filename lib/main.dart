// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/lecture_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScribApp());
}

class ScribApp extends StatelessWidget {
  const ScribApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LectureProvider(),
      child: MaterialApp(
        title: 'Scrib',
        debugShowCheckedModeBanner: false,
        theme: ScribTheme.dark,
        home: const SplashScreen(),
      ),
    );
  }
}