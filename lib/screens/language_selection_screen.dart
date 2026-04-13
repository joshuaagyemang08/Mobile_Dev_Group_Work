// lib/screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../core/theme.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLocale = languageProvider.locale;

    final languages = [
      {'name': languageProvider.translate('english'), 'code': 'en', 'flag': '🇺🇸'},
      {'name': languageProvider.translate('french'), 'code': 'fr', 'flag': '🇫🇷'},
      {'name': languageProvider.translate('spanish'), 'code': 'es', 'flag': '🇪🇸'},
      {'name': languageProvider.translate('german'), 'code': 'de', 'flag': '🇩🇪'},
      {'name': languageProvider.translate('chinese'), 'code': 'zh', 'flag': '🇨🇳'},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(languageProvider.translate('language')),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: languages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = currentLocale.languageCode == lang['code'];

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: isSelected 
                ? Border.all(color: ScribTheme.primary, width: 2)
                : null,
            ),
            child: ListTile(
              onTap: () {
                languageProvider.setLanguage(lang['code']!);
                Navigator.pop(context);
              },
              leading: Text(
                lang['flag']!,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                lang['name']!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected 
                ? const Icon(Icons.check_circle, color: ScribTheme.primary)
                : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}
