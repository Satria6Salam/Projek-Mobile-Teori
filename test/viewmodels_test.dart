import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/core/utils/dashboard_period.dart';
import 'package:smart_receipt/core/utils/password_hasher.dart';
import 'package:smart_receipt/data/models/category_model.dart';
import 'package:smart_receipt/data/models/category_summary_model.dart';
import 'package:smart_receipt/data/models/ml_classification_model.dart';
import 'package:smart_receipt/data/models/ocr_result_model.dart';
import 'package:smart_receipt/data/models/parsed_receipt_model.dart';
import 'package:smart_receipt/data/models/tfidf_feature_model.dart';
import 'package:smart_receipt/data/models/transaction_item_model.dart';
import 'package:smart_receipt/data/models/transaction_model.dart';
import 'package:smart_receipt/data/models/user_model.dart';
import 'package:smart_receipt/data/repositories/category_repository.dart';
import 'package:smart_receipt/data/repositories/ocr_result_repository.dart';
import 'package:smart_receipt/data/repositories/repository_exception.dart';
import 'package:smart_receipt/data/repositories/session_repository.dart';
import 'package:smart_receipt/data/repositories/transaction_repository.dart';
import 'package:smart_receipt/data/repositories/user_repository.dart';
import 'package:smart_receipt/services/image_format_service.dart';
import 'package:smart_receipt/services/image_picker_service.dart';
import 'package:smart_receipt/services/image_storage_service.dart';
import 'package:smart_receipt/services/ml_service.dart';
import 'package:smart_receipt/services/ocr_service.dart';
import 'package:smart_receipt/services/parsing_service.dart';
import 'package:smart_receipt/viewmodels/auth_viewmodel.dart';
import 'package:smart_receipt/viewmodels/dashboard_viewmodel.dart';
import 'package:smart_receipt/viewmodels/scan_viewmodel.dart';

// ============================================================ objek palsu

class FakeUserRepository extends Fake implements UserRepository {
  final Map<int, UserModel> users = <int, UserModel>{};
  int _nextId = 1;

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final String normalized = email.trim().toLowerCase();
    if (users.values.any((UserModel u) => u.email == normalized)) {
      throw const RepositoryException('Email sudah terdaftar');
    }
    final DateTime now = DateTime.now();
    final UserModel user = UserModel(
      id: _nextId++,
      name: name.trim(),
      email: normalized,
      passwordHash: PasswordHasher.hash(password),
      createdAt: now,
      updatedAt: now,
    );
    users[user.id ?? 0] = user;
    return user;
  }

  @override
  Future<UserModel?> authenticate({
    required String email,
    required String password,
  }) async {
    final String normalized = email.trim().toLowerCase();
    for (final UserModel user in users.values) {
      if (user.email == normalized &&
          PasswordHasher.verify(password, user.passwordHash)) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<UserModel?> getById(int id) async => users[id];
}

class FakeSessionRepository extends Fake implements SessionRepository {
  int? savedId;

  @override
  Future<int?> getSavedUserId() async => savedId;

  @override
  Future<void> saveUserId(int userId) async => savedId = userId;

  @override
  Future<void> clear() async => savedId = null;
}

class FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll() async {
    final DateTime now = DateTime.now();
    const List<String> names = <String>[
      'Konsumsi',
      'Transportasi',
      'Kesehatan',
      'Belanja',
      'Lainnya',
      'Elektronik',
    ];
    return <CategoryModel>[
      for (int i = 0; i < names.length; i++)
        CategoryModel(id: i + 1, name: names[i], createdAt: now),
    ];
  }
}

class FakeTransactionRepository extends Fake implements TransactionRepository {
  final List<TransactionModel> stored = <TransactionModel>[];
  OcrResultModel? lastOcr;
  List<TfidfFeatureModel> lastFeatures = <TfidfFeatureModel>[];
  List<TransactionItemModel> lastItems = <TransactionItemModel>[];

  Iterable<TransactionModel> _inMonth(int userId, int year, int month) {
    return stored.where(
      (TransactionModel t) =>
          t.userId == userId &&
          t.transactionDate.year == year &&
          t.transactionDate.month == month,
    );
  }

  @override
  Future<TransactionModel> saveScanTransaction({
    required OcrResultModel ocr,
    required ParsedReceiptModel parsed,
    required MlClassificationModel classification,
    required List<TfidfFeatureModel> features,
    required TransactionModel transaction,
    List<TransactionItemModel> items = const <TransactionItemModel>[],
  }) async {
    final TransactionModel saved =
        transaction.copyWith(id: stored.length + 1, ocrId: 1);
    stored.add(saved);
    lastOcr = ocr;
    lastFeatures = features;
    lastItems = items;
    return saved;
  }

  @override
  Future<List<TransactionItemModel>> getItems(int transactionId) async {
    return lastItems;
  }

