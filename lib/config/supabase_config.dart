/// Paste your Supabase project credentials here.
///
/// Find them in your Supabase dashboard:
///   Project Settings -> API
///     - Project URL      -> [url]
///     - anon public key  -> [anonKey]
///
/// The anon key is safe to ship in a client app (it only works alongside
/// Row Level Security, which this project sets up). Never put the
/// `service_role` key in the app.
class SupabaseConfig {
  static const String url = 'https://eltlsdwntacbeffofbor.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVsdGxzZHdudGFjYmVmZm9mYm9yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzMjMzMzEsImV4cCI6MjA5NTg5OTMzMX0.6sWEni8OcMzerdyJCaPC7a_I0A5yjaFNaXQO5s07kWE';

  /// Public URL of your hosted reset.html page (e.g. on Netlify/GitHub Pages).
  /// Must also be added to Supabase -> Authentication -> URL Configuration ->
  /// Redirect URLs. The "Forgot password?" email will send users here.
  static const String passwordResetRedirect =
      'https://starlit-parfait-740278.netlify.app/reset.html';
}
