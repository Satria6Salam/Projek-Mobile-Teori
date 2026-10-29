import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Latar belakang bergradasi lembut dengan lingkaran cahaya yang melayang pelan.
class AnimatedBackdrop extends StatefulWidget {
  const AnimatedBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedBackdrop> createState() => _AnimatedBackdropState();
}

class _AnimatedBackdropState extends State<AnimatedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFECFDF5),
                  AppColors.offWhite,
                  Color(0xFFF0FDFA),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double t = Curves.easeInOut.transform(_controller.value);
                return Stack(
                  children: [
                    Positioned(
                      top: -90 + 50 * t,
                      left: -70 + 40 * t,
                      child: const _Glow(
                        size: 280,
                        inner: Color(0x3310B981),
                        outer: Color(0x0010B981),
                      ),
                    ),
                    Positioned(
                      bottom: -110 + 40 * t,
                      right: -90 + 30 * (1 - t),
                      child: const _Glow(
                        size: 320,
                        inner: Color(0x2614B8A6),
                        outer: Color(0x0014B8A6),
                      ),
                    ),
                    Positioned(
                      top: 220 - 40 * t,
                      right: -60 + 20 * t,
                      child: const _Glow(
                        size: 180,
                        inner: Color(0x1F3B82F6),
                        outer: Color(0x003B82F6),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.inner, required this.outer});

  final double size;
  final Color inner;
  final Color outer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [inner, outer]),
      ),
    );
  }
}
