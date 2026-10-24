/// Supabase credentials loaded at compile time via --dart-define-from-file.
///
/// Run the app with:
///   flutter run --dart-define-from-file=.env.json
///
/// Build with:
///   flutter build apk --dart-define-from-file=.env.json
///   flutter build ipa --dart-define-from-file=.env.json
///
/// Never hard-code credentials here. Keep .env.json out of version control.
class SupabaseConfig {
  SupabaseConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Call this at startup to catch missing config early.
  static void assertConfigured() {
    assert(
      supabaseUrl.isNotEmpty,
      'SUPABASE_URL is not set. Run with: flutter run --dart-define-from-file=.env.json',
    );
    assert(
      supabaseAnonKey.isNotEmpty,
      'SUPABASE_ANON_KEY is not set. Run with: flutter run --dart-define-from-file=.env.json',
    );
  }
}
