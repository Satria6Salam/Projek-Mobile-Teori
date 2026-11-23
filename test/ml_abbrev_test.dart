import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/services/ml_service.dart';

/// Nama barang bergaya singkatan struk minimarket: huruf vokal dibuang, kata
/// dipotong, dan merek tanpa jenis barang. Set ini tidak dipakai untuk melatih.
const Map<String, List<String>> abbrevSet = <String, List<String>>{
  'Konsumsi': <String>[
    'INDOMIE GRG SPCL', 'INDMIE SOTO', 'SLVQN CHSW 45G', 'CHITATO SPCY 68',
    'TB SOSRO 450', 'AQUA BTL 600', 'LE MINERALE 600', 'POCARI SWT 500',
    'GOOD DAY CAPP', 'NESCAFE CLSC', 'TANGO WFR CKLT', 'BENG2 MAXX',
    'ROMA KLP', 'KHONG GUAN', 'TEH PCK HRM', 'FRUITEA APL', 'MILO ACTV GO',
    'ULTRAMILK FC 250', 'YKLT 5S', 'CHOCOLATOS', 'PILUS GRDA', 'QTELA SNGKG',
    'TARO NET', 'SARIMI ISI 2', 'POP MIE AYM',
  ],
  'Bahan Makanan': <String>[
    'BRS PANDAN WNGI 5KG', 'GULAKU 1KG', 'MNYK BIMOLI 2L', 'SUNCO 1L',
    'TLR AYM NEGERI', 'TPG SEGITIGA BRU', 'KCP BANGO 520', 'SAOS ABC SMBL',
    'MASAKO AYM', 'ROYCO SPI', 'SRDN ABC 155', 'KORNET PRONAS',
    'SUSU KNTL FRISIAN', 'BLUEBAND 200', 'GARAM REFINA', 'MIE TLR CAP 3 AYAM',
  ],
  'Perawatan Diri': <String>[
    'LIFEBUOY BW 450', 'PEPSODENT PTH 190', 'CLEAR SHMP MEN', 'SNSLK HTM 170',
    'REXONA MEN SPRY', 'CITRA HBL 250', 'GILLETTE GRD', 'LAURIER SFT',
    'PONDS WHT BTY', 'WARDAH LGHTN', 'NIVEA MEN', 'ZINC SHMP',
  ],
  'Rumah Tangga': <String>[
    'RINSO ANTN 770', 'SO KLIN LQD', 'MOLTO PWNGI', 'SUNLIGHT JRK 755',
    'BYCLN 500', 'WIPOL', 'PASEO TSU 250', 'BAYGON SPRY', 'STELLA PJT',
    'TISU NICE', 'VIXAL', 'MAMA LMN',
  ],
  'Kesehatan': <String>[
    'PANADOL MRH', 'BODREX', 'TOLAK ANGIN CR', 'ANTANGIN JRG', 'PROMAG TBL',
    'BETADINE 15', 'HANSAPLAST', 'ENERVON C', 'MKY KAYU PTH', 'OBH COMBI',
  ],
  'Transportasi': <String>[
    'PRTLT', 'PERTAMAX 92', 'PRKR MTR', 'E-TOLL TOPUP', 'GOJEK', 'OLI MPX 2',
  ],
  'Elektronik': <String>[
    'BATERAI ABC AA', 'ALKALINE AA2', 'LAMPU PHLPS 9W', 'KBL DATA TYPE C',
    'CHRGR SAMSUNG', 'EARPHONE JBL',
  ],
  'Pendidikan': <String>[
    'BUKU SIDU 38', 'PLPN STANDARD', 'PNSL 2B FABER', 'KRTS HVS A4',
    'PENGHPS STAEDTLER', 'SPIDOL SNOWMAN',
  ],
  'Tagihan & Utilitas': <String>[
    'TOKEN PLN 100RB', 'PULSA TSEL 25K', 'PKT DATA AXIS', 'BPJS KES', 'PDAM',
  ],
  'Hiburan': <String>['NETFLIX', 'TKT BIOSKOP XXI', 'VCR GAME', 'GOOGLE PLAY'],
  'Pakaian & Aksesori': <String>[
    'KAOS KAKI', 'SANDAL SWALLOW', 'KEMEJA PRIA', 'CELANA PDK',
  ],
  'Jasa & Layanan': <String>[
    'ONGKIR JNT', 'LAUNDRY 3KG', 'POTONG RMBT', 'SRVS MOTOR',
  ],
  'Donasi & Sosial': <String>['DONASI KASIR', 'INFAQ', 'ZAKAT FITRAH'],
};

double abbrevAccuracy(MlService ml, {bool printMisses = false}) {
  int ok = 0;
  int total = 0;
  abbrevSet.forEach((String label, List<String> items) {
    for (final String item in items) {
      total++;
      final String got = ml.classify(item).categoryName;
      if (got == label) {
        ok++;
      } else if (printMisses) {
        // ignore: avoid_print
        print('  SALAH: $item -> $got (seharusnya $label)');
      }
    }
  });
  return ok / total;
}

void main() {
  test('akurasi pada nama barang bergaya singkatan struk minimal 95%',
      () async {
    final MlService ml = MlService();
    await ml.initialize();
    expect(abbrevAccuracy(ml), greaterThanOrEqualTo(0.95));
  });

  test('singkatan tanpa vokal dan kata gabungan dikenali', () async {
    final MlService ml = MlService();
    await ml.initialize();
    expect(ml.tokenize('PRKR MTR'), <String>['parkir', 'motor']);
    expect(ml.tokenize('SNSLK'), <String>['sunsilk']);
    expect(ml.tokenize('ULTRAMILK'), <String>['ultra', 'milk']);
  });
}
