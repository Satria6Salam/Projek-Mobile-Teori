import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';

/// Logo SmartReceipt: kotak gradasi Emerald dengan ikon pemindai.
/// Bila [animated], logo muncul dengan efek membesar memantul.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64, this.animated = false});

  final double size;
  final bool animated;

  Widget _logo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3310B981),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(AppIcons.scanLine, color: AppColors.white, size: size * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!animated) return _logo();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: _logo(),
    );
  }
}
