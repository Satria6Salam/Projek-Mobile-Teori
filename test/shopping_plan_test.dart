import 'package:flutter_test/flutter_test.dart';
import 'package:smart_receipt/core/constants/db_constants.dart';
import 'package:smart_receipt/data/models/shopping_plan_model.dart';
import 'package:smart_receipt/data/repositories/shopping_plan_repository.dart';
import 'package:smart_receipt/services/ml_service.dart';
import 'package:smart_receipt/services/parsing_service.dart';
import 'package:smart_receipt/services/shopping_plan_service.dart';
import 'package:smart_receipt/viewmodels/auth_viewmodel.dart';
import 'package:smart_receipt/viewmodels/scan_viewmodel.dart';
import 'package:smart_receipt/viewmodels/shopping_plan_viewmodel.dart';

import 'viewmodels_test.dart'
    show
        FakeCategoryRepository,
        FakeImageFormatService,
        FakeImagePickerService,
        FakeImageStorageService,
        FakeOcrService,
        FakeTransactionRepository,
        buildLoggedInAuth,
        ocrOf;

/// Penyimpanan rencana belanja di memori (pengganti SQLite saat pengujian).
class FakeShoppingPlanRepository extends Fake
    implements ShoppingPlanRepository {
  final List<ShoppingPlanModel> rows = <ShoppingPlanModel>[];
  int _nextId = 1;

  ShoppingPlanModel _withId(ShoppingPlanModel p, int id) =>
      ShoppingPlanModel.fromMap(<String, Object?>{
        ...p.toMap(),
        PlanCols.id: id,
      });

  @override
  Future<List<ShoppingPlanModel>> getAll(int userId) async =>
      rows.where((ShoppingPlanModel p) => p.userId == userId).toList();

  @override
  Future<List<ShoppingPlanModel>> getPending(int userId) async => rows
      .where((ShoppingPlanModel p) => p.userId == userId && !p.isBought)
      .toList();

  @override
  Future<int> insert(ShoppingPlanModel plan) async {
    final int id = _nextId++;
    rows.add(_withId(plan, id));
    return id;
  }

  @override
  Future<void> update(ShoppingPlanModel plan) async {
    final int i = rows.indexWhere((ShoppingPlanModel p) => p.id == plan.id);
    if (i >= 0) rows[i] = plan;
  }

  @override
  Future<void> updateAll(List<ShoppingPlanModel> plans) async {
    for (final ShoppingPlanModel p in plans) {
      await update(p);
    }
  }

  @override
  Future<void> delete(int planId) async =>
      rows.removeWhere((ShoppingPlanModel p) => p.id == planId);

  @override
  Future<int> deleteBought(int userId) async {
    final int before = rows.length;
    rows.removeWhere((ShoppingPlanModel p) => p.userId == userId && p.isBought);
    return before - rows.length;
  }
}

ShoppingPlanModel _plan(int id, String name) => ShoppingPlanModel(
      id: id,
      userId: 1,
      name: name,
      createdAt: DateTime(2026, 11, 1),
    );

PurchasedLine _line(String name, double price) =>
    PurchasedLine(name: name, totalPrice: price);

