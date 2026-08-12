import 'package:powersync/powersync.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'powersync_schema.dart';

/// === PUT YOUR POWERSYNC INSTANCE URL HERE ===
/// PowerSync dashboard -> Client SDK Setup (or Edit instance -> Copy Instance URL).
const String kPowerSyncUrl = 'https://6a1fab3adeeddd0df601b72d.powersync.journeyapps.com';

/// The local SQLite database, kept in sync with Supabase by PowerSync.
late final PowerSyncDatabase db;

bool _dbReady = false;
bool _connected = false;

/// Open the local database (call once at startup, before runApp).
Future<void> openPowerSync() async {
  if (_dbReady) return;
  final dir = await getApplicationSupportDirectory();
  final path = p.join(dir.path, 'finance_plus.db');
  db = PowerSyncDatabase(schema: powerSyncSchema, path: path);
  await db.initialize();
  _dbReady = true;
}

/// Connect the local DB to the PowerSync service using the Supabase session.
Future<void> connectPowerSync() async {
  if (_connected) return;
  _connected = true;
  await db.connect(connector: SupabaseConnector(db));
}

/// On logout: stop syncing and clear the local data (so the next account that
/// signs in on this device doesn't see the previous user's data).
Future<void> disconnectPowerSync() async {
  if (!_connected) return;
  _connected = false;
  await db.disconnectAndClear();
}

/// Bridges PowerSync <-> Supabase: provides the auth token (so sync rules know
/// the user) and uploads queued local changes back to Supabase.
class SupabaseConnector extends PowerSyncBackendConnector {
  SupabaseConnector(this.database);
  final PowerSyncDatabase database;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;
    return PowerSyncCredentials(
      endpoint: kPowerSyncUrl,
      token: session.accessToken,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    try {
      for (final op in transaction.crud) {
        final table = _supabase.from(op.table);
        switch (op.op) {
          case UpdateType.put:
            final data = Map<String, dynamic>.of(op.opData ?? {});
            data['id'] = op.id;
            await table.upsert(data);
            break;
          case UpdateType.patch:
            await table.update(op.opData ?? {}).eq('id', op.id);
            break;
          case UpdateType.delete:
            await table.delete().eq('id', op.id);
            break;
        }
      }
      await transaction.complete();
    } catch (e) {
      // Network / transient errors: let PowerSync retry later.
      rethrow;
    }
  }
}
