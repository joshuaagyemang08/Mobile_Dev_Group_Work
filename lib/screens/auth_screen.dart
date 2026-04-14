// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'email_verification_screen.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');

enum _PasswordStrength { none, weak, fair, good, strong }

_PasswordStrength _getStrength(String pw) {
  if (pw.isEmpty) return _PasswordStrength.none;
  final hasUpper = pw.contains(RegExp(r'[A-Z]'));
  final hasLower = pw.contains(RegExp(r'[a-z]'));
  final hasDigit = pw.contains(RegExp(r'[0-9]'));
  final hasSpecial = pw.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  final long = pw.length >= 10;

  final score = [hasUpper, hasLower, hasDigit, hasSpecial, long]
      .where((b) => b)
      .length;

  if (pw.length < 6) return _PasswordStrength.weak;
  if (score <= 2) return _PasswordStrength.fair;
  if (score == 3) return _PasswordStrength.good;
  return _PasswordStrength.strong;
}

// ─── Auth Screen ──────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _submitted = false; // enables real-time validation after first attempt

  late AnimationController _formController;
  late Animation<double> _formOpacity;
  late Animation<Offset> _formSlide;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  _PasswordStrength _strength = _PasswordStrength.none;

  @override
  void initState() {
    super.initState();
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _formOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOut));
    _formController.forward();

    _passwordController.addListener(() {
      final s = _getStrength(_passwordController.text);
      if (s != _strength) setState(() => _strength = s);
      if (_submitted) _formKey.currentState?.validate();
    });
  }

  @override
  void dispose() {
    _formController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _formController.reverse().then((_) {
      setState(() {
        _isLogin = !_isLogin;
        _submitted = false;
        _strength = _PasswordStrength.none;
      });
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmController.clear();
      _formController.forward();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ScribTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: ScribTheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final client = Supabase.instance.client;

    try {
      if (_isLogin) {
        // ── Login flow ──
        await client.auth.signInWithPassword(email: email, password: password);

        // Sync name to SharedPreferences for greeting
        final user = client.auth.currentUser;
        final name = user?.userMetadata?['name'] as String? ?? '';
        if (name.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', name);
        }

        if (mounted) {
          _showSuccess('Welcome back!');
          await Future.delayed(const Duration(milliseconds: 600));
          _navigateToHome();
        }
      } else {
        // ── Register flow ──
        final name = _nameController.text.trim();
        final response = await client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
          emailRedirectTo: SupabaseConfig.redirectUrl,
        );

        // Supabase may return a user with no identities when an account already
        // exists (anti-enumeration behavior). In that case, guide user to login.
        final existingIdentities = response.user?.identities ?? const [];
        if (response.user != null && existingIdentities.isEmpty) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showError('Account already exists. Please log in or reset your password.');
          }
          return;
        }

        // Save name locally for greeting
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: email),
            ),
          );
        }
        return;
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (!_isLogin && msg.contains('over_email_send_rate_limit')) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Too many verification email requests. Wait about a minute, then tap Resend verification email.');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: email),
            ),
          );
        }
        return;
      }
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Something went wrong. Please try again.');
      }
    }
  }

  Future<void> _googleSignIn() async {
    if (SupabaseConfig.googleWebClientId
        .startsWith('YOUR_WEB_CLIENT_ID')) {
      _showError(
          'Google Sign-In is not configured yet. Please use email & password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConfig.googleWebClientId,
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the picker
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        setState(() => _isLoading = false);
        _showError('Google Sign-In failed. Please try again.');
        return;
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      // Sync display name to SharedPreferences for the greeting
      final user = Supabase.instance.client.auth.currentUser;
      final name = (user?.userMetadata?['full_name'] as String?) ??
          (user?.userMetadata?['name'] as String?) ??
          googleUser.displayName ??
          '';
      if (name.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', name);
      }

      if (mounted) {
        _showSuccess('Signed in with Google!');
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToHome();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Google Sign-In failed. Please try again.');
      }
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // ─── Validators ─────────────────────────────────────────────────────────────

  String? _validateName(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'Full name is required';
    if (val.length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(val)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'Email address is required';
    if (!_emailRegex.hasMatch(val)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    final val = v ?? '';
    if (val.isEmpty) return 'Password is required';
    if (val.length < 6) return 'Password must be at least 6 characters';
    if (_isLogin) return null;
    if (_strength == _PasswordStrength.weak) {
      return 'Password is too weak — add numbers or symbols';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScribTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _Header(isLogin: _isLogin),
              const SizedBox(height: 40),
              _TabToggle(isLogin: _isLogin, onToggle: _toggleMode),
              const SizedBox(height: 32),

              FadeTransition(
                opacity: _formOpacity,
                child: SlideTransition(
                  position: _formSlide,
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full name (register only)
                        if (!_isLogin) ...[
                          _InputField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            label: 'Full Name',
                            hint: 'e.g. Rose Alice',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_emailFocus),
                            validator: _validateName,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email
                        _InputField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          label: 'Email Address',
                          hint: 'you@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passwordFocus),
                          validator: _validateEmail,
                        ),

                        const SizedBox(height: 16),

                        // Password
                        _InputField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePassword,
                          textInputAction: _isLogin
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onFieldSubmitted: (_) {
                            if (_isLogin) {
                              _submit();
                            } else {
                              FocusScope.of(context)
                                  .requestFocus(_confirmFocus);
                            }
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: ScribTheme.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          validator: _validatePassword,
                        ),

                        // Password strength meter (register only)
                        if (!_isLogin && _strength != _PasswordStrength.none) ...[
                          const SizedBox(height: 10),
                          _PasswordStrengthBar(strength: _strength),
                        ],

                        // Confirm password (register only)
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          _InputField(
                            controller: _confirmController,
                            focusNode: _confirmFocus,
                            label: 'Confirm Password',
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: ScribTheme.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: _validateConfirm,
                          ),
                        ],

                        // Forgot password (login only)
                        if (_isLogin) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen()),
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                    color: ScribTheme.primary, fontSize: 13),
                              ),
                            ),
                          ),
                        ] else
                          const SizedBox(height: 24),

                        const SizedBox(height: 8),

                        // Submit button
                        _SubmitButton(
                          label: _isLogin ? 'Login' : 'Create Account',
                          isLoading: _isLoading,
                          onTap: _submit,
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: ScribTheme.surfaceVariant,
                                    thickness: 1)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                    color: ScribTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color: ScribTheme.surfaceVariant,
                                    thickness: 1)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _GoogleButton(onTap: _googleSignIn),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.isLogin});
  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
                colors: [ScribTheme.primary, Color(0xFF7B6FF0)]),
          ),
          child: const Icon(Icons.auto_stories_rounded,
              color: Colors.white, size: 24),
        ),
        const SizedBox(height: 24),
        Text(
          isLogin ? 'Welcome back 👋' : 'Create account ✨',
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: ScribTheme.onSurface),
        ),
        const SizedBox(height: 6),
        Text(
          isLogin
              ? 'Log in to access your lectures and notes'
              : 'Join Scrib and start studying smarter',
          style:
              const TextStyle(fontSize: 14, color: ScribTheme.textSecondary),
        ),
      ],
    );
  }
}

