import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/services/ocr_service.dart';
import 'package:smart_receipt/services/parsing_service.dart';

/// Satu contoh struk dan barang yang seharusnya terbaca (nama -> total harga).
class _Case {
  const _Case(this.raw, this.items, {this.qty = const <String, double>{}});

  final String raw;
  final Map<String, double> items;
  final Map<String, double> qty;
}

const Map<String, _Case> _cases = <String, _Case>{
  'minimarket: nama, jumlah, harga, total dalam satu baris': _Case(
    'INDOMARET\n01/10/2026\nAQUA 600ML 1 3.500 3.500\n'
    'ROTI TAWAR 2 12.000 24.000\nTOTAL 27.500',
    <String, double>{'AQUA 600ML': 3500, 'ROTI TAWAR': 24000},
    qty: <String, double>{'ROTI TAWAR': 2},
  ),
  'nama di satu baris, "jumlah x harga" di baris berikutnya': _Case(
    'ALFAMART\n01/10/2026\nINDOMIE GORENG\n3 x 3.000 9.000\n'
    'TEH PUCUK\n2 x 4.000 8.000\nTOTAL 17.000',
    <String, double>{'INDOMIE GORENG': 9000, 'TEH PUCUK': 8000},
    qty: <String, double>{'INDOMIE GORENG': 3},
  ),
  'kepala tabel berisi kata "Jumlah" bukan akhir daftar barang': _Case(
    'WARUNG MAKAN SARI\n01/10/2026\nItem Qty Harga Jumlah\n'
    'Nasi Goreng 2 15.000 30.000\nEs Teh 2 5.000 10.000\nTotal 40.000',
    <String, double>{'Nasi Goreng': 30000, 'Es Teh': 10000},
  ),
  'kolom nama dan kolom harga terbaca terpisah': _Case(
    'RM PADANG SEDERHANA\n01/10/2026\nNasi Rendang\nEs Jeruk\nKerupuk\n'
    '25.000\n7.000\n3.000\nTOTAL 35.000',
    <String, double>{'Nasi Rendang': 25000, 'Es Jeruk': 7000, 'Kerupuk': 3000},
  ),
  'titik pemandu di antara nama dan harga': _Case(
    'KEDAI KOPI\n01/10/2026\nKopi Susu........18.000\n'
    'Roti Bakar.......15.000\nTotal............33.000',
    <String, double>{'Kopi Susu': 18000, 'Roti Bakar': 15000},
  ),
  'ribuan dipisah spasi oleh OCR': _Case(
    'TOKO MAKMUR\n01/10/2026\nGula Pasir 1kg 14 500\n'
    'Minyak Goreng 2L 32 000\nTOTAL 46 500',
    <String, double>{'Gula Pasir 1kg': 14500, 'Minyak Goreng 2L': 32000},
  ),
  'harga tanpa pemisah ribuan (5 digit bukan kode pos)': _Case(
    'CAFE SENJA\n01/10/2026\n1 Americano 25000\n2 Croissant 36000\n'
    'Subtotal 61000\nTotal 61000',
    <String, double>{'Americano': 25000, 'Croissant': 36000},
    qty: <String, double>{'Croissant': 2},
  ),
  'jumlah bersatuan (SAK, KG) dan tanda "="': _Case(
    'TOKO BANGUNAN JAYA\n01/10/2026\nSemen Gresik\n2 SAK x 65.000 = 130.000\n'
    'Paku 5cm\n1 KG x 20.000 = 20.000\nTOTAL 150.000',
    <String, double>{'Semen Gresik': 130000, 'Paku 5cm': 20000},
    qty: <String, double>{'Semen Gresik': 2},
  ),
  'harga diawali Rp': _Case(
    'APOTEK SEHAT\n01/10/2026\nParacetamol 500mg Rp 8.000\n'
    'Vitamin C Rp. 25.000\nTotal Rp 33.000',
    <String, double>{'Paracetamol 500mg': 8000, 'Vitamin C': 25000},
  ),
  'harga dengan desimal ,00': _Case(
    'SUPERMARKET\n01/10/2026\nSusu UHT 1L 18.500,00\n'
    'Telur 1kg 28.000,00\nTOTAL 46.500,00',
    <String, double>{'Susu UHT 1L': 18500, 'Telur 1kg': 28000},
  ),
  'format angka Inggris (koma ribuan)': _Case(
    'COFFEE SHOP\n10/01/2026\n1 Caffe Latte Tall 45,000\n'
    '1 Cheese Cake 38,000\nTotal 83,000',
    <String, double>{'Caffe Latte Tall': 45000, 'Cheese Cake': 38000},
  ),
  'harga satuan dulu, lalu "x jumlah"': _Case(
    'TOKO ATK\n01/10/2026\nPulpen Standard 3.000 x 5 15.000\n'
    'Buku Tulis 5.000 x 2 10.000\nTOTAL 25.000',
    <String, double>{'Pulpen Standard': 15000, 'Buku Tulis': 10000},
    qty: <String, double>{'Pulpen Standard': 5},
  ),
  'potongan harga mengurangi barang di atasnya': _Case(
    'HYPERMART\n01/10/2026\nSABUN LIFEBUOY 4.500\nDISC -500\n'
    'SHAMPOO CLEAR 22.000\nTOTAL 26.000',
    <String, double>{'SABUN LIFEBUOY': 4000, 'SHAMPOO CLEAR': 22000},
  ),
  'kode barang di depan nama': _Case(
    'INDOMARET\n01/10/2026\n8992761111 AQUA 600ML 3.500\n'
    '8996001600 TEH BOTOL 5.000\nTOTAL 8.500',
    <String, double>{'AQUA 600ML': 3500, 'TEH BOTOL': 5000},
  ),
  'huruf O terbaca untuk angka nol': _Case(
    'ALFAMART\n01/10/2026\nKOPI KAPAL API 12.5OO\nGULA AREN 8.OOO\n'
    'TOTAL 20.500',
    <String, double>{'KOPI KAPAL API': 12500, 'GULA AREN': 8000},
  ),
  'jumlah di belakang nama tanpa tanda x': _Case(
    'RESTO BAKSO\n01/10/2026\nBakso Urat 2 40.000\nEs Teh Manis 2 10.000\n'
    'TOTAL 50.000',
    <String, double>{'Bakso Urat': 40000, 'Es Teh Manis': 10000},
    qty: <String, double>{'Bakso Urat': 2},
  ),
  'struk tanpa baris barang biasa (SPBU) memakai total': _Case(
    'SPBU 54.611.01\n01/10/2026\nPertalite\nVolume 10,00 L\n'
    'Harga/L 10.000\nTotal 100.000',
    <String, double>{'Pertalite': 100000},
  ),
  'harga terpotong spasi setelah titik': _Case(
    'TOKO SINAR\n01/10/2026\nSabun Cuci 12. 000\nSikat Gigi 8. 500\n'
    'TOTAL 20. 500',
    <String, double>{'Sabun Cuci': 12000, 'Sikat Gigi': 8500},
  ),
  'huruf S, B, Z terbaca di dalam harga': _Case(
    'MINIMARKET\n01/10/2026\nKopi Sachet 12.S00\nTeh Celup 1B.000\n'
    'TOTAL 30.500',
    <String, double>{'Kopi Sachet': 12500, 'Teh Celup': 18000},
  ),
};

