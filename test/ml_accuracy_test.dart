import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/services/ml_service.dart';

/// Tes regresi akurasi model AI pada nama barang bergaya struk.
/// Kumpulan data uji ini dipisahkan dari data latih bawaan.
const Map<String, List<String>> _testSet = <String, List<String>>{
  'Konsumsi': <String>[
    'INDOMIE GRG SPESIAL',
    'AQUA 600ML',
    'TEH PUCUK HARUM 350',
    'ULTRA MILK COKLAT 250',
    'ROTI SISIR KEJU',
    'TELUR AYAM 1KG',
    'MINYAK GORENG TROPICAL 2L',
    'CHITATO SAPI PANGGANG',
    'OREO VANILA',
    'KOPI SUSU GULA AREN',
    'NASI AYAM BAKAR',
    'ES TEH JUMBO',
    'SOSIS SO NICE',
    'BERAS RAJA LELE 5KG',
    'GULA PASIR GULAKU',
    'SUSU BEBELAC 3',
    'YOGURT CIMORY',
    'COCA COLA 390ML',
    'PISANG GORENG KEJU',
    'SATE TAICHAN',
    'MIE AYAM PANGSIT',
    'KERIPIK PISANG COKLAT',
    'BAKSO JUMBO',
    'JUS STROBERI',
    'NASI GORENG KAMPUNG',
    'INDOMIE SOTO',
    'TEH BOTOL SOSRO',
    'CIKI TARO',
    'SUSU KENTAL MANIS',
    'ROTI TAWAR GANDUM'
  ],
  'Transportasi': <String>[
    'PERTALITE 3.2L',
    'PARKIR MOTOR 2 JAM',
    'GRAB BIKE TRIP',
    'TOL CAWANG',
    'OLI MOTUL 1L',
    'SERVICE BERKALA MOTOR',
    'GOCAR 12KM',
    'TOP UP FLAZZ',
    'BUSI NGK',
    'TIKET KERETA ARGO',
    'TAMBAL BAN BOCOR',
    'SHELL V POWER',
    'PERTAMAX 10L',
    'PARKIR MOBIL',
    'GOJEK RIDE',
    'TIKET KRL JABODETABEK',
    'CUCI MOBIL',
    'GANTI OLI MESIN'
  ],
  'Kesehatan': <String>[
    'PANADOL BIRU',
    'VIT C 500MG',
    'OBAT BATUK HITAM',
    'MASKER KN95',
    'BETADINE 30ML',
    'PLESTER HANSAPLAST',
    'KONSULTASI DOKTER UMUM',
    'TOLAK ANGIN CAIR',
    'KAPSUL AMOXICILLIN 500',
    'TENSIMETER DIGITAL',
    'VICKS INHALER',
    'OBAT MAAG PROMAG',
    'MINYAK TELON',
    'SALEP GATAL',
    'PARACETAMOL 500MG',
    'MULTIVITAMIN ANAK',
    'HAND SANITIZER 100ML',
    'CEK GULA DARAH'
  ],
  'Belanja': <String>[
    'SUNSILK SHP 170ML',
    'PEPSODENT 190G',
    'SOFTEX DAUN SIRIH',
    'RINSO ANTI NODA',
    'KAOS POLOS HITAM',
    'BUKU TULIS SIDU',
    'PULPEN PILOT',
    'SEPATU SNEAKERS',
    'TISU PASEO',
    'SABUN LIFEBUOY',
    'HANDUK MANDI',
    'SPRAY PARFUM',
    'LIPSTIK WARDAH',
    'DETERJEN SO KLIN',
    'MOLTO PEWANGI',
    'TAS RANSEL',
    'KAOS KAKI',
    'SABUN CUCI PIRING SUNLIGHT',
    'PASTA GIGI CLOSEUP',
    'SHAMPOO PANTENE',
    'PEMBALUT LAURIER',
    'POPOK MAMYPOKO'
  ],
  'Elektronik': <String>[
    'BATERAI ABC AA',
    'KABEL USB TYPE C',
    'SENSOR SUHU DS18B20',
    'ARDUINO UNO R3',
    'MODUL BLUETOOTH HC05',
    'KABEL JUMPER MALE',
    'LASER POINTER HIJAU',
    'CHARGER SAMSUNG 25W',
    'SPEAKER BLUETOOTH JBL',
    'MONITOR LED 24 INCH',
    'KIPAS ANGIN MASPION',
    'SETRIKA PHILIPS',
    'HEADSET GAMING',
    'RESISTOR 10K',
    'LCD I2C 16X2',
    'SOLDER LISTRIK'
  ],
  'Lainnya': <String>[
    'TOKEN PLN 100000',
    'PULSA TELKOMSEL 50RB',
    'INDIHOME AGUSTUS',
    'NETFLIX BULANAN',
    'TIKET XXI',
    'FOTOCOPY 20 LBR',
    'LAUNDRY KILOAN',
    'POTONG RAMBUT',
    'BIAYA ADMIN',
    'IURAN SAMPAH',
    'DONASI MASJID',
    'KIRIM PAKET JNE',
    'TOPUP DIAMOND ML',
    'BAYAR PDAM',
    'SERVICE AC',
    'BIAYA PENGIRIMAN',
    'SPP BULAN INI',
    'TAGIHAN LISTRIK'
  ],
};

