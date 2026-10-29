import 'package:intl/intl.dart';

import 'dashboard_period.dart';

/// Format mata uang Rupiah, angka, dan tanggal (lokal Indonesia).
/// Data lokal diinisialisasi di main() melalui initializeDateFormatting('id_ID').
class AppFormatters {
  AppFormatters._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  static final NumberFormat _plain = NumberFormat('#,##0.##', 'id_ID');
  static final DateFormat _longDate = DateFormat('d MMMM y', 'id_ID');
  static final DateFormat _shortDate = DateFormat('d MMM y', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM y', 'id_ID');
  static final DateFormat _fullDate = DateFormat('EEEE, d MMMM y', 'id_ID');
  static final DateFormat _monthName = DateFormat('MMMM', 'id_ID');

  /// Contoh: Rp186.750
  static String rupiah(double value) => _rupiah.format(value);

  /// Angka berpemisah ribuan tanpa simbol, contoh: 186.750
  static String amountInput(double value) => _plain.format(value);

  /// Contoh: 24 September 2026
  static String longDate(DateTime value) => _longDate.format(value);

  /// Contoh: 24 Sep 2026
  static String shortDate(DateTime value) => _shortDate.format(value);

  /// Contoh: September 2026
  static String monthYear(DateTime value) => _monthYear.format(value);

  /// Contoh: Sabtu, 16 November 2019
  static String fullDate(DateTime value) => _fullDate.format(value);

  /// Contoh: November
  static String monthName(int month) =>
      _monthName.format(DateTime(2000, month));

  /// Singkatan bulan satu huruf: J F M A M J J A S O N D
  static String monthInitial(int month) => monthName(month)[0].toUpperCase();

  /// Singkatan bulan tiga huruf: Jan, Feb, Mar ...
  static String monthShort(int month) {
    final String name = monthName(month);
    return name.length <= 3 ? name : name.substring(0, 3);
  }

  /// Label periode Dasbor: tanggal lengkap, bulan + tahun, atau tahun saja.
  static String period(DashboardPeriod period) {
    switch (period.mode) {
      case PeriodMode.day:
        return longDate(period.anchor);
      case PeriodMode.month:
        return monthYear(period.anchor);
      case PeriodMode.year:
        return '${period.anchor.year}';
    }
  }

  /// Contoh: 0.254 -> 25%
  static String percent(double fraction) => '${(fraction * 100).round()}%';
}
