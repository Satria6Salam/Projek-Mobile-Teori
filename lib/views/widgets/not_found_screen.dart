import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_icons.dart';
import 'empty_state.dart';

/// Ditampilkan GoRouter bila rute tidak ditemukan.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: EmptyState(
            icon: AppIcons.info,
            title: 'Halaman Tidak Ditemukan',
            message: 'Rute "$location" tidak tersedia.',
            actionLabel: 'Kembali ke Dasbor',
            onAction: () => context.go(AppRoutes.dashboard),
          ),
        ),
      ),
    );
  }
}