/// Kumpulan lebih sulit: merek dan kata yang jarang muncul.
const Map<String, List<String>> _hardSet = <String, List<String>>{
  'Konsumsi': <String>[
    'NABATI WAFER KEJU',
    'KIT KAT 4 FINGER',
    'TIC TAC MINT',
    'GARUDA ROSTA',
    'SILVERQUEEN CHUNKY',
    'POCKY STRAWBERRY',
    'BENG BENG',
    'BISKUAT COKLAT',
    'SUSU KOTAK DIAMOND',
    'TEH SARIWANGI',
    'LE MINERALE 1500',
    'MILO ACTIV GO',
    'KOPIKO 78C',
    'ABC KOPI SUSU',
    'INDOMILK COKLAT',
    'FRISIAN FLAG',
    'CHEESE STICK',
    'BAKSO SAPI GG',
    'CILOK KUAH',
    'SEBLAK PEDAS',
    'MIE GACOAN LV 2',
    'KOPI TUBRUK',
    'TELUR ASIN',
    'SOTO MIE',
    'NASI TIM AYAM',
    'KLEPON',
    'WEDANG JAHE',
    'SMOOTHIE MANGGA',
    'SANDWICH TUNA',
    'LUMPIA SEMARANG'
  ],
  'Transportasi': <String>[
    'PERTALITE 5L',
    'PARKIR 3JAM',
    'E-TOLL BCA',
    'GOJEK TRIP',
    'OLI SHELL HELIX',
    'SERVIS RUTIN MOTOR',
    'GANTI BAN BELAKANG',
    'TIKET KA JARAK JAUH',
    'ONGKOS BAJAJ',
    'KARCIS BUS KOTA',
    'BENSIN ECER',
    'OJEK PAK DEDE',
    'TOL JAGORAWI',
    'PARKIR VALET',
    'GRAB TRIP'
  ],
  'Kesehatan': <String>[
    'PROMAG TAB',
    'BODREX EXTRA',
    'KOMIX HERBAL',
    'SANMOL DROP',
    'OBAT KUMUR HEXADOL',
    'MASKER 3PLY',
    'SIRUP OBH',
    'ANTIMO',
    'SALONPAS GEL',
    'DOKTER ANAK',
    'BPJS KESEHATAN',
    'KAPSUL VIT E',
    'VITAMIN B COMPLEX',
    'OBAT TETES MATA',
    'TEST PACK'
  ],
  'Belanja': <String>[
    'LIFEBUOY CAIR REFILL',
    'DOVE SHAMPOO',
    'FORMULA PASTA GIGI',
    'SIKAT GIGI FORMULA',
    'SO KLIN LANTAI',
    'SUNLIGHT JERUK NIPIS',
    'RINSO MOLTO',
    'TISSUE MONTIS',
    'BAJU ANAK',
    'JEANS PRIA',
    'SANDAL ESPERANZA',
    'TAS WANITA',
    'SEPATU NIKE',
    'NOTEBOOK',
    'BALLPOINT SNOWMAN',
    'KAOS POLO',
    'CELANA CHINO',
    'SABUN MUKA'
  ],
  'Lainnya': <String>[
    'PLN TOKEN 50000',
    'TELKOMSEL 25RB',
    'INDIHOME PAKET',
    'DONASI PANTI',
    'ZAKAT MAL',
    'CETAK POSTER',
    'LAUNDRY SEPATU',
    'SEWA GEDUNG',
    'LISTRIK PASCABAYAR',
    'BAYAR KOS',
    'TIKET MASUK ZOO',
    'PAKET KURIR',
    'STEAM WALLET',
    'LANGGANAN YOUTUBE',
    'PULSA 100RB'
  ],
  'Elektronik': <String>[
    'KABEL HDMI',
    'MOUSE LOGITECH',
    'ESP32 DEVKIT',
    'SENSOR ULTRASONIK',
    'MULTIMETER DIGITAL',
    'POWER SUPPLY 12V',
    'SERVO MOTOR SG90',
    'LAPTOP ASUS',
    'ROUTER TP LINK',
    'FLASH DISK SANDISK',
    'BATERAI LITHIUM 18650',
    'TV LED 32 INCH',
    'SENSOR HUJAN',
    'MODUL RELAY 2 CHANNEL',
    'KIPAS ANGIN'
  ],
};

double _accuracy(MlService ml, Map<String, List<String>> set) {
  int ok = 0;
  int total = 0;
  set.forEach((String label, List<String> items) {
    for (final String item in items) {
      total++;
      if (ml.classify(item).categoryName == label) ok++;
    }
  });
  return ok / total;
}

void main() {
  late MlService ml;

  setUpAll(() async {
    ml = MlService();
    await ml.initialize();
  });

  test('akurasi pada kumpulan uji standar minimal 92%', () {
    expect(_accuracy(ml, _testSet), greaterThanOrEqualTo(0.92));
  });

  test('akurasi pada kumpulan uji sulit minimal 85%', () {
    expect(_accuracy(ml, _hardSet), greaterThanOrEqualTo(0.85));
  });

  test('barang pada struk elektronik masuk kategori Elektronik', () {
    for (final String item in <String>['PPG', 'Pulse Sensor', 'Pointer']) {
      expect(ml.classify(item).categoryName, 'Elektronik', reason: item);
    }
  });
}
