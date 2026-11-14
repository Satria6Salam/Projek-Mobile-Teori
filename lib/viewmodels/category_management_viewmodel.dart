import 'package:flutter/foundation.dart';

import '../core/theme/category_palette.dart';
import '../data/models/category_model.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/repository_exception.dart';
import 'safe_change_notifier.dart';

/// Kelola kategori: tambah, ubah nama, ganti ikon dan warna, sembunyikan.
/// Kategori yang diubah ikut dilatih ulang oleh model saat koreksi pengguna.
class CategoryManagementViewModel extends ChangeNotifier
    with SafeChangeNotifier {
  CategoryManagementViewModel({required CategoryRepository categoryRepository})
      : _repository = categoryRepository;

  final CategoryRepository _repository;

  /// Kategori yang tidak boleh disembunyikan atau diganti namanya, karena
  /// dipakai sebagai cadangan saat model tidak yakin.
  static const String fallbackName = 'Lainnya';

  List<CategoryModel> _categories = <CategoryModel>[];
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<CategoryModel> get categories => _categories;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load() async {
    _categories = await _repository.getAll();
    CategoryPalette.applyTo(_categories);
    safeNotify();
  }

  /// Menambah kategori baru. Mengembalikan true bila berhasil.
  Future<bool> add({
    required String name,
    required String iconKey,
    required int colorValue,
  }) async {
    final String? invalid = _validateName(name);
    if (invalid != null) return _fail(invalid);
    return _run(() async {
      await _repository.insert(
        CategoryModel(
          name: name.trim(),
          description: 'Kategori kustom',
          createdAt: DateTime.now(),
          iconKey: iconKey,
          colorValue: colorValue,
        ),
      );
    }, 'Kategori ditambahkan.');
  }

  /// Mengubah nama, ikon, atau warna. Nama lama tidak boleh dipakai ulang.
  Future<bool> update(
    CategoryModel category, {
    required String name,
    required String iconKey,
    required int colorValue,
  }) async {
    if (category.name == fallbackName && name.trim() != fallbackName) {
      return _fail('Kategori "$fallbackName" tidak dapat diganti namanya.');
    }
    final String? invalid = _validateName(name, exceptId: category.id);
    if (invalid != null) return _fail(invalid);
    return _run(() async {
      await _repository.update(
        category.copyWith(
          name: name.trim(),
          iconKey: iconKey,
          colorValue: colorValue,
        ),
      );
    }, 'Perubahan kategori disimpan.');
  }

  /// Menyembunyikan atau menampilkan kembali kategori.
  Future<bool> setHidden(CategoryModel category, bool hidden) async {
    if (hidden && category.name == fallbackName) {
      return _fail('Kategori "$fallbackName" tidak dapat disembunyikan.');
    }
    return _run(() async {
      await _repository.update(category.copyWith(isHidden: hidden));
    }, hidden ? 'Kategori disembunyikan.' : 'Kategori ditampilkan kembali.');
  }

  String? _validateName(String raw, {int? exceptId}) {
    final String name = raw.trim();
    if (name.length < 2) return 'Nama kategori minimal 2 karakter.';
    if (name.length > 30) return 'Nama kategori maksimal 30 karakter.';
    final bool duplicate = _categories.any((CategoryModel c) =>
        c.id != exceptId && c.name.toLowerCase() == name.toLowerCase());
    if (duplicate) return 'Nama kategori sudah ada.';
    return null;
  }

  Future<bool> _run(Future<void> Function() action, String success) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    safeNotify();
    try {
      await action();
      _successMessage = success;
      _isSaving = false;
      await load();
      return true;
    } on RepositoryException {
      return _fail('Nama kategori sudah ada.');
    } catch (_) {
      return _fail('Gagal menyimpan kategori. Silakan coba lagi.');
    }
  }

  bool _fail(String message) {
    _errorMessage = message;
    _successMessage = null;
    _isSaving = false;
    safeNotify();
    return false;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    safeNotify();
  }
}
