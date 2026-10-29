import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/db_constants.dart';
import '../data/models/category_model.dart';
import '../data/models/ml_classification_model.dart';
import '../data/models/ocr_result_model.dart';
import '../data/models/parsed_receipt_model.dart';
import '../data/models/tfidf_feature_model.dart';
import '../data/models/transaction_item_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../services/image_format_service.dart';
import '../services/image_picker_service.dart';
import '../services/image_storage_service.dart';
import '../services/ml_service.dart';
import '../services/ml_training_data.dart';
import '../services/ocr_service.dart';
import '../services/parsing_service.dart';
import 'auth_viewmodel.dart';
import 'safe_change_notifier.dart';

export '../services/image_picker_service.dart' show ScanSource;

/// Tahapan alur pemindaian.
/// idle -> processing -> ready -> saving -> saved (atau error pada tahap mana pun).
enum ScanStatus { idle, processing, ready, saving, saved, error }

/// Satu barang pada pratinjau; nilainya dapat disunting pengguna.
class DraftItem {
  DraftItem({
    required this.localId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.categoryId,
    this.aiCategoryId,
    this.aiConfidence,
    this.isConfident = true,
  });

  final int localId;
  String name;
  double quantity;
  double unitPrice;
  int? categoryId;

  /// Tebakan awal AI (tidak berubah walau pengguna mengoreksi).
  final int? aiCategoryId;
  final double? aiConfidence;

  /// False bila AI kurang yakin (ditandai "Perlu dicek" pada UI).
  final bool isConfident;

  double get totalPrice => quantity * unitPrice;
}

/// Kelompok barang dengan kategori yang sama beserta subtotalnya.
class ItemGroup {
  ItemGroup({
    required this.categoryId,
    required this.categoryName,
    required this.items,
  });

  final int? categoryId;
  final String categoryName;
  final List<DraftItem> items;

  double get subtotal => items.fold<double>(
        0,
        (double sum, DraftItem item) => sum + item.totalPrice,
      );
}

/// Data pratinjau: hasil AI beserta nilai form yang boleh disunting pengguna.
class ScanDraft {
  ScanDraft({
    required this.imagePath,
    required this.source,
    required this.rawText,
    required this.parsed,
    required this.classification,
    required this.aiCategoryId,
    required this.merchantName,
    required this.transactionDate,
    required this.totalAmount,
    required this.items,
    required this.initialMerchant,
    required this.initialDate,
    required this.initialTotal,
    required this.initialItemsSignature,
    this.notes = '',
  });

  final String imagePath;
  final ScanSource source;
  final String rawText;

  /// Hasil asli Smart Parsing (tidak berubah walau pengguna menyunting form).
  final ParsedReceiptData parsed;

  /// Klasifikasi tingkat struk (untuk catatan model AI).
  final ClassificationOutput classification;
  final int? aiCategoryId;

  // Nilai form yang dapat disunting.
  String merchantName;
  DateTime? transactionDate;
  double? totalAmount;
  final List<DraftItem> items;
  String notes;

  // Nilai awal hasil AI, untuk mendeteksi penyuntingan manual.
  final String initialMerchant;
  final DateTime? initialDate;
  final double? initialTotal;
  final String initialItemsSignature;
}

/// Mengelola alur: ambil gambar -> OCR -> parsing -> klasifikasi per barang ->
/// pratinjau/koreksi -> simpan.
class ScanViewModel extends ChangeNotifier with SafeChangeNotifier {
  ScanViewModel({
    required AuthViewModel authViewModel,
    required OcrService ocrService,
    required ParsingService parsingService,
    required MlService mlService,
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
    required ImageStorageService imageStorageService,
    required ImageFormatService imageFormatService,
    required ImagePickerService imagePickerService,
    this.onTransactionSaved,
  })  : _auth = authViewModel,
        _ocrService = ocrService,
        _parsingService = parsingService,
        _mlService = mlService,
        _categoryRepository = categoryRepository,
        _transactionRepository = transactionRepository,
        _imageStorageService = imageStorageService,
        _imageFormatService = imageFormatService,
        _pickerService = imagePickerService {
    _activeUserId = _auth.currentUser?.id;
    _auth.addListener(_onAuthChanged);
    if (_activeUserId != null) unawaited(_refreshModel());
  }

