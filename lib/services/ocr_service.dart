import 'dart:io';
import 'dart:math';
import 'dart:ui' show Rect;

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
  /// Potongan teks yang sejajar disatukan menjadi satu baris struk.
  List<String> _buildRows(RecognizedText recognized) {
    return buildReceiptRows(<OcrFragment>[
      for (final TextBlock block in recognized.blocks)
        for (final TextLine line in block.lines) OcrFragment.fromLine(line),
    ]);
  }

  /// Melepas sumber daya ML Kit.
  Future<void> dispose() => _recognizer.close();
}

/// Satu potongan teks hasil OCR beserta posisinya di gambar.
class OcrFragment {
  const OcrFragment({
    required this.text,
    required this.left,
    required this.centerX,
    required this.centerY,
    required this.height,
    this.slope = 0,
  });

  factory OcrFragment.fromLine(TextLine line) {
    final Rect box = line.boundingBox;
    double slope = 0;
    final List<Point<int>> pts = line.cornerPoints;
    if (pts.length >= 2) {
      final int dx = pts[1].x - pts[0].x;
      if (dx.abs() > 0) slope = (pts[1].y - pts[0].y) / dx;
    }
    return OcrFragment(
      text: line.text,
      left: box.left,
      centerX: box.center.dx,
      centerY: box.center.dy,
      height: box.height,
      slope: slope,
    );
  }

  final String text;
  final double left;
  final double centerX;
  final double centerY;
  final double height;

  /// Kemiringan garis teks (dy/dx); 0 bila foto lurus.
  final double slope;
}

/// Menyusun potongan teks menjadi baris struk, dengan koreksi kemiringan.
///
/// Pada foto yang miring, harga di sisi kanan berada lebih rendah (atau lebih
/// tinggi) daripada nama barang di sisi kiri. Posisi vertikal tiap potongan
/// diproyeksikan dulu mengikuti kemiringan rata-rata (median) halaman, baru
/// kemudian dikelompokkan per baris dan diurutkan dari kiri ke kanan.
List<String> buildReceiptRows(List<OcrFragment> fragments) {
  if (fragments.isEmpty) return <String>[];

  final List<double> slopes = fragments
      .where((OcrFragment f) => f.text.trim().length >= 3)
      .map((OcrFragment f) => f.slope)
      .toList()
    ..sort();
  double slope = slopes.isEmpty ? 0 : slopes[slopes.length ~/ 2];
  if (slope.abs() > 0.5) slope = 0; // Abaikan nilai yang tidak masuk akal.

  double projected(OcrFragment f) => f.centerY - slope * f.centerX;

  final List<OcrFragment> sorted = List<OcrFragment>.of(fragments)
    ..sort(
        (OcrFragment a, OcrFragment b) => projected(a).compareTo(projected(b)));

  final List<List<OcrFragment>> rows = <List<OcrFragment>>[];
  for (final OcrFragment f in sorted) {
    if (rows.isNotEmpty) {
      final List<OcrFragment> current = rows.last;
      double sum = 0;
      for (final OcrFragment item in current) {
        sum += projected(item);
      }
      final double rowCenter = sum / current.length;
      if ((projected(f) - rowCenter).abs() <= f.height * 0.5) {
        current.add(f);
        continue;
      }
    }
    rows.add(<OcrFragment>[f]);
  }

  final List<String> result = <String>[];
  for (final List<OcrFragment> row in rows) {
    row.sort((OcrFragment a, OcrFragment b) => a.left.compareTo(b.left));
    final String text = row
        .map((OcrFragment f) => f.text.trim())
        .where((String t) => t.isNotEmpty)
        .join(' ');
    if (text.isNotEmpty) result.add(text);
  }
  return result;
}
