import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/core/constants/db_constants.dart';
import 'package:smart_receipt/services/ml_service.dart';
import 'package:smart_receipt/services/ml_training_data.dart';
import 'package:smart_receipt/services/parsing_service.dart';

void main() {
  group('ParsingService', () {
    const ParsingService service = ParsingService();

    test('mengurai struk contoh Indomaret', () {
      const String raw = 'INDOMARET\n'
          'Jl. Raya Malang\n'
          '01/10/2026\n'
          'Roti         12.000\n'
          'Air Mineral   5.000\n'
          'TOTAL        17.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.merchantName, 'Indomaret');
      expect(result.transactionDate, DateTime(2026, 10, 1));
      expect(result.totalAmount, 17000);
      expect(result.itemNames, <String>['Roti', 'Air Mineral']);
      expect(result.itemsTotal, 17000);
      expect(result.status, ParsingStatus.success);
    });

    test('struk Indomaret buram: nama PT dan baris alamat tidak salah baca', () {
      // Teks OCR asli dari foto struk yang kurang jelas.
      const String raw = 'PT INDOMARCO PFISMATAMA\n'
          '(GEDUNG MENARA Sndsmael\n'
          'INDOMARET BOULEVARD\n'
          'PANTAINDAH KAPUK\n'
          'JAKARTA UTARA\n'
          'NPVWP 00 i337994 6-092 000\n'
          'UREK UREK\n'
          'JL. RAYA UREK UREK NO., UREK UREK\n'
          'KEC GONDANGLEGI, KARUPATEN HALAG, 65174\n'
          '13.11.26-20:51/4.6.0/TQJ3-307201/AMIN /01\n'
          'AMEL OPT PURPLE 16S 1 28000 28,000\n'
          'TOTAL BELANJA: 28,000\n'
          'TUNAI 50,000\n'
          'KEMBALI : 22,000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.merchantName, 'Indomaret');
      expect(result.transactionDate, DateTime(2026, 11, 13));
      expect(result.totalAmount, 28000);
      expect(result.itemNames, <String>['AMEL OPT PURPLE 16S']);
      expect(result.itemsTotal, 28000);
    });

    test('baris kode pos dan alamat tidak dianggap barang', () {
      const String raw = 'TOKO SUMBER REJEKI\n'
          'Kel. Sukamaju Kota Bandung 40123\n'
          'Gula Pasir 1kg 15.000\n'
          'TOTAL 15.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.merchantName, 'Toko Sumber Rejeki');
      expect(result.itemNames, <String>['Gula Pasir 1kg']);
    });

    test('mengenali tanggal berbulan huruf, Rp, dan grand total', () {
      const String raw = 'ALFAMART\n'
          'TGL: 24 September 2026\n'
          'Sabun Mandi 2 x 3.500 7.000\n'
          'GRAND TOTAL Rp 186.750\n'
          'TUNAI 200.000\n'
          'KEMBALI 13.250';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.merchantName, 'Alfamart');
      expect(result.transactionDate, DateTime(2026, 9, 24));
      expect(result.totalAmount, 186750);
      expect(result.itemNames, <String>['Sabun Mandi']);
      expect(result.items.first.quantity, 2);
      expect(result.items.first.unitPrice, 3500);
      expect(result.items.first.totalPrice, 7000);
    });

    test('mengenali barang format dua baris dan nama berukuran (600ML)', () {
      const String raw = 'TOKO SINAR\n'
          '05/10/2026\n'
          'INDOMIE GORENG\n'
          '3 x 3.500   10.500\n'
          'AQUA 600ML 3.500\n'
          'TOTAL 14.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.items.length, 2);
      expect(result.items[0].name, 'INDOMIE GORENG');
      expect(result.items[0].quantity, 3);
      expect(result.items[0].unitPrice, 3500);
      expect(result.items[0].totalPrice, 10500);
      expect(result.items[1].name, 'AQUA 600ML');
      expect(result.items[1].totalPrice, 3500);
      expect(result.totalAmount, 14000);
    });

    test('jumlah di awal nama barang dikenali sebagai kuantitas', () {
      const String raw = 'KIOS BERKAH\n'
          '10/10/2026\n'
          '2 TEH BOTOL 7.000\n'
          'TOTAL 7.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.items.length, 1);
      expect(result.items.first.name, 'TEH BOTOL');
      expect(result.items.first.quantity, 2);
      expect(result.items.first.unitPrice, 3500);
    });

    test('struk elektronik dengan format "nama / harga X1 total" dan OCR salah baca', () {
      // Teks OCR apa adanya: angka 0 terbaca huruf "o" dan nama toko berhuruf campur.
      const String raw = 'sURYA ELEKTRONIK\n'
          'Jl. Veteran Utara No.248B\n'
          'Telp. 0411 3628529\n'
          'Sabtu, 16 November 2019\n'
          '13:56:30\n'
          'PPG\n'
          '500.00o X1 500.00o\n'
          'Pulse Sensor\n'
          '150.00o X1 150.00o\n'
          'Pointer\n'
          '225.000 X1 225.000\n'
          'Total Belanja Rp. 875.000\n'
          'Tunai RP. 900.000\n'
          'Kembali Rp. 25.000\n'
          'Terima Kasih';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.merchantName, 'Surya Elektronik');
      expect(result.transactionDate, DateTime(2019, 11, 16));
      expect(result.totalAmount, 875000);
      expect(result.itemNames, <String>['PPG', 'Pulse Sensor', 'Pointer']);
      expect(result.items[0].unitPrice, 500000);
      expect(result.items[0].quantity, 1);
      expect(result.items[1].totalPrice, 150000);
      expect(result.items[2].totalPrice, 225000);
      expect(result.itemsTotal, 875000);
      expect(result.status, ParsingStatus.success);
    });

    test('harga satuan dan jumlah pada satu baris (unit X qty total)', () {
      const String raw = 'TOKO A\n'
          '10/10/2026\n'
          'PPG 500.000 X1 500.000\n'
          'KABEL 2 x 15.000 30.000\n'
          'TOTAL 530.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.items.length, 2);
      expect(result.items[0].quantity, 1);
      expect(result.items[0].unitPrice, 500000);
      expect(result.items[1].quantity, 2);
      expect(result.items[1].unitPrice, 15000);
    });

    test('struk elektronik dengan 7 barang (harga satuan X jumlah)', () {
      const String raw = 'SURYA ELEKTRONIK\n'
          'Jl. Veteran Utara No.248B\n'
          'Sabtu, 16 November 2019\n'
          'PPG\n'
          '500.000 X1 500.000\n'
          'Pulse Sensor\n'
          '150.000 X1 150.000\n'
          'Pointer\n'
          '225.000 X1 225.000\n'
          'Arduino Uno R3\n'
          '95.000 X2 190.000\n'
          'Kabel Jumper\n'
          '12.000 X3 36.000\n'
          'Resistor 10K\n'
          '500 X10 5.000\n'
          'Solder Listrik\n'
          '85.000 X1 85.000\n'
          'Total Belanja Rp. 1.286.000\n'
          'Tunai Rp. 1.300.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.itemNames, <String>['PPG', 'Pulse Sensor', 'Pointer', 'Arduino Uno R3', 'Kabel Jumper', 'Resistor 10K', 'Solder Listrik']);
      expect(result.totalAmount, 1286000);
    });

    test('struk minimarket berkolom dengan 7 barang', () {
      const String raw = 'INDOMARET\n'
          'Jl. Raya Malang\n'
          '12/10/2026 10:21\n'
          'ROTI TAWAR SARI ROTI 2 6.000 12.000\n'
          'AQUA 600ML 1 3.500 3.500\n'
          'INDOMIE GORENG 5 3.000 15.000\n'
          'TEH PUCUK HARUM 350 2 4.000 8.000\n'
          'SO KLIN LANTAI 1 12.500 12.500\n'
          'ULTRA MILK COKLAT 1 6.500 6.500\n'
          'CHITATO SAPI 1 11.000 11.000\n'
          'TOTAL 68.500\n'
          'TUNAI 70.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.itemNames, <String>['ROTI TAWAR SARI ROTI', 'AQUA 600ML', 'INDOMIE GORENG', 'TEH PUCUK HARUM', 'SO KLIN LANTAI', 'ULTRA MILK COKLAT', 'CHITATO SAPI']);
      expect(result.totalAmount, 68500);
    });

    test('struk 6 barang dengan format nama lalu "jumlah x harga"', () {
      const String raw = 'ALFAMART\n'
          '05/10/2026\n'
          'MIE SEDAAP GORENG\n'
          '3 x 3.200   9.600\n'
          'GULA PASIR 1KG\n'
          '1 x 17.500   17.500\n'
          'MINYAK GORENG 2L\n'
          '1 x 38.000   38.000\n'
          'TELUR AYAM\n'
          '0,5 x 28.000   14.000\n'
          'SABUN LIFEBUOY\n'
          '2 x 3.500   7.000\n'
          'KOPI KAPAL API\n'
          '4 x 1.500   6.000\n'
          'TOTAL 92.100';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.itemNames, <String>['MIE SEDAAP GORENG', 'GULA PASIR 1KG', 'MINYAK GORENG 2L', 'TELUR AYAM', 'SABUN LIFEBUOY', 'KOPI KAPAL API']);
      expect(result.totalAmount, 92100);
    });

    test('nama barang dan harga berada di baris terpisah', () {
      const String raw = 'TOKO MAJU\n'
          '03/10/2026\n'
          'TEH BOTOL SOSRO\n'
          'Rp 4.000\n'
          'NASI GORENG SPESIAL\n'
          'Rp 18.000\n'
          'ES JERUK\n'
          'Rp 5.000\n'
          'AYAM BAKAR\n'
          'Rp 25.000\n'
          'SAMBAL TERASI\n'
          'Rp 3.000\n'
          'TOTAL 55.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.itemNames, <String>['TEH BOTOL SOSRO', 'NASI GORENG SPESIAL', 'ES JERUK', 'AYAM BAKAR', 'SAMBAL TERASI']);
      expect(result.totalAmount, 55000);
    });

    test('berbagai format dalam satu struk', () {
      const String raw = 'WARUNG BU TINI\n'
          '01/10/2026\n'
          'Nasi Goreng 15.000\n'
          'Es Teh 2 x 4.000 8.000\n'
          'Ayam Goreng 3 15.000 45.000\n'
          'Tempe Goreng 6.000 12.000\n'
          'Kerupuk 2.000\n'
          '2 Teh Hangat 6.000\n'
          'TOTAL 88.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.itemNames, <String>['Nasi Goreng', 'Es Teh', 'Ayam Goreng', 'Tempe Goreng', 'Kerupuk', 'Teh Hangat']);
      expect(result.totalAmount, 88000);
    });

    test('OCR salah membaca angka (l, O) pada harga dan jumlah', () {
      const String raw = 'TOKO ABC\n'
          '10/10/2026\n'
          'Buku Tulis\n'
          'l0.000 X2 20.000\n'
          'Pulpen Pilot\n'
          '3.500 Xl 3.500\n'
          'Penghapus\n'
          '2.OOO X1 2.OOO\n'
          'Spidol\n'
          '7.500 X2 15.000\n'
          'Total 40.500';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.itemNames, <String>['Buku Tulis', 'Pulpen Pilot', 'Penghapus', 'Spidol']);
      expect(result.totalAmount, 40500);
    });

    test('kolom dengan penanda pajak dan subtotal', () {
      const String raw = 'SUPERINDO\n'
          '11/10/2026\n'
          'BERAS RAMOS 5KG 1 65.000 65.000 A\n'
          'TELUR AYAM 1KG 1 29.000 29.000 A\n'
          'MINYAK BIMOLI 2L 2 36.000 72.000 B\n'
          'SUSU UHT COKLAT 6 5.500 33.000\n'
          'SUBTOTAL 199.000\n'
          'PPN 11% 1.200\n'
          'TOTAL 200.200';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.itemNames, <String>['BERAS RAMOS 5KG', 'TELUR AYAM 1KG', 'MINYAK BIMOLI 2L', 'SUSU UHT COKLAT']);
      expect(result.totalAmount, 200200);
    });

    test('struk 7 barang: jumlah dan harga satuan setiap barang benar', () {
      const String raw = 'SURYA ELEKTRONIK\n'
          'Sabtu, 16 November 2019\n'
          'PPG\n'
          '500.000 X1 500.000\n'
          'Pulse Sensor\n'
          '150.000 X1 150.000\n'
          'Pointer\n'
          '225.000 X1 225.000\n'
          'Arduino Uno R3\n'
          '95.000 X2 190.000\n'
          'Kabel Jumper\n'
          '12.000 X3 36.000\n'
          'Resistor 10K\n'
          '500 X10 5.000\n'
          'Solder Listrik\n'
          '85.000 X1 85.000\n'
          'Total Belanja Rp. 1.191.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.items.length, 7);
      expect(result.items[3].quantity, 2);
      expect(result.items[3].unitPrice, 95000);
      expect(result.items[3].totalPrice, 190000);
      expect(result.items[4].quantity, 3);
      expect(result.items[4].unitPrice, 12000);
      expect(result.items[5].quantity, 10);
      expect(result.items[5].unitPrice, 500);
      expect(result.itemsTotal, 1191000);
    });

    test('jumlah pecahan dan jumlah per bungkus terbaca benar', () {
      const String raw = 'ALFAMART\n'
          '05/10/2026\n'
          'TELUR AYAM\n'
          '0,5 x 28.000   14.000\n'
          'KOPI KAPAL API\n'
          '4 x 1.500   6.000\n'
          'TOTAL 20.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.items[0].quantity, 0.5);
      expect(result.items[0].unitPrice, 28000);
      expect(result.items[0].totalPrice, 14000);
      expect(result.items[1].quantity, 4);
      expect(result.items[1].unitPrice, 1500);
    });

    test('variabel yang tidak ditemukan dibiarkan kosong (partial)', () {
      const String raw = 'WARUNG BU TINI\nNasi Goreng 15.000';

      final ParsedReceiptData result = service.parse(raw);

      expect(result.merchantName, 'Warung Bu Tini');
      expect(result.transactionDate, isNull);
      expect(result.status, ParsingStatus.partial);
    });

    test('teks kosong menghasilkan status failed', () {
      final ParsedReceiptData result = service.parse('   \n  ');
      expect(result.status, ParsingStatus.failed);
      expect(result.merchantName, isNull);
      expect(result.totalAmount, isNull);
      expect(result.items, isEmpty);
    });
  });

  group('MlService', () {
    late MlService ml;

    setUp(() async {
      ml = MlService();
      await ml.initialize();
    });

    test('model terlatih dengan 15 kategori', () {
      expect(ml.isTrained, isTrue);
      expect(ml.categories.length, 15);
      expect(ml.categories, contains('Elektronik'));
      expect(ml.categories, contains('Bahan Makanan'));
      expect(ml.categories, contains('Tagihan & Utilitas'));
    });

    test('barang elektronik masuk kategori Elektronik', () {
      const List<String> items = <String>[
        'PPG',
        'Pulse Sensor',
        'Pointer',
        'ARDUINO UNO R3',
        'CHARGER SAMSUNG 25W',
      ];
      for (final String item in items) {
        expect(ml.classify(item).categoryName, 'Elektronik', reason: item);
      }
    });

    test('memprediksi kategori yang tepat, termasuk teks bergaya struk', () {
      const Map<String, String> cases = <String, String>{
        'Roti Tawar': 'Konsumsi',
        'INDOMIE GRG SPESIAL': 'Konsumsi',
        'ULTRA MLK COKLAT': 'Konsumsi',
        'TELUR AYAM 1KG': 'Bahan Makanan',
        'WORTEL LOKAL': 'Bahan Makanan',
        'Paracetamol 500mg': 'Kesehatan',
        'PANADOL BIRU': 'Kesehatan',
        'Pertalite': 'Transportasi',
        'GRAB BIKE TRIP': 'Transportasi',
        'Sabun Mandi': 'Perawatan Diri',
        'SUNSILK SHP 170ML': 'Perawatan Diri',
        'DETERJEN SO KLIN': 'Rumah Tangga',
        'KAOS POLOS HITAM': 'Pakaian & Aksesori',
        'BUKU TULIS SIDU': 'Pendidikan',
        'NETFLIX BULANAN': 'Hiburan',
        'Token Listrik PLN': 'Tagihan & Utilitas',
        'PULSA TELKOMSEL 50RB': 'Tagihan & Utilitas',
        'LAUNDRY KILOAN': 'Jasa & Layanan',
        'ZAKAT FITRAH': 'Donasi & Sosial',
      };
      cases.forEach((String text, String expected) {
        expect(ml.classify(text).categoryName, expected, reason: text);
      });
    });

    test('singkatan struk diperluas dan satuan dibuang', () {
      expect(ml.tokenize('INDOMIE GRG 600ML'), <String>['indomie', 'goreng']);
    });

    test('salah baca OCR dikoreksi ke kata yang dikenal', () {
      expect(ml.tokenize('IND0MIE GRG'), <String>['indomie', 'goreng']);
      expect(ml.tokenize('SHAMPO SUNSLK').last, 'sunsilk');
      expect(ml.classify('SHAMPO SUNSLK').categoryName, 'Perawatan Diri');
      expect(ml.classify('PARACETAM0L 500MG').categoryName, 'Kesehatan');
    });

    test('kata pertama dan frasa menentukan jenis barang atau jasa', () {
      expect(ml.classify('JAHIT CELANA').categoryName, 'Jasa & Layanan');
      expect(ml.classify('CELANA JEANS PRIA').categoryName, 'Pakaian & Aksesori');
      expect(ml.classify('SERVIS AC').categoryName, 'Jasa & Layanan');
      expect(ml.classify('CETAK FOTO').categoryName, 'Jasa & Layanan');
    });

    test('probabilitas valid dan berjumlah 1', () {
      final ClassificationOutput result = ml.classify('Roti Tawar');
      final double sum = result.probabilities.values.fold<double>(
        0,
        (double a, double b) => a + b,
      );
      expect(sum, closeTo(1.0, 1e-9));
      expect(result.probability, greaterThan(0.5));
      expect(result.isConfident, isTrue);
      expect(result.terms.any((TfidfTerm t) => t.term == 'roti'), isTrue);
    });

    test('teks tak dikenal diarahkan ke Lainnya dengan isConfident false', () {
      final ClassificationOutput result = ml.classify('xqzv 12345');
      expect(result.categoryName, 'Lainnya');
      expect(result.isConfident, isFalse);
    });

    test('nama merchant menjadi petunjuk bila barang tidak dikenal', () {
      expect(
        ml.classifyItem('Zzqx Wwvk', merchantName: 'Apotek K24').categoryName,
        'Kesehatan',
      );
      expect(
        ml.classifyItem('Zzqx Wwvk', merchantName: 'SPBU Pertamina').categoryName,
        'Transportasi',
      );
      // Barang yang dikenali tidak dipengaruhi merchant.
      expect(
        ml.classifyItem('Teh Botol', merchantName: 'Apotek K24').categoryName,
        'Konsumsi',
      );
    });

    test('model belajar dari koreksi pengguna', () {
      expect(ml.classify('kopi sachet').categoryName, 'Konsumsi');

      ml.learn(<LabeledSample>[const LabeledSample('kopi sachet', 'Rumah Tangga')]);

      expect(ml.classify('kopi sachet').categoryName, 'Rumah Tangga');
    });
  });
}
