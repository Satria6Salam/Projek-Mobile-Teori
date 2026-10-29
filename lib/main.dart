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
import 'data/models/category_model.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/ml_classification_repository.dart';
import 'data/repositories/ocr_result_repository.dart';
import 'data/repositories/parsed_receipt_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/user_repository.dart';
import 'services/image_format_service.dart';
import 'services/image_picker_service.dart';
import 'services/image_storage_service.dart';
import 'services/ml_service.dart';
import 'services/ocr_service.dart';
import 'services/parsing_service.dart';
import 'viewmodels/auth_viewmodel.dart';
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

  // Service (OCR, parsing, ML, penyimpanan gambar).
  final OcrService ocrService = OcrService();
  const ParsingService parsingService = ParsingService();
  final MlService mlService = MlService();
  await mlService.initialize(); // Melatih model TF-IDF + Naive Bayes (offline).
  final ImageStorageService imageStorageService = ImageStorageService();
  final ImageFormatService imageFormatService = ImageFormatService();
  final ImagePickerService imagePickerService = ImagePickerService();

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
    onTransactionSaved: dashboardViewModel.loadDashboard,
  );
  final ProfileViewModel profileViewModel = ProfileViewModel(
    authViewModel: authViewModel,
    userRepository: userRepository,
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
