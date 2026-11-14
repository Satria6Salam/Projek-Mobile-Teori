import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../widgets/app_bottom_nav.dart';

/// Cangkang aplikasi: menampung 4 menu utama (Beranda, Riwayat, Analisis, Profil)
/// dengan bilah navigasi bawah. Setiap menu mempertahankan posisi gulirnya.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        onScan: () => context.push(AppRoutes.scan),
      ),
    );
  }
}