// ── Tab Toggle ────────────────────────────────────────────────────────────────
class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.isLogin, required this.onToggle});
  final bool isLogin;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
          color: ScribTheme.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _Tab(
              label: 'Login',
              selected: isLogin,
              onTap: isLogin ? null : onToggle),
          _Tab(
              label: 'Register',
              selected: !isLogin,
              onTap: !isLogin ? null : onToggle),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? ScribTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: ScribTheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : ScribTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input Field ───────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ScribTheme.onSurface)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: const TextStyle(color: ScribTheme.onSurface, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: ScribTheme.textSecondary, fontSize: 14),
            prefixIcon:
                Icon(icon, color: ScribTheme.textSecondary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: ScribTheme.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: ScribTheme.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: ScribTheme.error, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: ScribTheme.error, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ── Password Strength Bar ─────────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final _PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final (label, color, filled) = switch (strength) {
      _PasswordStrength.weak => ('Weak', ScribTheme.error, 1),
      _PasswordStrength.fair => ('Fair', Colors.orange, 2),
      _PasswordStrength.good => ('Good', Colors.yellow.shade700, 3),
      _PasswordStrength.strong => ('Strong', ScribTheme.secondary, 4),
      _ => ('', Colors.transparent, 0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 4),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i < filled ? color : ScribTheme.surfaceVariant,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            label,
            key: ValueKey(label),
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }
}

// ── Submit Button ─────────────────────────────────────────────────────────────
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
              colors: [ScribTheme.primary, Color(0xFF7B6FF0)]),
          boxShadow: [
            BoxShadow(
                color: ScribTheme.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: isLoading ? null : onTap,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(label,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Google Button ─────────────────────────────────────────────────────────────
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ScribTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ScribTheme.surfaceVariant),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('G',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4285F4))),
                SizedBox(width: 12),
                Text('Continue with Google',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ScribTheme.onSurface)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
