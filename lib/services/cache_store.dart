import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Tiny on-disk JSON cache so the app can show the last-seen data when offline.
/// Keys are namespaced per user by the caller (e.g. "<uid>_transactions").
class CacheStore {
  Directory? _dir;

  Future<Directory> _d() async =>
      _dir ??= await getApplicationDocumentsDirectory();

  Future<File> _file(String key) async =>
      File('${(await _d()).path}/cache_$key.json');

  Future<void> write(String key, Object data) async {
    try {
      final f = await _file(key);
      await f.writeAsString(jsonEncode(data));
    } catch (_) {
      // Caching is best-effort; never let it break the app.
    }
  }

  Future<dynamic> read(String key) async {
    try {
      final f = await _file(key);
      if (!f.existsSync()) return null;
      return jsonDecode(await f.readAsString());
    } catch (_) {
      return null;
    }
  }
}
