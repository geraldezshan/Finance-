import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/credential_store.dart';
import '../../theme/app_theme.dart';

/// Lets the user switch between accounts saved on this device. Supabase keeps
/// one session at a time, so switching signs in the chosen saved account.
class SwitchAccountScreen extends StatefulWidget {
  const SwitchAccountScreen({super.key});

  @override
  State<SwitchAccountScreen> createState() => _SwitchAccountScreenState();
}

class _SwitchAccountScreenState extends State<SwitchAccountScreen> {
  final _auth = AuthService();
  final _creds = CredentialStore();
  List<SavedAccount> _accounts = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _creds.listAccounts();
    if (mounted) setState(() {
      _accounts = list;
      _loading = false;
    });
  }

  String get _currentEmail => _auth.currentUser?.email ?? '';

  Future<void> _switchTo(SavedAccount a) async {
    setState(() => _busy = true);
    try {
      await _auth.login(identifier: a.identifier, password: a.password);
      if (!mounted) return;
      // Clear pushed screens so the rebuilt app (new account) shows through.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthException catch (e) {
      _snack(e.message);
      setState(() => _busy = false);
    } catch (e) {
      _snack('Could not switch: $e');
      setState(() => _busy = false);
    }
  }

  Future<void> _addAccount() async {
    // Log out -> AuthGate shows the login screen so a new account can sign in.
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _remove(SavedAccount a) async {
    await _creds.removeAccount(a.identifier);
    _load();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Switch Account')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_accounts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No saved accounts yet. Accounts are remembered here '
                          'after you log in to them on this device.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ),
                    for (final a in _accounts)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              a.label.isNotEmpty
                                  ? a.label[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(a.label),
                          subtitle: a.identifier.toLowerCase() ==
                                  _currentEmail.toLowerCase()
                              ? const Text('Currently signed in',
                                  style: TextStyle(color: AppColors.primary))
                              : const Text('Tap to switch'),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _busy ? null : () => _remove(a),
                          ),
                          onTap: _busy ? null : () => _switchTo(a),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _addAccount,
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Add another account'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                    ),
                  ],
                ),
                if (_busy)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}
