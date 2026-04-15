// lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/email_guard.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.redirectUrl,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Something went wrong. Please try again.');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _emailSent ? _SuccessView(email: _emailController.text.trim()) : _FormView(
              formKey: _formKey,
              emailController: _emailController,
              isLoading: _isLoading,
              onSubmit: _sendReset,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Form view (before sending) ────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [ScribTheme.primary, Color(0xFF7B6FF0)],
            ),
          ),
          child: const Icon(Icons.lock_reset_rounded,
              color: Colors.white, size: 28),
        ),

        const SizedBox(height: 24),

        const Text(
          'Forgot your\npassword?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: ScribTheme.onSurface,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          "No worries — enter your email and we'll send you a reset link.",
          style: TextStyle(
            fontSize: 14,
            color: ScribTheme.textSecondary,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 40),

        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ScribTheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
                style: const TextStyle(
                    color: ScribTheme.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle: const TextStyle(
                      color: ScribTheme.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: ScribTheme.textSecondary, size: 20),
                  filled: true,
                  fillColor: ScribTheme.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: ScribTheme.primary, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: ScribTheme.error, width: 1.5)),
                  focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: ScribTheme.error, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                validator: (v) {
                  return validateEmailForAuth(v);
                },
              ),

              const SizedBox(height: 32),

              // Send button
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
                        color: ScribTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isLoading ? null : onSubmit,
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Success view (after sending) ──────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 60),

        // Checkmark circle
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ScribTheme.secondary.withValues(alpha: 0.12),
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: ScribTheme.secondary, size: 44),
        ),

        const SizedBox(height: 32),

        const Text(
          'Check your inbox',
          style: TextStyle(
            fontSize: 24,
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
                height: 1.6),
            children: [
              const TextSpan(text: "We sent a password reset link to\n"),
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: ScribTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(
                  text: "\n\nClick the link in the email to set a new password."),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // Back to login
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: ScribTheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ScribTheme.primary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          "Didn't receive it? Check your spam folder.",
          style: TextStyle(fontSize: 12, color: ScribTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
