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

    test(
        'struk elektronik dengan format "nama / harga X1 total" dan OCR salah baca',
        () {
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

    test('model terlatih dengan 6 kategori', () {
      expect(ml.isTrained, isTrue);
      expect(ml.categories.length, 6);
      expect(ml.categories, contains('Elektronik'));
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
        'Paracetamol 500mg': 'Kesehatan',
        'PANADOL BIRU': 'Kesehatan',
        'Pertalite': 'Transportasi',
        'GRAB BIKE TRIP': 'Transportasi',
        'Sabun Mandi': 'Belanja',
        'SUNSILK SHP 170ML': 'Belanja',
        'Token Listrik PLN': 'Lainnya',
        'PULSA TELKOMSEL 50RB': 'Lainnya',
      };
      cases.forEach((String text, String expected) {
        expect(ml.classify(text).categoryName, expected, reason: text);
      });
    });

    test('singkatan struk diperluas dan satuan dibuang', () {
      expect(ml.tokenize('INDOMIE GRG 600ML'), <String>['indomie', 'goreng']);
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
        ml
            .classifyItem('Zzqx Wwvk', merchantName: 'SPBU Pertamina')
            .categoryName,
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

      ml.learn(<LabeledSample>[const LabeledSample('kopi sachet', 'Belanja')]);

      expect(ml.classify('kopi sachet').categoryName, 'Belanja');
    });
  });
}
