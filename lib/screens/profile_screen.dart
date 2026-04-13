// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../core/theme.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import 'auth_screen.dart';
import 'notification_settings_screen.dart';
import 'language_selection_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('user_name') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
      _imagePath = prefs.getString('user_profile_image');
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        String finalPath = pickedFile.path;
        if (!kIsWeb) {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = path.basename(pickedFile.path);
          final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
          finalPath = savedImage.path;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile_image', finalPath);
        setState(() => _imagePath = finalPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image.')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('user_email', _emailController.text.trim());
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(languageProvider.translate('profile')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header / Avatar Section ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).cardTheme.color,
                          border: Border.all(color: ScribTheme.primary.withOpacity(0.4), width: 3),
                        ),
                        child: ClipOval(child: _buildProfileImage()),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: ScribTheme.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Personal Information ---
              _buildSectionTitle(languageProvider.translate('personal_info')),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: languageProvider.translate('full_name'),
                icon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: languageProvider.translate('email'),
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScribTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(languageProvider.translate('save_changes'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),

              // --- App Settings Section ---
              _buildSectionTitle(languageProvider.translate('app_settings')),
              const SizedBox(height: 8),
              _buildClickableTile(
                icon: Icons.notifications_none_rounded,
                title: languageProvider.translate('notifications'),
                subtitle: 'Manage alerts',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                  );
                },
              ),
              _buildClickableTile(
                icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                title: languageProvider.translate('theme'),
                subtitle: isDark ? 'Dark mode' : 'Light mode',
                trailing: Switch(
                  value: isDark,
                  activeColor: ScribTheme.primary,
                  onChanged: (val) => themeProvider.toggleTheme(),
                ),
                onTap: () => themeProvider.toggleTheme(),
              ),
              _buildClickableTile(
                icon: Icons.language_rounded,
                title: languageProvider.translate('language'),
                subtitle: _getLanguageName(languageProvider.locale.languageCode, languageProvider),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                  );
                },
              ),

              const SizedBox(height: 32),

              // --- Support & More ---
              _buildSectionTitle(languageProvider.translate('support')),
              const SizedBox(height: 8),
              _buildClickableTile(
                icon: Icons.help_outline_rounded,
                title: languageProvider.translate('help'),
                onTap: () {},
              ),
              _buildClickableTile(
                icon: Icons.privacy_tip_outlined,
                title: languageProvider.translate('privacy'),
                onTap: () {},
              ),
              _buildClickableTile(
                icon: Icons.info_outline_rounded,
                title: languageProvider.translate('about'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),

              const SizedBox(height: 32),

              // --- Danger Zone ---
              _buildSectionTitle('Account'),
              const SizedBox(height: 8),
              _buildClickableTile(
                icon: Icons.logout_rounded,
                title: languageProvider.translate('logout'),
                titleColor: ScribTheme.error,
                iconColor: ScribTheme.error,
                onTap: _logout,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String code, LanguageProvider provider) {
    switch (code) {
      case 'fr': return provider.translate('french');
      case 'es': return provider.translate('spanish');
      case 'de': return provider.translate('german');
      case 'zh': return provider.translate('chinese');
      default: return provider.translate('english');
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark 
            ? ScribTheme.textSecondaryDark 
            : ScribTheme.textSecondaryLight,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildClickableTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? ScribTheme.primary, size: 22),
        title: Text(title, style: TextStyle(color: titleColor ?? Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight, fontSize: 12)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: ScribTheme.textSecondaryDark, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_imagePath == null || _imagePath!.isEmpty) {
      return const Icon(Icons.person, size: 50, color: ScribTheme.textSecondaryDark);
    }
    if (kIsWeb) {
      return Image.network(_imagePath!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: ScribTheme.textSecondaryDark));
    } else {
      final file = File(_imagePath!);
      if (!file.existsSync()) return const Icon(Icons.person, size: 50, color: ScribTheme.textSecondaryDark);
      return Image.file(file, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: ScribTheme.textSecondaryDark));
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight, fontSize: 14),
        prefixIcon: Icon(icon, color: isDark ? ScribTheme.textSecondaryDark : ScribTheme.textSecondaryLight, size: 20),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ScribTheme.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
