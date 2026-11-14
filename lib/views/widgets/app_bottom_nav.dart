import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import 'pressable_scale.dart';

/// Bilah navigasi bawah yang melayang: 4 menu dan tombol Scan Struk di tengah.
/// Menu terpilih ditandai kapsul hijau beranimasi; tombol Scan berdenyut halus.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onScan,
  });

  /// 0 = Beranda, 1 = Riwayat, 2 = Analisis, 3 = Profil.
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final List<_NavSpec> items = <_NavSpec>[
      _NavSpec('Beranda', AppIcons.layoutDashboard),
      _NavSpec('Riwayat', AppIcons.history),
      _NavSpec('Analisis', AppIcons.trendingUp),
      _NavSpec('Profil', AppIcons.user),
    ];

    Widget item(int index) {
      return Expanded(
        child: _NavItem(
          spec: items[index],
          selected: currentIndex == index,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(index);
          },
        ),
      );
    }

    return Container(
      color: AppColors.offWhite,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SizedBox(
            height: 92,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x240F172A),
                          blurRadius: 28,
                          offset: Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: const Color(0x0F0F172A)),
                    ),
                    child: Row(
                      children: [
                        item(0),
                        item(1),
                        const SizedBox(width: 80),
                        item(2),
                        item(3),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Scan',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.emeraldDeep,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(child: _ScanButton(onTap: onScan)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return InkResponse(
      onTap: onTap,
      radius: 36,
      highlightShape: BoxShape.circle,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: selected ? 52 : 40,
            height: 32,
            decoration: BoxDecoration(
              color: selected ? AppColors.emeraldTint : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(
                spec.icon,
                size: 22,
                color: selected ? AppColors.emeraldDark : AppColors.coolGray,
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: (textTheme.labelMedium ?? const TextStyle()).copyWith(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? AppColors.emeraldDeep : AppColors.coolGray,
            ),
            child: Text(spec.label),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatefulWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<_ScanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.92,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double t = Curves.easeInOut.transform(_controller.value);
            return Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(16, 185, 129, 0.22 + 0.16 * t),
                    blurRadius: 18 + 10 * t,
                    spreadRadius: 1 + 2 * t,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF34C38A),
                  Color(0xFF16855A),
                  Color(0xFF0F6B47)
                ],
              ),
            ),
            child: Icon(AppIcons.scanLine, color: AppColors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
