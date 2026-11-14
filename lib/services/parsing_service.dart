import '../core/constants/db_constants.dart';

/// Satu barang hasil pembacaan struk.
class ParsedItem {
  const ParsedItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String name;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
}

/// Hasil Smart Parsing dari teks mentah struk.
/// Setiap variabel bernilai null bila tidak ditemukan (UC-03).
class ParsedReceiptData {
  const ParsedReceiptData({
    this.merchantName,
    this.transactionDate,
    this.totalAmount,
    this.items = const <ParsedItem>[],
    required this.status,
    this.totalFromKeyword = true,
  });

  /// True bila total diambil dari baris berkata kunci (TOTAL, JUMLAH, dll.),
  /// bukan tebakan dari nominal terbesar.
  final bool totalFromKeyword;

  final String? merchantName;
  final DateTime? transactionDate;
  final double? totalAmount;

  /// Barang yang dikenali dari baris-baris struk (nama, jumlah, harga).
  final List<ParsedItem> items;

  /// `ParsingStatus.success`, `partial`, atau `failed`.
  final String status;

  /// Nama barang saja (kompatibilitas).
  List<String> get itemNames =>
      items.map((ParsedItem item) => item.name).toList();

  /// Jumlah harga seluruh barang.
  double get itemsTotal => items.fold<double>(
        0,
        (double sum, ParsedItem item) => sum + item.totalPrice,
      );

  /// Teks gabungan merchant + nama barang (untuk catatan klasifikasi tingkat struk).
  String get classificationText {
    final String merchant = (merchantName ?? '').trim();
    return <String>[if (merchant.isNotEmpty) merchant, ...itemNames].join(' ');
  }
}

/// Satu angka pada ekor baris barang (token asli dan nilainya).
class _Num {
  const _Num(this.token, this.value);

  final String token;
  final double value;
}

/// Baris barang yang dipecah menjadi teks nama dan ekor angka.
class _Tail {
  const _Tail(this.name, this.nums, this.hasMarker);

  final String name;
  final List<_Num> nums;

  /// True bila ada penanda kali (x, X, @, *).
  final bool hasMarker;
}

/// Hasil penafsiran angka: jumlah, harga satuan, total, dan potongan nama.
class _Interp {
  const _Interp(this.qty, this.unit, this.total, this.suffix);

  final double qty;
  final double unit;
  final double total;
  final String suffix;
}

/// Smart Parsing berbasis Regular Expression untuk mengekstrak
/// Nama Merchant, Tanggal, Total Nominal, dan daftar barang.
class ParsingService {
  const ParsingService();

  static const int _merchantSearchLimit = 8;
  static const int _maxItems = 60;
  static const double _maxValue = 1e9;
  static const double _minAmount = 100;

  // ------------------------------------------------------------------ pola
  static final RegExp _merchantSkip = RegExp(
    r'^(?:jl|jln|jalan|telp|tel|telepon|hp|wa|npwp|kasir|cashier|no|nomor|struk|faktur|invoice|tanggal|tgl|date|alamat|www|http|email|kode|order|resi|trx|selamat|welcome|terima|thank)\b',
    caseSensitive: false,
  );

  /// Nama dagang jaringan ritel. Struknya sering diawali nama badan usaha
  /// (mis. "PT INDOMARCO PRISMATAMA"), padahal yang dikenal pengguna adalah
  /// nama tokonya. Pola dibuat longgar agar tetap cocok saat OCR sedikit salah
  /// baca (mis. "PRISMATAMA" terbaca "PFISMATAMA").
  static final List<(RegExp, String)> _knownChains = <(RegExp, String)>[
    (RegExp(r'alfa\s*midi|midi\s*utama', caseSensitive: false), 'Alfamidi'),
    (
      RegExp(r'alfa\s*mart|sumber\s*alfaria|alfaria\s*tri',
          caseSensitive: false),
      'Alfamart',
    ),
    (RegExp(r'indo\s*grosir', caseSensitive: false), 'Indogrosir'),
    (
      RegExp(r'indo\s*mar[ce]t|indo\s*marco|indomar\w*\s*p\w{1,2}smatama',
          caseSensitive: false),
      'Indomaret',
    ),
    (RegExp(r'lawson', caseSensitive: false), 'Lawson'),
    (RegExp(r'family\s*mart', caseSensitive: false), 'FamilyMart'),
    (RegExp(r'circle\s*k\b', caseSensitive: false), 'Circle K'),
    (RegExp(r'super\s*indo', caseSensitive: false), 'Super Indo'),
    (RegExp(r'hypermart|matahari\s*putra', caseSensitive: false), 'Hypermart'),
    (RegExp(r'transmart|trans\s*retail', caseSensitive: false), 'Transmart'),
  ];