void main() {
  late MlService ml;
  late ShoppingMatcher matcher;

  setUpAll(() async {
    ml = MlService();
    await ml.initialize();
    matcher = ShoppingMatcher(tokenizer: ml.tokenize);
  });

  group('ShoppingMatcher', () {
    test('barang yang ada di struk dicocokkan, yang tidak dibeli tetap', () {
      final List<PlanMatch> matches = matcher.match(
        <ShoppingPlanModel>[
          _plan(1, 'Telur ayam'),
          _plan(2, 'Gula pasir'),
          _plan(3, 'Indomie goreng'),
          _plan(4, 'Sabun cuci piring'),
          _plan(5, 'Kopi'),
        ],
        <PurchasedLine>[
          _line('TLR AYM NEGERI', 28000),
          _line('GULA PASIR 1KG', 14500),
          _line('INDOMIE SOTO', 3000),
          _line('INDOMIE GRG SPCL', 3500),
          _line('AQUA 600ML', 3500),
        ],
      );

      final Map<String, String> pairs = <String, String>{
        for (final PlanMatch m in matches) m.plan.name: m.line.name,
      };
      expect(pairs, <String, String>{
        'Telur ayam': 'TLR AYM NEGERI',
        'Gula pasir': 'GULA PASIR 1KG',
        'Indomie goreng': 'INDOMIE GRG SPCL',
      });
    });

    test('satu barang struk hanya mencoret satu rencana', () {
      final List<PlanMatch> matches = matcher.match(
        <ShoppingPlanModel>[_plan(1, 'Aqua'), _plan(2, 'Aqua')],
        <PurchasedLine>[_line('AQUA 600ML', 3500)],
      );
      expect(matches, hasLength(1));
    });

    test('kata rencana tidak cocok dengan kata struk yang lebih panjang', () {
      final List<PlanMatch> matches = matcher.match(
        <ShoppingPlanModel>[_plan(1, 'Susu')],
        <PurchasedLine>[_line('SUSUN RAK PLASTIK', 45000)],
      );
      expect(matches, isEmpty);
    });

    test('kata yang terpotong di struk tetap dikenali', () {
      final List<PlanMatch> matches = matcher.match(
        <ShoppingPlanModel>[_plan(1, 'Sunlight jeruk nipis')],
        <PurchasedLine>[_line('SUNLIG JRK NPS 755', 18500)],
      );
      expect(matches, hasLength(1));
    });

    test('rencana dua kata butuh kedua kata ada di struk', () {
      final List<PlanMatch> matches = matcher.match(
        <ShoppingPlanModel>[_plan(1, 'Minyak goreng')],
        <PurchasedLine>[_line('MINYAK KAYU PUTIH', 22000)],
      );
      expect(matches, isEmpty);
    });
  });

  group('ShoppingPlanViewModel', () {
    late FakeShoppingPlanRepository repo;
    late ShoppingPlanViewModel vm;

    setUp(() async {
      repo = FakeShoppingPlanRepository();
      final AuthViewModel auth = await buildLoggedInAuth();
      vm = ShoppingPlanViewModel(
        authViewModel: auth,
        repository: repo,
        clock: () => DateTime(2026, 11, 20),
      );
    });

    test('menambah barang, menolak nama kosong dan duplikat', () async {
      expect(await vm.add('Telur ayam', quantity: 2), isTrue);
      expect(await vm.add('   '), isFalse);
      expect(await vm.add('telur AYAM'), isFalse);
      expect(vm.errorMessage, contains('sudah ada'));
      expect(vm.pending.single.quantity, 2);
    });

    test('rekap: sudah dibeli, belum dibeli, dan kemajuan', () async {
      await vm.add('Telur ayam');
      await vm.add('Gula pasir');
      await vm.setBought(vm.pending.first, true);

      expect(vm.bought, hasLength(1));
      expect(vm.pending, hasLength(1));
      expect(vm.progress, 0.5);

      await vm.setBought(vm.bought.single, false);
      expect(vm.pending, hasLength(2));
      expect(vm.bought, isEmpty);
    });

    test('bersihkan riwayat hanya menghapus yang sudah dibeli', () async {
      await vm.add('Telur ayam');
      await vm.add('Gula pasir');
      await vm.setBought(vm.pending.first, true);
      await vm.clearBought();

      expect(vm.bought, isEmpty);
      expect(vm.pending, hasLength(1));
    });
  });

  test('scan struk mencoret rencana yang dibeli dan menyisakan yang belum',
      () async {
    final FakeShoppingPlanRepository repo = FakeShoppingPlanRepository();
    final AuthViewModel auth = await buildLoggedInAuth();
    final int userId = auth.currentUser!.id!;
    for (final String name in <String>['Roti tawar', 'Air mineral', 'Kopi']) {
      await repo.insert(ShoppingPlanModel(
        userId: userId,
        name: name,
        createdAt: DateTime(2026, 9, 30),
      ));
    }

    final FakeTransactionRepository txRepo = FakeTransactionRepository();
    final ScanViewModel scan = ScanViewModel(
      authViewModel: auth,
      ocrService: FakeOcrService(
        result: ocrOf('INDOMARET\n01/10/2026\nROTI TAWAR 12.000\n'
            'AIR MINERAL 600ML 5.000\nTOTAL 17.000'),
      ),
      parsingService: const ParsingService(),
      mlService: ml,
      categoryRepository: FakeCategoryRepository(),
      transactionRepository: txRepo,
      imageStorageService: FakeImageStorageService(),
      imageFormatService: FakeImageFormatService(),
      imagePickerService: FakeImagePickerService(),
      shoppingPlanService: ShoppingPlanService(
        repository: repo,
        matcher: ShoppingMatcher(tokenizer: ml.tokenize),
      ),
    );

    await scan.processImage(
      imagePath: '/tmp/struk.jpg',
      source: ScanSource.gallery,
    );
    expect(await scan.saveTransaction(), isTrue);

    expect(scan.lastPlanMatches.toSet(), <String>{'Roti tawar', 'Air mineral'});
    final List<ShoppingPlanModel> all = await repo.getAll(userId);
    final ShoppingPlanModel roti =
        all.firstWhere((ShoppingPlanModel p) => p.name == 'Roti tawar');
    expect(roti.isBought, isTrue);
    expect(roti.boughtPrice, 12000);
    expect(roti.boughtAt, DateTime(2026, 10, 1));
    expect(roti.transactionId, txRepo.stored.single.id);
    expect(
      all.firstWhere((ShoppingPlanModel p) => p.name == 'Kopi').isBought,
      isFalse,
    );
  });
}
