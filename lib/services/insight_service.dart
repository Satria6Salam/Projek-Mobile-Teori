import 'dart:math' as math;

import '../core/utils/dashboard_period.dart';
import '../core/utils/formatters.dart';
import '../data/models/category_summary_model.dart';
import '../data/models/transaction_model.dart';

enum InsightKind { positive, warning, info, tip }

enum InsightTopic {
  trend,
  projection,
  category,
  shift,
  weekend,
  weekday,
  merchant,
  biggest,
  smallSpend,
  tip,
  data,
  monthlyTrend,
  yearlyTrend,
}

/// Satu temuan dari analisis perilaku pengeluaran.
class Insight {
  const Insight({
    required this.kind,
    required this.topic,
    required this.title,
    required this.message,
  });

  final InsightKind kind;
  final InsightTopic topic;
  final String title;
  final String message;
}

class DailySpending {
  const DailySpending({required this.day, required this.amount});

  /// Tanggal (1 - 31).
  final int day;
  final double amount;
}

class MerchantStat {
  const MerchantStat({
    required this.name,
    required this.visits,
    required this.total,
  });

  final String name;
  final int visits;
  final double total;
}

/// Tipe pengeluaran pengguna berdasarkan kategori dominan.
class SpendingPersona {
  const SpendingPersona({
    required this.title,
    required this.description,
    this.categoryName,
    this.sharePercent = 0,
  });

  final String title;
  final String description;
  final String? categoryName;
  final double sharePercent;
}

/// Hasil analisis satu periode (hari, bulan, atau tahun).
class SpendingAnalytics {
  const SpendingAnalytics({
    this.total = 0,
    this.transactionCount = 0,
    this.previousToDate = 0,
    this.previousMonthTotal = 0,
    this.changePercent,
    this.averagePerDay = 0,
    this.averagePerTransaction = 0,
    this.projectedTotal = 0,
    this.daysElapsed = 0,
    this.totalDays = 30,
    this.activeDays = 0,
    this.isCurrentPeriod = true,
    this.dailyTotals = const <DailySpending>[],
    this.topMerchants = const <MerchantStat>[],
    this.biggestTransaction,
    this.persona,
    this.insights = const <Insight>[],
  });

  final double total;
  final int transactionCount;

  /// Total periode sebelumnya pada rentang yang sama (adil untuk dibandingkan).
  final double previousToDate;

  /// Total penuh periode sebelumnya.
  final double previousMonthTotal;

  /// Perubahan (%) dibanding periode yang sama sebelumnya; null bila tidak ada pembanding.
  final double? changePercent;
  final double averagePerDay;
  final double averagePerTransaction;
  final double projectedTotal;
  final int daysElapsed;
  final int totalDays;

  /// Jumlah hari yang memiliki pengeluaran.
  final int activeDays;
  final bool isCurrentPeriod;

  /// Total harian (hanya untuk periode bulan).
  final List<DailySpending> dailyTotals;
  final List<MerchantStat> topMerchants;
  final TransactionModel? biggestTransaction;
  final SpendingPersona? persona;
  final List<Insight> insights;

  bool get hasData => transactionCount > 0;

  // Nama lama, dipertahankan agar kompatibel.
  double get monthlyTotal => total;
  int get daysInMonth => totalDays;
  bool get isCurrentMonth => isCurrentPeriod;
}

class YearlyPoint {
  const YearlyPoint({required this.year, required this.amount});

  final int year;
  final double amount;
}

/// Hasil analisis tren bulanan (dalam satu tahun) dan tren tahunan.
class TrendAnalytics {
  const TrendAnalytics({
    this.year = 0,
    this.monthlyTotals = const <double>[],
    this.yearlyTotals = const <YearlyPoint>[],
    this.monthlyAverage = 0,
    this.peakMonth,
    this.activeMonths = 0,
    this.yearOverYearPercent,
    this.insights = const <Insight>[],
  });