  /// Baris alamat pada kepala struk (bukan barang belanjaan).
  static final RegExp _addressLike = RegExp(
    r'\b(?:kec|kecamatan|kel|kelurahan|kab|kabupaten|karupaten|kota|kodya|desa|dusun|jl|jln|jalan|gedung|gd|komplek|komp|perum|perumahan|ruko|blok|provinsi|prov|kode\s*pos|rt|rw)\b\.?',
    caseSensitive: false,
  );

  /// Baris yang diakhiri kode pos 5 digit (mis. "..., KABUPATEN MALANG, 65174").
  static final RegExp _postalCodeEnd = RegExp(r'[,\s]\s*\d{5}\s*$');

  static final RegExp _longDigits = RegExp(r'\d{6,}');
  static final RegExp _phoneLike = RegExp(r'\d{2,4}[\s\-]\d{5,}');

  static final RegExp _dateKeyword =
      RegExp(r'\b(?:tgl|tanggal|date|waktu|time)\b', caseSensitive: false);
  static final RegExp _dateIso =
      RegExp(r'(?<!\d)(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})(?!\d)');
  static final RegExp _dateDmy =
      RegExp(r'(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4}|\d{2})(?!\d)');
  static final RegExp _dateMonthName = RegExp(
    r'(?<!\d)(\d{1,2})\s*(jan|feb|mar|apr|mei|may|jun|jul|agu|aug|sep|okt|oct|nov|des|dec)[a-z]*\.?\s*,?\s*(\d{4}|\d{2})(?!\d)',
    caseSensitive: false,
  );
  static const Map<String, int> _months = <String, int>{
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'mei': 5,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'agu': 8,
    'aug': 8,
    'sep': 9,
    'okt': 10,
    'oct': 10,
    'nov': 11,
    'des': 12,
    'dec': 12,
  };

  static final RegExp _totalStrong = RegExp(
    r'grand\s*total|total\s*(?:bayar|belanja|tagihan|pembayaran|akhir|transaksi)|jumlah\s*(?:bayar|tagihan)|amount\s*due|total\s*due|net\s*total',
    caseSensitive: false,
  );
  static final RegExp _totalStrongExclude =
      RegExp(r'sub\s*-?\s*total|kembali|change', caseSensitive: false);
  static final RegExp _totalWeak =
      RegExp(r'\b(?:total|jumlah|tagihan|amount)\b', caseSensitive: false);
  static final RegExp _totalWeakExclude = RegExp(
    r'sub\s*-?\s*total|kembali|change|diskon|discount|hemat',
    caseSensitive: false,
  );
  static final RegExp _fallbackExclude = RegExp(
    r'\b(?:tunai|cash|kembali|kembalian|change|bayar|debit|kredit|card|kartu|qris|ppn|pajak|tax|diskon|discount|npwp|telp|telepon|tel|hp|nomor|no|tgl|tanggal|jam|kasir|cashier|member|poin|point|saldo)\b',
    caseSensitive: false,
  );

  static final RegExp _rpPrefix =
      RegExp(r'(?<![A-Za-z])rp\.?\s*', caseSensitive: false);
  static final RegExp _amountToken = RegExp(
    r'(?<![\d.,])(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)(?!\d)',
  );

  static final RegExp _totalBoundary = RegExp(
    r'\b(?:sub\s*-?\s*total|total|jumlah)\b',
    caseSensitive: false,
  );
  static final RegExp _itemExclude = RegExp(
    r'\b(?:sub\s*-?\s*total|total|jumlah|tunai|cash|kembali|kembalian|change|ppn|pajak|tax|diskon|discount|disc|potongan|promo|voucher|pembulatan|rounding|bonus|cashback|bayar|kasir|cashier|tanggal|tgl|jam|struk|terima\s*kasih|npwp|member|poin|point|debit|kredit|qris|telp|telepon|alamat|invoice|faktur|harga|hemat|saving|no|nomor)\b|www|http|@',
    caseSensitive: false,
  );

