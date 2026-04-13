// lib/providers/language_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LanguageProvider() {
    _loadFromPrefs();
  }

  void setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code') ?? 'en';
    _locale = Locale(code);
    notifyListeners();
  }

  // Simplified localization helper
  String translate(String key) {
    final translations = _translations[_locale.languageCode] ?? _translations['en']!;
    return translations[key] ?? key;
  }

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'profile': 'My Profile',
      'personal_info': 'Personal Information',
      'full_name': 'Full Name',
      'email': 'Email Address',
      'save_changes': 'Save Changes',
      'app_settings': 'App Settings',
      'notifications': 'Notifications',
      'theme': 'Theme',
      'language': 'App Language',
      'support': 'Support & More',
      'help': 'Help Center',
      'privacy': 'Privacy Policy',
      'about': 'About Scrib',
      'logout': 'Logout',
      'english': 'English',
      'french': 'French',
      'spanish': 'Spanish',
      'german': 'German',
      'chinese': 'Chinese',
    },
    'fr': {
      'profile': 'Mon Profil',
      'personal_info': 'Informations Personnelles',
      'full_name': 'Nom Complet',
      'email': 'Adresse E-mail',
      'save_changes': 'Enregistrer les modifications',
      'app_settings': "Paramètres de l'application",
      'notifications': 'Notifications',
      'theme': 'Thème',
      'language': "Langue de l'application",
      'support': 'Support et plus',
      'help': "Centre d'aide",
      'privacy': 'Politique de confidentialité',
      'about': 'À propos de Scrib',
      'logout': 'Déconnexion',
      'english': 'Anglais',
      'french': 'Français',
      'spanish': 'Espagnol',
      'german': 'Allemand',
      'chinese': 'Chinois',
    },
    'es': {
      'profile': 'Mi Perfil',
      'personal_info': 'Información Personal',
      'full_name': 'Nombre Completo',
      'email': 'Correo Electrónico',
      'save_changes': 'Guardar Cambios',
      'app_settings': 'Ajustes de la Aplicación',
      'notifications': 'Notificaciones',
      'theme': 'Tema',
      'language': 'Idioma de la Aplicación',
      'support': 'Soporte y Más',
      'help': 'Centro de Ayuda',
      'privacy': 'Política de Privacidad',
      'about': 'Acerca de Scrib',
      'logout': 'Cerrar Sesión',
      'english': 'Inglés',
      'french': 'Francés',
      'spanish': 'Español',
      'german': 'Alemán',
      'chinese': 'Chino',
    },
    'de': {
      'profile': 'Mein Profil',
      'personal_info': 'Persönliche Informationen',
      'full_name': 'Vollständiger Name',
      'email': 'E-Mail-Adresse',
      'save_changes': 'Änderungen speichern',
      'app_settings': 'App-Einstellungen',
      'notifications': 'Benachrichtigungen',
      'theme': 'Design',
      'language': 'App-Sprache',
      'support': 'Support & Mehr',
      'help': 'Hilfe-Center',
      'privacy': 'Datenschutzrichtlinie',
      'about': 'Über Scrib',
      'logout': 'Abmelden',
      'english': 'Englisch',
      'french': 'Französisch',
      'spanish': 'Spanisch',
      'german': 'Deutsch',
      'chinese': 'Chinesisch',
    },
    'zh': {
      'profile': '我的个人资料',
      'personal_info': '个人信息',
      'full_name': '姓名',
      'email': '电子邮件地址',
      'save_changes': '保存更改',
      'app_settings': '应用设置',
      'notifications': '通知',
      'theme': '主题',
      'language': '应用语言',
      'support': '支持与更多',
      'help': '帮助中心',
      'privacy': '隐私政策',
      'about': '关于 Scrib',
      'logout': '登出',
      'english': '英语',
      'french': '法语',
      'spanish': '西班牙语',
      'german': '德语',
      'chinese': '中文',
    },
  };
}
