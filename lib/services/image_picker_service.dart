import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../core/constants/db_constants.dart';
import 'image_format_service.dart';

/// Sumber gambar struk.
enum ScanSource { camera, gallery, file }

extension ScanSourceX on ScanSource {
  /// Nilai untuk kolom `ocr_source`.
  String get dbValue {
    switch (this) {
      case ScanSource.camera:
        return OcrSource.camera;
      case ScanSource.gallery:
        return OcrSource.gallery;
      case ScanSource.file:
        return OcrSource.file;
    }
  }
}

/// Kesalahan saat mengambil gambar (izin ditolak, dsb.).
class ImagePickException implements Exception {
  const ImagePickException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Mengambil gambar struk dari kamera, galeri, atau file penyimpanan.
class ImagePickerService {
  ImagePickerService({ImagePicker? imagePicker})
      : _picker = imagePicker ?? ImagePicker();

  final ImagePicker _picker;

  /// Mengembalikan path file yang dipilih, atau null bila pengguna membatalkan.
  Future<String?> pick(ScanSource source) async {
    try {
      switch (source) {
        case ScanSource.camera:
          final XFile? photo = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 92,
            maxWidth: 2400,
          );
          return photo?.path;
        case ScanSource.gallery:
          final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 92,
            maxWidth: 2400,
          );
          return image?.path;
        case ScanSource.file:
          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ImageFormatService.supportedExtensions,
            allowMultiple: false,
          );
          if (result == null || result.files.isEmpty) return null;
          return result.files.single.path;
      }
    } on PlatformException {
      throw const ImagePickException(
        'Tidak dapat mengakses kamera atau penyimpanan. Periksa izin aplikasi.',
      );
    } catch (_) {
      throw const ImagePickException(
        'Gagal mengambil gambar. Silakan coba lagi.',
      );
    }
  }
}
