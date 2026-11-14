import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import 'pressable_scale.dart';

/// Satu tombol aksi cepat (ikon di kotak membulat dengan label di bawahnya).
class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// True untuk aksi utama (latar hijau gelap).
  final bool highlight;
}

/// Baris aksi cepat seperti pada aplikasi keuangan: Scan, Catat, Anggaran, ...
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _ActionButton(action: actions[i], index: i)),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.index});

  final QuickAction action;
  final int index;

  @override
  Widget build(BuildContext context) {
    final bool hi = action.highlight;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + index * 90),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double v, Widget? child) {
        return Transform.scale(scale: 0.6 + 0.4 * v, child: child);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: action.onTap,
        child: PressableScale(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: hi ? AppColors.cardGradient : null,
                    color: hi ? null : AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: hi
                        ? <BoxShadow>[
                            BoxShadow(
                              color:
                                  AppColors.emeraldDeep.withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : AppDecorations.softShadow,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hi
                          ? AppColors.white.withValues(alpha: 0.18)
                          : AppColors.mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action.icon,
                      size: 19,
                      color: hi ? AppColors.white : AppColors.emeraldDeep,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.slateDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
