import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Hasil pembacaan teks dari satu gambar struk.
class OcrResult {
  const OcrResult({required this.rawText, required this.lineCount});

  /// Teks mentah; satu baris struk = satu baris teks.
  final String rawText;
  final int lineCount;

  static const int _minAlphanumericCount = 10;

  /// Teks dianggap terbaca bila memuat cukup huruf/angka.
  /// Gambar buram atau gelap umumnya menghasilkan teks kosong atau sangat pendek.
  bool get isReadable {
    final int count = RegExp(r'[A-Za-z0-9]').allMatches(rawText).length;
    return count >= _minAlphanumericCount;
  }
}

/// Kesalahan OCR dengan pesan yang aman ditampilkan ke pengguna.
class OcrException implements Exception {
  const OcrException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Layanan OCR on-device (Google ML Kit Text Recognition, sepenuhnya offline).
class OcrService {
  OcrService({TextRecognizer? recognizer})
      : _recognizer =
            recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  /// Membaca teks dari file gambar (hasil kamera atau galeri).
  Future<OcrResult> recognizeFromFile(String imagePath) async {
    final File file = File(imagePath);
    if (!await file.exists()) {
      throw const OcrException('File gambar tidak ditemukan');
    }

    try {
      final InputImage inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognized =
          await _recognizer.processImage(inputImage);
      final List<String> rows = _buildRows(recognized);
      return OcrResult(rawText: rows.join('\n'), lineCount: rows.length);
    } catch (_) {
      throw const OcrException(
        'Gagal membaca teks dari gambar. Silakan coba lagi.',
      );
    }
  }

  /// ML Kit sering memecah "Roti" dan "12.000" menjadi blok berbeda.
  /// Fungsi ini menyatukan potongan teks yang sejajar secara vertikal
  /// menjadi satu baris, agar nama barang dan harganya tetap berdampingan.
  List<String> _buildRows(RecognizedText recognized) {
    final List<TextLine> lines = <TextLine>[
      for (final TextBlock block in recognized.blocks) ...block.lines,
    ];
    if (lines.isEmpty) return <String>[];

    lines.sort(
      (TextLine a, TextLine b) =>
          a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy),
    );

    final List<List<TextLine>> rows = <List<TextLine>>[];
    for (final TextLine line in lines) {
      if (rows.isEmpty) {
        rows.add(<TextLine>[line]);
        continue;
      }
      final List<TextLine> current = rows.last;
      double centerSum = 0;
      for (final TextLine item in current) {
        centerSum += item.boundingBox.center.dy;
      }
      final double rowCenter = centerSum / current.length;
      final double tolerance = line.boundingBox.height * 0.5;

      if ((line.boundingBox.center.dy - rowCenter).abs() <= tolerance) {
        current.add(line);
      } else {
        rows.add(<TextLine>[line]);
      }
    }

    final List<String> result = <String>[];
    for (final List<TextLine> row in rows) {
      row.sort(
        (TextLine a, TextLine b) =>
            a.boundingBox.left.compareTo(b.boundingBox.left),
      );
      final String text =
          row.map((TextLine l) => l.text.trim()).where((String t) => t.isNotEmpty).join(' ');
      if (text.isNotEmpty) result.add(text);
    }
    return result;
  }

  /// Melepas sumber daya ML Kit.
  Future<void> dispose() => _recognizer.close();
}