  // Token pada ekor baris barang: angka, penanda kali, "X1", "2x", atau "2x3.500".
  static final RegExp _tokNum = RegExp(r'^[\d.,]*\d[\d.,]*$');
  static final RegExp _tokMark = RegExp(r'^[xX@*×]$');
  static final RegExp _tokMarkN = RegExp(r'^[xX@*×]([\d.,]*\d[\d.,]*)$');
  static final RegExp _tokNMark = RegExp(r'^([\d.,]*\d[\d.,]*)[xX@*×]$');
  static final RegExp _tokNMN =
      RegExp(r'^([\d.,]*\d[\d.,]*)[xX@*×]([\d.,]*\d[\d.,]*)$');
  static final RegExp _digitLookalike = RegExp(r'^[\dOoIl.,]+$');
  static final RegExp _lookalikeLetter = RegExp(r'[OoIl]');
  static final RegExp _leadingQty =
      RegExp(r'^(\d{1,2})\s*[xX]?\s+(?=[A-Za-z])');
  static final RegExp _trailingFlag = RegExp(r'\s+[A-Za-z]$');
  static final RegExp _qtyInName =
      RegExp(r'\d+(?:[.,]\d+)?\s*[xX@*]\s*[\d.,]+');
  static final RegExp _numericWord = RegExp(r'^[\d.,]+$');
  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');

  // --------------------------------------------------------------- publik

  /// Mengurai teks mentah OCR menjadi data transaksi terstruktur.
  ParsedReceiptData parse(String rawText) {
    final List<String> lines = _splitLines(rawText);
    if (lines.isEmpty) {
      return const ParsedReceiptData(status: ParsingStatus.failed);
    }

    final int merchantIndex = _findMerchantIndex(lines);
    final String? merchant = _knownChainName(lines) ??
        (merchantIndex < 0 ? null : _cleanMerchant(lines[merchantIndex]));
    final DateTime? date = _extractDate(lines);
    final double? keywordTotal = _extractKeywordTotal(lines);
    final double? total = keywordTotal ?? _fallbackTotal(lines);
    List<ParsedItem> items =
        _extractItems(lines, startIndex: merchantIndex + 1);

    // Satu barang tidak mungkin lebih mahal dari total belanja. Baris seperti
    // itu hampir pasti salah baca (kode pos, nomor telepon, nomor transaksi).
    if (keywordTotal != null && keywordTotal > 0) {
      items = items
          .where((ParsedItem item) => item.totalPrice <= keywordTotal * 1.01)
          .toList();
    }

    final int found = <Object?>[
      if (merchant != null && merchant.isNotEmpty) merchant,
      date,
      total,
    ].whereType<Object>().length;

    final String status = found == 3
        ? ParsingStatus.success
        : (found == 0 ? ParsingStatus.failed : ParsingStatus.partial);

    return ParsedReceiptData(
      merchantName: (merchant == null || merchant.isEmpty) ? null : merchant,
      transactionDate: date,
      totalAmount: total,
      items: items,
      status: status,
      totalFromKeyword: keywordTotal != null,
    );
  }

  // ------------------------------------------------------------- util umum

  List<String> _splitLines(String rawText) {
    return rawText
        .split(RegExp(r'\r?\n'))
        .map((String l) =>
            _fixDigitLookalikes(l.replaceAll(RegExp(r'\s+'), ' ').trim()))
        .where((String l) => l.isNotEmpty)
        .toList();
  }

  /// OCR sering salah membaca angka 0 sebagai huruf "o" dan angka 1 sebagai "l"/"I"
  /// (mis. "500.00o", "2.OOO", "Xl"). Pada token yang jelas berupa angka,
  /// huruf yang mirip angka dikembalikan.
  String _fixDigitLookalikes(String line) {
    final String fixed = line.split(' ').map((String token) {
      final int digits = RegExp(r'\d').allMatches(token).length;
      final bool hasSeparator = token.contains('.') || token.contains(',');
      if (token.length >= 3 &&
          _digitLookalike.hasMatch(token) &&
          _lookalikeLetter.hasMatch(token) &&
          (digits >= 2 || (digits >= 1 && hasSeparator))) {
        return token
            .replaceAll(RegExp(r'[Oo]'), '0')
            .replaceAll(RegExp(r'[Il]'), '1');
      }
      return token;
    }).join(' ');
    // Penanda jumlah "Xl" / "XI" setelah sebuah angka dibaca sebagai "X1".
    return fixed.replaceAllMapped(
      RegExp(r'(?<=\d) ([xX])([lI])(?=\s|$)'),
      (Match m) => ' ${m.group(1)}1',
    );
  }