  @override
  Future<List<LabeledItem>> getTrainingSamples(
    int userId, {
    int limit = 2000,
  }) async {
    return <LabeledItem>[];
  }

  Iterable<TransactionModel> _between(
      int userId, DateTime start, DateTime end) {
    return stored.where((TransactionModel t) {
      final DateTime d = t.transactionDate;
      return t.userId == userId && !d.isBefore(start) && d.isBefore(end);
    });
  }

  @override
  Future<double> getTotalBetween(
    int userId,
    DateTime start,
    DateTime endExclusive,
  ) async {
    return _between(userId, start, endExclusive)
        .fold<double>(0, (double s, TransactionModel t) => s + t.totalAmount);
  }

  @override
  Future<List<CategorySummaryModel>> getCategorySummaryBetween(
    int userId,
    DateTime start,
    DateTime endExclusive,
  ) async {
    final Map<int, CategorySummaryModel> grouped =
        <int, CategorySummaryModel>{};
    for (final TransactionModel t in _between(userId, start, endExclusive)) {
      final CategorySummaryModel? old = grouped[t.categoryId];
      grouped[t.categoryId] = CategorySummaryModel(
        categoryId: t.categoryId,
        categoryName: t.categoryName ?? '',
        totalAmount: (old?.totalAmount ?? 0) + t.totalAmount,
        transactionCount: (old?.transactionCount ?? 0) + 1,
      );
    }
    final List<CategorySummaryModel> result = grouped.values.toList()
      ..sort(
        (CategorySummaryModel a, CategorySummaryModel b) =>
            b.totalAmount.compareTo(a.totalAmount),
      );
    return result;
  }

  @override
  Future<List<TransactionModel>> getBetween(
    int userId,
    DateTime start,
    DateTime endExclusive,
  ) async {
    return _between(userId, start, endExclusive).toList();
  }

  @override
  Future<List<double>> getMonthlyTotals(int userId, int year) async {
    final List<double> result = List<double>.filled(12, 0);
    for (final TransactionModel t in stored) {
      if (t.userId == userId && t.transactionDate.year == year) {
        result[t.transactionDate.month - 1] += t.totalAmount;
      }
    }
    return result;
  }

  @override
  Future<Map<int, double>> getYearlyTotals(int userId) async {
    final Map<int, double> result = <int, double>{};
    for (final TransactionModel t in stored) {
      if (t.userId == userId) {
        result[t.transactionDate.year] =
            (result[t.transactionDate.year] ?? 0) + t.totalAmount;
      }
    }
    return result;
  }

  @override
  Future<double> getMonthlyTotal(int userId, int year, int month) async {
    return _inMonth(userId, year, month)
        .fold<double>(0, (double s, TransactionModel t) => s + t.totalAmount);
  }

  @override
  Future<List<CategorySummaryModel>> getCategorySummary(
    int userId,
    int year,
    int month,
  ) async {
    final Map<int, CategorySummaryModel> grouped =
        <int, CategorySummaryModel>{};
    for (final TransactionModel t in _inMonth(userId, year, month)) {
      final CategorySummaryModel? old = grouped[t.categoryId];
      grouped[t.categoryId] = CategorySummaryModel(
        categoryId: t.categoryId,
        categoryName: t.categoryName ?? '',
        totalAmount: (old?.totalAmount ?? 0) + t.totalAmount,
        transactionCount: (old?.transactionCount ?? 0) + 1,
      );
    }
    final List<CategorySummaryModel> result = grouped.values.toList()
      ..sort(
        (CategorySummaryModel a, CategorySummaryModel b) =>
            b.totalAmount.compareTo(a.totalAmount),
      );
    return result;
  }

  @override
  Future<List<TransactionModel>> getByMonth(
    int userId,
    int year,
    int month,
  ) async {
    return _inMonth(userId, year, month).toList();
  }

  @override
  Future<TransactionModel?> getById(int id) async {
    for (final TransactionModel t in stored) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  Future<bool> delete(int id) async {
    final int before = stored.length;
    stored.removeWhere((TransactionModel t) => t.id == id);
    return stored.length < before;
  }
}

class FakeOcrResultRepository extends Fake implements OcrResultRepository {
  @override
  Future<OcrResultModel?> getById(int id) async {
    return OcrResultModel(
      id: id,
      userId: 1,
      imagePath: 'receipt_images/foto.jpg',
      rawText: 'x',
      ocrSource: 'gallery',
      ocrStatus: 'success',
      createdAt: DateTime.now(),
    );
  }
}

class FakeImageStorageService extends Fake implements ImageStorageService {
  final List<String> deleted = <String>[];

  @override
  Future<String> persistImage(String sourcePath) async => 'stored:$sourcePath';

  @override
  Future<void> deleteImage(String path) async => deleted.add(path);
}

class FakeImageFormatService extends Fake implements ImageFormatService {
  FakeImageFormatService({this.error});

  final Object? error;

