import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class EditInfoScreen extends StatefulWidget {
  const EditInfoScreen({super.key});

  @override
  State<EditInfoScreen> createState() => _EditInfoScreenState();
}

class _EditInfoScreenState extends State<EditInfoScreen> {
  final _auth = AuthService();
  final _data = DataService();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  Profile? _profile;
  String _originalUsername = '';
  String _originalEmail = '';
  bool _loading = true;
  bool _saving = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final p = await _data.getProfile();
    _email.text = _auth.currentUser?.email ?? '';
    _originalEmail = _email.text;
    if (p != null) {
      _name.text = p.fullName ?? '';
      _username.text = p.username ?? '';
      _originalUsername = p.username ?? '';
    }
    if (mounted) setState(() {
      _profile = p;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newUsername = _username.text.trim();
    final newEmail = _email.text.trim();
    if (_name.text.trim().isEmpty) return _snack('Name cannot be empty.');
    if (newUsername.length < 3) return _snack('Username must be 3+ characters.');

    setState(() => _saving = true);
    try {
      // Username change -> check availability first.
      if (newUsername.toLowerCase() != _originalUsername.toLowerCase()) {
        final free = await _auth.isUsernameAvailable(newUsername);
        if (!free) {
          _snack('That username is already taken.');
          return;
        }
      }
      await _data.updateProfile(
          fullName: _name.text.trim(), username: newUsername);

      // Password change (optional).
      if (_password.text.isNotEmpty) {
        if (_password.text.length < 6) {
          _snack('Profile saved, but password needs 6+ characters.');
          return;
        }
        await _auth.updatePassword(_password.text);
      }

      // Email change (optional) -> sends a confirmation email.
      var emailMsg = '';
      if (newEmail.toLowerCase() != _originalEmail.toLowerCase()) {
        await _auth.updateEmail(newEmail);
        emailMsg = ' A confirmation link was sent to your new email.';
      }

      if (!mounted) return;
      _snack('Changes saved.$emailMsg');
      _password.clear();
      _originalUsername = newUsername;
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Information')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field('Full name', _name),
                      const SizedBox(height: 16),
                      _field('Username', _username),
                      const SizedBox(height: 16),
                      _field('Email', _email,
                          keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          helperText: 'Leave blank to keep current password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save changes'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Changing your email requires confirming it from the new '
                  'inbox before you can log in with it.',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? keyboard}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
    );
  }
}
