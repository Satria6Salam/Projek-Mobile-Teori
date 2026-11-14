import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';

/// Representasi tabel `budgets`. [categoryId] kosong berarti batas total bulanan.
class BudgetModel {
  const BudgetModel({
    this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int userId;
  final int? categoryId;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BudgetModel.fromMap(Map<String, Object?> map) {
    return BudgetModel(
      id: map[BudgetCols.id] as int?,
      userId: map[BudgetCols.userId] as int? ?? 0,
      categoryId: map[BudgetCols.categoryId] as int?,
      amount: (map[BudgetCols.amount] as num?)?.toDouble() ?? 0,
      createdAt: DbDateUtils.parseOrNow(map[BudgetCols.createdAt]),
      updatedAt: DbDateUtils.parseOrNow(map[BudgetCols.updatedAt]),
    );
  }
}
