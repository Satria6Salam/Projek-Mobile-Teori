/// Nama kategori pengeluaran (harus sama persis dengan isi tabel `categories`)
/// beserta urutan tampilan di antarmuka.
class CategoryNames {
  CategoryNames._();

  static const String konsumsi = 'Konsumsi';
  static const String bahanMakanan = 'Bahan Makanan';
  static const String transportasi = 'Transportasi';
  static const String kesehatan = 'Kesehatan';
  static const String perawatanDiri = 'Perawatan Diri';
  static const String rumahTangga = 'Rumah Tangga';
  static const String pakaianAksesori = 'Pakaian & Aksesori';
  static const String elektronik = 'Elektronik';
  static const String pendidikan = 'Pendidikan';
  static const String hiburan = 'Hiburan';
  static const String tagihanUtilitas = 'Tagihan & Utilitas';
  static const String jasaLayanan = 'Jasa & Layanan';
  static const String donasiSosial = 'Donasi & Sosial';
  static const String belanja = 'Belanja';
  static const String lainnya = 'Lainnya';

  /// Urutan tampil: kategori khusus dulu, "Belanja" dan "Lainnya" di akhir.
  static const List<String> displayOrder = <String>[
    konsumsi,
    bahanMakanan,
    transportasi,
    kesehatan,
    perawatanDiri,
    rumahTangga,
    pakaianAksesori,
    elektronik,
    pendidikan,
    hiburan,
    tagihanUtilitas,
    jasaLayanan,
    donasiSosial,
    belanja,
    lainnya,
  ];

  /// Peringkat urutan tampil; nama yang tidak dikenal berada sebelum "Lainnya".
  static int rank(String name) {
    final int index = displayOrder.indexOf(name);
    if (name == lainnya) return 1000;
    return index < 0 ? 500 : index;
  }
}
