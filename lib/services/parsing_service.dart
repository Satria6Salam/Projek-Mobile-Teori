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
  });

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

class _ItemParse {
  const _ItemParse(this.item, this.usedNextLine);

  final ParsedItem item;
  final bool usedNextLine;
}

/// Smart Parsing berbasis Regular Expression untuk mengekstrak
/// Nama Merchant, Tanggal, Total Nominal, dan daftar barang.
class ParsingService {
  const ParsingService();

  static const int _merchantSearchLimit = 8;
  static const int _maxItems = 40;
  static const double _minAmount = 100;

  // ------------------------------------------------------------------ pola
  static final RegExp _merchantSkip = RegExp(
    r'^(?:jl|jln|jalan|telp|tel|telepon|hp|wa|npwp|kasir|cashier|no|nomor|struk|faktur|invoice|tanggal|tgl|date|alamat|www|http|email|kode|order|resi|trx|selamat|welcome|terima|thank)\b',
    caseSensitive: false,
  );
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

  // Pola baris barang.
  // "NAMA 2 x 3.500 7.000" maupun "NAMA 500.000 X1 500.000" (jumlah dan harga
  // satuan dapat tertukar urutannya, ditentukan oleh [_resolveQtyUnit]).
  static final RegExp _itemQtyUnitTotal = RegExp(
    r'^(.*?[A-Za-z].*?)\s+([\d.,]+)\s*[xX@*]\s*([\d.,]+)\s+([\d.,]+)$',
  );
  static final RegExp _itemQtyUnitTotalPlain = RegExp(
    r'^(.*?[A-Za-z].*?)\s+(\d{1,2})\s+([\d.,]+)\s+([\d.,]+)$',
  );
  static final RegExp _itemNameTotal =
      RegExp(r'^(.*?[A-Za-z].*?)\s+([\d.,]+)$');
  static final RegExp _qtyPriceLine = RegExp(
    r'^([\d.,]+)\s*[xX@*]\s*([\d.,]+)(?:\s+([\d.,]+))?$',
  );
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
    final String? merchant =
        merchantIndex < 0 ? null : _cleanMerchant(lines[merchantIndex]);
    final DateTime? date = _extractDate(lines);
    final double? total = _extractTotal(lines);
    final List<ParsedItem> items =
        _extractItems(lines, startIndex: merchantIndex + 1);

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

  /// OCR sering salah membaca angka 0 sebagai huruf "o" (mis. "500.00o").
  /// Pada token yang jelas berupa angka, huruf yang mirip angka dikembalikan.
  String _fixDigitLookalikes(String line) {
    return line.split(' ').map((String token) {
      final int digits = RegExp(r'\d').allMatches(token).length;
      if (token.length >= 3 &&
          digits >= 2 &&
          _digitLookalike.hasMatch(token) &&
          _lookalikeLetter.hasMatch(token)) {
        return token
            .replaceAll(RegExp(r'[Oo]'), '0')
            .replaceAll(RegExp(r'[Il]'), '1');
      }
      return token;
    }).join(' ');
  }

  // -------------------------------------------------------------- merchant

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

  double? _extractTotal(List<String> lines) {
    final double? strong =
        _findAmountByPattern(lines, _totalStrong, _totalStrongExclude);
    if (strong != null) return strong;

    final double? weak =
        _findAmountByPattern(lines, _totalWeak, _totalWeakExclude);
    if (weak != null) return weak;

    return _fallbackTotal(lines);
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
    int i = startIndex;
    while (i < endIndex) {
      final String line = lines[i];
      if (_itemExclude.hasMatch(line) || _dateFromLine(line) != null) {
        i++;
        continue;
      }

      final String? next = i + 1 < lines.length ? lines[i + 1] : null;
      final _ItemParse? parsed = _parseItemLine(line, next);
      if (parsed != null) {
        items.add(parsed.item);
        if (parsed.usedNextLine) i++;
        if (items.length >= _maxItems) break;
      }
      i++;
    }
    return items;
  }

