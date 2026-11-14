import 'dart:math' as math;

import '../core/utils/month_utils.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/recurring_repository.dart';
import '../data/repositories/transaction_repository.dart';

/// Membuat transaksi bulanan dari daftar transaksi berulang yang sudah jatuh tempo.
class RecurringService {
  RecurringService({
    required RecurringRepository recurring,
    required TransactionRepository transactions,
  })  : _recurring = recurring,
        _transactions = transactions;

  final RecurringRepository _recurring;
  final TransactionRepository _transactions;

  /// Mengembalikan jumlah transaksi yang dibuat. Bulan yang sudah dibuat tidak
  /// digandakan, karena posisinya dicatat di kolom last_generated.
  Future<int> generateDue(int userId, {DateTime? now}) async {
    final DateTime current = now ?? DateTime.now();
    final String currentKey = MonthUtils.key(current);
    int created = 0;

    for (final rec in await _recurring.getAll(userId)) {
      if (!rec.isActive || rec.id == null) continue;

      DateTime cursor = MonthUtils.parse(rec.lastGenerated ?? rec.startMonth);
      if (rec.lastGenerated != null) {
        cursor = DateTime(cursor.year, cursor.month + 1);
      }

      while (MonthUtils.key(cursor).compareTo(currentKey) <= 0) {
        final int day = math.min(
          rec.dayOfMonth,
          MonthUtils.daysIn(cursor.year, cursor.month),
        );
        final DateTime date = DateTime(cursor.year, cursor.month, day);
        // Bulan berjalan menunggu sampai tanggalnya tiba.
        if (date.isAfter(current)) break;

        await _transactions.insert(
          TransactionModel(
            userId: userId,
            merchantName: rec.merchantName,
            transactionDate: date,
            totalAmount: rec.totalAmount,
            categoryId: rec.categoryId,
            notes: 'Otomatis (transaksi berulang)',
            createdAt: current,
            updatedAt: current,
          ),
        );
        await _recurring.setLastGenerated(rec.id!, MonthUtils.key(cursor));
        created++;
        cursor = DateTime(cursor.year, cursor.month + 1);
      }
    }
    return created;
  }
}
