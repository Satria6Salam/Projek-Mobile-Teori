/// Jenis periode yang dapat ditampilkan pada Dasbor.
enum PeriodMode { day, month, year }

/// Periode waktu yang sedang dilihat pada Dasbor: satu hari, satu bulan, atau satu tahun.
class DashboardPeriod {
  const DashboardPeriod._(this.mode, this.anchor);

  /// Satu hari tertentu.
  factory DashboardPeriod.day(DateTime date) {
    return DashboardPeriod._(
      PeriodMode.day,
      DateTime(date.year, date.month, date.day),
    );
  }

  /// Satu bulan tertentu.
  factory DashboardPeriod.month(int year, int month) {
    return DashboardPeriod._(PeriodMode.month, DateTime(year, month));
  }

  /// Satu tahun penuh.
  factory DashboardPeriod.year(int year) {
    return DashboardPeriod._(PeriodMode.year, DateTime(year));
  }

  /// Bulan berjalan.
  factory DashboardPeriod.currentMonth(DateTime now) {
    return DashboardPeriod.month(now.year, now.month);
  }

  final PeriodMode mode;

  /// Hari: tanggal tersebut. Bulan: tanggal 1. Tahun: 1 Januari.
  final DateTime anchor;

  DateTime get start => anchor;

  /// Batas akhir (eksklusif).
  DateTime get endExclusive {
    switch (mode) {
      case PeriodMode.day:
        return DateTime(anchor.year, anchor.month, anchor.day + 1);
      case PeriodMode.month:
        return DateTime(anchor.year, anchor.month + 1);
      case PeriodMode.year:
        return DateTime(anchor.year + 1);
    }
  }

  DashboardPeriod get previous {
    switch (mode) {
      case PeriodMode.day:
        return DashboardPeriod.day(
          DateTime(anchor.year, anchor.month, anchor.day - 1),
        );
      case PeriodMode.month:
        return DashboardPeriod.month(anchor.year, anchor.month - 1);
      case PeriodMode.year:
        return DashboardPeriod.year(anchor.year - 1);
    }
  }

  DashboardPeriod get next {
    switch (mode) {
      case PeriodMode.day:
        return DashboardPeriod.day(
          DateTime(anchor.year, anchor.month, anchor.day + 1),
        );
      case PeriodMode.month:
        return DashboardPeriod.month(anchor.year, anchor.month + 1);
      case PeriodMode.year:
        return DashboardPeriod.year(anchor.year + 1);
    }
  }

  /// Jumlah hari dalam periode.
  int get totalDays {
    final DateTime a = DateTime.utc(start.year, start.month, start.day);
    final DateTime b = DateTime.utc(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    );
    return b.difference(a).inDays;
  }

  /// True bila hari ini berada di dalam periode.
  bool isCurrent(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(start) && today.isBefore(endExclusive);
  }

  /// Periode berikutnya hanya boleh dilihat bila sudah dimulai (tidak melewati hari ini).
  bool canGoNext(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    return !next.start.isAfter(today);
  }

  @override
  bool operator ==(Object other) {
    return other is DashboardPeriod &&
        other.mode == mode &&
        other.anchor == anchor;
  }

  @override
  int get hashCode => Object.hash(mode, anchor);
}