  final int year;

  /// 12 nilai, indeks 0 = Januari.
  final List<double> monthlyTotals;
  final List<YearlyPoint> yearlyTotals;

  /// Rata-rata pada bulan yang memiliki pengeluaran.
  final double monthlyAverage;

  /// 1 - 12; null bila tidak ada data.
  final int? peakMonth;
  final int activeMonths;

  /// Perubahan (%) dibanding tahun sebelumnya pada rentang bulan yang sama.
  final double? yearOverYearPercent;
  final List<Insight> insights;

  bool get hasData =>
      monthlyTotals.any((double v) => v > 0) || yearlyTotals.isNotEmpty;
}

/// Menganalisis kebiasaan pengeluaran dari data transaksi (murni Dart).
class InsightService {
  const InsightService();

  static const List<String> _weekdayNames = <String>[
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _monthNames = <String>[
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const double _smallSpendLimit = 25000;
  static const int _minTransactionsForBehavior = 3;

  int _daysBetween(DateTime a, DateTime b) {
    return DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;
  }

  /// Analisis satu bulan (pembungkus [analyzePeriod]).
  SpendingAnalytics analyze({
    required DateTime month,
    required DateTime now,
    required List<TransactionModel> transactions,
    required List<CategorySummaryModel> summaries,
    required double monthlyTotal,
    List<TransactionModel> previousTransactions = const <TransactionModel>[],
  }) {
    return analyzePeriod(
      period: DashboardPeriod.month(month.year, month.month),
      now: now,
      transactions: transactions,
      summaries: summaries,
      total: monthlyTotal,
      previousTransactions: previousTransactions,
    );
  }

  /// Analisis satu periode: hari, bulan, atau tahun.
  SpendingAnalytics analyzePeriod({
    required DashboardPeriod period,
    required DateTime now,
    required List<TransactionModel> transactions,
    required List<CategorySummaryModel> summaries,
    required double total,
    List<TransactionModel> previousTransactions = const <TransactionModel>[],
  }) {
    final int totalDays = period.totalDays;
    final DateTime today = DateTime(now.year, now.month, now.day);
    final bool isCurrent = period.isCurrent(now);
    final int daysElapsed = isCurrent
        ? math.min(_daysBetween(period.start, today) + 1, totalDays)
        : totalDays;
    final int count = transactions.length;
    final bool isDay = period.mode == PeriodMode.day;

    // Total harian (hanya bermakna untuk periode bulan).
    List<DailySpending> dailyTotals = const <DailySpending>[];
    if (period.mode == PeriodMode.month) {
      final List<double> daily = List<double>.filled(totalDays, 0);
      for (final TransactionModel t in transactions) {
        final int day = t.transactionDate.day;
        if (day >= 1 && day <= totalDays) daily[day - 1] += t.totalAmount;
      }
      dailyTotals = <DailySpending>[
        for (int d = 1; d <= totalDays; d++)
          DailySpending(day: d, amount: daily[d - 1]),
      ];
    }

    final Set<int> activeKeys = <int>{
      for (final TransactionModel t in transactions)
        t.transactionDate.year * 10000 +
            t.transactionDate.month * 100 +
            t.transactionDate.day,
    };

    // Pembanding periode sebelumnya pada rentang yang sama.
    final DashboardPeriod prev = period.previous;
    final DateTime previousCut = isCurrent
        ? DateTime(
            prev.start.year, prev.start.month, prev.start.day + daysElapsed)
        : prev.endExclusive;
    double previousToDate = 0;
    double previousTotal = 0;
    for (final TransactionModel t in previousTransactions) {
      previousTotal += t.totalAmount;
      final DateTime d = DateTime(
        t.transactionDate.year,
        t.transactionDate.month,
        t.transactionDate.day,
      );
      if (d.isBefore(previousCut)) previousToDate += t.totalAmount;
    }
    final double? changePercent = previousToDate > 0
        ? (total - previousToDate) / previousToDate * 100
        : null;

    final double avgPerDay = daysElapsed > 0 ? total / daysElapsed : 0;
    final double avgPerTx = count > 0 ? total / count : 0;
    final double projected =
        (isCurrent && !isDay) ? avgPerDay * totalDays : total;

    // Merchant.
    final Map<String, _MerchantAcc> merchants = <String, _MerchantAcc>{};
    for (final TransactionModel t in transactions) {
      final String key = t.merchantName.trim().toLowerCase();
      if (key.isEmpty) continue;
      final _MerchantAcc acc =
          merchants.putIfAbsent(key, () => _MerchantAcc(t.merchantName.trim()));
      acc.visits++;
      acc.total += t.totalAmount;
    }
    final List<MerchantStat> topMerchants = merchants.values
        .map((_MerchantAcc a) =>
            MerchantStat(name: a.name, visits: a.visits, total: a.total))
        .toList()
      ..sort((MerchantStat a, MerchantStat b) {
        final int byTotal = b.total.compareTo(a.total);
        return byTotal != 0 ? byTotal : b.visits.compareTo(a.visits);
      });

    // Transaksi terbesar.
    TransactionModel? biggest;
    for (final TransactionModel t in transactions) {
      if (biggest == null || t.totalAmount > biggest.totalAmount) biggest = t;
    }

    // Hari dalam seminggu.
    final List<double> weekdayTotals = List<double>.filled(7, 0);
    for (final TransactionModel t in transactions) {
      weekdayTotals[t.transactionDate.weekday - 1] += t.totalAmount;
    }
    int weekendDays = 0;
    int weekdayDays = 0;
    for (int d = 0; d < daysElapsed; d++) {
      final int wd = DateTime(
        period.start.year,
        period.start.month,
        period.start.day + d,
      ).weekday;
      if (wd >= 6) {
        weekendDays++;
      } else {
        weekdayDays++;
      }
    }
    final double weekendTotal = weekdayTotals[5] + weekdayTotals[6];
    final double weekdayTotal = total - weekendTotal;
    final double weekendAvg = weekendDays > 0 ? weekendTotal / weekendDays : 0;
    final double weekdayAvg = weekdayDays > 0 ? weekdayTotal / weekdayDays : 0;

    // Kategori.
    double categoryTotal = 0;
    CategorySummaryModel? top;
    for (final CategorySummaryModel s in summaries) {
      categoryTotal += s.totalAmount;
      if (top == null || s.totalAmount > top.totalAmount) top = s;
    }
    final double topShare = (top != null && categoryTotal > 0)
        ? top.totalAmount / categoryTotal
        : 0;

    // Kata-kata menurut jenis periode.
    final String periodText;
    final String compareText;
    final String periodNoun;
    switch (period.mode) {
      case PeriodMode.day:
        periodText = isCurrent ? 'Hari ini' : 'Pada hari itu';
        compareText = 'hari sebelumnya';
        periodNoun = 'hari ini';
      case PeriodMode.month:
        periodText =
            isCurrent ? 'Hingga tanggal $daysElapsed' : 'Sepanjang bulan';
        compareText =
            isCurrent ? 'periode yang sama bulan lalu' : 'bulan sebelumnya';
        periodNoun = 'bulan ini';
      case PeriodMode.year:
        periodText = isCurrent ? 'Sejak awal tahun' : 'Sepanjang tahun';
        compareText =
            isCurrent ? 'periode yang sama tahun lalu' : 'tahun sebelumnya';
        periodNoun = 'tahun ini';
    }

    final List<Insight> insights = <Insight>[];

    if (count < _minTransactionsForBehavior) {
      insights.add(
        const Insight(
          kind: InsightKind.info,
          topic: InsightTopic.data,
          title: 'Data masih sedikit',
          message:
              'Catat minimal 3 transaksi agar analisis kebiasaan pengeluaran Anda lebih akurat.',
        ),
      );
    } else {
      // 1. Tren dibanding periode sebelumnya.
      final double? change = changePercent;
      if (change != null) {
        final int pct = change.abs().round();
        if (change >= 15) {
          insights.add(Insight(
            kind: InsightKind.warning,
            topic: InsightTopic.trend,
            title: 'Pengeluaran naik $pct%',
            message:
                '$periodText pengeluaran Anda ${AppFormatters.rupiah(total)}, lebih tinggi $pct% dari $compareText (${AppFormatters.rupiah(previousToDate)}).',
          ));
        } else if (change <= -10) {
          insights.add(Insight(
            kind: InsightKind.positive,
            topic: InsightTopic.trend,
            title: 'Pengeluaran turun $pct%',
            message:
                'Bagus! $periodText pengeluaran Anda ${AppFormatters.rupiah(total)}, lebih hemat $pct% dari $compareText (${AppFormatters.rupiah(previousToDate)}).',
          ));
        } else {
          insights.add(Insight(
            kind: InsightKind.info,
            topic: InsightTopic.trend,
            title: 'Pengeluaran stabil',
            message:
                'Pengeluaran Anda relatif sama dengan $compareText (${AppFormatters.rupiah(previousToDate)}).',
          ));
        }
      }

      // 2. Proyeksi akhir periode.
      final int minDays = period.mode == PeriodMode.year ? 30 : 3;
      if (isCurrent && !isDay && daysElapsed >= minDays && total > 0) {
        final bool overPrev =
            previousTotal > 0 && projected > previousTotal * 1.2;
        insights.add(Insight(
          kind: overPrev ? InsightKind.warning : InsightKind.info,
          topic: InsightTopic.projection,
          title: period.mode == PeriodMode.year
              ? 'Proyeksi akhir tahun'
              : 'Proyeksi akhir bulan',
          message:
              'Dengan pola saat ini (${AppFormatters.rupiah(avgPerDay)} per hari), total $periodNoun diperkirakan ${AppFormatters.rupiah(projected)}'
              '${overPrev ? ', melebihi total periode sebelumnya (${AppFormatters.rupiah(previousTotal)}).' : '.'}',
        ));
      }

      // 3. Kategori dominan.
      if (top != null && topShare >= 0.5) {
        insights.add(Insight(
          kind: InsightKind.warning,
          topic: InsightTopic.category,
          title: '${top.categoryName} mendominasi',
          message:
              '${(topShare * 100).round()}% pengeluaran Anda (${AppFormatters.rupiah(top.totalAmount)}) tersedot ke kategori ${top.categoryName}.',
        ));
      }

      // 4. Akhir pekan vs hari kerja (hanya untuk periode >= 1 minggu).
      if (!isDay &&
          totalDays >= 7 &&
          count >= 5 &&
          weekendDays > 0 &&
          weekdayDays > 0) {
        if (weekdayAvg > 0 && weekendAvg > weekdayAvg * 1.5) {
          insights.add(Insight(
            kind: InsightKind.warning,
            topic: InsightTopic.weekend,
            title: 'Lebih boros di akhir pekan',
            message:
                'Rata-rata ${AppFormatters.rupiah(weekendAvg)} per hari di Sabtu-Minggu, dibanding ${AppFormatters.rupiah(weekdayAvg)} di hari kerja.',
          ));
        } else if (weekendAvg > 0 && weekdayAvg > weekendAvg * 1.5) {
          insights.add(Insight(
            kind: InsightKind.info,
            topic: InsightTopic.weekend,
            title: 'Pengeluaran terpusat di hari kerja',
            message:
                'Rata-rata ${AppFormatters.rupiah(weekdayAvg)} per hari kerja, jauh di atas akhir pekan (${AppFormatters.rupiah(weekendAvg)}).',
          ));
        }
      }

      // 5. Hari paling boros.
      if (!isDay && totalDays >= 7 && count >= 5) {
        int busiest = 0;
        for (int i = 1; i < 7; i++) {
          if (weekdayTotals[i] > weekdayTotals[busiest]) busiest = i;
        }
        if (weekdayTotals[busiest] > 0) {
          insights.add(Insight(
            kind: InsightKind.info,
            topic: InsightTopic.weekday,
            title: 'Hari paling boros: ${_weekdayNames[busiest]}',
            message:
                'Total pengeluaran setiap hari ${_weekdayNames[busiest]} pada periode ini mencapai ${AppFormatters.rupiah(weekdayTotals[busiest])}.',
          ));
        }
      }

      // 6. Merchant langganan.
      MerchantStat? frequent;
      for (final MerchantStat m in topMerchants) {
        if (frequent == null || m.visits > frequent.visits) frequent = m;
      }
      if (frequent != null && frequent.visits >= 3) {
        insights.add(Insight(
          kind: InsightKind.info,
          topic: InsightTopic.merchant,
          title: 'Langganan: ${frequent.name}',
          message:
              'Anda berbelanja ${frequent.visits} kali di ${frequent.name} dengan total ${AppFormatters.rupiah(frequent.total)}.',
        ));
      }

      // 7. Transaksi terbesar.
      if (biggest != null && total > 0) {
        final double share = biggest.totalAmount / total;
        final DateTime bd = biggest.transactionDate;
        insights.add(Insight(
          kind: share >= 0.3 ? InsightKind.warning : InsightKind.info,
          topic: InsightTopic.biggest,
          title: share >= 0.3
              ? 'Satu transaksi mendominasi'
              : 'Transaksi terbesar',
          message:
              '${AppFormatters.rupiah(biggest.totalAmount)} di ${biggest.merchantName} (${bd.day}/${bd.month}/${bd.year}), setara ${(share * 100).round()}% dari total periode ini.',
        ));
      }

      // 8. Pengeluaran kecil yang menumpuk.
      final List<TransactionModel> small = transactions
          .where((TransactionModel t) => t.totalAmount < _smallSpendLimit)
          .toList();
      if (small.length >= 5 && small.length / count >= 0.4) {
        final double smallTotal = small.fold<double>(
          0,
          (double s, TransactionModel t) => s + t.totalAmount,
        );
        insights.add(Insight(
          kind: InsightKind.tip,
          topic: InsightTopic.smallSpend,
          title: 'Pengeluaran kecil menumpuk',
          message:
              '${small.length} transaksi di bawah ${AppFormatters.rupiah(_smallSpendLimit)} menghabiskan ${AppFormatters.rupiah(smallTotal)}. Pembelian kecil yang sering mudah terlewat.',
        ));
      }

      // 9. Saran sesuai kategori dominan.
      if (top != null && topShare >= 0.35) {
        final String? tip = _tipFor(top.categoryName);
        if (tip != null) {
          insights.add(Insight(
            kind: InsightKind.tip,
            topic: InsightTopic.tip,
            title: 'Saran untuk ${top.categoryName}',
            message: tip,
          ));
        }
      }
    }

    return SpendingAnalytics(
      total: total,
      transactionCount: count,
      previousToDate: previousToDate,
      previousMonthTotal: previousTotal,
      changePercent: changePercent,
      averagePerDay: avgPerDay,
      averagePerTransaction: avgPerTx,
      projectedTotal: projected,
      daysElapsed: daysElapsed,
      totalDays: totalDays,
      activeDays: activeKeys.length,
      isCurrentPeriod: isCurrent,
      dailyTotals: dailyTotals,
      topMerchants: topMerchants.take(5).toList(),
      biggestTransaction: biggest,
      persona:
          count >= _minTransactionsForBehavior ? _persona(top, topShare) : null,
      insights: _ordered(insights, 7),
    );
  }

  /// Analisis tren: total per bulan dalam [year], dan total per tahun.
  TrendAnalytics analyzeTrends({
    required int year,
    required DateTime now,
    required List<double> monthlyTotals,
    required List<double> previousYearMonthlyTotals,
    required Map<int, double> yearlyTotals,
  }) {
    final List<double> months = _twelve(monthlyTotals);
    final List<double> prevMonths = _twelve(previousYearMonthlyTotals);

    // Rentang bulan yang adil dibandingkan: tahun berjalan hanya sampai bulan ini.
    final int cutoff =
        year == now.year ? now.month : (year > now.year ? 0 : 12);

    double sum = 0;
    int active = 0;
    int? peak;
    double peakValue = 0;
    for (int i = 0; i < 12; i++) {
      final double v = months[i];
      if (v > 0) {
        sum += v;
        active++;
        if (v > peakValue) {
          peakValue = v;
          peak = i + 1;
        }
      }
    }
    final double average = active > 0 ? sum / active : 0;

    double ytdCurrent = 0;
    double ytdPrevious = 0;
    for (int i = 0; i < cutoff; i++) {
      ytdCurrent += months[i];
      ytdPrevious += prevMonths[i];
    }
    final double? yoy =
        ytdPrevious > 0 ? (ytdCurrent - ytdPrevious) / ytdPrevious * 100 : null;

    final List<YearlyPoint> yearly = (yearlyTotals.entries
        .map((MapEntry<int, double> e) =>
            YearlyPoint(year: e.key, amount: e.value))
        .toList()
      ..sort((YearlyPoint a, YearlyPoint b) => a.year.compareTo(b.year)));

    final List<Insight> insights = <Insight>[];
    if (active == 0 && yearly.isEmpty) {
      insights.add(
        const Insight(
          kind: InsightKind.info,
          topic: InsightTopic.monthlyTrend,
          title: 'Belum ada data tren',
          message:
              'Catat transaksi pada beberapa bulan agar tren bulanan dan tahunan dapat dianalisis.',
        ),
      );
    } else if (active > 0) {
      final int peakMonth = peak ?? 1;
      insights.add(Insight(
        kind: InsightKind.info,
        topic: InsightTopic.monthlyTrend,
        title: 'Bulan terboros: ${_monthNames[peakMonth - 1]}',
        message:
            'Pengeluaran tertinggi tahun $year terjadi pada ${_monthNames[peakMonth - 1]} sebesar ${AppFormatters.rupiah(peakValue)}. Rata-rata bulanan ${AppFormatters.rupiah(average)} (dari $active bulan tercatat).',
      ));

      // Tiga bulan terakhir yang berurutan.
      final List<int> activeIdx = <int>[
        for (int i = 0; i < 12; i++)
          if (months[i] > 0 && (cutoff == 0 || i < cutoff)) i,
      ];
      if (activeIdx.length >= 3) {
        final int c = activeIdx[activeIdx.length - 1];
        final int b = activeIdx[activeIdx.length - 2];
        final int a = activeIdx[activeIdx.length - 3];
        if (c - b == 1 && b - a == 1) {
          if (months[a] < months[b] && months[b] < months[c]) {
            insights.add(Insight(
              kind: InsightKind.warning,
              topic: InsightTopic.monthlyTrend,
              title: 'Naik 3 bulan berturut-turut',
              message:
                  'Pengeluaran terus naik dari ${_monthNames[a]} (${AppFormatters.rupiah(months[a])}) hingga ${_monthNames[c]} (${AppFormatters.rupiah(months[c])}).',
            ));
          } else if (months[a] > months[b] && months[b] > months[c]) {
            insights.add(Insight(
              kind: InsightKind.positive,
              topic: InsightTopic.monthlyTrend,
              title: 'Turun 3 bulan berturut-turut',
              message:
                  'Pengeluaran terus turun dari ${_monthNames[a]} (${AppFormatters.rupiah(months[a])}) hingga ${_monthNames[c]} (${AppFormatters.rupiah(months[c])}). Pertahankan!',
            ));
          }
        }
      }

      // Bulan terakhir dibanding bulan sebelumnya.
      if (activeIdx.length >= 2) {
        final int last = activeIdx[activeIdx.length - 1];
        final int before = activeIdx[activeIdx.length - 2];
        if (last - before == 1 && months[before] > 0) {
          final double change =
              (months[last] - months[before]) / months[before] * 100;
          if (change.abs() >= 20) {
            final int pct = change.abs().round();
            insights.add(Insight(
              kind: change > 0 ? InsightKind.warning : InsightKind.positive,
              topic: InsightTopic.monthlyTrend,
              title: change > 0
                  ? '${_monthNames[last]} naik $pct%'
                  : '${_monthNames[last]} turun $pct%',
              message:
                  '${_monthNames[last]} (${AppFormatters.rupiah(months[last])}) ${change > 0 ? 'lebih tinggi' : 'lebih rendah'} $pct% dibanding ${_monthNames[before]} (${AppFormatters.rupiah(months[before])}).',
            ));
          }
        }
      }
    }

    // Tren tahunan.
    final double? y = yoy;
    if (y != null) {
      final int pct = y.abs().round();
      final String span = cutoff >= 12 || cutoff == 0
          ? 'Sepanjang tahun $year'
          : 'Januari hingga ${_monthNames[cutoff - 1]} $year';
      if (y >= 15) {
        insights.add(Insight(
          kind: InsightKind.warning,
          topic: InsightTopic.yearlyTrend,
          title: 'Lebih boros $pct% dari tahun lalu',
          message:
              '$span pengeluaran ${AppFormatters.rupiah(ytdCurrent)}, naik $pct% dibanding rentang yang sama tahun ${year - 1} (${AppFormatters.rupiah(ytdPrevious)}).',
        ));
      } else if (y <= -10) {
        insights.add(Insight(
          kind: InsightKind.positive,
          topic: InsightTopic.yearlyTrend,
          title: 'Lebih hemat $pct% dari tahun lalu',
          message:
              '$span pengeluaran ${AppFormatters.rupiah(ytdCurrent)}, turun $pct% dibanding rentang yang sama tahun ${year - 1} (${AppFormatters.rupiah(ytdPrevious)}).',
        ));
      } else {
        insights.add(Insight(
          kind: InsightKind.info,
          topic: InsightTopic.yearlyTrend,
          title: 'Setara dengan tahun lalu',
          message:
              '$span pengeluaran ${AppFormatters.rupiah(ytdCurrent)}, relatif sama dengan tahun ${year - 1} (${AppFormatters.rupiah(ytdPrevious)}).',
        ));
      }
    }

    return TrendAnalytics(
      year: year,
      monthlyTotals: months,
      yearlyTotals: yearly,
      monthlyAverage: average,
      peakMonth: peak,
      activeMonths: active,
      yearOverYearPercent: yoy,
      insights: _ordered(insights, 5),
    );
  }

  List<double> _twelve(List<double> values) {
    return <double>[
      for (int i = 0; i < 12; i++) i < values.length ? values[i] : 0.0,
    ];
  }

  /// Urutkan: peringatan dulu, lalu kabar baik, info, saran (urutan awal dipertahankan).
  List<Insight> _ordered(List<Insight> insights, int limit) {
    final List<MapEntry<int, Insight>> indexed = <MapEntry<int, Insight>>[
      for (int i = 0; i < insights.length; i++)
        MapEntry<int, Insight>(i, insights[i]),
    ]..sort((MapEntry<int, Insight> a, MapEntry<int, Insight> b) {
        final int byKind = _rank(a.value.kind).compareTo(_rank(b.value.kind));
        return byKind != 0 ? byKind : a.key.compareTo(b.key);
      });
    return indexed
        .map((MapEntry<int, Insight> e) => e.value)
        .take(limit)
        .toList();
  }

  int _rank(InsightKind kind) {
    switch (kind) {
      case InsightKind.warning:
        return 0;
      case InsightKind.positive:
        return 1;
      case InsightKind.info:
        return 2;
      case InsightKind.tip:
        return 3;
    }
  }

  String? _tipFor(String category) {
    switch (category.toLowerCase()) {
      case 'konsumsi':
        return 'Coba bawa bekal atau masak sendiri 2-3 kali seminggu untuk menekan biaya makan di luar.';
      case 'transportasi':
        return 'Pertimbangkan transportasi umum atau berbagi tumpangan untuk perjalanan rutin.';
      case 'kesehatan':
        return 'Pastikan Anda memiliki perlindungan seperti BPJS atau asuransi, dan jaga pola hidup sehat untuk menekan biaya berobat.';
      case 'belanja':
        return 'Buat daftar belanja dan tunda pembelian non-esensial 24 jam untuk menghindari belanja impulsif.';
      case 'lainnya':
        return 'Tinjau tagihan dan langganan rutin; hentikan layanan yang jarang dipakai.';
      case 'elektronik':
        return 'Bandingkan harga dan garansi sebelum membeli perangkat; prioritaskan kebutuhan dibanding keinginan.';
    }
    return null;
  }

  SpendingPersona _persona(CategorySummaryModel? top, double share) {
    if (top == null || share < 0.35) {
      return const SpendingPersona(
        title: 'Pengeluar Seimbang',
        description:
            'Pengeluaran Anda tersebar merata di berbagai kategori, pola yang sehat untuk keuangan jangka panjang.',
      );
    }
    final double percent = share * 100;
    switch (top.categoryName.toLowerCase()) {
      case 'konsumsi':
        return SpendingPersona(
          title: 'Pencinta Kuliner',
          description:
              'Sebagian besar uang Anda mengalir ke makanan dan minuman. Menikmati hidup itu penting, pantau agar tetap terkendali.',
          categoryName: top.categoryName,
          sharePercent: percent,
        );
      case 'transportasi':
        return SpendingPersona(
          title: 'Si Mobilitas Tinggi',
          description:
              'Anda banyak bergerak! Biaya perjalanan dan kendaraan menjadi pos terbesar pada periode ini.',
          categoryName: top.categoryName,
          sharePercent: percent,
        );
      case 'kesehatan':
        return SpendingPersona(
          title: 'Peduli Kesehatan',
          description:
              'Anda memprioritaskan kesehatan. Pastikan perlindungan seperti BPJS atau asuransi sudah memadai.',
          categoryName: top.categoryName,
          sharePercent: percent,
        );
      case 'belanja':
        return SpendingPersona(
          title: 'Pemburu Belanja',
          description:
              'Kebutuhan pribadi dan rumah tangga mendominasi pengeluaran Anda. Daftar belanja membantu menghindari pembelian impulsif.',
          categoryName: top.categoryName,
          sharePercent: percent,
        );
      case 'elektronik':
        return SpendingPersona(
          title: 'Pecinta Gadget',
          description:
              'Perangkat dan komponen elektronik menjadi pos terbesar Anda. Bandingkan harga dan cek garansi sebelum membeli.',
          categoryName: top.categoryName,
          sharePercent: percent,
        );
      default:
        return SpendingPersona(
          title: 'Pengelola Tagihan',
          description:
              'Tagihan, layanan, dan kebutuhan rutin mendominasi. Tinjau langganan secara berkala agar tidak ada yang terlupa.',
          categoryName: top.categoryName,
          sharePercent: percent,
        );
    }
  }
}

class _MerchantAcc {
  _MerchantAcc(this.name);

  final String name;
  int visits = 0;
  double total = 0;
}