  @override
  Future<String> prepare(String sourcePath) async {
    final Object? failure = error;
    if (failure != null) throw failure;
    return sourcePath;
  }
}

class FakeImagePickerService extends Fake implements ImagePickerService {
  FakeImagePickerService({this.path, this.error});

  final String? path;
  final Object? error;

  @override
  Future<String?> pick(ScanSource source) async {
    final Object? failure = error;
    if (failure != null) throw failure;
    return path;
  }
}

class FakeOcrService extends Fake implements OcrService {
  FakeOcrService({this.result, this.error});

  OcrResult? result;
  Object? error;

  @override
  Future<OcrResult> recognizeFromFile(String imagePath) async {
    final Object? failure = error;
    if (failure != null) throw failure;
    return result ?? const OcrResult(rawText: '', lineCount: 0);
  }

  @override
  Future<void> dispose() async {}
}

// ================================================================ pembantu

Future<AuthViewModel> buildLoggedInAuth() async {
  final AuthViewModel auth = AuthViewModel(
    userRepository: FakeUserRepository(),
    sessionRepository: FakeSessionRepository(),
  );
  await auth.register(
      name: 'Budi', email: 'budi@mail.com', password: 'rahasia1');
  await auth.login(email: 'budi@mail.com', password: 'rahasia1');
  return auth;
}

const String sampleReceipt = 'INDOMARET\n'
    'Jl. Raya Malang\n'
    '01/10/2026\n'
    'Roti 12.000\n'
    'Air Mineral 5.000\n'
    'TOTAL 17.000';

const String multiCategoryReceipt = 'SUPERMARKET MAJU\n'
    '02/10/2026\n'
    'Roti Tawar 12.000\n'
    'Shampoo Sunsilk 25.000\n'
    'Paracetamol 500mg 8.000\n'
    'TOTAL 45.000';

Future<ScanViewModel> buildScan({
  required FakeOcrService ocr,
  required FakeTransactionRepository txRepo,
  FakeImageFormatService? formatService,
  FakeImagePickerService? pickerService,
  void Function()? onSaved,
}) async {
  final AuthViewModel auth = await buildLoggedInAuth();
  final MlService ml = MlService();
  await ml.initialize();
  return ScanViewModel(
    authViewModel: auth,
    ocrService: ocr,
    parsingService: const ParsingService(),
    mlService: ml,
    categoryRepository: FakeCategoryRepository(),
    transactionRepository: txRepo,
    imageStorageService: FakeImageStorageService(),
    imageFormatService: formatService ?? FakeImageFormatService(),
    imagePickerService: pickerService ?? FakeImagePickerService(),
    onTransactionSaved: onSaved,
  );
}

OcrResult ocrOf(String text) =>
    OcrResult(rawText: text, lineCount: text.split('\n').length);

Future<ScanViewModel> readyScan(
  String receipt,
  FakeTransactionRepository repo, {
  void Function()? onSaved,
  ScanSource source = ScanSource.gallery,
}) async {
  final ScanViewModel scan = await buildScan(
    ocr: FakeOcrService(result: ocrOf(receipt)),
    txRepo: repo,
    onSaved: onSaved,
  );
  await scan.processImage(imagePath: '/tmp/struk.jpg', source: source);
  return scan;
}

// ==================================================================== tes

void main() {
  group('AuthViewModel', () {
    late FakeUserRepository users;
    late FakeSessionRepository session;
    late AuthViewModel auth;

    setUp(() {
      users = FakeUserRepository();
      session = FakeSessionRepository();
      auth = AuthViewModel(userRepository: users, sessionRepository: session);
    });

    test('registrasi berhasil tidak langsung login', () async {
      final bool ok = await auth.register(
        name: 'Budi',
        email: 'budi@mail.com',
        password: 'rahasia1',
      );
      expect(ok, isTrue);
      expect(auth.isLoggedIn, isFalse);
      expect(auth.infoMessage, 'Registrasi berhasil. Silakan login.');
    });

    test('registrasi dengan password lemah ditolak', () async {
      final bool ok = await auth.register(
        name: 'Budi',
        email: 'budi@mail.com',
        password: 'abcdefgh',
      );
      expect(ok, isFalse);
      expect(auth.errorMessage, 'Password harus mengandung angka');
    });

    test('registrasi dengan email yang sudah dipakai ditolak', () async {
      await auth.register(
          name: 'Budi', email: 'budi@mail.com', password: 'rahasia1');
      final bool ok = await auth.register(
        name: 'Budi Dua',
        email: 'BUDI@mail.com',
        password: 'rahasia1',
      );
      expect(ok, isFalse);
      expect(auth.errorMessage, 'Email sudah terdaftar');
    });

    test('login berhasil menyimpan sesi', () async {
      await auth.register(
          name: 'Budi', email: 'budi@mail.com', password: 'rahasia1');
      final bool ok =
          await auth.login(email: 'budi@mail.com', password: 'rahasia1');
      expect(ok, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser?.name, 'Budi');
      expect(session.savedId, isNotNull);
    });

    test('password salah menampilkan pesan galat', () async {
      await auth.register(
          name: 'Budi', email: 'budi@mail.com', password: 'rahasia1');
      final bool ok =
          await auth.login(email: 'budi@mail.com', password: 'salah123');
      expect(ok, isFalse);
      expect(auth.isLoggedIn, isFalse);
      expect(auth.errorMessage, 'Username atau Password salah');
    });

    test('format email salah ditolak sebelum ke database', () async {
      final bool ok = await auth.login(email: 'abc', password: 'rahasia1');
      expect(ok, isFalse);
      expect(auth.errorMessage,
          'Format email tidak valid (contoh: nama@email.com)');
    });

    test('login dikunci sementara setelah 5 kali gagal', () async {
      DateTime now = DateTime(2026, 1, 1, 10);
      final AuthViewModel locked = AuthViewModel(
        userRepository: users,
        sessionRepository: session,
        clock: () => now,
      );
      await locked.register(
          name: 'Budi', email: 'budi@mail.com', password: 'rahasia1');

      for (int i = 0; i < AuthViewModel.maxFailedAttempts; i++) {
        await locked.login(email: 'budi@mail.com', password: 'salah123');
      }
      expect(locked.errorMessage, contains('Terlalu banyak percobaan gagal'));

      // Password benar pun ditolak selama masih terkunci.
      expect(await locked.login(email: 'budi@mail.com', password: 'rahasia1'),
          isFalse);
      expect(locked.errorMessage, contains('Coba lagi dalam'));

      // Setelah masa kunci lewat, login normal kembali.
      now = now.add(const Duration(seconds: 31));
      expect(await locked.login(email: 'budi@mail.com', password: 'rahasia1'),
          isTrue);
    });

    test('sesi tersimpan dipulihkan oleh checkSession', () async {
      await auth.register(
          name: 'Budi', email: 'budi@mail.com', password: 'rahasia1');
      await auth.login(email: 'budi@mail.com', password: 'rahasia1');

      final AuthViewModel restarted = AuthViewModel(
        userRepository: users,
        sessionRepository: session,
      );
      expect(restarted.isInitialized, isFalse);
      await restarted.checkSession();

      expect(restarted.isInitialized, isTrue);
      expect(restarted.isLoggedIn, isTrue);
      expect(restarted.currentUser?.email, 'budi@mail.com');
    });

    test('logout menghapus sesi', () async {
      await auth.register(
          name: 'Budi', email: 'budi@mail.com', password: 'rahasia1');
      await auth.login(email: 'budi@mail.com', password: 'rahasia1');
      await auth.logout();
      expect(auth.isLoggedIn, isFalse);
      expect(session.savedId, isNull);
    });

    test('validator nama', () {
      expect(AuthViewModel.validateName(''), 'Nama wajib diisi');
      expect(AuthViewModel.validateName('A'), 'Nama minimal 2 karakter');
      expect(
        AuthViewModel.validateName('Budi123'),
        'Nama hanya boleh berisi huruf, spasi, titik, apostrof, dan tanda hubung',
      );
      expect(AuthViewModel.validateName('Budi Santoso'), isNull);
      expect(AuthViewModel.validateName("O'Brien"), isNull);
    });

    test('validator email', () {
      expect(AuthViewModel.validateEmail(''), 'Email wajib diisi');
      expect(
        AuthViewModel.validateEmail('abc'),
        'Format email tidak valid (contoh: nama@email.com)',
      );
      expect(
        AuthViewModel.validateEmail('a..b@mail.com'),
        'Format email tidak valid (contoh: nama@email.com)',
      );
      expect(AuthViewModel.validateEmail('nama@email.co.id'), isNull);
    });

    test('validator password registrasi', () {
      expect(AuthViewModel.validatePassword(''), 'Password wajib diisi');
      expect(AuthViewModel.validatePassword('abc12'),
          'Password minimal 8 karakter');
      expect(
        AuthViewModel.validatePassword('abcdefgh'),
        'Password harus mengandung angka',
      );
      expect(
        AuthViewModel.validatePassword('12345678'),
        'Password harus mengandung huruf',
      );
      expect(
        AuthViewModel.validatePassword('abc 12345'),
        'Password tidak boleh mengandung spasi',
      );
      expect(AuthViewModel.validatePassword('rahasia1'), isNull);
      expect(
        AuthViewModel.validateConfirmPassword('abcdef12', 'abcdef13'),
        'Konfirmasi password tidak sama',
      );
    });

    test('kekuatan password', () {
      expect(AuthViewModel.evaluatePassword(''), PasswordStrength.empty);
      expect(AuthViewModel.evaluatePassword('abc'), PasswordStrength.weak);
      expect(
          AuthViewModel.evaluatePassword('Rahasia123!'), PasswordStrength.good);
      expect(
        AuthViewModel.evaluatePassword('Rahasia123!xyz'),
        PasswordStrength.strong,
      );
    });
  });

  group('DashboardViewModel', () {
    TransactionModel tx(
        int id, double amount, int categoryId, String category) {
      final DateTime now = DateTime.now();
      return TransactionModel(
        id: id,
        userId: 1,
        ocrId: id == 2 ? 7 : null,
        merchantName: 'Toko $id',
        transactionDate: DateTime(now.year, now.month, 1),
        totalAmount: amount,
        categoryId: categoryId,
        createdAt: now,
        updatedAt: now,
        categoryName: category,
      );
    }

    test('memuat total, rekap kategori, analitik, dan riwayat bulan ini',
        () async {
      final FakeTransactionRepository repo = FakeTransactionRepository()
        ..stored.addAll(<TransactionModel>[
          tx(1, 10000, 1, 'Konsumsi'),
          tx(2, 30000, 4, 'Belanja'),
        ]);
      final DashboardViewModel dash = DashboardViewModel(
        authViewModel: await buildLoggedInAuth(),
        transactionRepository: repo,
        ocrResultRepository: FakeOcrResultRepository(),
        imageStorageService: FakeImageStorageService(),
      );

      await dash.loadDashboard();

      expect(dash.isLoading, isFalse);
      expect(dash.monthlyTotal, 40000);
      expect(dash.transactionCount, 2);
      expect(dash.topCategory?.categoryName, 'Belanja');
      expect(
          dash.percentageOf(dash.categorySummaries.first), closeTo(0.75, 1e-9));
      expect(dash.analytics.transactionCount, 2);
      expect(dash.analytics.dailyTotals, isNotEmpty);
      expect(dash.analytics.biggestTransaction?.totalAmount, 30000);
    });

    test('pindah ke bulan sebelumnya mengosongkan data bulan ini', () async {
      final FakeTransactionRepository repo = FakeTransactionRepository()
        ..stored.add(tx(1, 10000, 1, 'Konsumsi'));
      final DashboardViewModel dash = DashboardViewModel(
        authViewModel: await buildLoggedInAuth(),
        transactionRepository: repo,
        ocrResultRepository: FakeOcrResultRepository(),
        imageStorageService: FakeImageStorageService(),
      );
      await dash.loadDashboard();
      expect(dash.canGoNext, isFalse);

      await dash.goToPrevious();

      expect(dash.monthlyTotal, 0);
      expect(dash.isEmpty, isTrue);
      expect(dash.canGoNext, isTrue);
    });

    test('menghapus transaksi ikut menghapus foto struk', () async {
      final FakeTransactionRepository repo = FakeTransactionRepository()
        ..stored.addAll(<TransactionModel>[
          tx(1, 10000, 1, 'Konsumsi'),
          tx(2, 30000, 4, 'Belanja'),
        ]);
      final FakeImageStorageService images = FakeImageStorageService();
      final DashboardViewModel dash = DashboardViewModel(
        authViewModel: await buildLoggedInAuth(),
        transactionRepository: repo,
        ocrResultRepository: FakeOcrResultRepository(),
        imageStorageService: images,
      );
      await dash.loadDashboard();

      final bool ok = await dash.deleteTransaction(2);

      expect(ok, isTrue);
      expect(images.deleted, <String>['receipt_images/foto.jpg']);
      expect(dash.transactionCount, 1);
      expect(dash.monthlyTotal, 10000);
    });
  });

  group('DashboardViewModel: pencarian periode dan tren', () {
    TransactionModel tx(DateTime date, double amount, {int id = 1}) {
      return TransactionModel(
        id: id,
        userId: 1,
        merchantName: 'Toko $id',
        transactionDate: date,
        totalAmount: amount,
        categoryId: 1,
        createdAt: date,
        updatedAt: date,
        categoryName: 'Konsumsi',
      );
    }

    Future<DashboardViewModel> build(FakeTransactionRepository repo) async {
      return DashboardViewModel(
        authViewModel: await buildLoggedInAuth(),
        transactionRepository: repo,
        ocrResultRepository: FakeOcrResultRepository(),
        imageStorageService: FakeImageStorageService(),
      );
    }

    test('mencari berdasarkan tahun, bulan, dan tanggal', () async {
      final DateTime now = DateTime.now();
      final FakeTransactionRepository repo = FakeTransactionRepository()
        ..stored.addAll(<TransactionModel>[
          tx(DateTime(2022, 3, 5), 50000, id: 1),
          tx(DateTime(2022, 3, 20), 25000, id: 2),
          tx(DateTime(2022, 8, 1), 10000, id: 3),
          tx(DateTime(now.year, now.month, 1), 99000, id: 4),
        ]);
      final DashboardViewModel dash = await build(repo);
      await dash.loadDashboard();

      // Tahun 2022.
      expect(await dash.showYear(2022), isTrue);
      expect(dash.period.mode, PeriodMode.year);
      expect(dash.total, 85000);
      expect(dash.transactionCount, 3);
      expect(dash.trends.year, 2022);
      expect(dash.trends.monthlyTotals[2], 75000); // Maret
      expect(dash.trends.monthlyTotals[7], 10000); // Agustus
      expect(dash.availableYears, contains(2022));

      // Maret 2022.
      expect(await dash.showMonth(2022, 3), isTrue);
      expect(dash.total, 75000);
      expect(dash.transactionCount, 2);

      // Tanggal 5 Maret 2022.
      expect(await dash.showDay(DateTime(2022, 3, 5)), isTrue);
      expect(dash.total, 50000);
      expect(dash.transactionCount, 1);
    });

    test('periode di masa depan ditolak', () async {
      final DashboardViewModel dash = await build(FakeTransactionRepository());
      await dash.loadDashboard();
      final DashboardPeriod before = dash.period;

      expect(await dash.showYear(DateTime.now().year + 1), isFalse);
      expect(dash.period, before);
    });

    test('panah sebelumnya/berikutnya mengikuti jenis periode', () async {
      final DashboardViewModel dash = await build(FakeTransactionRepository());
      await dash.showYear(2022);
      expect(dash.period, DashboardPeriod.year(2022));

      await dash.goToPrevious();
      expect(dash.period, DashboardPeriod.year(2021));

      await dash.goToNext();
      expect(dash.period, DashboardPeriod.year(2022));
      expect(dash.canGoNext, isTrue);
    });

    test('tren tahunan memuat total setiap tahun', () async {
      final DateTime now = DateTime.now();
      final FakeTransactionRepository repo = FakeTransactionRepository()
        ..stored.addAll(<TransactionModel>[
          tx(DateTime(2023, 6, 1), 40000, id: 1),
          tx(DateTime(now.year, now.month, 1), 60000, id: 2),
        ]);
      final DashboardViewModel dash = await build(repo);
      await dash.loadDashboard();

      final Map<int, double> byYear = <int, double>{
        for (final p in dash.trends.yearlyTotals) p.year: p.amount,
      };
      expect(byYear[2023], 40000);
      expect(byYear[now.year], 60000);
    });
  });

  group('ScanViewModel', () {
    test('alur sukses: barang terbaca dan dikelompokkan per kategori',
        () async {
      final ScanViewModel scan = await readyScan(
        sampleReceipt,
        FakeTransactionRepository(),
      );

      expect(scan.status, ScanStatus.ready);
      final ScanDraft? draft = scan.draft;
      expect(draft, isNotNull);
      expect(draft?.merchantName, 'Indomaret');
      expect(draft?.totalAmount, 17000);
      expect(draft?.transactionDate, DateTime(2026, 10, 1));
      expect(draft?.items.length, 2);
      expect(scan.groupedItems.length, 1);
      expect(scan.groupedItems.first.categoryName, 'Konsumsi');
      expect(scan.groupedItems.first.subtotal, 17000);
      expect(scan.hasTotalMismatch, isFalse);
      expect(scan.lastProcessingDuration, isNotNull);
    });

    test('satu struk dengan banyak kategori terkelompok terpisah', () async {
      final FakeTransactionRepository repo = FakeTransactionRepository();
      final ScanViewModel scan = await readyScan(multiCategoryReceipt, repo);

      final Map<String, double> byCategory = <String, double>{
        for (final ItemGroup g in scan.groupedItems) g.categoryName: g.subtotal,
      };
      expect(byCategory, <String, double>{
        'Konsumsi': 12000,
        'Belanja': 25000,
        'Kesehatan': 8000,
      });
      // Kelompok dengan subtotal terbesar tampil lebih dulu.
      expect(scan.groupedItems.first.categoryName, 'Belanja');

      expect(await scan.saveTransaction(), isTrue);
      expect(repo.lastItems.length, 3);
      // Kategori utama transaksi = kategori dengan jumlah terbesar (Belanja = id 4).
      expect(repo.stored.first.categoryId, 4);
    });

    test('struk Surya Elektronik: semua barang tercatat sebagai Elektronik',
        () async {
      const String receipt = 'sURYA ELEKTRONIK\n'
          'Jl. Veteran Utara No.248B\n'
          'Telp. 0411 3628529\n'
          'Sabtu, 16 November 2019\n'
          '13:56:30\n'
          'PPG\n'
          '500.00o X1 500.00o\n'
          'Pulse Sensor\n'
          '150.00o X1 150.00o\n'
          'Pointer\n'
          '225.000 X1 225.000\n'
          'Total Belanja Rp. 875.000\n'
          'Tunai RP. 900.000\n'
          'Kembali Rp. 25.000\n'
          'Terima Kasih';
      final FakeTransactionRepository repo = FakeTransactionRepository();
      final ScanViewModel scan = await readyScan(receipt, repo);

      final ScanDraft? draft = scan.draft;
      expect(draft?.merchantName, 'Surya Elektronik');
      expect(draft?.transactionDate, DateTime(2019, 11, 16));
      expect(draft?.totalAmount, 875000);
      expect(draft?.items.length, 3);
      expect(scan.groupedItems.length, 1);
      expect(scan.groupedItems.first.categoryName, 'Elektronik');
      expect(scan.groupedItems.first.subtotal, 875000);
      expect(scan.hasTotalMismatch, isFalse);

      expect(await scan.saveTransaction(), isTrue);
      expect(repo.lastItems.length, 3);
      expect(repo.stored.first.categoryId, 6); // Elektronik
    });

    test('kategori "Lainnya" selalu berada di urutan terakhir pilihan',
        () async {
      final ScanViewModel scan = await readyScan(
        sampleReceipt,
        FakeTransactionRepository(),
      );
      expect(scan.categories.last.name, 'Lainnya');
      expect(scan.categories.map((c) => c.name), contains('Elektronik'));
    });

    test('gambar tidak terbaca menghasilkan pesan galat', () async {
      final ScanViewModel scan = await buildScan(
        ocr: FakeOcrService(result: ocrOf('a b')),
        txRepo: FakeTransactionRepository(),
      );

      await scan.processImage(
          imagePath: '/tmp/buram.jpg', source: ScanSource.camera);

      expect(scan.status, ScanStatus.error);
      expect(scan.errorMessage, 'Gambar Tidak Jelas, Silakan Ulangi');
      expect(scan.draft, isNull);
    });

    test('galat OCR dan format gambar diteruskan ke pengguna', () async {
      final ScanViewModel ocrFail = await buildScan(
        ocr: FakeOcrService(error: const OcrException('Gagal membaca gambar')),
        txRepo: FakeTransactionRepository(),
      );
      await ocrFail.processImage(
          imagePath: '/tmp/x.jpg', source: ScanSource.camera);
      expect(ocrFail.errorMessage, 'Gagal membaca gambar');

      final ScanViewModel formatFail = await buildScan(
        ocr: FakeOcrService(result: ocrOf(sampleReceipt)),
        txRepo: FakeTransactionRepository(),
        formatService: FakeImageFormatService(
          error: const ImageFormatException('Format file .pdf tidak didukung.'),
        ),
      );
      await formatFail.processImage(
          imagePath: '/tmp/x.pdf', source: ScanSource.file);
      expect(formatFail.status, ScanStatus.error);
      expect(formatFail.errorMessage, 'Format file .pdf tidak didukung.');
    });

    test('pickAndProcess: file dipilih, dibatalkan, atau izin ditolak',
        () async {
      final ScanViewModel picked = await buildScan(
        ocr: FakeOcrService(result: ocrOf(sampleReceipt)),
        txRepo: FakeTransactionRepository(),
        pickerService: FakeImagePickerService(path: '/tmp/struk.png'),
      );
      await picked.pickAndProcess(ScanSource.file);
      expect(picked.status, ScanStatus.ready);

      final ScanViewModel cancelled = await buildScan(
        ocr: FakeOcrService(result: ocrOf(sampleReceipt)),
        txRepo: FakeTransactionRepository(),
        pickerService: FakeImagePickerService(),
      );
      await cancelled.pickAndProcess(ScanSource.gallery);
      expect(cancelled.status, ScanStatus.idle);

      final ScanViewModel denied = await buildScan(
        ocr: FakeOcrService(result: ocrOf(sampleReceipt)),
        txRepo: FakeTransactionRepository(),
        pickerService: FakeImagePickerService(
          error: const ImagePickException('Tidak dapat mengakses kamera.'),
        ),
      );
      await denied.pickAndProcess(ScanSource.camera);
      expect(denied.status, ScanStatus.error);
      expect(denied.errorMessage, 'Tidak dapat mengakses kamera.');
    });

    test('simpan tanpa sunting: is_manual_edit false dan callback terpanggil',
        () async {
      final FakeTransactionRepository repo = FakeTransactionRepository();
      int savedCount = 0;
      final ScanViewModel scan = await readyScan(
        sampleReceipt,
        repo,
        onSaved: () => savedCount++,
      );

      final bool ok = await scan.saveTransaction();

      expect(ok, isTrue);
      expect(scan.status, ScanStatus.saved);
      expect(savedCount, 1);
      expect(repo.stored.length, 1);
      expect(repo.stored.first.isManualEdit, isFalse);
      expect(repo.stored.first.merchantName, 'Indomaret');
      expect(repo.lastItems.length, 2);
      expect(repo.lastOcr?.ocrSource, 'gallery');
      expect(repo.lastOcr?.imagePath, 'stored:/tmp/struk.jpg');
      expect(repo.lastFeatures, isNotEmpty);
    });

    test('sumber file tercatat sebagai ocr_source file', () async {
      final FakeTransactionRepository repo = FakeTransactionRepository();
      final ScanViewModel scan =
          await readyScan(sampleReceipt, repo, source: ScanSource.file);
      await scan.saveTransaction();
      expect(repo.lastOcr?.ocrSource, 'file');
    });

    test('mengubah nama, harga, dan kategori barang menandai sunting manual',
        () async {
      final FakeTransactionRepository repo = FakeTransactionRepository();
      final ScanViewModel scan = await readyScan(sampleReceipt, repo);
      final DraftItem first = scan.draft!.items.first;

      scan.updateItem(
        first.localId,
        name: 'Roti Gandum',
        quantity: 1,
        unitPrice: 15000,
        categoryId: 4, // Belanja
      );

      // Jumlah barang (20.000) kini berbeda dari total struk (17.000).
      expect(scan.hasTotalMismatch, isTrue);
      expect(scan.itemsTotal, 20000);
      scan.useItemsTotal();
      expect(scan.draft?.totalAmount, 20000);
      expect(scan.hasTotalMismatch, isFalse);

      expect(await scan.saveTransaction(), isTrue);
      expect(repo.stored.first.isManualEdit, isTrue);
      expect(repo.stored.first.totalAmount, 20000);
      expect(repo.lastItems.first.name, 'Roti Gandum');
      expect(repo.lastItems.first.unitPrice, 15000);
      expect(repo.lastItems.first.categoryId, 4);
      // AI semula menebak Konsumsi; tebakan awal tetap tersimpan untuk pembelajaran.
      expect(repo.lastItems.first.aiCategoryId, 1);
    });

    test('menambah dan menghapus barang', () async {
      final ScanViewModel scan = await readyScan(
        sampleReceipt,
        FakeTransactionRepository(),
      );
      expect(scan.draft?.items.length, 2);

      scan.addItem(
          name: 'Pertalite', quantity: 1, unitPrice: 30000, categoryId: 2);
      expect(scan.draft?.items.length, 3);
      expect(scan.groupedItems.length, 2);

      scan.removeItem(scan.draft!.items.last.localId);
      expect(scan.draft?.items.length, 2);
    });

    test('mengubah tanggal dan total struk', () async {
      final FakeTransactionRepository repo = FakeTransactionRepository();
      final ScanViewModel scan = await readyScan(sampleReceipt, repo);

      scan.updateTransactionDate(DateTime(2026, 10, 9));
      scan.updateTotalAmountText('18.500');
      scan.updateMerchantName('Indomaret Point');

      expect(await scan.saveTransaction(), isTrue);
      expect(repo.stored.first.transactionDate, DateTime(2026, 10, 9));
      expect(repo.stored.first.totalAmount, 18500);
      expect(repo.stored.first.merchantName, 'Indomaret Point');
      expect(repo.stored.first.isManualEdit, isTrue);
    });

    test('tanggal kosong dan tanpa barang ditolak oleh validasi', () async {
      final FakeTransactionRepository repo = FakeTransactionRepository();
      final ScanViewModel scan = await readyScan(
        'WARUNG BU TINI\nNasi Goreng 15.000',
        repo,
      );

      expect(await scan.saveTransaction(), isFalse);
      expect(scan.formErrors.containsKey(ScanViewModel.fieldDate), isTrue);

      for (final DraftItem item in List<DraftItem>.of(scan.draft!.items)) {
        scan.removeItem(item.localId);
      }
      scan.updateTransactionDate(DateTime(2026, 10, 2));
      expect(await scan.saveTransaction(), isFalse);
      expect(scan.formErrors.containsKey(ScanViewModel.fieldItems), isTrue);
      expect(scan.status, ScanStatus.ready);
      expect(repo.stored, isEmpty);
    });

    test('saran kategori dari nama barang', () async {
      final ScanViewModel scan = await readyScan(
        sampleReceipt,
        FakeTransactionRepository(),
      );
      expect(scan.suggestCategoryId('Pertalite'), 2);
      expect(scan.suggestCategoryId('Paracetamol'), 3);
      expect(scan.suggestCategoryId('   '), isNull);
    });

    test('batal membuang data sementara', () async {
      final ScanViewModel scan = await readyScan(
        sampleReceipt,
        FakeTransactionRepository(),
      );

      scan.cancel();

      expect(scan.status, ScanStatus.idle);
      expect(scan.draft, isNull);
    });

    test('parseAmountInput memahami format Indonesia', () {
      expect(ScanViewModel.parseAmountInput('17.000'), 17000);
      expect(ScanViewModel.parseAmountInput('Rp 186.750'), 186750);
      expect(ScanViewModel.parseAmountInput('1.234,50'), 1234.5);
      expect(ScanViewModel.parseAmountInput(''), isNull);
    });
  });
}