  // -------------------------------------------------------------- merchant

  /// Nama toko jaringan ritel yang dikenali di bagian atas struk; null bila tidak ada.
  String? _knownChainName(List<String> lines) {
    final int limit = lines.length < _merchantSearchLimit
        ? lines.length
        : _merchantSearchLimit;
    final String head = lines.sublist(0, limit).join(' ');
    for (final (RegExp pattern, String name) in _knownChains) {
      if (pattern.hasMatch(head)) return name;
    }
    return null;
  }

  int _findMerchantIndex(List<String> lines) {
    final int limit = lines.length < _merchantSearchLimit
        ? lines.length
        : _merchantSearchLimit;
    for (int i = 0; i < limit; i++) {
      if (_isMerchantCandidate(lines[i])) return i;
    }
    return -1;
  }

  bool _isMerchantCandidate(String line) {
    if (line.length > 45) return false;
    if (_merchantSkip.hasMatch(line)) return false;
    if (_longDigits.hasMatch(line) || _phoneLike.hasMatch(line)) return false;
    if (line.contains('@') || line.toLowerCase().contains('.com')) return false;
    if (_dateFromLine(line) != null) return false;

    final int letters = RegExp(r'[A-Za-z]').allMatches(line).length;
    final int visible = line.replaceAll(' ', '').length;
    if (letters < 3 || visible == 0) return false;
    return letters / visible >= 0.6;
  }

