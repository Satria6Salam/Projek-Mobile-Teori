import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_enhancer.dart';

/// Foto struk yang sudah diperjelas dan siap dibaca ulang oleh OCR.
class EnhancedImage {
  const EnhancedImage({required this.path, required this.quality});

  /// Lokasi file sementara hasil perbaikan.
  final String path;

  /// Mutu foto aslinya.
  final ImageQuality quality;
}

/// Hasil kerja isolate (hanya berisi data sederhana).
class _EnhanceOutput {
  const _EnhanceOutput(this.jpg, this.quality);

  final Uint8List jpg;
  final ImageQuality quality;
}

/// Memperjelas foto struk yang pudar, gelap, atau berbayang sebelum OCR.
/// Pengolahan piksel dijalankan di isolate agar antarmuka tidak tersendat.
class ImageEnhancementService {
  /// Sisi terpanjang gambar saat diolah (menjaga waktu dan memori).
  static const int _maxSide = 1600;

  /// Mengembalikan null bila format gambar tidak dapat diolah (mis. HEIC);
  /// pemanggil cukup memakai hasil OCR dari foto asli.
  Future<EnhancedImage?> enhance(String imagePath) async {
    try {
      final Uint8List bytes = await File(imagePath).readAsBytes();
      final _EnhanceOutput? output = await compute(_enhanceBytes, bytes);
      if (output == null) return null;

      final Directory directory = await getTemporaryDirectory();
      final String name =
          'enhanced_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final File file = File(p.join(directory.path, name));
      await file.writeAsBytes(output.jpg, flush: true);
      return EnhancedImage(path: file.path, quality: output.quality);
    } catch (_) {
      return null;
    }
  }

  /// Menghapus file sementara hasil perbaikan.
  Future<void> discard(EnhancedImage image) async {
    try {
      final File file = File(image.path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // File sementara; kegagalan menghapus tidak perlu ditampilkan.
    }
  }
}

_EnhanceOutput? _enhanceBytes(Uint8List bytes) {
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  img.Image image = img.bakeOrientation(decoded);
  final int longest = image.width > image.height ? image.width : image.height;
  if (longest > ImageEnhancementService._maxSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: ImageEnhancementService._maxSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: ImageEnhancementService._maxSide,
            interpolation: img.Interpolation.average,
          );
  }

  final int width = image.width;
  final int height = image.height;
  final Uint8List gray = Uint8List(width * height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final img.Pixel pixel = image.getPixel(x, y);
      final double luminance =
          0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
      gray[y * width + x] =
          luminance <= 0 ? 0 : (luminance >= 255 ? 255 : luminance.round());
    }
  }

  final EnhancedPixels result =
      const ImageEnhancer().enhance(gray, width, height);

  final img.Image output = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int value = result.pixels[y * width + x];
      output.setPixelRgb(x, y, value, value, value);
    }
  }
  return _EnhanceOutput(img.encodeJpg(output, quality: 92), result.quality);
}
