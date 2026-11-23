import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'fade_slide_in.dart';

/// Jenis ilustrasi tema. Digambar langsung dengan kode (tanpa berkas gambar),
/// sehingga ringan, tetap jalan offline, dan ikut animasi.
enum ThemeArtKind {
  receipt,
  wallet,
  bell,
  tags,
  backup,
  chart,
  history,
  profile,
  scan,
  cart,
}

/// Ilustrasi animasi: melayang terus-menerus, dan masuk sekali saat tampil.
class ThemeArt extends StatefulWidget {
  const ThemeArt({super.key, required this.kind, this.size = 88});

  final ThemeArtKind kind;
  final double size;

  @override
  State<ThemeArt> createState() => _ThemeArtState();
}

class _ThemeArtState extends State<ThemeArt> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_loop, _enter]),
        builder: (BuildContext context, Widget? child) {
          return CustomPaint(
            painter: _ArtPainter(
              kind: widget.kind,
              loop: _loop.value,
              enter: Curves.easeOutCubic.transform(_enter.value),
            ),
          );
        },
      ),
    );
  }
}

/// Header berwarna gradien dengan lingkaran dekoratif, judul, dan ilustrasi.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.kind,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final ThemeArtKind kind;

  /// Widget tambahan di bawah subjudul (mis. ringkasan angka).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return FadeSlideIn(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.emeraldDeep.withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.cardGradient,
            ),
            child: Stack(
              children: <Widget>[
                const Positioned(
                    right: -34, top: -36, child: _Bubble(size: 130)),
                const Positioned(
                    left: -24, bottom: -46, child: _Bubble(size: 100)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: textTheme.titleLarge?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.88),
                              ),
                            ),
                            if (trailing != null) ...<Widget>[
                              const SizedBox(height: 12),
                              trailing!,
                            ],
                          ],
                        ),
                      ),
                      ThemeArt(kind: kind, size: 84),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.09),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Penggambar seluruh ilustrasi. Koordinat dirancang pada kanvas 96x96.
class _ArtPainter extends CustomPainter {
  _ArtPainter({
    required this.kind,
    required this.loop,
    required this.enter,
  });

  final ThemeArtKind kind;
  final double loop; // 0..1, berulang
  final double enter; // 0..1, sekali saat tampil