  String _cleanMerchant(String line) {
    String name = line
        .replaceAll(RegExp(r'^[^A-Za-z0-9]+'), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final int letterCount = RegExp(r'[A-Za-z]').allMatches(name).length;
    final int upperCount = RegExp(r'[A-Z]').allMatches(name).length;
    final bool mostlyUpper = letterCount > 0 && upperCount / letterCount >= 0.8;
    if (name.isNotEmpty && mostlyUpper) {
      name = name
          .split(' ')
          .map(
            (String w) => w.isEmpty
                ? w
                : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
          )
          .join(' ');
    }
    return name;
  }

  // --------------------------------------------------------------- tanggal

  DateTime? _extractDate(List<String> lines) {
    for (final String line in lines) {
      if (!_dateKeyword.hasMatch(line)) continue;
      final DateTime? date = _dateFromLine(line);
      if (date != null) return date;
    }
    for (final String line in lines) {
      final DateTime? date = _dateFromLine(line);
      if (date != null) return date;
    }
    return null;
  }

  DateTime? _dateFromLine(String line) {
    for (final RegExpMatch m in _dateIso.allMatches(line)) {
      final DateTime? date =
          _buildDate(_group(m, 1), _group(m, 2), _group(m, 3));
      if (date != null) return date;
    }
    for (final RegExpMatch m in _dateDmy.allMatches(line)) {
      final DateTime? date =
          _buildDayFirst(_group(m, 1), _group(m, 2), _group(m, 3));
      if (date != null) return date;
    }
    for (final RegExpMatch m in _dateMonthName.allMatches(line)) {
      final String key = (m.group(2) ?? '').toLowerCase();
      final int? month = _months[key];
      final DateTime? date = _buildDate(_group(m, 3), month, _group(m, 1));
      if (date != null) return date;
    }
    return null;
  }

  int? _group(RegExpMatch match, int index) =>
      int.tryParse(match.group(index) ?? '');

  /// Format hari-bulan-tahun; jika bulan > 12 dan hari <= 12, keduanya ditukar.
  DateTime? _buildDayFirst(int? first, int? second, int? year) {
    if (first == null || second == null) return null;
    int day = first;
    int month = second;
    if (month > 12 && day <= 12) {
      final int tmp = day;
      day = month;
      month = tmp;
    }
    return _buildDate(year, month, day);
  }

  DateTime? _buildDate(int? year, int? month, int? day) {
    if (year == null || month == null || day == null) return null;
    int y = year;
    if (y < 100) y += 2000;
    if (y < 2000 || y > DateTime.now().year + 1) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final DateTime date = DateTime(y, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  // ----------------------------------------------------------------- total

  /// Total dari baris berkata kunci saja; null bila tidak ada.
  double? _extractKeywordTotal(List<String> lines) {
    final double? strong =
        _findAmountByPattern(lines, _totalStrong, _totalStrongExclude);
    if (strong != null) return strong;

    final double? weak =
        _findAmountByPattern(lines, _totalWeak, _totalWeakExclude);
    return weak;
  }

  /// Menelusuri dari baris paling bawah (total biasanya di bagian akhir struk).
  double? _findAmountByPattern(
    List<String> lines,
    RegExp include,
    RegExp exclude,
  ) {
    for (int i = lines.length - 1; i >= 0; i--) {
      final String line = lines[i];
      if (!include.hasMatch(line) || exclude.hasMatch(line)) continue;

      final double? amount = _lastAmountInLine(line);
      if (amount != null) return amount;

      // Nominal kadang terpisah ke baris berikutnya.
      if (i + 1 < lines.length && _isAmountOnlyLine(lines[i + 1])) {
        final double? next = _lastAmountInLine(lines[i + 1]);
        if (next != null) return next;
      }
    }
    return null;
  }

  /// Cadangan bila tidak ada kata kunci total: nominal terbesar pada baris yang layak.
  /// Hasilnya perkiraan; pengguna tetap memvalidasinya di form pratinjau.
  double? _fallbackTotal(List<String> lines) {
    double? best;
    for (final String line in lines) {
      if (_fallbackExclude.hasMatch(line)) continue;
      if (RegExp(r'\d{8,}').hasMatch(line)) continue;
      if (_dateFromLine(line) != null) continue;
      final double? amount = _lastAmountInLine(line);
      if (amount == null) continue;
      if (best == null || amount > best) best = amount;
    }
    return best;
  }

  bool _isAmountOnlyLine(String line) {
    final String cleaned = line.replaceAll(_rpPrefix, ' ');
    return !_hasLetter.hasMatch(cleaned) && _amountToken.hasMatch(cleaned);
  }

  /// Nominal terakhir pada baris (bernilai minimal [_minAmount]).
  double? _lastAmountInLine(String line) {
    final String cleaned = line.replaceAll(_rpPrefix, ' ');
    final List<RegExpMatch> matches = _amountToken.allMatches(cleaned).toList();
    for (int i = matches.length - 1; i >= 0; i--) {
      final double? value = _parseAmount(matches[i].group(1) ?? '');
      if (value != null && value >= _minAmount) return value;
    }
    return null;
  }

  /// Mengonversi teks angka berformat Indonesia/Inggris menjadi double.
  /// Contoh: "17.000" -> 17000, "1.234,50" -> 1234.5, "1,234.50" -> 1234.5.
  double? _parseAmount(String token) {
    if (token.isEmpty) return null;
    final bool hasDot = token.contains('.');
    final bool hasComma = token.contains(',');
    String normalized;

    if (hasDot && hasComma) {
      final String decimalSep =
          token.lastIndexOf('.') > token.lastIndexOf(',') ? '.' : ',';
      final String thousandSep = decimalSep == '.' ? ',' : '.';
      normalized =
          token.replaceAll(thousandSep, '').replaceAll(decimalSep, '.');
    } else if (hasDot || hasComma) {
      final String sep = hasDot ? '.' : ',';
      final List<String> parts = token.split(sep);
      if (parts.length > 2 || parts.last.length == 3) {
        normalized = parts.join();
      } else {
        normalized = '${parts.first}.${parts.last}';
      }
    } else {
      normalized = token;
    }
    return double.tryParse(normalized);
  }

  // ---------------------------------------------------------------- barang

  List<ParsedItem> _extractItems(List<String> lines,
      {required int startIndex}) {
    int endIndex = lines.length;
    for (int i = startIndex; i < lines.length; i++) {
      if (_totalBoundary.hasMatch(lines[i])) {
        endIndex = i;
        break;
      }
    }

    final List<ParsedItem> items = <ParsedItem>[];
    String? pending; // nama barang yang harganya ada di baris berikutnya
    for (int i = startIndex; i < endIndex; i++) {
      final String line = lines[i];
      if (_itemExclude.hasMatch(line) ||
          _addressLike.hasMatch(line) ||
          _postalCodeEnd.hasMatch(line) ||
          _dateFromLine(line) != null) {
        pending = null;
        continue;
      }

      final _Tail tail = _splitTail(line);
      final bool named = _letters(tail.name) >= 3;

      if (tail.nums.isEmpty) {
        // Baris berisi nama saja: harga biasanya ada di baris berikutnya.
        if (named) {
          pending = tail.name;
        } else if (tail.name.trim().isNotEmpty) {
          pending = null;
        }
        continue;
      }

      if (named) {
        final ParsedItem? item =
            _buildItem(tail.name, tail.nums, tail.hasMarker);
        if (item != null) items.add(item);
      } else {
        // Baris hanya angka: dipasangkan dengan nama pada baris sebelumnya.
        final String? name = pending;
        if (name != null) {
          final ParsedItem? item = _buildItem(name, tail.nums, tail.hasMarker);
          if (item != null) items.add(item);
        }
      }
      pending = null;
      if (items.length >= _maxItems) break;
    }
    return items;
  }

  String _normalizeLine(String raw) {
    return raw
        .replaceAll(_rpPrefix, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isTailToken(String t) {
    return _tokNum.hasMatch(t) ||
        _tokMark.hasMatch(t) ||
        _tokMarkN.hasMatch(t) ||
        _tokNMark.hasMatch(t) ||
        _tokNMN.hasMatch(t);
  }

  /// Memisahkan baris menjadi nama (teks di depan) dan ekor angka (di belakang).
  /// Contoh: "AQUA 600ML 3.500" -> nama "AQUA 600ML", angka [3.500];
  /// "PPG 500.000 X1 500.000" -> nama "PPG", angka [500.000, 1, 500.000] (ada penanda x).
  _Tail _splitTail(String rawLine) {
    String line = _normalizeLine(rawLine);
    final String stripped = line.replaceFirst(_trailingFlag, '');
    if (RegExp(r'[\d.,]$').hasMatch(stripped)) line = stripped;

    final List<String> tokens = line.split(' ');
    int i = tokens.length;
    while (i > 0 && _isTailToken(tokens[i - 1])) {
      i--;
    }
    final List<String> prefix = tokens.sublist(0, i);
    final List<String> tail = tokens.sublist(i);

    final bool hasNumber = tail.any(
      (String t) =>
          _tokNum.hasMatch(t) ||
          _tokMarkN.hasMatch(t) ||
          _tokNMark.hasMatch(t) ||
          _tokNMN.hasMatch(t),
    );
    if (!hasNumber) return _Tail(tokens.join(' '), const <_Num>[], false);

    final List<_Num> nums = <_Num>[];
    bool hasMarker = false;

    void add(String token) {
      final double? value = _parseAmount(token);
      if (value != null && value <= _maxValue) nums.add(_Num(token, value));
    }

    for (final String t in tail) {
      if (_tokMark.hasMatch(t)) {
        hasMarker = true;
        continue;
      }
      final RegExpMatch? markN = _tokMarkN.firstMatch(t);
      if (markN != null) {
        hasMarker = true;
        add(markN.group(1) ?? '');
        continue;
      }
      final RegExpMatch? nMark = _tokNMark.firstMatch(t);
      if (nMark != null) {
        hasMarker = true;
        add(nMark.group(1) ?? '');
        continue;
      }
      final RegExpMatch? nmn = _tokNMN.firstMatch(t);
      if (nmn != null) {
        hasMarker = true;
        add(nmn.group(1) ?? '');
        add(nmn.group(2) ?? '');
        continue;
      }
      add(t);
    }
    return _Tail(prefix.join(' '), nums, hasMarker);
  }

  bool _hasSeparator(String token) =>
      token.contains('.') || token.contains(',');

  /// Menentukan jumlah dan harga satuan dari dua angka di sekitar tanda "x".
  /// Jumlah biasanya lebih kecil dari harga satuan, sehingga "2 x 3.500" dan
  /// "3.500 x2" sama-sama dibaca sebagai 2 buah @ Rp3.500.
  ({double qty, double unit}) _resolveQtyUnit(
      double a, double b, double? total) {
    final bool aIsQty = a <= b;
    final double qty = aIsQty ? a : b;
    double unit = aIsQty ? b : a;
    if (total != null && (qty * unit - total).abs() > total * 0.02 + 1) {
      unit = total / qty; // Percaya total struk bila tidak cocok.
    }
    return (qty: qty, unit: unit);
  }

  /// Menafsirkan ekor angka sebuah baris barang menjadi jumlah, harga satuan, dan total.
  /// Mendukung antara lain: "12.000", "2 12.000", "6.000 12.000", "2 6.000 12.000",
  /// "2 x 6.000 12.000", dan "500.000 X1 500.000".
  _Interp? _interpret(List<_Num> nums, bool hasMarker) {
    final int n = nums.length;
    if (n == 0) return null;
    final List<double> v = nums.map((_Num x) => x.value).toList();

    if (hasMarker) {
      if (n == 1) return null;
      if (n == 2) {
        if (v[0] <= 0 || v[1] <= 0) return null;
        final double qty = v[0] <= v[1] ? v[0] : v[1];
        final double unit = v[0] <= v[1] ? v[1] : v[0];
        return _Interp(qty, unit, qty * unit, '');
      }
      final double a = v[n - 3];
      final double b = v[n - 2];
      final double total = v[n - 1];
      if (a <= 0 || b <= 0) return null;
      final ({double qty, double unit}) pair = _resolveQtyUnit(a, b, total);
      return _Interp(pair.qty, pair.unit, total, '');
    }

    if (n == 1) return _Interp(1, v[0], v[0], '');

    if (n == 2) {
      final double a = v[0];
      final double b = v[1];
      final String firstToken = nums[0].token;
      if (!_hasSeparator(firstToken) && a >= 1 && a <= 99) {
        return _Interp(a, b / a, b, ''); // "2 12.000"
      }
      if (_hasSeparator(firstToken) || a >= 1000) {
        final double q = a > 0 ? b / a : 1;
        if ((q - q.roundToDouble()).abs() < 0.01 &&
            q.round() >= 1 &&
            q.round() <= 99) {
          return _Interp(q.roundToDouble(), a, b, ''); // "6.000 12.000"
        }
        return _Interp(1, b, b, '');
      }
      return _Interp(1, b, b, firstToken); // 100-999 tanpa pemisah: bagian nama
    }

    final double x = v[n - 3];
    final double y = v[n - 2];
    final double z = v[n - 1];
    if (x > 0 && y > 0 && (x * y - z).abs() <= z * 0.02 + 1) {
      final double qty = x <= y ? x : y;
      final double unit = x <= y ? y : x;
      return _Interp(qty, unit, z, '');
    }
    final String suffix =
        nums.sublist(0, n - 1).map((_Num e) => e.token).join(' ');
    return _Interp(1, z, z, suffix);
  }

  ParsedItem? _buildItem(String nameRaw, List<_Num> nums, bool hasMarker) {
    final _Interp? r = _interpret(nums, hasMarker);
    if (r == null) return null;
    if (r.total < _minAmount || r.total > _maxValue) return null;

    String name = '$nameRaw ${r.suffix}'.trim();
    double qty = r.qty;
    double unit = r.unit;

    // Jumlah di awal nama ("2 TEH BOTOL 7.000").
    if (nums.length == 1 && !hasMarker) {
      final RegExpMatch? lead = _leadingQty.firstMatch(name);
      if (lead != null) {
        final int? q = int.tryParse(lead.group(1) ?? '');
        final String rest = name.substring(lead.end);
        if (q != null &&
            q >= 1 &&
            r.total / q >= _minAmount &&
            _letters(rest) >= 3) {
          qty = q.toDouble();
          unit = r.total / q;
          name = rest;
        }
      }
    }

    final String? cleaned = _cleanItemName(name);
    if (cleaned == null) return null;
    return ParsedItem(
      name: cleaned,
      quantity: qty,
      unitPrice: unit,
      totalPrice: r.total,
    );
  }

  int _letters(String text) => RegExp(r'[A-Za-z]').allMatches(text).length;

  String? _cleanItemName(String raw) {
    final String withoutQty = raw.replaceAll(_qtyInName, ' ');
    final String name = withoutQty
        .split(' ')
        .where((String w) => w.isNotEmpty && !_numericWord.hasMatch(w))
        .join(' ')
        .replaceAll(RegExp(r'^[^A-Za-z0-9]+'), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9]+$'), '')
        .trim();

    if (_letters(name) < 3) return null;
    return name.length > 60 ? name.substring(0, 60).trim() : name;
  }
}