void main() {
  const ParsingService parser = ParsingService();

  group('Format struk yang berbeda-beda', () {
    _cases.forEach((String name, _Case c) {
      test(name, () {
        final ParsedReceiptData result = parser.parse(c.raw);
        final Map<String, double> got = <String, double>{
          for (final ParsedItem item in result.items)
            item.name: item.totalPrice,
        };
        expect(got, c.items);
        c.qty.forEach((String item, double q) {
          final ParsedItem found =
              result.items.firstWhere((ParsedItem i) => i.name == item);
          expect(found.quantity, q, reason: 'jumlah $item');
        });
        expect(result.itemsTotal, result.totalAmount,
            reason: 'jumlah harga barang harus sama dengan total struk');
      });
    });
  });

  group('Penyusunan baris OCR', () {
    test('foto miring: nama dan harga tetap satu baris', () {
      // Kemiringan 0,08: harga di x=300 terletak 19px lebih rendah dari nama.
      const double slope = 0.08;
      List<OcrFragment> row(String name, String price, double y) =>
          <OcrFragment>[
            OcrFragment(
              text: name,
              left: 10,
              centerX: 60,
              centerY: y + 60 * slope,
              height: 20,
              slope: slope,
            ),
            OcrFragment(
              text: price,
              left: 260,
              centerX: 300,
              centerY: y + 300 * slope,
              height: 20,
              slope: slope,
            ),
          ];

      final List<String> rows = buildReceiptRows(<OcrFragment>[
        ...row('Nasi Goreng', '25.000', 100),
        ...row('Es Teh Manis', '5.000', 125),
        ...row('Kerupuk', '3.000', 150),
      ]);

      expect(rows, <String>[
        'Nasi Goreng 25.000',
        'Es Teh Manis 5.000',
        'Kerupuk 3.000',
      ]);
    });

    test('foto lurus tetap tersusun seperti biasa', () {
      final List<String> rows = buildReceiptRows(const <OcrFragment>[
        OcrFragment(
            text: '12.000', left: 200, centerX: 230, centerY: 50, height: 18),
        OcrFragment(
            text: 'Roti', left: 10, centerX: 30, centerY: 51, height: 18),
        OcrFragment(
            text: 'TOTAL 12.000',
            left: 10,
            centerX: 80,
            centerY: 90,
            height: 18),
      ]);
      expect(rows, <String>['Roti 12.000', 'TOTAL 12.000']);
    });
  });
}