  static const String fieldMerchant = 'merchant';
  static const String fieldDate = 'date';
  static const String fieldAmount = 'amount';
  static const String fieldItems = 'items';

  static const String unreadableMessage = 'Gambar Tidak Jelas, Silakan Ulangi';

  final AuthViewModel _auth;
  final OcrService _ocrService;
  final ParsingService _parsingService;
  final MlService _mlService;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;
  final ImageStorageService _imageStorageService;
  final ImageFormatService _imageFormatService;
  final ImagePickerService _pickerService;

  /// Dipanggil setelah transaksi tersimpan (misalnya untuk memuat ulang Dasbor).
  final VoidCallback? onTransactionSaved;

  ScanStatus _status = ScanStatus.idle;
  String? _errorMessage;
  String? _progressMessage;
  ScanDraft? _draft;
  List<CategoryModel> _categories = <CategoryModel>[];
  final Map<String, String> _formErrors = <String, String>{};
  Duration? _lastProcessingDuration;
  int? _activeUserId;
  int _nextItemId = 1;

  ScanStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// Keterangan langkah yang sedang berjalan (untuk indikator loading).
  String? get progressMessage => _progressMessage;
  ScanDraft? get draft => _draft;
  List<CategoryModel> get categories => _categories;
  Map<String, String> get formErrors =>
      Map<String, String>.unmodifiable(_formErrors);

  /// Lama proses OCR + parsing + klasifikasi terakhir (target maksimal 3 detik).
  Duration? get lastProcessingDuration => _lastProcessingDuration;

  bool get isProcessing => _status == ScanStatus.processing;
  bool get isSaving => _status == ScanStatus.saving;
  bool get isBusy => isProcessing || isSaving;
  bool get hasDraft => _draft != null;

  /// Jumlah harga seluruh barang pada pratinjau.
  double get itemsTotal {
    final ScanDraft? draft = _draft;
    if (draft == null) return 0;
    return draft.items.fold<double>(
      0,
      (double sum, DraftItem item) => sum + item.totalPrice,
    );
  }

  /// True bila total struk berbeda dari jumlah harga barang (mis. ada pajak/diskon).
  bool get hasTotalMismatch {
    final ScanDraft? draft = _draft;
    final double? total = draft?.totalAmount;
    if (draft == null || total == null || draft.items.isEmpty) return false;
    return (itemsTotal - total).abs() > 1;
  }

  /// Barang dikelompokkan per kategori, subtotal terbesar lebih dulu.
  List<ItemGroup> get groupedItems {
    final ScanDraft? draft = _draft;
    if (draft == null) return <ItemGroup>[];

    final Map<int?, ItemGroup> groups = <int?, ItemGroup>{};
    for (final DraftItem item in draft.items) {
      final ItemGroup group = groups.putIfAbsent(
        item.categoryId,
        () => ItemGroup(
          categoryId: item.categoryId,
          categoryName: categoryNameOf(item.categoryId),
          items: <DraftItem>[],
        ),
      );
      group.items.add(item);
    }
    final List<ItemGroup> result = groups.values.toList()
      ..sort((ItemGroup a, ItemGroup b) => b.subtotal.compareTo(a.subtotal));
    return result;
  }

  /// Nama kategori untuk sebuah ID ('Tanpa kategori' bila tidak ditemukan).
  String categoryNameOf(int? categoryId) {
    for (final CategoryModel category in _categories) {
      if (category.id == categoryId) return category.name;
    }
    return 'Tanpa kategori';
  }

  Future<void> loadCategories() async {
    await _ensureCategories();
    safeNotify();
  }

  Future<void> _ensureCategories() async {
    if (_categories.isEmpty) {
      final List<CategoryModel> loaded =
          List<CategoryModel>.of(await _categoryRepository.getAll());
      // "Lainnya" selalu di urutan terakhir agar mudah dicari.
      loaded.sort((CategoryModel a, CategoryModel b) {
        final int ra = a.name == MlService.fallbackCategory ? 1 : 0;
        final int rb = b.name == MlService.fallbackCategory ? 1 : 0;
        if (ra != rb) return ra.compareTo(rb);
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });
      _categories = loaded;
    }
  }

