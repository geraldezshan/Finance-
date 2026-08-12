import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../utils/format.dart';
import 'powersync_db.dart';

/// All data access now goes through the local PowerSync SQLite database (`db`).
///
///  - READS are live `watch()` streams: the UI updates automatically whenever
///    local data changes — whether from a local write or a sync from another
///    device.
///  - WRITES go to the local database and are queued by PowerSync, which
///    uploads them to Supabase when online (so the app is fully usable offline).
///
/// Avatars are the one exception: image bytes go to Supabase Storage (which
/// needs a connection); the resulting URL is then written locally and synced.
class DataService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;
  String _now() => DateTime.now().toUtc().toIso8601String();

  // ============================ READS (live) ============================

  Stream<Profile?> watchProfile() => db.watch(
        'SELECT * FROM profiles WHERE id = ?',
        parameters: [_uid],
      ).map((rs) => rs.isEmpty ? null : Profile.fromMap(rs.first));

  /// One-time profile read (used to pre-fill the Edit Information form).
  Future<Profile?> getProfile() async {
    final rs = await db.getAll('SELECT * FROM profiles WHERE id = ?', [_uid]);
    return rs.isEmpty ? null : Profile.fromMap(rs.first);
  }

  Stream<Budget> watchBudget() => db.watch(
        'SELECT * FROM budgets WHERE user_id = ?',
        parameters: [_uid],
      ).map((rs) => rs.isEmpty ? Budget() : Budget.fromMap(rs.first));

  Stream<List<TransactionRecord>> watchTransactions({String? type}) {
    final sql = type == null
        ? 'SELECT * FROM transactions WHERE user_id = ? ORDER BY created_at DESC'
        : 'SELECT * FROM transactions WHERE user_id = ? AND type = ? ORDER BY created_at DESC';
    final params = type == null ? [_uid] : [_uid, type];
    return db.watch(sql, parameters: params).map(
        (rs) => rs.map((r) => TransactionRecord.fromMap(r)).toList());
  }

  Stream<List<Goal>> watchGoals() => db.watch(
        'SELECT * FROM goals WHERE user_id = ? ORDER BY created_at ASC',
        parameters: [_uid],
      ).map((rs) => rs.map((r) => Goal.fromMap(r)).toList());

  /// Totals + per-category expense breakdown, derived live from transactions.
  Stream<Map<String, dynamic>> watchSummary() => watchTransactions().map((txns) {
        double income = 0, expense = 0;
        final byCategory = <String, double>{};
        for (final t in txns) {
          if (t.type == 'income') {
            income += t.amount;
          } else {
            expense += t.amount;
            byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
          }
        }
        return {
          'totalIncome': income,
          'totalExpense': expense,
          'byCategory': byCategory,
        };
      });

  // ============================ WRITES ============================

  Future<void> updateProfile({String? fullName, String? username}) async {
    final sets = <String>[];
    final args = <Object?>[];
    if (fullName != null) {
      sets.add('full_name = ?');
      args.add(fullName);
    }
    if (username != null) {
      sets.add('username = ?');
      args.add(username);
    }
    if (sets.isEmpty) return;
    args.add(_uid);
    await db.execute('UPDATE profiles SET ${sets.join(', ')} WHERE id = ?', args);
  }

  /// Adds one income's allocation on top of the existing budget totals.
  Future<void> addIncomeAllocation(double income,
      {List<double>? fractions}) async {
    final f = (fractions != null && fractions.length == 4)
        ? fractions
        : const [0.50, 0.20, 0.20, 0.10];
    final rs = await db.getAll('SELECT * FROM budgets WHERE user_id = ?', [_uid]);
    if (rs.isEmpty) {
      await db.execute(
        'INSERT INTO budgets(id, user_id, total_income, needs_amount, savings_amount, debt_amount, tithes_amount, updated_at) '
        'VALUES(uuid(), ?, ?, ?, ?, ?, ?, ?)',
        [
          _uid,
          income,
          income * f[0],
          income * f[1],
          income * f[2],
          income * f[3],
          _now(),
        ],
      );
    } else {
      final r = rs.first;
      await db.execute(
        'UPDATE budgets SET total_income = ?, needs_amount = ?, savings_amount = ?, debt_amount = ?, tithes_amount = ?, updated_at = ? WHERE id = ?',
        [
          asDouble(r['total_income']) + income,
          asDouble(r['needs_amount']) + income * f[0],
          asDouble(r['savings_amount']) + income * f[1],
          asDouble(r['debt_amount']) + income * f[2],
          asDouble(r['tithes_amount']) + income * f[3],
          _now(),
          r['id'],
        ],
      );
    }
  }

  // ---------- Transactions ----------
  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    String? description,
  }) async {
    await db.execute(
      'INSERT INTO transactions(id, user_id, type, amount, category, description, created_at) '
      'VALUES(uuid(), ?, ?, ?, ?, ?, ?)',
      [_uid, type, amount, category, description, _now()],
    );
  }

  Future<void> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required String category,
    String? description,
    DateTime? createdAt,
  }) async {
    if (createdAt != null) {
      await db.execute(
        'UPDATE transactions SET type = ?, amount = ?, category = ?, description = ?, created_at = ? WHERE id = ?',
        [type, amount, category, description, createdAt.toUtc().toIso8601String(), id],
      );
    } else {
      await db.execute(
        'UPDATE transactions SET type = ?, amount = ?, category = ?, description = ? WHERE id = ?',
        [type, amount, category, description, id],
      );
    }
  }

  Future<void> deleteTransaction(String id) async {
    await db.execute('DELETE FROM transactions WHERE id = ?', [id]);
  }

  // ---------- Goals ----------
  Future<void> createGoal({
    required String name,
    required double targetAmount,
    String? category,
    String? description,
  }) async {
    await db.execute(
      'INSERT INTO goals(id, user_id, name, target_amount, current_amount, category, description, created_at) '
      'VALUES(uuid(), ?, ?, ?, 0, ?, ?, ?)',
      [_uid, name, targetAmount, category, description, _now()],
    );
  }

  Future<void> addToGoal(String goalId, double amount) async {
    await db.execute(
      'UPDATE goals SET current_amount = current_amount + ? WHERE id = ?',
      [amount, goalId],
    );
  }

  Future<void> updateGoal({
    required String id,
    required String name,
    required double targetAmount,
    String? category,
    String? description,
  }) async {
    await db.execute(
      'UPDATE goals SET name = ?, target_amount = ?, category = ?, description = ? WHERE id = ?',
      [name, targetAmount, category, description, id],
    );
  }

  Future<void> deleteGoal(String id) async {
    await db.execute('DELETE FROM goals WHERE id = ?', [id]);
  }

  // ---------- Feedback ----------
  Future<void> submitFeedback(int stars, String comment) async {
    await db.execute(
      'INSERT INTO feedback(id, user_id, stars, comment, created_at) VALUES(uuid(), ?, ?, ?, ?)',
      [_uid, stars, comment.trim().isEmpty ? null : comment.trim(), _now()],
    );
  }

  // ---------- Avatar ----------
  /// Uploads the image to Supabase Storage (needs a connection), then writes
  /// the public URL locally so it syncs to the profile row.
  Future<String> uploadAvatar(Uint8List bytes, String ext) async {
    final e = (ext.isEmpty ? 'jpg' : ext).toLowerCase();
    final path = '$_uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$e';
    await _supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: 'image/${e == 'jpg' ? 'jpeg' : e}',
          ),
        );
    final url = _supabase.storage.from('avatars').getPublicUrl(path);
    await db.execute('UPDATE profiles SET avatar_url = ? WHERE id = ?', [url, _uid]);
    return url;
  }
}