  String _normalizeLine(String raw) {
    return raw
        .replaceAll(_rpPrefix, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Mengenali satu barang dari satu baris ("ROTI 12.000", "SABUN 2 x 3.500 7.000",
  /// "2 INDOMIE 7.000") atau dari dua baris (nama, lalu "2 x 6.000  12.000" atau
  /// "500.000 X1 500.000").
  _ItemParse? _parseItemLine(String rawLine, String? nextLine) {
    String line = _normalizeLine(rawLine);
    final String stripped = line.replaceFirst(_trailingFlag, '');
    if (RegExp(r'[\d.,]$').hasMatch(stripped)) line = stripped;

    RegExpMatch? m = _itemQtyUnitTotal.firstMatch(line);
    if (m != null) {
      final ParsedItem? item = _buildItem(
        nameRaw: m.group(1) ?? '',
        first: m.group(2),
        second: m.group(3),
        totalRaw: m.group(4),
        requireConsistent: false,
      );
      if (item != null) return _ItemParse(item, false);
    }

    m = _itemQtyUnitTotalPlain.firstMatch(line);
    if (m != null) {
      final ParsedItem? item = _buildItem(
        nameRaw: m.group(1) ?? '',
        first: m.group(2),
        second: m.group(3),
        totalRaw: m.group(4),
        requireConsistent: true,
      );
      if (item != null) return _ItemParse(item, false);
    }

    m = _itemNameTotal.firstMatch(line);
    if (m != null) {
      String name = m.group(1) ?? '';
      final double? total = _parseAmount(m.group(2) ?? '');
      if (total == null || total < _minAmount) return null;

      double qty = 1;
      final RegExpMatch? lead = _leadingQty.firstMatch(name);
      if (lead != null) {
        final int? q = int.tryParse(lead.group(1) ?? '');
        final String rest = name.substring(lead.end);
        if (q != null &&
            q >= 1 &&
            total / q >= _minAmount &&
            _letters(rest) >= 3) {
          qty = q.toDouble();
          name = rest;
        }
      }
      final String? cleaned = _cleanItemName(name);
      if (cleaned == null) return null;
      return _ItemParse(
        ParsedItem(
          name: cleaned,
          quantity: qty,
          unitPrice: total / qty,
          totalPrice: total,
        ),
        false,
      );
    }

    // Format dua baris: nama barang di baris ini, jumlah/harga di baris berikutnya.
    if (nextLine != null && _hasLetter.hasMatch(line)) {
      final RegExpMatch? q = _qtyPriceLine.firstMatch(_normalizeLine(nextLine));
      if (q != null) {
        final ParsedItem? item = _buildItem(
          nameRaw: line,
          first: q.group(1),
          second: q.group(2),
          totalRaw: q.group(3),
          requireConsistent: false,
        );
        if (item != null) return _ItemParse(item, true);
      }
    }
    return null;
  }

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

  ParsedItem? _buildItem({
    required String nameRaw,
    required String? first,
    required String? second,
    required String? totalRaw,
    required bool requireConsistent,
  }) {
    final String? name = _cleanItemName(nameRaw);
    if (name == null) return null;

    final double? a = first == null ? null : _parseAmount(first);
    final double? b = second == null ? null : _parseAmount(second);
    if (a == null || b == null || a <= 0 || b <= 0) return null;
    final double? given = totalRaw == null ? null : _parseAmount(totalRaw);

    final ({double qty, double unit}) pair = _resolveQtyUnit(a, b, given);
    final double total = given ?? pair.qty * pair.unit;

    if (requireConsistent &&
        (pair.qty * pair.unit - total).abs() > total * 0.02 + 1) {
      return null;
    }
    if (total < _minAmount) return null;
    return ParsedItem(
      name: name,
      quantity: pair.qty,
      unitPrice: pair.unit,
      totalPrice: total,
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
