import '../../core/constants/db_constants.dart';
import '../../core/utils/db_date_utils.dart';

/// Transaksi yang berulang setiap bulan (mis. internet, Netflix).
/// Transaksi bulanannya dibuat otomatis saat aplikasi dibuka.
class RecurringTransactionModel {
  const RecurringTransactionModel({
    this.id,
    required this.userId,
    required this.merchantName,
    required this.totalAmount,
    required this.categoryId,
    required this.dayOfMonth,
    required this.startMonth,
    this.lastGenerated,
    this.isActive = true,
    this.notes,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String merchantName;
  final double totalAmount;
  final int categoryId;

  /// Tanggal dalam bulan (1-31). Bulan pendek memakai tanggal terakhir.
  final int dayOfMonth;

  /// Bulan pertama, format "yyyy-MM".
  final String startMonth;

  /// Bulan terakhir transaksinya dibuat, format "yyyy-MM".
  final String? lastGenerated;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;

  factory RecurringTransactionModel.fromMap(Map<String, Object?> map) {
    return RecurringTransactionModel(
      id: map[RecurringCols.id] as int?,
      userId: map[RecurringCols.userId] as int? ?? 0,
      merchantName: map[RecurringCols.merchantName] as String? ?? '',
      totalAmount: (map[RecurringCols.totalAmount] as num?)?.toDouble() ?? 0,
      categoryId: map[RecurringCols.categoryId] as int? ?? 0,
      dayOfMonth: map[RecurringCols.dayOfMonth] as int? ?? 1,
      startMonth: map[RecurringCols.startMonth] as String? ?? '',
      lastGenerated: map[RecurringCols.lastGenerated] as String?,
      isActive: (map[RecurringCols.isActive] as int? ?? 1) == 1,
      notes: map[RecurringCols.notes] as String?,
      createdAt: DbDateUtils.parseOrNow(map[RecurringCols.createdAt]),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (id != null) RecurringCols.id: id,
      RecurringCols.userId: userId,
      RecurringCols.merchantName: merchantName,
      RecurringCols.totalAmount: totalAmount,
      RecurringCols.categoryId: categoryId,
      RecurringCols.dayOfMonth: dayOfMonth,
      RecurringCols.startMonth: startMonth,
      RecurringCols.lastGenerated: lastGenerated,
      RecurringCols.isActive: isActive ? 1 : 0,
      RecurringCols.notes: notes,
      RecurringCols.createdAt: DbDateUtils.dateTimeToDb(createdAt),
    };
  }
}
