import 'package:powersync/powersync.dart';

/// Local SQLite schema mirroring the Supabase tables that sync via PowerSync.
/// Note: the `id` (primary key) is implicit in PowerSync — do NOT declare it.
/// All other columns are declared with their type.
const powerSyncSchema = Schema([
  Table('profiles', [
    Column.text('full_name'),
    Column.text('username'),
    Column.text('avatar_url'),
    Column.text('created_at'),
  ]),
  Table('budgets', [
    Column.text('user_id'),
    Column.real('total_income'),
    Column.real('needs_amount'),
    Column.real('savings_amount'),
    Column.real('debt_amount'),
    Column.real('tithes_amount'),
    Column.text('updated_at'),
  ]),
  Table('transactions', [
    Column.text('user_id'),
    Column.text('type'),
    Column.real('amount'),
    Column.text('description'),
    Column.text('category'),
    Column.text('created_at'),
  ]),
  Table('goals', [
    Column.text('user_id'),
    Column.text('name'),
    Column.real('target_amount'),
    Column.real('current_amount'),
    Column.text('category'),
    Column.text('description'),
    Column.text('created_at'),
  ]),
  Table('feedback', [
    Column.text('user_id'),
    Column.integer('stars'),
    Column.text('comment'),
    Column.text('created_at'),
  ]),
]);
