import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/services/image_enhancer.dart';

const int _width = 240;
const int _height = 160;

/// Gambar tiruan: kertas dengan goresan "tulisan" setebal 4 piksel.
/// [shadow] menggelapkan gambar makin ke kanan.
Uint8List _synthetic({
  required int paper,
  required int ink,
  double shadow = 0,
}) {
  final Uint8List pixels = Uint8List(_width * _height);
  for (int y = 0; y < _height; y++) {
    for (int x = 0; x < _width; x++) {
      final bool isInk =
          y % 16 >= 4 && y % 16 <= 7 && x % 8 < 4 && x >= 20 && x < 220;
      final double value = (isInk ? ink : paper) * (1 - shadow * x / _width);
      pixels[y * _width + x] = value.floor();
    }
  }
  return pixels;
}

/// Rata-rata piksel di tengah goresan tinta.
double _inkMean(Uint8List pixels) {
  double sum = 0;
  int count = 0;
  for (int y = 0; y < _height; y++) {
    for (int x = 20; x < 220; x++) {
      if ((y % 16 == 5 || y % 16 == 6) && (x % 8 == 1 || x % 8 == 2)) {
        sum += pixels[y * _width + x];
        count++;
      }
    }
  }
  return sum / count;
}

/// Rata-rata piksel pada baris kertas kosong di antara tulisan.
double _paperMean(Uint8List pixels) {
  double sum = 0;
  int count = 0;
  for (int y = 0; y < _height; y++) {
    if (y % 16 < 11 || y % 16 > 14) continue;
    for (int x = 0; x < _width; x++) {
      sum += pixels[y * _width + x];
      count++;
    }
  }
  return sum / count;
}

void main() {
  const ImageEnhancer enhancer = ImageEnhancer();

  test('foto jelas tidak ditandai bermasalah', () {
    final EnhancedPixels result =
        enhancer.enhance(_synthetic(paper: 240, ink: 40), _width, _height);

    expect(result.quality.hasIssue, isFalse);
    expect(result.quality.notes, isEmpty);
    expect(_inkMean(result.pixels), lessThan(30));
    expect(_paperMean(result.pixels), greaterThan(245));
  });

  test('tulisan pudar dipertegas dan ditandai', () {
    final Uint8List faded = _synthetic(paper: 230, ink: 214);
    final double before = _paperMean(faded) - _inkMean(faded);

    final EnhancedPixels result = enhancer.enhance(faded, _width, _height);
    final double after = _paperMean(result.pixels) - _inkMean(result.pixels);

    expect(result.quality.isFaded, isTrue);
    expect(result.quality.notes, contains('tulisan pudar'));
    expect(after, greaterThan(before * 3));
    expect(_paperMean(result.pixels), greaterThan(245));
  });

  test('bayangan diratakan sehingga kertas kembali putih', () {
    final Uint8List shadowed = _synthetic(paper: 230, ink: 120, shadow: 0.6);

    final EnhancedPixels result = enhancer.enhance(shadowed, _width, _height);

    expect(result.quality.hasShadow, isTrue);
    expect(result.quality.notes, contains('ada bayangan'));
    expect(_paperMean(result.pixels), greaterThan(245));
    expect(_inkMean(result.pixels), lessThan(40));
  });

  test('foto gelap ditandai dan tulisannya tetap terbaca', () {
    final EnhancedPixels result =
        enhancer.enhance(_synthetic(paper: 90, ink: 40), _width, _height);

    expect(result.quality.isDark, isTrue);
    expect(result.quality.notes, contains('foto gelap'));
    expect(_paperMean(result.pixels), greaterThan(245));
    expect(_inkMean(result.pixels), lessThan(40));
  });

  test('ukuran piksel yang tidak cocok ditolak', () {
    expect(
      () => enhancer.enhance(Uint8List(10), _width, _height),
      throwsArgumentError,
    );
  });
}
