import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/credential_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _identifier = TextEditingController(); // email OR username
  final _password = TextEditingController();
  final _auth = AuthService();
  final _creds = CredentialStore();

  bool _loading = false;
  bool _obscure = true;
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final saved = await _creds.load();
    if (!mounted || !saved.remember) return;
    setState(() {
      _remember = true;
      _identifier.text = saved.identifier;
      _password.text = saved.password;
    });
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.login(
        identifier: _identifier.text.trim(),
        password: _password.text,
      );
      // Remember (or forget) the credentials based on the checkbox.
      if (_remember) {
        await _creds.save(_identifier.text.trim(), _password.text);
      } else {
        await _creds.clear();
      }
      // Track this account on the device so it can be switched to later.
      await _creds.addAccount(SavedAccount(
        label: _identifier.text.trim(),
        identifier: _identifier.text.trim(),
        password: _password.text,
      ));
      // AuthGate reacts to the auth change and navigates on.
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(
      text: _identifier.text.contains('@') ? _identifier.text.trim() : '',
    );
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter your account email and we will send a reset link.',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
            onPressed: () => Navigator.pop(ctx, emailCtrl.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || !email.contains('@')) return;
    try {
      await _auth.resetPassword(email);
      _snack('Reset link sent to $email (check your inbox).');
    } catch (e) {
      _snack('Could not send reset email: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const SizedBox(height: 6),
                  const Text('Plan • Manage • Grow',
                      style:
                          TextStyle(color: AppColors.textGrey, fontSize: 12)),
                  const SizedBox(height: 36),
                  SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Log in to continue',
                            style: TextStyle(color: AppColors.textGrey)),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _identifier,
                          decoration: const InputDecoration(
                              labelText: 'Email or username'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter your email or username'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Enter your password'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Remember me
                            Expanded(
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _remember,
                                    activeColor: AppColors.primary,
                                    onChanged: (v) =>
                                        setState(() => _remember = v ?? false),
                                  ),
                                  const Flexible(
                                    child: Text('Remember me',
                                        style: TextStyle(fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _loading ? null : _forgotPassword,
                              child: const Text('Forgot password?',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('LOG IN'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen()),
                            ),
                    child: const Text("Don't have an account? Register"),
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
