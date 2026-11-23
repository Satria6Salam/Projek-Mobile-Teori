import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'data/database/app_database.dart';
import 'core/theme/category_palette.dart';
import 'data/models/category_model.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/shopping_plan_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/recurring_repository.dart';
import 'data/repositories/ml_classification_repository.dart';
import 'data/repositories/ocr_result_repository.dart';
import 'data/repositories/parsed_receipt_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/user_repository.dart';
import 'services/budget_service.dart';
import 'services/shopping_plan_service.dart';
import 'services/export_service.dart';
import 'services/image_enhancement_service.dart';
import 'services/image_format_service.dart';
import 'services/image_picker_service.dart';
import 'services/image_storage_service.dart';
import 'services/ml_service.dart';
import 'services/notification_service.dart';
import 'services/ocr_service.dart';
import 'services/parsing_service.dart';
import 'services/recurring_service.dart';
import 'services/reminder_coordinator.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/budget_viewmodel.dart';
import 'viewmodels/shopping_plan_viewmodel.dart';
import 'viewmodels/category_management_viewmodel.dart';
import 'viewmodels/data_tools_viewmodel.dart';
import 'viewmodels/manual_entry_viewmodel.dart';
import 'viewmodels/reminder_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/scan_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Data format tanggal Indonesia (contoh: 24 September 2026).
  await initializeDateFormatting('id_ID');

  // Membuka (dan membuat, jika belum ada) basis data lokal SQLite.
  await AppDatabase.instance.database;

  // Repository.
  final UserRepository userRepository = UserRepository();
  final CategoryRepository categoryRepository = CategoryRepository();
  final OcrResultRepository ocrResultRepository = OcrResultRepository();
  final ParsedReceiptRepository parsedReceiptRepository =
      ParsedReceiptRepository();
  final MlClassificationRepository mlClassificationRepository =
      MlClassificationRepository();
  final TransactionRepository transactionRepository = TransactionRepository();
  final SessionRepository sessionRepository = SessionRepository();
  final BudgetRepository budgetRepository = BudgetRepository();
  final RecurringRepository recurringRepository = RecurringRepository();
  final ShoppingPlanRepository shoppingPlanRepository =
      ShoppingPlanRepository();

  // Ikon dan warna kustom kategori dimuat sebelum tampilan pertama.
  CategoryPalette.applyTo(await categoryRepository.getAll());

  // Service (OCR, parsing, ML, penyimpanan gambar).
  final OcrService ocrService = OcrService();
  const ParsingService parsingService = ParsingService();
  final MlService mlService = MlService();
  final ImageStorageService imageStorageService = ImageStorageService();
  final ImageFormatService imageFormatService = ImageFormatService();
  final ImageEnhancementService imageEnhancementService =
      ImageEnhancementService();
  final ImagePickerService imagePickerService = ImagePickerService();

  // Fitur UAS: notifikasi, anggaran, transaksi berulang, dan ekspor.
  final NotificationService notificationService = NotificationService();
  final BudgetService budgetService = BudgetService(
    budgets: budgetRepository,
    transactions: transactionRepository,
    categories: categoryRepository,
    notifications: notificationService,
  );
  final RecurringService recurringService = RecurringService(
    recurring: recurringRepository,
    transactions: transactionRepository,
  );
  final ReminderCoordinator reminderCoordinator = ReminderCoordinator(
    notifications: notificationService,
    transactions: transactionRepository,
    recurring: recurringService,
    budgets: budgetService,
  );
  final ExportService exportService = ExportService(
    transactions: transactionRepository,
  );
  // Rencana belanja: dicocokkan dengan tokenizer model AI agar singkatan
  // struk ("TLR AYM") tetap cocok dengan rencana ("Telur ayam").
  final ShoppingPlanService shoppingPlanService = ShoppingPlanService(
    repository: shoppingPlanRepository,
    matcher: ShoppingMatcher(tokenizer: mlService.tokenize),
  );

  // ViewModel.
  final AuthViewModel authViewModel = AuthViewModel(
    userRepository: userRepository,
    sessionRepository: sessionRepository,
  );
  // Cek sesi sebelum UI tampil, agar router langsung ke Dasbor atau Login.
  await authViewModel.checkSession();

  final DashboardViewModel dashboardViewModel = DashboardViewModel(
    authViewModel: authViewModel,
    transactionRepository: transactionRepository,
    ocrResultRepository: ocrResultRepository,
    imageStorageService: imageStorageService,
  );
  final ShoppingPlanViewModel shoppingPlanViewModel = ShoppingPlanViewModel(
    authViewModel: authViewModel,
    repository: shoppingPlanRepository,
  );
  final ScanViewModel scanViewModel = ScanViewModel(
    authViewModel: authViewModel,
    ocrService: ocrService,
    parsingService: parsingService,
    mlService: mlService,
    categoryRepository: categoryRepository,
    transactionRepository: transactionRepository,
    imageStorageService: imageStorageService,
    imageFormatService: imageFormatService,
    imagePickerService: imagePickerService,
    imageEnhancementService: imageEnhancementService,
    shoppingPlanService: shoppingPlanService,
    onTransactionSaved: () {
      dashboardViewModel.loadDashboard();
      unawaited(shoppingPlanViewModel.load());
      final int? userId = authViewModel.currentUser?.id;
      if (userId != null) {
        unawaited(budgetService.checkAndNotify(userId));
      }
    },
  );
  final ProfileViewModel profileViewModel = ProfileViewModel(
    authViewModel: authViewModel,
    userRepository: userRepository,
  );
  final BudgetViewModel budgetViewModel = BudgetViewModel(
    authViewModel: authViewModel,
    budgetRepository: budgetRepository,
    budgetService: budgetService,
  );
  final ManualEntryViewModel manualEntryViewModel = ManualEntryViewModel(
    authViewModel: authViewModel,
    transactionRepository: transactionRepository,
    categoryRepository: categoryRepository,
    recurringRepository: recurringRepository,
    budgetService: budgetService,
  );
  final CategoryManagementViewModel categoryManagementViewModel =
      CategoryManagementViewModel(categoryRepository: categoryRepository);
  final ReminderViewModel reminderViewModel = ReminderViewModel(
    authViewModel: authViewModel,
    notifications: notificationService,
    coordinator: reminderCoordinator,
  );
  final DataToolsViewModel dataToolsViewModel = DataToolsViewModel(
    authViewModel: authViewModel,
    exportService: exportService,
  );

  if (kDebugMode) {
    final List<CategoryModel> categories = await categoryRepository.getAll();
    debugPrint(
      '[SmartReceipt] Database siap. Kategori awal: '
      '${categories.map((CategoryModel c) => c.name).join(', ')}',
    );
    debugPrint(
      '[SmartReceipt] Sesi: ${authViewModel.isLoggedIn ? 'login sebagai ${authViewModel.currentUser?.email}' : 'belum login'}',
    );
  }

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Melatih model TF-IDF + Naive Bayes (offline) setelah tampilan pertama muncul,
  // sehingga aplikasi tidak menunggu pelatihan saat dibuka.
  unawaited(Future<void>.delayed(
    const Duration(milliseconds: 700),
    mlService.initialize,
  ));

  // Transaksi berulang yang jatuh tempo, cek anggaran, dan jadwal pengingat.
  final int? openedUserId = authViewModel.currentUser?.id;
  if (openedUserId != null) {
    unawaited(Future<void>.delayed(
      const Duration(milliseconds: 1200),
      () => reminderCoordinator.onAppOpened(openedUserId),
    ));
  }

  runApp(
    MultiProvider(
      providers: [
        // Repository & service (lapisan data dan AI).
        Provider<UserRepository>.value(value: userRepository),
        Provider<CategoryRepository>.value(value: categoryRepository),
        Provider<OcrResultRepository>.value(value: ocrResultRepository),
        Provider<ParsedReceiptRepository>.value(value: parsedReceiptRepository),
        Provider<MlClassificationRepository>.value(
          value: mlClassificationRepository,
        ),
        Provider<TransactionRepository>.value(value: transactionRepository),
        Provider<SessionRepository>.value(value: sessionRepository),
        Provider<OcrService>.value(value: ocrService),
        Provider<ParsingService>.value(value: parsingService),
        Provider<MlService>.value(value: mlService),
        Provider<ImageStorageService>.value(value: imageStorageService),
        Provider<ImageFormatService>.value(value: imageFormatService),
        Provider<ImagePickerService>.value(value: imagePickerService),
        // ViewModel (state management).
        ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
        ChangeNotifierProvider<DashboardViewModel>.value(
          value: dashboardViewModel,
        ),
        ChangeNotifierProvider<ScanViewModel>.value(value: scanViewModel),
        ChangeNotifierProvider<ProfileViewModel>.value(value: profileViewModel),
        ChangeNotifierProvider<BudgetViewModel>.value(value: budgetViewModel),
        ChangeNotifierProvider<ShoppingPlanViewModel>.value(
          value: shoppingPlanViewModel,
        ),
        ChangeNotifierProvider<ManualEntryViewModel>.value(
          value: manualEntryViewModel,
        ),
        ChangeNotifierProvider<CategoryManagementViewModel>.value(
          value: categoryManagementViewModel,
        ),
        ChangeNotifierProvider<ReminderViewModel>.value(
          value: reminderViewModel,
        ),
        ChangeNotifierProvider<DataToolsViewModel>.value(
          value: dataToolsViewModel,
        ),
      ],
      child: const SmartReceiptApp(),
    ),
  );
}

class SmartReceiptApp extends StatefulWidget {
  const SmartReceiptApp({super.key});

  @override
  State<SmartReceiptApp> createState() => _SmartReceiptAppState();
}

class _SmartReceiptAppState extends State<SmartReceiptApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final AuthViewModel auth = context.read<AuthViewModel>();
    _router = AppRouter.create(
      refreshListenable: auth,
      isLoggedIn: () => auth.isLoggedIn,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SmartReceipt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      locale: const Locale('id', 'ID'),
      supportedLocales: const <Locale>[Locale('id', 'ID')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
