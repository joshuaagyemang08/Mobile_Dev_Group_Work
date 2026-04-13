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
      // Home
      'good_morning': 'Good morning',
      'good_afternoon': 'Good afternoon',
      'good_evening': 'Good evening',
      'your_lectures': 'Your Lectures',
      'search_hint': 'Search lectures or subjects...',
      'record_lecture': 'Record Lecture',
      'no_lectures': 'No lectures yet',
      'no_lectures_desc': 'Record your first lecture and let AI turn it into study notes automatically.',
      'start_recording': 'Start Recording',
      'no_results': 'No lectures found',
      'nothing_matched': 'Nothing matched',
      'clear_search': 'Clear search',
      'clear_filter': 'Clear filter',
      'results': 'results',
      'result': 'result',
      'lectures_stat': 'Lectures',
      'notes_ready_stat': 'Notes Ready',
      'recorded_stat': 'Recorded',

      // Profile
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
      // Home
      'good_morning': 'Bon matin',
      'good_afternoon': 'Bon après-midi',
      'good_evening': 'Bonsoir',
      'your_lectures': 'Vos Cours',
      'search_hint': 'Rechercher des cours ou des sujets...',
      'record_lecture': 'Enregistrer un cours',
      'no_lectures': 'Pas encore de cours',
      'no_lectures_desc': 'Enregistrez votre premier cours et laissez l\'IA le transformer automatiquement en notes d\'étude.',
      'start_recording': 'Démarrer l\'enregistrement',
      'no_results': 'Aucun cours trouvé',
      'nothing_matched': 'Rien ne correspond à',
      'clear_search': 'Effacer la recherche',
      'clear_filter': 'Effacer le filtre',
      'results': 'résultats',
      'result': 'résultat',
      'lectures_stat': 'Cours',
      'notes_ready_stat': 'Notes prêtes',
      'recorded_stat': 'Enregistré',

      // Profile
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
      // Home
      'good_morning': 'Buenos días',
      'good_afternoon': 'Buenas tardes',
      'good_evening': 'Buenas noches',
      'your_lectures': 'Tus Clases',
      'search_hint': 'Buscar clases o temas...',
      'record_lecture': 'Grabar Clase',
      'no_lectures': 'Aún no hay clases',
      'no_lectures_desc': 'Graba tu primera clase y deja que la IA la convierta automáticamente en notas de estudio.',
      'start_recording': 'Iniciar Grabación',
      'no_results': 'No se encontraron clases',
      'nothing_matched': 'Nada coincidió con',
      'clear_search': 'Borrar búsqueda',
      'clear_filter': 'Borrar filtro',
      'results': 'resultados',
      'result': 'resultado',
      'lectures_stat': 'Clases',
      'notes_ready_stat': 'Notas Listas',
      'recorded_stat': 'Grabado',

      // Profile
      'profile': 'Mi Perfil',
      'personal_info': 'Información Personal',
      'full_name': 'Nombre Complet',
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
      // Home
      'good_morning': 'Guten Morgen',
      'good_afternoon': 'Guten Tag',
      'good_evening': 'Guten Abend',
      'your_lectures': 'Deine Vorlesungen',
      'search_hint': 'Vorlesungen oder Themen suchen...',
      'record_lecture': 'Vorlesung aufzeichnen',
      'no_lectures': 'Noch keine Vorlesungen',
      'no_lectures_desc': 'Nehmen Sie Ihre erste Vorlesung auf und lassen Sie sie von der KI automatisch in Studiennotizen umwandeln.',
      'start_recording': 'Aufnahme starten',
      'no_results': 'Keine Vorlesungen gefunden',
      'nothing_matched': 'Nichts gefunden für',
      'clear_search': 'Suche löschen',
      'clear_filter': 'Filter löschen',
      'results': 'Ergebnisse',
      'result': 'Ergebnis',
      'lectures_stat': 'Vorlesungen',
      'notes_ready_stat': 'Notizen bereit',
      'recorded_stat': 'Aufgezeichnet',

      // Profile
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
      // Home
      'good_morning': '早上好',
      'good_afternoon': '下午好',
      'good_evening': '晚上好',
      'your_lectures': '您的课程',
      'search_hint': '搜索课程或主题...',
      'record_lecture': '录制课程',
      'no_lectures': '暂无课程',
      'no_lectures_desc': '录制您的第一节课，让人工智能自动将其转换为学习笔记。',
      'start_recording': '开始录制',
      'no_results': '未找到课程',
      'nothing_matched': '没有匹配项',
      'clear_search': '清除搜索',
      'clear_filter': '清除过滤器',
      'results': '个结果',
      'result': '个结果',
      'lectures_stat': '课程',
      'notes_ready_stat': '笔记已就绪',
      'recorded_stat': '已录制',

      // Profile
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
