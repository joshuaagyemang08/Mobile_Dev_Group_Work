// lib/core/supabase_config.dart
// Supabase project credentials — anon/publishable key is safe to commit.
// NEVER put the secret key here.

class SupabaseConfig {
  static const String url = 'https://aumjypllgwftjfcxqoci.supabase.co';
  static const String anonKey = 'sb_publishable_O2igyq6qZdKH0EHRya-IFA_mPJCFLUB';

  /// Web OAuth Client ID from Google Cloud Console.
  /// Authentication > Providers > Google in your Supabase dashboard also needs this.
  static const String googleWebClientId =
      '136604301160-dmkrvmrs85qklpjjivc1mctsb5jrj5ad.apps.googleusercontent.com';

  /// Deep-link scheme used for email confirmation & OAuth callbacks.
  static const String redirectScheme = 'com.example.scrib';
  static const String appRedirectUrl = '$redirectScheme://login-callback/';

  /// Browser redirect page shown after email verification/reset.
  /// Override with --dart-define=SUPABASE_EMAIL_REDIRECT_URL=... when needed.
  static const String browserRedirectUrl = String.fromEnvironment(
    'SUPABASE_EMAIL_REDIRECT_URL',
    defaultValue:
        'https://joshuaagyemang08.github.io/Mobile_Dev_Group_Work/docs/verification-status.html',
  );

  /// Keep existing usage sites simple.
  static const String redirectUrl = browserRedirectUrl;
}
