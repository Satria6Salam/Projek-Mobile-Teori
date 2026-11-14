import 'dart:math' as math;
import 'dart:typed_data';

/// Ukuran mutu foto struk, dihitung dari piksel abu-abu.
class ImageQuality {
  const ImageQuality({
    required this.brightness,
    required this.inkContrast,
    required this.lightUnevenness,
    required this.sharpness,
  });

  /// Rata-rata kecerahan 0-255.
  final double brightness;

  /// Selisih kertas dan tinta tergelap setelah cahaya diratakan (0-235).
  final double inkContrast;

  /// Perbandingan bagian paling terang dan paling gelap dari latar.
  final double lightUnevenness;

  /// Ketajaman tepi huruf relatif terhadap kontras tinta.
  final double sharpness;

  static const double _darkBelow = 110;
  static const double _fadedBelow = 30;
  static const double _unevenAbove = 1.6;
  static const double _blurryBelow = 0.25;

  bool get isDark => brightness < _darkBelow;
  bool get isFaded => inkContrast < _fadedBelow;
  bool get hasShadow => lightUnevenness > _unevenAbove;
  bool get isBlurry => sharpness < _blurryBelow;

  bool get hasIssue => isDark || isFaded || hasShadow || isBlurry;

  /// Keterangan singkat untuk ditampilkan ke pengguna.
  List<String> get notes => <String>[
        if (isFaded) 'tulisan pudar',
        if (isBlurry) 'foto buram',
        if (isDark) 'foto gelap',
        if (hasShadow && !isDark) 'ada bayangan',
      ];
}

/// Hasil perbaikan: piksel abu-abu baru beserta ukuran mutu foto aslinya.
class EnhancedPixels {
  const EnhancedPixels({required this.pixels, required this.quality});

  final Uint8List pixels;
  final ImageQuality quality;
}

/// Perbaikan citra struk sebelum OCR, ditulis murni Dart.
///
/// Langkah:
/// 1. Meredam noise (rata-rata 3x3 dua kali).
/// 2. Meratakan cahaya: setiap piksel dibagi kecerahan latar di sekitarnya,
///    sehingga bayangan dan sudut gelap hilang.
/// 3. Menarik kontras: kertas dijadikan putih dan tinta, termasuk yang pudar,
///    dijadikan gelap. Penguatan dibatasi agar noise tidak ikut menjadi tinta.
class ImageEnhancer {
  const ImageEnhancer();

  static const double _paperLevel = 235;
  static const double _maxGain = 10;
  static const double _minInkRange = 6;

