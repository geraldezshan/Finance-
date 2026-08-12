import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A saved account for quick switching on this device.
class SavedAccount {
  final String label; // username or email shown in the list
  final String identifier; // what to log in with
  final String password;
  SavedAccount(
      {required this.label, required this.identifier, required this.password});

  Map<String, dynamic> toJson() =>
      {'label': label, 'identifier': identifier, 'password': password};
  factory SavedAccount.fromJson(Map<String, dynamic> j) => SavedAccount(
        label: j['label'] as String,
        identifier: j['identifier'] as String,
        password: j['password'] as String,
      );
}

/// Stores "remember me" credentials AND the list of accounts saved on this
/// device, all in the device's encrypted storage (Keystore / Keychain).
class CredentialStore {
  static const _storage = FlutterSecureStorage();
  static const _kRemember = 'remember_me';
  static const _kIdentifier = 'saved_identifier';
  static const _kPassword = 'saved_password';
  static const _kAccounts = 'saved_accounts';

  Future<void> save(String identifier, String password) async {
    await _storage.write(key: _kRemember, value: 'true');
    await _storage.write(key: _kIdentifier, value: identifier);
    await _storage.write(key: _kPassword, value: password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kRemember);
    await _storage.delete(key: _kIdentifier);
    await _storage.delete(key: _kPassword);
  }

  Future<({bool remember, String identifier, String password})> load() async {
    final remember = (await _storage.read(key: _kRemember)) == 'true';
    final identifier = await _storage.read(key: _kIdentifier) ?? '';
    final password = await _storage.read(key: _kPassword) ?? '';
    return (remember: remember, identifier: identifier, password: password);
  }

  // ----- Multiple accounts (for "Switch account") -----

  Future<List<SavedAccount>> listAccounts() async {
    final raw = await _storage.read(key: _kAccounts);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => SavedAccount.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> addAccount(SavedAccount account) async {
    final accounts = await listAccounts();
    accounts.removeWhere((a) =>
        a.identifier.toLowerCase() == account.identifier.toLowerCase());
    accounts.add(account);
    await _storage.write(
        key: _kAccounts,
        value: jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  Future<void> removeAccount(String identifier) async {
    final accounts = await listAccounts();
    accounts.removeWhere(
        (a) => a.identifier.toLowerCase() == identifier.toLowerCase());
    await _storage.write(
        key: _kAccounts,
        value: jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }
}
