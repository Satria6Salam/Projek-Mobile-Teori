import 'package:flutter_test/flutter_test.dart';
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
}
