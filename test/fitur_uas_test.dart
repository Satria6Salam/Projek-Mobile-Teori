import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/core/theme/app_icons.dart';
import 'package:smart_receipt/core/theme/category_palette.dart';
import 'package:smart_receipt/core/utils/month_utils.dart';
import 'package:smart_receipt/services/budget_service.dart';

void main() {
  group('MonthUtils', () {
    test('kunci bulan berformat yyyy-MM', () {
      expect(MonthUtils.key(DateTime(2026, 3, 5)), '2026-03');
      expect(MonthUtils.key(DateTime(2026, 11, 13)), '2026-11');
    });

    test('parse kebalikan dari key', () {
      expect(MonthUtils.parse('2026-02'), DateTime(2026, 2));
    });

    test('jumlah hari, termasuk tahun kabisat', () {
      expect(MonthUtils.daysIn(2024, 2), 29);
      expect(MonthUtils.daysIn(2026, 2), 28);
      expect(MonthUtils.daysIn(2026, 4), 30);
    });

    test('akhir bulan eksklusif melewati Desember ke Januari', () {
      expect(
        MonthUtils.endExclusive(DateTime(2026, 12, 3)),
        DateTime(2027, 1),
      );
    });
  });

  group('BudgetRow dan BudgetSnapshot', () {
    test('rasio pemakaian dihitung dari batas', () {
      const BudgetRow row =
          BudgetRow(name: 'Makanan', spent: 50000, limit: 100000);
      expect(row.hasLimit, isTrue);
      expect(row.ratio, closeTo(0.5, 1e-9));
    });

    test('tanpa batas, rasio nol dan hasLimit false', () {
      const BudgetRow row = BudgetRow(name: 'Lainnya', spent: 12000);
      expect(row.hasLimit, isFalse);
      expect(row.ratio, 0);
    });

    test('batas nol dianggap tidak ada', () {
      const BudgetRow row =
          BudgetRow(name: 'Lainnya', spent: 12000, limit: 0);
      expect(row.hasLimit, isFalse);
    });

    test('pemakaian melewati batas menghasilkan rasio di atas 1', () {
      const BudgetRow row =
          BudgetRow(name: 'Belanja', spent: 150000, limit: 100000);
      expect(row.ratio, greaterThan(1));
    });

    test('rasio total pada snapshot', () {
      final BudgetSnapshot snapshot = BudgetSnapshot(
        month: DateTime(2026, 11),
        totalSpent: 400000,
        totalLimit: 1000000,
        rows: const <BudgetRow>[],
      );
      expect(snapshot.hasTotalLimit, isTrue);
      expect(snapshot.totalRatio, closeTo(0.4, 1e-9));
    });
  });

  group('CategoryPalette', () {
    test('kunci ikon tidak dikenal memakai ikon tag', () {
      expect(CategoryPalette.iconFor(null), AppIcons.tag);
      expect(CategoryPalette.iconFor('tidak-ada'), AppIcons.tag);
    });

    test('kunci ikon yang dikenal memakai ikonnya sendiri', () {
      expect(CategoryPalette.iconFor('car'), AppIcons.car);
    });
  });
}
