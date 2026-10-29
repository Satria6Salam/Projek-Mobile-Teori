import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Menyimpan foto struk secara permanen di penyimpanan aplikasi.
/// Foto dari kamera/galeri berada di folder cache yang bisa dibersihkan sistem,
/// sehingga perlu disalin sebelum path-nya disimpan ke basis data.
class ImageStorageService {
  static const String _folderName = 'receipt_images';

  /// Menyalin gambar ke folder permanen dan mengembalikan path barunya.
  Future<String> persistImage(String sourcePath) async {
    final Directory base = await getApplicationDocumentsDirectory();
    final Directory folder = Directory(p.join(base.path, _folderName));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final String extension =
        p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final String fileName =
        'receipt_${DateTime.now().microsecondsSinceEpoch}$extension';
    final File saved = await File(sourcePath).copy(p.join(folder.path, fileName));
    return saved.path;
  }

  /// Menghapus gambar, hanya jika berada di folder milik aplikasi.
  Future<void> deleteImage(String path) async {
    try {
      if (!path.contains(_folderName)) return;
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Kegagalan menghapus file tidak boleh menggagalkan proses utama.
    }
  }
}
