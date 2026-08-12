import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../settings/terms_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _snack('Please accept the Terms & Conditions to continue.');
      return;
    }
    setState(() => _loading = true);
    try {
      final username = _username.text.trim();
      // Make sure the username isn't already taken.
      final available = await _auth.isUsernameAvailable(username);
      if (!available) {
        _snack('That username is already taken. Try another.');
        return;
      }
      await _auth.register(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
        username: username,
      );
      if (!mounted) return;
      await _showNotice();
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Notice shown after a successful registration.
  /// - If email confirmation is OFF, the user is already signed in, so we
  ///   close the auth screens and let AuthGate show the app.
  /// - If it's ON, we tell them to confirm and send them back to login.
  Future<void> _showNotice() async {
    final signedIn = _auth.currentSession != null;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.primary, size: 40),
        title: const Text('Account created'),
        content: Text(
          signedIn
              ? 'Welcome to Finance+! Your account is ready — let\'s get started.'
              : 'Your account has been created. Please confirm your email, '
                  'then log in.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(signedIn ? 'Get started' : 'Go to login'),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (signedIn) {
      // Reveal the app (pop the register + login routes).
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      Navigator.pop(context); // back to login
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FinanceLogo(size: 30),
                  const SizedBox(height: 30),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create your account',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration:
                              const InputDecoration(labelText: 'Full name'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _username,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            helperText: 'Used for logging in',
                          ),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.length < 3) {
                              return 'At least 3 characters';
                            }
                            if (t.contains('@') || t.contains(' ')) {
                              return 'No spaces or @ symbol';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            helperText: 'At least 6 characters',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Use at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        // Terms & Conditions — must be checked to register.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              activeColor: AppColors.primary,
                              onChanged: (v) =>
                                  setState(() => _agreedToTerms = v ?? false),
                            ),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('I agree to the '),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const TermsScreen()),
                                    ),
                                    child: const Text(
                                      'Terms & Conditions',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              (_loading || !_agreedToTerms) ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('REGISTER'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Already have an account? Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}