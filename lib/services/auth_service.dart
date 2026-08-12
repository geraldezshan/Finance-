import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  final SupabaseClient _c = Supabase.instance.client;

  User? get currentUser => _c.auth.currentUser;
  Session? get currentSession => _c.auth.currentSession;

  Stream<AuthState> get authChanges => _c.auth.onAuthStateChange;

  /// Register with email + password and store full name + username in the
  /// user's metadata (the DB trigger copies these into the profiles table).
  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    await _c.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'username': username},
    );
  }

  /// True if no profile already uses this username (case-insensitive).
  Future<bool> isUsernameAvailable(String username) async {
    final res = await _c.rpc('username_available', params: {'uname': username});
    return res == true;
  }

  /// Log in using EITHER an email or a username.
  /// If [identifier] isn't an email, we resolve it to the account's email
  /// via a database function, then sign in.
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    var email = identifier.trim();
    if (!email.contains('@')) {
      final res = await _c.rpc('email_for_username', params: {'uname': email});
      if (res == null || (res is String && res.isEmpty)) {
        throw const AuthException('No account found with that username.');
      }
      email = res as String;
    }
    await _c.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> logout() => _c.auth.signOut();

  /// Change the logged-in user's password.
  Future<void> updatePassword(String newPassword) =>
      _c.auth.updateUser(UserAttributes(password: newPassword));

  /// Change the logged-in user's email. Supabase sends a confirmation email to
  /// the new address; the change applies once confirmed.
  Future<void> updateEmail(String newEmail) =>
      _c.auth.updateUser(UserAttributes(email: newEmail));

  Future<void> resetPassword(String email) => _c.auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.passwordResetRedirect,
      );
}
