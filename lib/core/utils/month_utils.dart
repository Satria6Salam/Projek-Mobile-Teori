/// Bantuan bulan (format kunci "yyyy-MM") untuk anggaran dan transaksi berulang.
class MonthUtils {
  MonthUtils._();

  /// Kunci bulan, mis. 2026-11.
  static String key(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month';
  }

  /// Kebalikan [key]: tanggal pertama bulan tersebut.
  static DateTime parse(String key) {
    final List<String> parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Awal bulan (inklusif).
  static DateTime startOf(DateTime date) => DateTime(date.year, date.month);

  /// Awal bulan berikutnya (eksklusif).
  static DateTime endExclusive(DateTime date) =>
      DateTime(date.year, date.month + 1);

  /// Jumlah hari dalam bulan.
  static int daysIn(int year, int month) => DateTime(year, month + 1, 0).day;
}
