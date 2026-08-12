import '../utils/format.dart';

class Profile {
  final String id;
  final String? fullName;
  final String? username;
  final String? avatarUrl;

  Profile({required this.id, this.fullName, this.username, this.avatarUrl});

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: m['full_name'] as String?,
        username: m['username'] as String?,
        avatarUrl: m['avatar_url'] as String?,
      );
}

/// One accumulating budget row per user. Each "Set" adds a new income's
/// allocation on top of the previous totals.
class Budget {
  final double totalIncome;
  final double needs;
  final double savings;
  final double debt;
  final double tithes;

  Budget({
    this.totalIncome = 0,
    this.needs = 0,
    this.savings = 0,
    this.debt = 0,
    this.tithes = 0,
  });

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
        totalIncome: asDouble(m['total_income']),
        needs: asDouble(m['needs_amount']),
        savings: asDouble(m['savings_amount']),
        debt: asDouble(m['debt_amount']),
        tithes: asDouble(m['tithes_amount']),
      );
}

class TransactionRecord {
  final String id;
  final String type; // 'income' | 'expense'
  final double amount;
  final String? description;
  final String category;
  final DateTime createdAt;

  TransactionRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.createdAt,
  });

  factory TransactionRecord.fromMap(Map<String, dynamic> m) => TransactionRecord(
        id: m['id'] as String,
        type: m['type'] as String,
        amount: asDouble(m['amount']),
        description: m['description'] as String?,
        category: m['category'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}

class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? category;
  final String? description;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.category,
    this.description,
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1).toDouble();
  int get percent => (progress * 100).round();

  factory Goal.fromMap(Map<String, dynamic> m) => Goal(
        id: m['id'] as String,
        name: m['name'] as String,
        targetAmount: asDouble(m['target_amount']),
        currentAmount: asDouble(m['current_amount']),
        category: m['category'] as String?,
        description: m['description'] as String?,
      );
}