  // ------------------------------------------------------ ambil & proses

  /// Membuka kamera/galeri/file, lalu langsung memproses gambar yang dipilih.
  Future<void> pickAndProcess(ScanSource source) async {
    if (isBusy) return;
    try {
      final String? path = await _pickerService.pick(source);
      if (path == null) return; // Pengguna membatalkan pemilihan.
      await processImage(imagePath: path, source: source);
    } on ImagePickException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Gagal mengambil gambar. Silakan coba lagi.');
    }
  }

  /// Cek format -> OCR -> cek keterbacaan -> parsing -> klasifikasi tiap barang -> pratinjau.
  Future<void> processImage({
    required String imagePath,
    required ScanSource source,
  }) async {
    if (isBusy) return;
    if (_auth.currentUser?.id == null) {
      _setError('Sesi berakhir. Silakan login kembali.');
      return;
    }

    _draft = null;
    _formErrors.clear();
    _errorMessage = null;
    _status = ScanStatus.processing;
    _progressMessage = 'Memeriksa format gambar...';
    safeNotify();

    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      await _ensureCategories();
      final String preparedPath = await _imageFormatService.prepare(imagePath);

      await _setProgress('Membaca teks struk...');
      final OcrResult ocr = await _ocrService.recognizeFromFile(preparedPath);
      if (!ocr.isReadable) {
        _setError(unreadableMessage);
        return;
      }

      await _setProgress('Mengekstrak data transaksi...');
      final ParsedReceiptData parsed = _parsingService.parse(ocr.rawText);

      await _setProgress('Mengklasifikasikan setiap barang...');
      await _mlService.initialize();
      final ClassificationOutput receiptLevel =
          _mlService.classify(parsed.classificationText);
      final CategoryModel? receiptCategory =
          _findCategory(receiptLevel.categoryName);

      final List<DraftItem> items = <DraftItem>[];
      for (final ParsedItem parsedItem in parsed.items) {
        final ClassificationOutput out = _mlService.classifyItem(
          parsedItem.name,
          merchantName: parsed.merchantName,
        );
        final CategoryModel? category = _findCategory(out.categoryName);
        items.add(
          DraftItem(
            localId: _nextItemId++,
            name: parsedItem.name,
            quantity: parsedItem.quantity,
            unitPrice: parsedItem.unitPrice,
            categoryId: category?.id,
            aiCategoryId: category?.id,
            aiConfidence: out.probability,
            isConfident: out.isConfident,
          ),
        );
      }

      // Tidak ada barang terbaca tetapi total diketahui: buat satu barang agar bisa disunting.
      final double? parsedTotal = parsed.totalAmount;
      if (items.isEmpty && parsedTotal != null && parsedTotal > 0) {
        final String merchant = parsed.merchantName ?? '';
        items.add(
          DraftItem(
            localId: _nextItemId++,
            name: merchant.isEmpty ? 'Pembelian' : 'Pembelian di $merchant',
            quantity: 1,
            unitPrice: parsedTotal,
            categoryId: receiptCategory?.id,
            aiCategoryId: receiptCategory?.id,
            aiConfidence: receiptLevel.probability,
            isConfident: receiptLevel.isConfident,
          ),
        );
      }

      final double itemsSum = items.fold<double>(
        0,
        (double sum, DraftItem item) => sum + item.totalPrice,
      );
      final double? initialTotal =
          parsedTotal ?? (items.isEmpty ? null : itemsSum);

      stopwatch.stop();
      _lastProcessingDuration = stopwatch.elapsed;

      _draft = ScanDraft(
        imagePath: preparedPath,
        source: source,
        rawText: ocr.rawText,
        parsed: parsed,
        classification: receiptLevel,
        aiCategoryId: receiptCategory?.id,
        merchantName: parsed.merchantName ?? '',
        transactionDate: parsed.transactionDate,
        totalAmount: initialTotal,
        items: items,
        initialMerchant: (parsed.merchantName ?? '').trim(),
        initialDate: parsed.transactionDate,
        initialTotal: initialTotal,
        initialItemsSignature: _signature(items),
      );
      _status = ScanStatus.ready;
      _progressMessage = null;
      safeNotify();
    } on ImageFormatException catch (e) {
      _setError(e.message);
    } on OcrException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Terjadi kesalahan saat memproses struk. Silakan coba lagi.');
    }
  }

  CategoryModel? _findCategory(String name) {
    CategoryModel? fallback;
    for (final CategoryModel category in _categories) {
      if (category.name.toLowerCase() == name.toLowerCase()) return category;
      if (category.name == MlService.fallbackCategory) fallback = category;
    }
    return fallback ?? (_categories.isEmpty ? null : _categories.first);
  }

  Future<void> _setProgress(String message) async {
    _progressMessage = message;
    safeNotify();
    // Beri kesempatan UI menggambar ulang sebelum langkah berikutnya.
    await Future<void>.delayed(Duration.zero);
  }

  void _setError(String message) {
    _status = ScanStatus.error;
    _errorMessage = message;
    _progressMessage = null;
    _draft = null;
    safeNotify();
  }

  // -------------------------------------------------------- edit pratinjau
  // Perubahan teks (merchant, total, catatan) tidak memicu rebuild agar kursor
  // pada TextField tidak melompat; rebuild hanya bila ada pesan galat yang perlu hilang.

  void updateMerchantName(String value) {
    final ScanDraft? draft = _draft;
    if (draft == null) return;
    draft.merchantName = value;
    _clearFieldError(fieldMerchant);
  }

  void updateTotalAmountText(String text) {
    final ScanDraft? draft = _draft;
    if (draft == null) return;
    draft.totalAmount = parseAmountInput(text);
    _clearFieldError(fieldAmount);
    safeNotify(); // Peringatan selisih total perlu diperbarui.
  }

  void updateNotes(String value) {
    _draft?.notes = value;
  }

  void updateTransactionDate(DateTime? value) {
    final ScanDraft? draft = _draft;
    if (draft == null) return;
    draft.transactionDate = value;
    _formErrors.remove(fieldDate);
    safeNotify();
  }

  /// Mengganti total struk dengan jumlah harga seluruh barang.
  void useItemsTotal() {
    final ScanDraft? draft = _draft;
    if (draft == null) return;
    draft.totalAmount = itemsTotal;
    _formErrors.remove(fieldAmount);
    safeNotify();
  }

  void _clearFieldError(String field) {
    if (_formErrors.remove(field) != null) safeNotify();
  }

  // ---------------------------------------------------------- edit barang

  /// Menambah barang baru ke pratinjau.
  void addItem({
    required String name,
    required double quantity,
    required double unitPrice,
    required int categoryId,
  }) {
    final ScanDraft? draft = _draft;
    if (draft == null) return;
    draft.items.add(
      DraftItem(
        localId: _nextItemId++,
        name: name.trim(),
        quantity: quantity,
        unitPrice: unitPrice,
        categoryId: categoryId,
        aiCategoryId: null,
      ),
    );
    _formErrors.remove(fieldItems);
    safeNotify();
  }

  /// Mengubah nama, jumlah, harga, atau kategori sebuah barang.
  void updateItem(
    int localId, {
    required String name,
    required double quantity,
    required double unitPrice,
    required int categoryId,
  }) {
    final ScanDraft? draft = _draft;
    if (draft == null) return;
    for (final DraftItem item in draft.items) {
      if (item.localId == localId) {
        item
          ..name = name.trim()
          ..quantity = quantity
          ..unitPrice = unitPrice
          ..categoryId = categoryId;
        break;
      }
    }
    safeNotify();
  }

  void removeItem(int localId) {
    final ScanDraft? draft = _draft;
    if (draft == null) return;
    draft.items.removeWhere((DraftItem item) => item.localId == localId);
    safeNotify();
  }

  /// Saran kategori untuk nama barang yang sedang diketik (dipakai pada editor barang).
  int? suggestCategoryId(String name) {
    if (name.trim().isEmpty) return null;
    final ClassificationOutput out = _mlService.classifyItem(
      name,
      merchantName: _draft?.merchantName,
    );
    return _findCategory(out.categoryName)?.id;
  }

  /// Mengubah teks nominal ("17.000", "Rp 17.000,50", "17000") menjadi angka.
  /// Titik dianggap pemisah ribuan dan koma sebagai desimal (format Indonesia).
  static double? parseAmountInput(String text) {
    final String cleaned = text
        .replaceAll(RegExp(r'[Rr][Pp]'), '')
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Memeriksa form pratinjau. Kunci peta: lihat konstanta `field*`.
  Map<String, String> validateForm() {
    final Map<String, String> errors = <String, String>{};
    final ScanDraft? draft = _draft;
    if (draft == null) return errors;

    if (draft.merchantName.trim().isEmpty) {
      errors[fieldMerchant] = 'Nama merchant wajib diisi';
    }
    if (draft.transactionDate == null) {
      errors[fieldDate] = 'Tanggal transaksi wajib diisi';
    }
    final double? amount = draft.totalAmount;
    if (amount == null || amount <= 0) {
      errors[fieldAmount] = 'Total belanja harus lebih dari 0';
    }
    if (draft.items.isEmpty) {
      errors[fieldItems] = 'Tambahkan minimal satu barang';
    } else {
      for (final DraftItem item in draft.items) {
        if (item.name.trim().isEmpty ||
            item.unitPrice <= 0 ||
            item.quantity <= 0 ||
            item.categoryId == null) {
          errors[fieldItems] =
              'Lengkapi nama, harga, dan kategori setiap barang';
          break;
        }
      }
    }
    return errors;
  }

  // ---------------------------------------------------------------- simpan

  /// Menyimpan transaksi (beserta rincian barang, jejak OCR, parsing,
  /// klasifikasi, dan TF-IDF) ke basis data lokal. Mengembalikan true bila berhasil.
  Future<bool> saveTransaction() async {
    final ScanDraft? draft = _draft;
    final int? userId = _auth.currentUser?.id;
    if (draft == null || isBusy) return false;
    if (userId == null) {
      _setError('Sesi berakhir. Silakan login kembali.');
      return false;
    }

    final Map<String, String> errors = validateForm();
    _formErrors
      ..clear()
      ..addAll(errors);
    if (errors.isNotEmpty) {
      safeNotify();
      return false;
    }

    final DateTime? date = draft.transactionDate;
    final double? amount = draft.totalAmount;
    final int? dominantCategory = _dominantCategoryId(draft);
    if (date == null || amount == null || dominantCategory == null) {
      return false;
    }

    _status = ScanStatus.saving;
    _errorMessage = null;
    safeNotify();

    String? storedImagePath;
    try {
      storedImagePath =
          await _imageStorageService.persistImage(draft.imagePath);
      final DateTime now = DateTime.now();

      final OcrResultModel ocr = OcrResultModel(
        userId: userId,
        imagePath: storedImagePath,
        rawText: draft.rawText,
        ocrSource: draft.source.dbValue,
        ocrStatus: OcrStatus.success,
        createdAt: now,
      );
      final ParsedReceiptModel parsed = ParsedReceiptModel(
        ocrId: 0, // Diisi repository setelah OCR tersimpan.
        merchantName: draft.parsed.merchantName,
        transactionDate: draft.parsed.transactionDate,
        totalAmount: draft.parsed.totalAmount,
        parsingStatus: draft.parsed.status,
        createdAt: now,
      );
      final ClassificationOutput output = draft.classification;
      final MlClassificationModel classification = MlClassificationModel(
        parsedId: 0, // Diisi repository setelah parsing tersimpan.
        inputText: output.inputText,
        preprocessedText: output.preprocessedText,
        predictedCategoryId: draft.aiCategoryId,
        predictionProbability: output.probability,
        modelName: output.modelName,
        modelVersion: output.modelVersion,
        classificationStatus: ClassificationStatus.success,
        createdAt: now,
      );
      final List<TfidfFeatureModel> features = output.terms
          .map(
            (TfidfTerm t) => TfidfFeatureModel(
              classificationId: 0, // Diisi repository.
              term: t.term,
              tf: t.tf,
              idf: t.idf,
              tfidfWeight: t.weight,
            ),
          )
          .toList();
      final List<TransactionItemModel> items = draft.items
          .map(
            (DraftItem d) => TransactionItemModel(
              transactionId: 0, // Diisi repository.
              name: d.name.trim(),
              quantity: d.quantity,
              unitPrice: d.unitPrice,
              totalPrice: d.totalPrice,
              categoryId: d.categoryId ?? dominantCategory,
              aiCategoryId: d.aiCategoryId,
              aiConfidence: d.aiConfidence,
              createdAt: now,
            ),
          )
          .toList();
      final String notes = draft.notes.trim();
      final TransactionModel transaction = TransactionModel(
        userId: userId,
        merchantName: draft.merchantName.trim(),
        transactionDate: date,
        totalAmount: amount,
        categoryId: dominantCategory,
        isManualEdit: _isManuallyEdited(draft),
        notes: notes.isEmpty ? null : notes,
        createdAt: now,
        updatedAt: now,
      );

      await _transactionRepository.saveScanTransaction(
        ocr: ocr,
        parsed: parsed,
        classification: classification,
        features: features,
        transaction: transaction,
        items: items,
      );

      _draft = null;
      _formErrors.clear();
      _status = ScanStatus.saved;
      safeNotify();
      onTransactionSaved?.call();
      unawaited(_refreshModel()); // Model belajar dari koreksi terbaru.
      return true;
    } catch (_) {
      if (storedImagePath != null) {
        await _imageStorageService.deleteImage(storedImagePath);
      }
      _status = ScanStatus.ready;
      _errorMessage = 'Gagal menyimpan transaksi. Silakan coba lagi.';
      safeNotify();
      return false;
    }
  }

  /// Kategori dengan jumlah harga terbesar; menjadi kategori utama transaksi.
  int? _dominantCategoryId(ScanDraft draft) {
    final Map<int, double> totals = <int, double>{};
    for (final DraftItem item in draft.items) {
      final int? id = item.categoryId;
      if (id == null) continue;
      totals[id] = (totals[id] ?? 0) + item.totalPrice;
    }
    int? best;
    double bestValue = -1;
    totals.forEach((int id, double value) {
      if (value > bestValue) {
        bestValue = value;
        best = id;
      }
    });
    return best;
  }

  String _signature(List<DraftItem> items) {
    return items
        .map(
          (DraftItem i) =>
              '${i.name.trim().toLowerCase()}|${i.quantity}|${i.unitPrice.round()}|${i.categoryId}',
        )
        .join('#');
  }

  /// True bila ada nilai form yang berbeda dari hasil AI (kolom is_manual_edit).
  bool _isManuallyEdited(ScanDraft draft) {
    if (draft.merchantName.trim() != draft.initialMerchant) return true;
    if (!_sameDay(draft.transactionDate, draft.initialDate)) return true;

    final double? initial = draft.initialTotal;
    final double? amount = draft.totalAmount;
    if (amount == null || initial == null) {
      if (amount != initial) return true;
    } else if ((amount - initial).abs() > 0.5) {
      return true;
    }
    return _signature(draft.items) != draft.initialItemsSignature;
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ------------------------------------------------- belajar dari koreksi

  /// Melatih ulang model AI dengan barang yang pernah divalidasi pengguna,
  /// sehingga tebakan kategori makin sesuai kebiasaan pengguna.
  Future<void> _refreshModel() async {
    final int? userId = _auth.currentUser?.id;
    if (userId == null) return;
    try {
      final List<LabeledItem> labeled =
          await _transactionRepository.getTrainingSamples(userId);
      _mlService.learn(
        labeled
            .map((LabeledItem l) => LabeledSample(l.name, l.categoryName))
            .toList(),
      );
    } catch (_) {
      // Model dasar tetap dipakai bila gagal memuat riwayat.
    }
  }

  // ------------------------------------------------------------------ reset

  /// Membatalkan proses dan membuang data sementara (tidak ada yang disimpan).
  void cancel() => reset();

  void reset() {
    _status = ScanStatus.idle;
    _errorMessage = null;
    _progressMessage = null;
    _draft = null;
    _formErrors.clear();
    safeNotify();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    safeNotify();
  }

  void _onAuthChanged() {
    final int? userId = _auth.currentUser?.id;
    if (userId == _activeUserId) return;
    _activeUserId = userId;
    reset();
    if (userId != null) unawaited(_refreshModel());
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
