import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/core/utils/dashboard_period.dart';
import 'package:smart_receipt/data/models/category_summary_model.dart';
import 'package:smart_receipt/data/models/transaction_model.dart';
import 'package:smart_receipt/services/insight_service.dart';

TransactionModel tx(
  int id,
  DateTime date,
  double amount, {
  String merchant = 'Toko A',
}) {
  return TransactionModel(
    id: id,
    userId: 1,
    merchantName: merchant,
    transactionDate: date,
    totalAmount: amount,
    categoryId: 1,
    createdAt: date,
    updatedAt: date,
  );
}

CategorySummaryModel summary(String name, double amount, int count) {
  return CategorySummaryModel(
    categoryId: name.length,
    categoryName: name,
    totalAmount: amount,
    transactionCount: count,
  );
}

bool hasTopic(SpendingAnalytics a, InsightTopic topic) =>
    a.insights.any((Insight i) => i.topic == topic);

void main() {
  const InsightService service = InsightService();
  final DateTime now = DateTime(2026, 10, 15);
  final DateTime month = DateTime(2026, 10);

  test('data sedikit menghasilkan pesan data dan tanpa profil', () {
    final SpendingAnalytics a = service.analyze(
      month: month,
      now: now,
      transactions: <TransactionModel>[
        tx(1, DateTime(2026, 10, 2), 50000),
        tx(2, DateTime(2026, 10, 3), 50000),
      ],
      summaries: <CategorySummaryModel>[summary('Konsumsi', 100000, 2)],
      monthlyTotal: 100000,
    );
    expect(hasTopic(a, InsightTopic.data), isTrue);
    expect(a.persona, isNull);
  });

  test('profil Pencinta Kuliner untuk kategori Konsumsi yang dominan', () {
    final SpendingAnalytics a = service.analyze(
      month: month,
      now: now,
      transactions: <TransactionModel>[
        tx(1, DateTime(2026, 10, 2), 30000),
        tx(2, DateTime(2026, 10, 3), 30000),
        tx(3, DateTime(2026, 10, 4), 20000),
      ],
      summaries: <CategorySummaryModel>[
        summary('Konsumsi', 60000, 2),
        summary('Belanja', 20000, 1),
      ],
      monthlyTotal: 80000,
    );
    expect(a.persona?.title, 'Pencinta Kuliner');
    expect(a.persona?.sharePercent, closeTo(75, 1e-9));
    expect(hasTopic(a, InsightTopic.category), isTrue);
  });

  test('pengeluaran naik dibanding periode yang sama bulan lalu', () {
    final SpendingAnalytics a = service.analyze(
      month: month,
      now: now,
      transactions: <TransactionModel>[
        tx(1, DateTime(2026, 10, 2), 100000),
        tx(2, DateTime(2026, 10, 5), 100000),
        tx(3, DateTime(2026, 10, 9), 50000),
        tx(4, DateTime(2026, 10, 12), 50000),
      ],
      summaries: <CategorySummaryModel>[summary('Belanja', 300000, 4)],
      monthlyTotal: 300000,
      previousTransactions: <TransactionModel>[
        tx(9, DateTime(2026, 9, 3), 100000),
      ],
    );
    expect(a.changePercent, closeTo(200, 1e-9));
    final Insight trend =
        a.insights.firstWhere((Insight i) => i.topic == InsightTopic.trend);
    expect(trend.kind, InsightKind.warning);
    expect(trend.title, 'Pengeluaran naik 200%');
  });

  test('pengeluaran turun dibanding bulan lalu menjadi kabar baik', () {
    final SpendingAnalytics a = service.analyze(
      month: month,
      now: now,
      transactions: <TransactionModel>[
        tx(1, DateTime(2026, 10, 2), 25000),
        tx(2, DateTime(2026, 10, 5), 25000),
        tx(3, DateTime(2026, 10, 9), 25000),
        tx(4, DateTime(2026, 10, 12), 25000),
      ],
      summaries: <CategorySummaryModel>[summary('Konsumsi', 100000, 4)],
      monthlyTotal: 100000,
      previousTransactions: <TransactionModel>[
        tx(9, DateTime(2026, 9, 3), 400000),
      ],
    );
    final Insight trend =
        a.insights.firstWhere((Insight i) => i.topic == InsightTopic.trend);
    expect(trend.kind, InsightKind.positive);
    expect(trend.title, 'Pengeluaran turun 75%');
  });

  test('rata-rata harian, proyeksi akhir bulan, dan total harian', () {
    final SpendingAnalytics a = service.analyze(
      month: month,
      now: now,
      transactions: <TransactionModel>[
        tx(1, DateTime(2026, 10, 2), 100000),
        tx(2, DateTime(2026, 10, 5), 100000),
        tx(3, DateTime(2026, 10, 9), 100000),
      ],
      summaries: <CategorySummaryModel>[summary('Konsumsi', 300000, 3)],
      monthlyTotal: 300000,
    );
    expect(a.daysElapsed, 15);
    expect(a.averagePerDay, closeTo(20000, 1e-9));
    expect(a.projectedTotal, closeTo(620000, 1e-6));
    expect(a.dailyTotals.length, 31);
    expect(a.dailyTotals[1].amount, 100000);
    expect(a.biggestTransaction?.totalAmount, 100000);
  });

  test('mendeteksi kecenderungan boros di akhir pekan', () {
    // Oktober 2026: tgl 3-4 dan 10-11 adalah Sabtu-Minggu.
    final SpendingAnalytics a = service.analyze(
      month: month,
      now: now,
      transactions: <TransactionModel>[
        tx(1, DateTime(2026, 10, 3), 200000),
        tx(2, DateTime(2026, 10, 4), 200000),
        tx(3, DateTime(2026, 10, 10), 200000),
        tx(4, DateTime(2026, 10, 5), 10000),
        tx(5, DateTime(2026, 10, 6), 10000),
        tx(6, DateTime(2026, 10, 7), 10000),
      ],
      summaries: <CategorySummaryModel>[summary('Belanja', 630000, 6)],
      monthlyTotal: 630000,
    );
    final Insight weekend =
        a.insights.firstWhere((Insight i) => i.topic == InsightTopic.weekend);
    expect(weekend.kind, InsightKind.warning);
    expect(weekend.title, 'Lebih boros di akhir pekan');
  });

  test('toko langganan dan daftar toko favorit', () {
    final SpendingAnalytics a = service.analyze(
      month: month,
      now: now,
      transactions: <TransactionModel>[
        tx(1, DateTime(2026, 10, 2), 20000, merchant: 'Kopi Kenangan'),
        tx(2, DateTime(2026, 10, 5), 20000, merchant: 'kopi kenangan'),
        tx(3, DateTime(2026, 10, 9), 20000, merchant: 'Kopi Kenangan'),
        tx(4, DateTime(2026, 10, 12), 90000, merchant: 'Hypermart'),
      ],
      summaries: <CategorySummaryModel>[summary('Konsumsi', 150000, 4)],
      monthlyTotal: 150000,
    );
    expect(hasTopic(a, InsightTopic.merchant), isTrue);
    expect(a.topMerchants.first.name, 'Hypermart');
    final MerchantStat kopi = a.topMerchants
        .firstWhere((MerchantStat m) => m.name.toLowerCase() == 'kopi kenangan');
    expect(kopi.visits, 3);
  });

  test('analisis tahun penuh: tanpa grafik harian dan rata-rata per hari', () {
    final SpendingAnalytics a = service.analyzePeriod(
      period: DashboardPeriod.year(2022),
      now: now,
      transactions: <TransactionModel>[
        tx(1, DateTime(2022, 3, 5), 365000),
        tx(2, DateTime(2022, 8, 9), 365000),
        tx(3, DateTime(2022, 11, 2), 365000),
      ],
      summaries: <CategorySummaryModel>[summary('Elektronik', 1095000, 3)],
      total: 1095000,
    );
    expect(a.isCurrentPeriod, isFalse);
    expect(a.totalDays, 365);
    expect(a.dailyTotals, isEmpty);
    expect(a.activeDays, 3);
    expect(a.averagePerDay, closeTo(3000, 1e-9));
    expect(a.persona?.title, 'Pecinta Gadget');
  });

  test('analisis satu hari', () {
    final SpendingAnalytics a = service.analyzePeriod(
      period: DashboardPeriod.day(DateTime(2019, 11, 16)),
      now: now,
      transactions: <TransactionModel>[
        tx(1, DateTime(2019, 11, 16), 500000),
        tx(2, DateTime(2019, 11, 16), 375000),
      ],
      summaries: <CategorySummaryModel>[summary('Elektronik', 875000, 2)],
      total: 875000,
    );
    expect(a.totalDays, 1);
    expect(a.transactionCount, 2);
    expect(a.biggestTransaction?.totalAmount, 500000);
  });

  group('tren bulanan dan tahunan', () {
    List<double> months(Map<int, double> values) {
      return <double>[for (int m = 1; m <= 12; m++) values[m] ?? 0];
    }

    test('mendeteksi kenaikan 3 bulan berturut-turut, bulan terboros, dan YoY', () {
      final TrendAnalytics t = service.analyzeTrends(
        year: 2026,
        now: now, // 15 Oktober 2026
        monthlyTotals: months(<int, double>{7: 100000, 8: 200000, 9: 300000}),
        previousYearMonthlyTotals:
            months(<int, double>{3: 100000, 4: 100000, 8: 200000}),
        yearlyTotals: <int, double>{2025: 400000, 2026: 600000},
      );

      expect(t.peakMonth, 9);
      expect(t.activeMonths, 3);
      expect(t.monthlyAverage, closeTo(200000, 1e-9));
      expect(t.yearOverYearPercent, closeTo(50, 1e-9));
      expect(t.yearlyTotals.length, 2);
      expect(t.yearlyTotals.first.year, 2025);

      bool has(InsightTopic topic, String title) => t.insights.any(
            (Insight i) => i.topic == topic && i.title == title,
          );
      expect(has(InsightTopic.monthlyTrend, 'Naik 3 bulan berturut-turut'), isTrue);
      expect(has(InsightTopic.monthlyTrend, 'Bulan terboros: September'), isTrue);
      expect(has(InsightTopic.yearlyTrend, 'Lebih boros 50% dari tahun lalu'), isTrue);
    });

    test('tanpa data menghasilkan pesan belum ada data tren', () {
      final TrendAnalytics t = service.analyzeTrends(
        year: 2026,
        now: now,
        monthlyTotals: months(<int, double>{}),
        previousYearMonthlyTotals: months(<int, double>{}),
        yearlyTotals: <int, double>{},
      );
      expect(t.hasData, isFalse);
      expect(t.insights.first.title, 'Belum ada data tren');
    });
  });
}