  /// [gray] berisi `width * height` nilai kecerahan 0-255, baris demi baris.
  EnhancedPixels enhance(Uint8List gray, int width, int height) {
    final int count = width * height;
    if (count == 0 || gray.length < count) {
      throw ArgumentError(
          'Ukuran piksel tidak sesuai dengan lebar dan tinggi.');
    }

    final Float64List integral = Float64List((width + 1) * (height + 1));
    final Float64List source = Float64List(count);
    double brightnessSum = 0;
    for (int i = 0; i < count; i++) {
      source[i] = gray[i].toDouble();
      brightnessSum += source[i];
    }

    // 1. Redam noise.
    final Float64List denoised = Float64List(count);
    final Float64List scratch = Float64List(count);
    _boxMean(source, scratch, width, height, 1, integral);
    _boxMean(scratch, denoised, width, height, 1, integral);

    // 2. Ratakan cahaya.
    final int radius = math.max(8, math.max(width, height) ~/ 24);
    final Float64List background = scratch;
    _boxMean(denoised, background, width, height, radius, integral);
    final double backgroundLow = _percentile(background, 0.05);
    final double backgroundHigh = _percentile(background, 0.95);

    final Float64List normalized = source; // pakai ulang penyangga
    for (int i = 0; i < count; i++) {
      final double bg = background[i] < 1 ? 1 : background[i];
      final double value = denoised[i] * _paperLevel / bg;
      normalized[i] = value > 255 ? 255 : value;
    }

    // Ketajaman: gradien mendatar terbesar (persentil 99,5).
    final Float64List gradient = denoised; // pakai ulang penyangga
    for (int y = 0; y < height; y++) {
      final int row = y * width;
      gradient[row] = 0;
      if (width > 1) gradient[row + width - 1] = 0;
      for (int x = 1; x < width - 1; x++) {
        final double g =
            (normalized[row + x + 1] - normalized[row + x - 1]).abs() * 2;
        gradient[row + x] = g > 255 ? 255 : g;
      }
    }
    final double edge = _percentile(gradient, 0.995) / 4;

    // 3. Tarik kontras.
    final Float64List smooth = scratch;
    _boxMean(normalized, smooth, width, height, 2, integral);
    double residual = 0;
    for (int i = 0; i < count; i++) {
      final double diff = normalized[i] - smooth[i];
      residual += diff * diff;
    }
    final double sigma = math.sqrt(residual / count);

    final double paper = _paperLevel - math.min(3 * sigma, 60);
    double ink = _percentile(normalized, 0.01);
    final double inkContrast = math.max(0, _paperLevel - ink);
    if (paper - ink < _minInkRange) ink = paper - _minInkRange;
    final double gain = math.min(255 / (paper - ink), _maxGain);

    final Uint8List output = Uint8List(count);
    for (int i = 0; i < count; i++) {
      final double value = 255 - (paper - normalized[i]) * gain;
      output[i] = value <= 0 ? 0 : (value >= 255 ? 255 : value.floor());
    }

    return EnhancedPixels(
      pixels: output,
      quality: ImageQuality(
        brightness: brightnessSum / count,
        inkContrast: inkContrast,
        lightUnevenness: backgroundHigh / math.max(backgroundLow, 1),
        sharpness: edge / math.max(inkContrast, 1),
      ),
    );
  }

  /// Rata-rata kotak beradius [radius] memakai citra integral.
  /// Jendela dipotong di tepi gambar.
  void _boxMean(
    Float64List input,
    Float64List output,
    int width,
    int height,
    int radius,
    Float64List integral,
  ) {
    final int stride = width + 1;
    for (int x = 0; x <= width; x++) {
      integral[x] = 0;
    }
    for (int y = 0; y < height; y++) {
      double rowSum = 0;
      final int inRow = y * width;
      final int outRow = (y + 1) * stride;
      integral[outRow] = 0;
      for (int x = 0; x < width; x++) {
        rowSum += input[inRow + x];
        integral[outRow + x + 1] = integral[outRow - stride + x + 1] + rowSum;
      }
    }
    for (int y = 0; y < height; y++) {
      final int top = math.max(0, y - radius);
      final int bottom = math.min(height, y + radius + 1);
      final int topRow = top * stride;
      final int bottomRow = bottom * stride;
      for (int x = 0; x < width; x++) {
        final int left = math.max(0, x - radius);
        final int right = math.min(width, x + radius + 1);
        final double sum = integral[bottomRow + right] -
            integral[topRow + right] -
            integral[bottomRow + left] +
            integral[topRow + left];
        output[y * width + x] = sum / ((bottom - top) * (right - left));
      }
    }
  }

  /// Nilai (0-255, dibulatkan ke bawah) pada persentil [fraction].
  double _percentile(Float64List values, double fraction) {
    final Int32List histogram = Int32List(256);
    for (int i = 0; i < values.length; i++) {
      final double v = values[i];
      histogram[v <= 0 ? 0 : (v >= 255 ? 255 : v.floor())]++;
    }
    final double target = fraction * values.length;
    int cumulative = 0;
    for (int level = 0; level < 256; level++) {
      cumulative += histogram[level];
      if (cumulative >= target) return level.toDouble();
    }
    return 255;
  }
}
