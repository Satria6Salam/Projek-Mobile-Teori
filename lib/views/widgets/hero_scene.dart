import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Ilustrasi besar beranimasi untuk halaman Login dan Daftar.
///
/// Digambar dengan kode (tanpa berkas gambar): langit senja dengan matahari,
/// siluet kota, ponsel yang memindai struk, koin melayang, kartu grafik kecil,
/// dan daun yang bergoyang. Ringan dan tetap berjalan offline.
class HeroScene extends StatefulWidget {
  const HeroScene({super.key, this.height = 260});

  final double height;

  @override
  State<HeroScene> createState() => _HeroSceneState();
}

class _HeroSceneState extends State<HeroScene> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _loop.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_loop, _enter]),
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _HeroPainter(
              loop: _loop.value,
              enter: Curves.easeOutCubic.transform(_enter.value),
            ),
          );
        },
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter({required this.loop, required this.enter});

  final double loop; // 0..1 berulang
  final double enter; // 0..1 sekali

  static const double _w = 360;
  static const double _h = 260;

  static const Color _sky1 = Color(0xFFFDE7C8);
  static const Color _sky2 = Color(0xFFE3F4EA);
  static const Color _sun = Color(0xFFFFC56B);
  static const Color _city1 = Color(0xFFB9DCC8);
  static const Color _city2 = Color(0xFF8FC6A7);
  static const Color _paper = Color(0xFFFFFFFF);
  static const Color _amber = Color(0xFFFBBF24);
  static const Color _leaf1 = Color(0xFF1E9A68);
  static const Color _leaf2 = Color(0xFF0F6B47);

  double _wave(double offset, [double speed = 1]) =>
      math.sin((loop * speed + offset) * 2 * math.pi);

  @override
  void paint(Canvas canvas, Size size) {
    // Skala "cover" agar adegan mengisi lebar tanpa terdistorsi.
    final double scale = math.max(size.width / _w, size.height / _h);
    final double dx = (size.width - _w * scale) / 2;
    final double dy = (size.height - _h * scale) / 2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(dx, dy);
    canvas.scale(scale);

    _sky(canvas);
    _clouds(canvas);
    _skyline(canvas);
    _ground(canvas);
    _plant(canvas, const Offset(40, 236), 1.0, 0);
    _plant(canvas, const Offset(322, 240), 0.8, 0.4);
    _phone(canvas);
    _chartCard(canvas);
    _coins(canvas);

    canvas.restore();
  }

  void _sky(Canvas c) {
    const Rect r = Rect.fromLTWH(0, 0, _w, _h);
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[_sky1, _sky2],
        ).createShader(r),
    );
    // Matahari dengan cahaya berdenyut.
    final double glow = 0.5 + 0.5 * _wave(0);
    const Offset sun = Offset(250, 92);
    c.drawCircle(
        sun, 52 + glow * 6, Paint()..color = _sun.withValues(alpha: 0.18));
    c.drawCircle(sun, 34, Paint()..color = _sun.withValues(alpha: 0.9));
  }

  void _clouds(Canvas c) {
    final Paint p = Paint()..color = _paper.withValues(alpha: 0.85);
    for (int i = 0; i < 2; i++) {
      final double x = ((loop + i * 0.5) % 1.0) * (_w + 120) - 80;
      final double y = 40.0 + i * 34;
      c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 70 - i * 14.0, 16), const Radius.circular(8)),
        p,
      );
      c.drawCircle(Offset(x + 22, y + 2), 12 - i * 2.0, p);
      c.drawCircle(Offset(x + 40, y), 9 - i * 2.0, p);
    }
  }

  void _skyline(Canvas c) {
    final double rise = (1 - enter) * 40;
    c.save();
    c.translate(0, rise);
    // Lapis belakang.
    const List<List<double>> back = <List<double>>[
      <double>[0, 150, 34],
      <double>[30, 128, 26],
      <double>[54, 160, 30],
      <double>[200, 120, 28],
      <double>[226, 146, 34],
      <double>[262, 112, 24],
      <double>[284, 140, 36],
      <double>[318, 124, 42],
    ];
    for (final List<double> b in back) {
      c.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(b[0], b[1], b[2], _h - b[1]),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3)),
        Paint()..color = _city1,
      );
    }
    // Lapis depan dengan jendela.
    const List<List<double>> front = <List<double>>[
      <double>[10, 176, 30],
      <double>[38, 160, 22],
      <double>[236, 168, 26],
      <double>[290, 158, 30],
      <double>[322, 178, 38],
    ];
    for (final List<double> b in front) {
      c.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(b[0], b[1], b[2], _h - b[1]),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3)),
        Paint()..color = _city2,
      );
      for (double y = b[1] + 8; y < 220; y += 12) {
        for (double x = b[0] + 5; x < b[0] + b[2] - 6; x += 8) {
          c.drawRect(Rect.fromLTWH(x, y, 3.5, 5),
              Paint()..color = _paper.withValues(alpha: 0.55));
        }
      }
    }
    c.restore();
  }

  void _ground(Canvas c) {
    final Path hill = Path()
      ..moveTo(0, 222)
      ..quadraticBezierTo(90, 204, 180, 216)
      ..quadraticBezierTo(270, 228, _w, 210)
      ..lineTo(_w, _h)
      ..lineTo(0, _h)
      ..close();
    c.drawPath(hill, Paint()..color = const Color(0xFFCDEBDA));
  }

  void _plant(Canvas c, Offset base, double s, double phase) {
    final double sway = _wave(phase, 1) * 0.08 * enter;
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(s * enter);
    for (int i = 0; i < 5; i++) {
      final double a = -math.pi / 2 + (i - 2) * 0.42 + sway * (1 + i * 0.2);
      c.save();
      c.rotate(a + math.pi / 2);
      final Path leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(14, -26, 0, -54 + (i % 2) * 8)
        ..quadraticBezierTo(-14, -26, 0, 0)
        ..close();
      c.drawPath(leaf, Paint()..color = i.isEven ? _leaf1 : _leaf2);
      c.restore();
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-14, -4, 28, 18), const Radius.circular(5)),
      Paint()..color = const Color(0xFFE8B98A),
    );
    c.restore();
  }

  void _phone(Canvas c) {
    final double bob = _wave(0.1) * 4;
    c.save();
    c.translate(0, (1 - enter) * 70 + bob);
    c.translate(180, 140);
    c.rotate(-0.08);
    const Rect body = Rect.fromLTWH(-48, -92, 96, 180);
    c.drawRRect(
      RRect.fromRectAndRadius(
          body.shift(const Offset(6, 10)), const Radius.circular(20)),
      Paint()..color = const Color(0x22083D2A),
    );
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(20)),
        Paint()..color = AppColors.forest);
    final Rect screen = body.deflate(6);
    c.drawRRect(RRect.fromRectAndRadius(screen, const Radius.circular(15)),
        Paint()..color = const Color(0xFFF4F7F5));
    // Notch.
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-14, -84, 28, 6), const Radius.circular(3)),
      Paint()..color = AppColors.forest,
    );

    // Struk di layar.
    final Path receipt = Path()
      ..moveTo(-30, -64)
      ..lineTo(30, -64)
      ..lineTo(30, 52);
    const int teeth = 8;
    const double tw = 60 / teeth;
    for (int i = 0; i < teeth; i++) {
      receipt.lineTo(30 - tw * i - tw / 2, 46);
      receipt.lineTo(30 - tw * (i + 1), 52);
    }
    receipt.close();
    c.drawShadow(receipt, const Color(0x33000000), 3, false);
    c.drawPath(receipt, Paint()..color = _paper);
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-20, -54, 40, 6), const Radius.circular(3)),
      Paint()..color = AppColors.emerald,
    );
    for (int i = 0; i < 5; i++) {
      final double p = ((enter - 0.3 - i * 0.08) / 0.4).clamp(0.0, 1.0);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-22, -38 + i * 12.0, 30 * p, 4),
            const Radius.circular(2)),
        Paint()..color = const Color(0x5516855A),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(12, -38 + i * 12.0, 10 * p, 4),
            const Radius.circular(2)),
        Paint()..color = const Color(0x3316855A),
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-22, 26, 44, 6), const Radius.circular(3)),
      Paint()..color = AppColors.emeraldDeep,
    );

    // Garis pindai yang menyapu naik-turun.
    final double t = _wave(0, 2) * 0.5 + 0.5;
    final double y = -66 + t * 118;
    final Rect glow = Rect.fromLTWH(-40, y - 14, 80, 14);
    c.drawRect(
      glow,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x0034C38A), Color(0x6634C38A)],
        ).createShader(glow),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-40, y, 80, 2.5), const Radius.circular(2)),
      Paint()..color = AppColors.emeraldLight,
    );
    c.restore();
  }

  void _chartCard(Canvas c) {
    final double p = ((enter - 0.4) / 0.6).clamp(0.0, 1.0);
    if (p <= 0) return;
    final double bob = _wave(0.35) * 5;
    c.save();
    c.translate(262, 150 + bob + (1 - p) * 30);
    c.scale(Curves.easeOutBack.transform(p));
    const Rect card = Rect.fromLTWH(-34, -30, 72, 58);
    c.drawRRect(
      RRect.fromRectAndRadius(
          card.shift(const Offset(0, 4)), const Radius.circular(12)),
      Paint()..color = const Color(0x1F083D2A),
    );
    c.drawRRect(RRect.fromRectAndRadius(card, const Radius.circular(12)),
        Paint()..color = _paper);
    const List<double> bars = <double>[0.4, 0.65, 0.5, 0.9];
    for (int i = 0; i < bars.length; i++) {
      final double h = 30 * bars[i] * (0.85 + 0.15 * _wave(i * 0.2, 1));
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-24 + i * 15.0, 18 - h, 9, h),
            const Radius.circular(4)),
        Paint()..color = i == 3 ? AppColors.emerald : AppColors.mint,
      );
    }
    c.restore();
  }

  void _coins(Canvas c) {
    const List<Offset> spots = <Offset>[
      Offset(96, 92),
      Offset(118, 168),
      Offset(306, 84),
    ];
    for (int i = 0; i < spots.length; i++) {
      final double p = ((enter - 0.5 - i * 0.1) / 0.5).clamp(0.0, 1.0);
      if (p <= 0) continue;
      final double bob = _wave(i * 0.33, 1) * 7;
      final double spin = (_wave(i * 0.2, 2)).abs() * 0.6 + 0.4;
      final Offset o = spots[i] + Offset(0, bob);
      final double r = 13 * Curves.easeOutBack.transform(p) - i * 1.5;
      c.save();
      c.translate(o.dx, o.dy);
      c.scale(spin, 1);
      c.drawCircle(
          const Offset(0, 2), r, Paint()..color = const Color(0xFFD99A0B));
      c.drawCircle(Offset.zero, r, Paint()..color = _amber);
      c.drawCircle(
          Offset.zero, r * 0.62, Paint()..color = const Color(0xFFFCD34D));
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: 'Rp',
          style: TextStyle(
            fontSize: r * 0.62,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFB45309),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HeroPainter old) =>
      old.loop != loop || old.enter != enter;
}
