/// Konversi tanggal <-> teks untuk penyimpanan di SQLite.
class DbDateUtils {
  DbDateUtils._();

  /// Waktu lengkap (kolom created_at / updated_at), format ISO-8601.
  static String dateTimeToDb(DateTime value) => value.toIso8601String();

  /// Tanggal saja (kolom DATE), format yyyy-MM-dd agar bisa dibandingkan sebagai teks.
  static String dateToDb(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-${two(value.month)}-${two(value.day)}';
  }

  /// Membaca teks dari database menjadi DateTime. Mengembalikan null jika kosong/tidak valid.
  static DateTime? tryParse(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Seperti [tryParse], tetapi memakai waktu sekarang bila gagal.
  static DateTime parseOrNow(Object? value) => tryParse(value) ?? DateTime.now();
}
