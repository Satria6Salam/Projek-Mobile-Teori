/// Daftar path rute aplikasi (satu sumber kebenaran untuk GoRouter).
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String history = '/history';
  static const String analysis = '/analysis';
  static const String settings = '/settings';
  static const String scan = '/scan';
  static const String preview = '/preview';

  // Fitur lanjutan (dibuka dari menu Pengaturan).
  static const String budget = '/budget';
  static const String manualEntry = '/manual-entry';
  static const String categories = '/categories';
  static const String notifications = '/notifications';
  static const String dataTools = '/data-tools';
  static const String shoppingPlan = '/shopping-plan';
}