  static const double _design = 96;
  static const Color _paper = Color(0xF7FFFFFF);
  static const Color _mint = Color(0xFFA7F3D0);
  static const Color _amber = Color(0xFFFBBF24);
  static const Color _deepEmerald = Color(0xFF0B5238);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _design, size.height / _design);
    final double wave = math.sin(loop * 2 * math.pi);
    switch (kind) {
      case ThemeArtKind.receipt:
        _receipt(canvas, wave);
      case ThemeArtKind.wallet:
        _wallet(canvas, wave);
      case ThemeArtKind.bell:
        _bell(canvas, wave);
      case ThemeArtKind.tags:
        _tags(canvas, wave);
      case ThemeArtKind.backup:
        _backup(canvas, wave);
      case ThemeArtKind.chart:
        _chart(canvas, wave);
      case ThemeArtKind.history:
        _history(canvas, wave);
      case ThemeArtKind.profile:
        _profile(canvas);
      case ThemeArtKind.scan:
        _scan(canvas, wave);
      case ThemeArtKind.cart:
        _cart(canvas, wave);
    }
    canvas.restore();
  }

  void _rr(Canvas c, Rect r, double radius, Color color) {
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      Paint()..color = color,
    );
  }

  void _shadowRr(Canvas c, Rect r, double radius) {
    c.drawRRect(
      RRect.fromRectAndRadius(
          r.shift(const Offset(0, 3)), Radius.circular(radius)),
      Paint()..color = const Color(0x22000000),
    );
  }

  void _receipt(Canvas c, double wave) {
    c.save();
    c.translate(0, (1 - enter) * 26 + wave * 2.2);

    // Kertas dengan tepi bergerigi di bawah.
    final Path paper = Path()
      ..moveTo(28, 12)
      ..lineTo(68, 12)
      ..lineTo(68, 80);
    const int teeth = 6;
    const double w = 40 / teeth;
    for (int i = 0; i < teeth; i++) {
      paper.lineTo(68 - w * i - w / 2, 74);
      paper.lineTo(68 - w * (i + 1), 80);
    }
    paper.close();
    c.drawShadow(paper, const Color(0x33000000), 4, false);
    c.drawPath(paper, Paint()..color = _paper);

    // Baris rincian muncul berurutan.
    for (int i = 0; i < 4; i++) {
      final double p = ((enter - 0.14 * i) / 0.5).clamp(0.0, 1.0).toDouble();
      final double width = (i == 3 ? 16 : 26) * p;
      _rr(c, Rect.fromLTWH(34, 24 + i * 9.0, width, 3.5), 2,
          const Color(0x6616855A));
    }

    // Garis total dan stempel yang berdenyut.
    _rr(c, const Rect.fromLTWH(34, 60, 24, 4), 2, _deepEmerald);
    final double stamp = ((enter - 0.7) / 0.3).clamp(0.0, 1.0).toDouble();
    final double radius =
        8 * Curves.easeOutBack.transform(stamp) + wave.abs() * 0.8;
    c.drawCircle(const Offset(62, 70), radius, Paint()..color = _amber);
    c.drawCircle(
      const Offset(62, 70),
      radius * 0.45,
      Paint()..color = _deepEmerald.withValues(alpha: stamp),
    );
    c.restore();
  }

  void _wallet(Canvas c, double wave) {
    // Koin jatuh ke dalam dompet, lalu menghilang di baliknya.
    for (int i = 0; i < 3; i++) {
      final double phase = (loop + i * 0.33) % 1.0;
      final double fall = Curves.easeIn.transform(phase);
      final double alpha = enter * (phase > 0.8 ? (1 - phase) / 0.2 : 1.0);
      c.drawCircle(
        Offset(38 + i * 11.0, 12 + fall * 34),
        6,
        Paint()
          ..color = _amber.withValues(alpha: alpha.clamp(0.0, 1.0).toDouble()),
      );
    }

    c.save();
    c.translate(0, (1 - enter) * 14 + wave * 1.2);
    final Rect body = const Rect.fromLTWH(14, 36, 68, 40);
    _shadowRr(c, body, 10);
    _rr(c, body, 10, _paper);
    _rr(c, const Rect.fromLTWH(56, 48, 30, 17), 6, _mint);
    c.drawCircle(const Offset(66, 56.5), 3.2, Paint()..color = _amber);
    c.restore();
  }

  void _bell(Canvas c, double wave) {
    final double angle = wave * 0.16 * enter;
    c.save();
    c.translate(48, 18);
    c.rotate(angle);
    c.translate(-48, -18);

    final Path bell = Path()
      ..moveTo(28, 62)
      ..quadraticBezierTo(30, 20, 48, 20)
      ..quadraticBezierTo(66, 20, 68, 62)
      ..lineTo(76, 70)
      ..lineTo(20, 70)
      ..close();
    c.drawPath(bell, Paint()..color = _paper);
    c.drawCircle(const Offset(48, 16), 4, Paint()..color = _mint);
    c.restore();

    c.drawCircle(const Offset(48, 80), 5, Paint()..color = _amber);

    // Garis getar di kiri dan kanan, mengikuti ayunan.
    final double strength = (wave.abs() * enter).clamp(0.0, 1.0).toDouble();
    final Paint arc = Paint()
      ..color = _paper.withValues(alpha: 0.7 * strength)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(14, 36), const Offset(9, 42), arc);
    c.drawLine(const Offset(82, 36), const Offset(87, 42), arc);
  }

  void _tags(Canvas c, double wave) {
    const List<Offset> spots = <Offset>[
      Offset(30, 32),
      Offset(66, 30),
      Offset(46, 60),
      Offset(72, 68),
    ];
    const List<Color> colors = <Color>[
      _mint,
      _amber,
      Color(0xFF7DD3FC),
      Color(0xFFF9A8D4)
    ];

    for (int i = 0; i < spots.length; i++) {
      final double p = ((enter - i * 0.12) / 0.5).clamp(0.0, 1.0).toDouble();
      final double scale = Curves.easeOutBack.transform(p);
      final double bob = math.sin((loop + i * 0.25) * 2 * math.pi) * 3;
      c.save();
      c.translate(spots[i].dx, spots[i].dy + bob);
      c.scale(scale);
      c.drawCircle(Offset.zero, 14, Paint()..color = colors[i]);
      c.drawCircle(Offset.zero, 4.5, Paint()..color = _paper);
      c.restore();
    }
  }

  void _backup(Canvas c, double wave) {
    // Panah naik-turun di atas dokumen.
    final double arrowY = 12 + wave * -3;
    final double arrowAlpha = enter.clamp(0.0, 1.0).toDouble();
    final Paint arrow = Paint()..color = _amber.withValues(alpha: arrowAlpha);
    c.save();
    c.translate(0, arrowY);
    c.drawPath(
      Path()
        ..moveTo(38, 14)
        ..lineTo(48, 4)
        ..lineTo(58, 14)
        ..close(),
      arrow,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(46.5, 12, 3, 12), const Radius.circular(1.5)),
      arrow,
    );
    c.restore();

    // Dokumen dan baki di bawahnya.
    c.save();
    c.translate(0, (1 - enter) * 10);
    const Rect doc = Rect.fromLTWH(34, 38, 28, 30);
    _shadowRr(c, doc, 4);
    _rr(c, doc, 4, _paper);
    for (int i = 0; i < 3; i++) {
      _rr(c, Rect.fromLTWH(40, 46 + i * 7.0, 16 - i * 3.0, 3), 1.5,
          const Color(0x6616855A));
    }
    c.restore();
    _rr(c, const Rect.fromLTWH(18, 72, 60, 6), 3,
        _paper.withValues(alpha: 0.6));
  }

  void _chart(Canvas c, double wave) {
    // Batang grafik tumbuh bergantian, satu batang disorot.
    const List<double> base = <double>[0.45, 0.7, 0.5, 0.85, 0.62];
    for (int i = 0; i < base.length; i++) {
      final double grow = ((enter - i * 0.1) / 0.55).clamp(0.0, 1.0).toDouble();
      final double pulse = math.sin((loop + i * 0.18) * 2 * math.pi) * 0.06;
      final double h =
          54 * (base[i] + pulse) * Curves.easeOutCubic.transform(grow);
      final bool focus = i == 3;
      _rr(c, Rect.fromLTWH(16 + i * 14.0, 78 - h, 9, h), 4.5,
          focus ? _amber : _paper.withValues(alpha: 0.85));
    }
    _rr(c, const Rect.fromLTWH(12, 80, 72, 3), 1.5,
        _paper.withValues(alpha: 0.5));
    // Lencana nilai di atas batang sorotan.
    final double tag = ((enter - 0.6) / 0.4).clamp(0.0, 1.0).toDouble();
    if (tag > 0) {
      final double y = 10 + wave * 2;
      _rr(c, Rect.fromLTWH(50, y, 28, 12), 6, _paper.withValues(alpha: tag));
      _rr(c, Rect.fromLTWH(55, y + 4.5, 18, 3), 1.5,
          _deepEmerald.withValues(alpha: tag));
    }
  }

  void _history(Canvas c, double wave) {
    // Tumpukan struk di belakang dan jam dengan jarum berputar.
    c.save();
    c.translate(0, (1 - enter) * 16);
    for (int i = 2; i >= 0; i--) {
      c.save();
      c.translate(16 + i * 6.0, 14 + i * 5.0 + wave * (i + 1) * 0.6);
      c.rotate((-0.12 + i * 0.08) * enter);
      const Rect r = Rect.fromLTWH(0, 0, 34, 44);
      _shadowRr(c, r, 5);
      _rr(c, r, 5, _paper.withValues(alpha: 0.75 + i * 0.08));
      for (int j = 0; j < 3; j++) {
        _rr(c, Rect.fromLTWH(6, 9 + j * 8.0, 22 - j * 4.0, 3), 1.5,
            const Color(0x5516855A));
      }
      c.restore();
    }
    c.restore();

    final double clock = Curves.easeOutBack
        .transform(((enter - 0.3) / 0.7).clamp(0.0, 1.0).toDouble());
    const Offset center = Offset(66, 66);
    c.drawCircle(center, 17 * clock, Paint()..color = _amber);
    c.drawCircle(center, 13 * clock, Paint()..color = _paper);
    final Paint hand = Paint()
      ..color = _deepEmerald
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final double a = loop * 2 * math.pi - math.pi / 2;
    c.drawLine(
        center, center + Offset(math.cos(a), math.sin(a)) * 9 * clock, hand);
    c.drawLine(center, center + const Offset(0, -6) * clock, hand);
    c.drawCircle(center, 2.2 * clock, Paint()..color = _deepEmerald);
  }

  void _profile(Canvas c) {
    // Perisai dengan centang, cincin berdenyut, dan bintang berkilau.
    final double wave = math.sin(loop * 2 * math.pi);
    c.drawCircle(
      const Offset(48, 47),
      26 + loop * 18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _paper.withValues(alpha: (1 - loop) * 0.5 * enter),
    );

    c.save();
    c.translate(0, (1 - enter) * 18 + wave * 1.8);
    final Path shield = Path()
      ..moveTo(48, 18)
      ..lineTo(70, 26)
      ..quadraticBezierTo(70, 62, 48, 76)
      ..quadraticBezierTo(26, 62, 26, 26)
      ..close();
    c.drawShadow(shield, const Color(0x33000000), 4, false);
    c.drawPath(shield, Paint()..color = _paper);
    final double tick = ((enter - 0.45) / 0.45).clamp(0.0, 1.0).toDouble();
    final Path check = Path()
      ..moveTo(38, 47)
      ..lineTo(45, 54)
      ..lineTo(59, 39);
    final Paint checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _deepEmerald;
    for (final PathMetric metric in check.computeMetrics()) {
      c.drawPath(metric.extractPath(0, metric.length * tick), checkPaint);
    }
    c.restore();

    for (int i = 0; i < 2; i++) {
      final double t = math.sin((loop + i * 0.5) * 2 * math.pi).abs();
      final Offset o = i == 0 ? const Offset(80, 20) : const Offset(16, 72);
      _sparkle(c, o, (2.5 + t * 3) * enter);
    }
  }

  void _scan(Canvas c, double wave) {
    // Ponsel dengan struk di layar dan garis pindai yang menyapu.
    c.save();
    c.translate(0, (1 - enter) * 20 + wave * 1.5);
    const Rect phone = Rect.fromLTWH(28, 10, 40, 76);
    _shadowRr(c, phone, 9);
    _rr(c, phone, 9, _deepEmerald);
    _rr(c, phone.deflate(3.5), 6.5, _paper);
    for (int i = 0; i < 5; i++) {
      _rr(c, Rect.fromLTWH(37, 24 + i * 9.0, i == 4 ? 12 : 22, 3), 1.5,
          const Color(0x5516855A));
    }
    final double y = 18 + (math.sin(loop * 2 * math.pi) * 0.5 + 0.5) * 58;
    final Rect glow = Rect.fromLTWH(31.5, y - 8, 33, 8);
    c.drawRect(
      glow,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x0034C38A), Color(0x8834C38A)],
        ).createShader(glow),
    );
    _rr(c, Rect.fromLTWH(31.5, y, 33, 2), 1, _amber);
    c.restore();

    // Sudut bingkai pindai di luar ponsel.
    final Paint corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = _paper.withValues(alpha: 0.8 * enter);
    const double g = 7;
    for (final Offset o in const <Offset>[
      Offset(16, 4),
      Offset(80, 4),
      Offset(16, 92),
      Offset(80, 92),
    ]) {
      final double dx = o.dx < 48 ? g : -g;
      final double dy = o.dy < 48 ? g : -g;
      c.drawLine(o, o + Offset(dx, 0), corner);
      c.drawLine(o, o + Offset(0, dy), corner);
    }
  }

  void _cart(Canvas c, double wave) {
    // Troli belanja yang bergoyang, barang masuk satu per satu, dan centang.
    c.save();
    c.translate((1 - enter) * -20 + wave * 1.5, 0);
    final Paint frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _paper;
    c.drawPath(
      Path()
        ..moveTo(10, 26)
        ..lineTo(20, 26)
        ..lineTo(28, 64)
        ..lineTo(72, 64),
      frame,
    );
    // Barang di dalam troli (masuk bergantian).
    const List<Color> goods = <Color>[_mint, _amber, Color(0xFF7DD3FC)];
    for (int i = 0; i < 3; i++) {
      final double p = ((enter - 0.2 - i * 0.15) / 0.4).clamp(0.0, 1.0);
      final double drop = (1 - Curves.easeOutBack.transform(p)) * -30;
      final double bob = math.sin((loop + i * 0.3) * 2 * math.pi) * 1.2;
      _rr(c, Rect.fromLTWH(30 + i * 13.0, 36 + drop + bob, 11, 18), 3,
          goods[i].withValues(alpha: p));
    }
    c.drawPath(
      Path()
        ..moveTo(22, 32)
        ..lineTo(78, 32)
        ..lineTo(72, 56)
        ..lineTo(27, 56)
        ..close(),
      frame..strokeWidth = 3.5,
    );
    final double spin = loop * 2 * math.pi;
    for (final double x in const <double>[34, 66]) {
      c.drawCircle(Offset(x, 74), 6, Paint()..color = _paper);
      c.drawCircle(
        Offset(x + math.cos(spin) * 2.5, 74 + math.sin(spin) * 2.5),
        1.6,
        Paint()..color = _deepEmerald,
      );
    }
    c.restore();

    // Lencana centang (barang rencana sudah dibeli).
    final double tick = Curves.easeOutBack
        .transform(((enter - 0.65) / 0.35).clamp(0.0, 1.0).toDouble());
    if (tick > 0) {
      const Offset o = Offset(78, 20);
      c.drawCircle(o, 11 * tick, Paint()..color = _amber);
      final Paint check = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = _deepEmerald;
      c.drawPath(
        Path()
          ..moveTo(o.dx - 5 * tick, o.dy)
          ..lineTo(o.dx - 1 * tick, o.dy + 4 * tick)
          ..lineTo(o.dx + 5 * tick, o.dy - 4 * tick),
        check,
      );
    }
  }

  void _sparkle(Canvas c, Offset o, double r) {
    if (r <= 0) return;
    final double k = r * 1.6;
    final Path p = Path()
      ..moveTo(o.dx, o.dy - k)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + k, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + k)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - k, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - k)
      ..close();
    c.drawPath(p, Paint()..color = _amber);
  }

  @override
  bool shouldRepaint(covariant _ArtPainter old) {
    return old.loop != loop || old.enter != enter || old.kind != kind;
  }
}
