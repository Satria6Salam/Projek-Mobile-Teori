import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/core/constants/db_constants.dart';
import 'package:smart_receipt/services/parsing_service.dart';
import 'package:smart_receipt/services/receipt_selector.dart';

const String _full = 'INDOMARET\n'
    'Jl. Raya Malang\n'
    '01/10/2026\n'
    'Roti 12.000\n'
    'Air Mineral 5.000\n'
    'TOTAL 17.000';

void main() {
  const ParsingService parser = ParsingService();
  const ReceiptSelector selector = ReceiptSelector();

  ReceiptReading reading(String text, {bool enhanced = false}) {
    return ReceiptReading(
      rawText: text,
      parsed: parser.parse(text),
      fromEnhancedImage: enhanced,
    );
  }

  test('struk lengkap dan cocok dianggap selesai', () {
    final ReceiptReading full = reading(_full);
    expect(selector.isConsistent(full.parsed), isTrue);
    expect(selector.isComplete(full.parsed), isTrue);
  });

  test('struk tanpa total atau dengan jumlah tidak cocok belum selesai', () {
    expect(
      selector.isComplete(reading('INDOMARET\n01/10/2026\nRoti 12.000').parsed),
      isFalse,
    );
    expect(
      selector.isComplete(
        reading('INDOMARET\n01/10/2026\nRoti 12.000\nTOTAL 17.000').parsed,
      ),
      isFalse,
    );
  });

  test('bacaan yang lebih lengkap mendapat nilai lebih tinggi', () {
    final ReceiptReading partial = reading('INDOMARET\n01/10/2026\nRoti 12.000');
    final ReceiptReading full = reading(_full, enhanced: true);

    expect(selector.score(full), greaterThan(selector.score(partial)));
    final ReceiptReading chosen = selector.choose(partial, full);
    expect(chosen.fromEnhancedImage, isTrue);
    expect(chosen.parsed.items.length, 2);
    expect(chosen.parsed.totalAmount, 17000);
  });

  test('foto asli dipertahankan bila hasil perjelasan tidak lebih baik', () {
    final ReceiptReading original = reading(_full);
    final ReceiptReading worse = reading('INDOMARET\nRoti 12.000', enhanced: true);

    final ReceiptReading chosen = selector.choose(original, worse);
    expect(chosen.fromEnhancedImage, isFalse);
    expect(chosen.parsed.status, ParsingStatus.success);
  });

  test('data utama yang kosong dilengkapi dari bacaan lain', () {
    // Bacaan terpilih tidak memuat tanggal; tanggal diambil dari bacaan lain.
    final ReceiptReading noDate = reading(
      'INDOMARET\nRoti 12.000\nAir Mineral 5.000\nTOTAL 17.000',
      enhanced: true,
    );
    final ReceiptReading dateOnly = reading('INDOMARET\n01/10/2026');

    final ReceiptReading chosen = selector.choose(dateOnly, noDate);
    expect(chosen.fromEnhancedImage, isTrue);
    expect(chosen.parsed.transactionDate, DateTime(2026, 10, 1));
    expect(chosen.parsed.totalAmount, 17000);
    expect(chosen.parsed.status, ParsingStatus.success);
  });

  test('tanpa bacaan kedua, bacaan pertama dikembalikan apa adanya', () {
    final ReceiptReading original = reading(_full);
    expect(identical(selector.choose(original, null), original), isTrue);
  });
}
