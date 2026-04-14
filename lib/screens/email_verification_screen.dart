// lib/screens/email_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import 'home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? pendingPassword;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.pendingPassword,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  bool _isResending = false;
  int _resendCooldown = 0; // seconds remaining before allow resend

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (mounted && user?.emailConfirmedAt != null) {
        _goHome();
      }
    });
  }

  // Listen for auth state changes — if the user clicks the link in the email
  // the session updates and we auto-navigate.
  late final _authSubscription =
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    if (session != null &&
        session.user.emailConfirmedAt != null &&
        mounted) {
      _goHome();
    }
  });

  @override
  void dispose() {
    _fadeController.dispose();
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    setState(() => _isChecking = true);
    try {
      await Supabase.instance.client.auth.refreshSession();
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.emailConfirmedAt != null) {
        _goHome();
        return;
      }

      if (widget.pendingPassword != null && widget.pendingPassword!.isNotEmpty) {
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: widget.email,
            password: widget.pendingPassword!,
          );
          if (mounted) {
            _goHome();
          }
          return;
        } on AuthException catch (e) {
          final msg = e.message.toLowerCase();
          if (msg.contains('email not confirmed') || msg.contains('email_not_confirmed')) {
            if (mounted) {
              _showSnack(
                'Email not verified yet. Click the link in your inbox first.',
                isError: true,
              );
            }
            return;
          }

          if (mounted) {
            _showSnack('Email looks verified. Please log in to continue.');
            await Future.delayed(const Duration(milliseconds: 700));
            _backToLogin();
          }
          return;
        }
      } else {
        if (mounted) {
          _showSnack(
            'Email not verified yet. Check your inbox and click the link.',
            isError: true,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        _showSnack('Could not check status. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0) return;
    setState(() => _isResending = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
        emailRedirectTo: SupabaseConfig.redirectUrl,
      );
      if (mounted) {
        _showSnack('Verification email sent!');
        _startCooldown();
      }
    } on AuthException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (_) {
      if (mounted) _showSnack('Failed to resend. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (route) => false,
    );
  }

  void _backToLogin() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? ScribTheme.error : ScribTheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),

                // Envelope illustration
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ScribTheme.primary.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.forward_to_inbox_rounded,
                      size: 50, color: ScribTheme.primary),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Verify your email',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: ScribTheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: ScribTheme.textSecondary,
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(text: "We sent a verification link to\n"),
                      TextSpan(
                        text: widget.email,
                        style: const TextStyle(
                          color: ScribTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(
                          text: "\n\nClick the link to activate your account. If the browser shows a blank page, return to the app and tap the button below."),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Check verification button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                          colors: [ScribTheme.primary, Color(0xFF7B6FF0)]),
                      boxShadow: [
                        BoxShadow(
                          color: ScribTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isChecking ? null : _checkVerification,
                        child: Center(
                          child: _isChecking
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  "I've verified my email",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Resend button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: (_isResending || _resendCooldown > 0)
                        ? null
                        : _resendEmail,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: ScribTheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      disabledForegroundColor:
                          ScribTheme.textSecondary,
                    ),
                    child: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: ScribTheme.primary, strokeWidth: 2),
                          )
                        : Text(
                            _resendCooldown > 0
                                ? 'Resend in ${_resendCooldown}s'
                                : 'Resend verification email',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: _resendCooldown > 0
                                  ? ScribTheme.textSecondary
                                  : ScribTheme.primary,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Spam note
                const Text(
                  "Didn't get it? Check your spam folder.",
                  style: TextStyle(
                      fontSize: 12, color: ScribTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // Back to login
                TextButton(
                  onPressed: () => Navigator.of(context).popUntil(
                    (route) => route.isFirst,
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                        color: ScribTheme.textSecondary, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
