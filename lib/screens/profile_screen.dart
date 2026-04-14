// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/theme_provider.dart';
import 'auth_screen.dart';
import 'notification_settings_screen.dart';

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
    final user = Supabase.instance.client.auth.currentUser;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text =
          (user?.userMetadata?['name'] as String?) ??
          prefs.getString('user_name') ?? '';
      _emailController.text = user?.email ?? '';
      _imagePath = prefs.getString('user_profile_image');
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(picked.path);
        final saved =
            await File(picked.path).copy('${appDir.path}/$fileName');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile_image', saved.path);
        setState(() => _imagePath = saved.path);
      }
    } catch (_) {
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

    final name = _nameController.text.trim();
    try {
      // Update Supabase user metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'name': name}),
      );
      // Keep SharedPreferences in sync for the greeting
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access your lectures.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: ScribTheme.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await Supabase.instance.client.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');

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
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
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
                          border: Border.all(
                              color: ScribTheme.primary.withOpacity(0.4),
                              width: 3),
                        ),
                        child: ClipOval(child: _buildProfileImage()),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: ScribTheme.primary,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Personal Information
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Name is required';
                  if (val.length < 2) return 'Name must be at least 2 characters';
                  if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(val)) {
                    return 'Name can only contain letters and spaces';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                readOnly: true, // email managed by Supabase Auth
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScribTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),

              // App Settings
              _buildSectionTitle('App Settings'),
              const SizedBox(height: 8),
              _buildTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Manage alerts and reminders',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen()),
                ),
              ),
              _buildTile(
                icon: isDark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Theme',
                subtitle: isDark ? 'Dark mode' : 'Light mode',
                trailing: Switch(
                  value: isDark,
                  activeColor: ScribTheme.primary,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
                onTap: () => themeProvider.toggleTheme(),
              ),
              const SizedBox(height: 32),

              // Support
              _buildSectionTitle('Support & More'),
              const SizedBox(height: 8),
              _buildTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center',
                  onTap: () {}),
              _buildTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {}),
              _buildTile(
                icon: Icons.info_outline_rounded,
                title: 'About Scrib',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
              const SizedBox(height: 32),

              // Account Actions
              _buildSectionTitle('Account Actions'),
              const SizedBox(height: 8),
              _buildTile(
                icon: Icons.logout_rounded,
                title: 'Log out',
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

  Widget _buildSectionTitle(String title) => Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      );

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
    Widget? trailing,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          onTap: onTap,
          leading:
              Icon(icon, color: iconColor ?? ScribTheme.primary, size: 22),
          title: Text(title,
              style: TextStyle(
                  color: titleColor ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          subtitle: subtitle != null
              ? Text(subtitle,
                  style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12))
              : null,
          trailing: trailing ??
              Icon(Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      );

  Widget _buildProfileImage() {
    if (_imagePath == null || _imagePath!.isEmpty) {
      final name = _nameController.text;
      return Container(
        color: ScribTheme.primary.withOpacity(0.15),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'S',
            style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: ScribTheme.primary),
          ),
        ),
      );
    }
    final file = File(_imagePath!);
    if (!file.existsSync()) {
      return const Icon(Icons.person, size: 50, color: ScribTheme.textSecondary);
    }
    return Image.file(file, fit: BoxFit.cover);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14),
        prefixIcon: Icon(icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: ScribTheme.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        suffixIcon: readOnly
            ? const Icon(Icons.lock_outline_rounded,
                size: 16, color: ScribTheme.textSecondary)
            : null,
      ),
    );
  }
}
