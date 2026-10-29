import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/dashboard/dashboard_screen.dart';
import '../../views/profile/settings_screen.dart';
import '../../views/scanner/camera_screen.dart';
import '../../views/scanner/preview_screen.dart';
import '../../views/widgets/not_found_screen.dart';
import '../constants/app_routes.dart';

/// Konfigurasi GoRouter beserta Auth Guard (UC-01) dan transisi halaman halus.
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
        // Sudah login: langsung ke Dasbor Keuangan.
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
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) =>
              _page(state, const DashboardScreen()),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => _page(state, const SettingsScreen()),
        ),
        GoRoute(
          path: AppRoutes.scan,
          pageBuilder: (context, state) => _page(state, const CameraScreen()),
        ),
        GoRoute(
          path: AppRoutes.preview,
          pageBuilder: (context, state) => _page(state, const PreviewScreen()),
        ),
      ],
      errorBuilder: (context, state) =>
          NotFoundScreen(location: state.uri.toString()),
    );
  }
}
