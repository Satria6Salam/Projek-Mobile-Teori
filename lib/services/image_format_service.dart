import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Kesalahan format/ukuran gambar dengan pesan yang aman ditampilkan.
class ImageFormatException implements Exception {
  const ImageFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Memeriksa dan menyiapkan file gambar struk dari berbagai format.
class ImageFormatService {
  /// Format yang diterima.
  static const List<String> supportedExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'webp',
    'bmp',
    'gif',
    'heic',
    'heif',
  ];

  /// Untuk ditampilkan di UI.
  static const String supportedLabel = 'JPG, PNG, WEBP, BMP, GIF, HEIC';

  static const int maxBytes = 25 * 1024 * 1024;

  /// Format yang dikonversi ke PNG agar seragam dibaca mesin OCR.
  static const Set<String> _convertToPng = <String>{'webp', 'bmp', 'gif'};

  /// Memvalidasi file dan mengembalikan path yang siap dipakai OCR.
  Future<String> prepare(String sourcePath) async {
    final String extension =
        p.extension(sourcePath).replaceFirst('.', '').toLowerCase();
    if (extension.isNotEmpty && !supportedExtensions.contains(extension)) {
      throw ImageFormatException(
        'Format file .$extension tidak didukung. Gunakan $supportedLabel.',
      );
    }

    final File file = File(sourcePath);
    if (!await file.exists()) {
      throw const ImageFormatException('File gambar tidak ditemukan.');
    }
    final int length = await file.length();
    if (length == 0) {
      throw const ImageFormatException('File kosong atau rusak.');
    }
    if (length > maxBytes) {
      throw const ImageFormatException(
        'Ukuran file terlalu besar (maksimal 25 MB).',
      );
    }

    if (_convertToPng.contains(extension)) {
      final String? converted = await _toPng(file);
      if (converted != null) return converted;
    }
    return sourcePath;
  }

  Future<String?> _toPng(File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ByteData? data =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      codec.dispose();
      if (data == null) return null;

      final Directory temp = await getTemporaryDirectory();
      final File out = File(
        p.join(temp.path, 'conv_${DateTime.now().microsecondsSinceEpoch}.png'),
      );
      await out.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      return out.path;
    } catch (_) {
      // Bila konversi gagal, pakai file asli.
      return null;
    }
  }
}
