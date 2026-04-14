// lib/core/supabase_config.dart
// Supabase project credentials — anon/publishable key is safe to commit.
// NEVER put the secret key here.

class SupabaseConfig {
  static const String url = 'https://aumjypllgwftjfcxqoci.supabase.co';
  static const String anonKey = 'sb_publishable_O2igyq6qZdKH0EHRya-IFA_mPJCFLUB';

  /// Web OAuth Client ID from Google Cloud Console.
  /// Authentication > Providers > Google in your Supabase dashboard also needs this.
  static const String googleWebClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  /// Deep-link scheme used for email confirmation & OAuth callbacks.
  static const String redirectScheme = 'com.example.scrib';
  static const String redirectUrl = '$redirectScheme://login-callback/';
}
