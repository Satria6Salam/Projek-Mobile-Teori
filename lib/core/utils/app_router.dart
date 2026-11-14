import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../views/analysis/analysis_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/budget/budget_screen.dart';
import '../../views/category/category_management_screen.dart';
import '../../views/dashboard/dashboard_screen.dart';
import '../../views/profile/data_tools_screen.dart';
import '../../views/profile/notification_settings_screen.dart';
import '../../views/history/history_screen.dart';
import '../../views/profile/settings_screen.dart';
import '../../views/scanner/camera_screen.dart';
import '../../views/scanner/preview_screen.dart';
import '../../views/shell/app_shell.dart';
import '../../views/transaction/manual_entry_screen.dart';
import '../../views/widgets/not_found_screen.dart';
import '../constants/app_routes.dart';

/// Konfigurasi GoRouter: Auth Guard (UC-01), cangkang navigasi bawah untuk
/// 4 menu utama, dan transisi halus untuk halaman lain.
class AppRouter {
  AppRouter._();

  /// Transisi: memudar + bergeser sedikit dari bawah.
  static Page<void> _page(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
      ) {
        final CurvedAnimation curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// [refreshListenable] dipantau agar redirect dievaluasi ulang saat sesi berubah
  /// (diisi AuthViewModel). [isLoggedIn] mengembalikan status sesi saat ini.
  static GoRouter create({
    required Listenable refreshListenable,
    required bool Function() isLoggedIn,
  }) {
    return GoRouter(
      initialLocation: AppRoutes.dashboard,
      refreshListenable: refreshListenable,
      debugLogDiagnostics: kDebugMode,
      redirect: (BuildContext context, GoRouterState state) {
        final bool loggedIn = isLoggedIn();
        final String location = state.matchedLocation;
        final bool onAuthPage =
            location == AppRoutes.login || location == AppRoutes.register;

        // Belum login: hanya boleh di halaman Login / Registrasi.
        if (!loggedIn) {
          return onAuthPage ? null : AppRoutes.login;
        }
        // Sudah login: langsung ke Beranda.
        if (onAuthPage) {
          return AppRoutes.dashboard;
        }
        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (context, state) => _page(state, const LoginScreen()),
        ),
        GoRoute(
          path: AppRoutes.register,
          pageBuilder: (context, state) => _page(state, const RegisterScreen()),
        ),
        // Empat menu utama dengan navigasi bawah (urutan = indeks menu).
        StatefulShellRoute.indexedStack(
          builder: (
            BuildContext context,
            GoRouterState state,
            StatefulNavigationShell navigationShell,
          ) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.dashboard,
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.history,
                  builder: (context, state) => const HistoryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.analysis,
                  builder: (context, state) => const AnalysisScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: AppRoutes.settings,
                  builder: (context, state) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.scan,
          pageBuilder: (context, state) => _page(state, const CameraScreen()),
        ),
        GoRoute(
          path: AppRoutes.preview,
          pageBuilder: (context, state) => _page(state, const PreviewScreen()),
        ),
        GoRoute(
          path: AppRoutes.budget,
          pageBuilder: (context, state) => _page(state, const BudgetScreen()),
        ),
        GoRoute(
          path: AppRoutes.manualEntry,
          pageBuilder: (context, state) =>
              _page(state, const ManualEntryScreen()),
        ),
        GoRoute(
          path: AppRoutes.categories,
          pageBuilder: (context, state) =>
              _page(state, const CategoryManagementScreen()),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          pageBuilder: (context, state) =>
              _page(state, const NotificationSettingsScreen()),
        ),
        GoRoute(
          path: AppRoutes.dataTools,
          pageBuilder: (context, state) =>
              _page(state, const DataToolsScreen()),
        ),
      ],
      errorBuilder: (context, state) =>
          NotFoundScreen(location: state.uri.toString()),
    );
  }
}
