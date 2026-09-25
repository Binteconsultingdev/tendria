import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Regalos dibujados como vectores (no dependen de las emojis del sistema).
class GiftIcon extends StatelessWidget {
  final String code;
  final double size;

  const GiftIcon({super.key, required this.code, this.size = 56});

  static const known = {'rosa', 'corazon', 'ramo', 'osito', 'diamante', 'corona'};

  @override
  Widget build(BuildContext context) {
    if (!known.contains(code)) {
      return SizedBox(width: size, height: size, child: Icon(LucideIcons.gift, size: size * 0.7));
    }
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _GiftPainter(code)));
  }
}

class _GiftPainter extends CustomPainter {
  final String code;
  _GiftPainter(this.code);

  // Todo se dibuja en una cuadrícula de 100 x 100 y se escala al tamaño del widget.
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    switch (code) {
      case 'rosa':
        _rose(canvas);
        break;
      case 'corazon':
        _heart(canvas);
        break;
      case 'ramo':
        _bouquet(canvas);
        break;
      case 'osito':
        _bear(canvas);
        break;
      case 'diamante':
        _diamond(canvas);
        break;
      case 'corona':
        _crown(canvas);
        break;
    }
  }

  Paint _fill(Color c) => Paint()..color = c;

  Paint _grad(Rect r, Color a, Color b, {bool vertical = true}) => Paint()
    ..shader = LinearGradient(
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: [a, b],
    ).createShader(r);

  void _leaf(Canvas c, Offset base, Offset tip, double bend) {
    final mid = Offset((base.dx + tip.dx) / 2, (base.dy + tip.dy) / 2);
    final p = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(mid.dx + bend, mid.dy - 8, tip.dx, tip.dy)
      ..quadraticBezierTo(mid.dx - bend, mid.dy + 8, base.dx, base.dy);
    c.drawPath(p, _grad(p.getBounds(), const Color(0xFF6BD68A), const Color(0xFF1E9E55)));
  }

  void _rose(Canvas c) {
    c.drawLine(const Offset(50, 56), const Offset(50, 94),
        Paint()..color = const Color(0xFF2FAE60)..strokeWidth = 4.5..strokeCap = StrokeCap.round);
    _leaf(c, const Offset(50, 80), const Offset(76, 66), 6);
    _leaf(c, const Offset(50, 72), const Offset(24, 60), -6);

    const center = Offset(50, 36);
    c.drawCircle(center, 27, _grad(Rect.fromCircle(center: center, radius: 27), const Color(0xFFFF6B8A), const Color(0xFFB80F3A)));
    c.drawCircle(const Offset(50, 37), 19, _grad(Rect.fromCircle(center: const Offset(50, 37), radius: 19), const Color(0xFFFF4D72), const Color(0xFFD01446)));
    c.drawCircle(const Offset(50, 38), 11, _grad(Rect.fromCircle(center: const Offset(50, 38), radius: 11), const Color(0xFFFF7A96), const Color(0xFFE0245E)));

    final line = Paint()
      ..color = const Color(0xFF8C0A2A).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    c.drawArc(Rect.fromCircle(center: const Offset(50, 38), radius: 11), math.pi * 0.1, math.pi * 1.1, false, line);
    c.drawArc(Rect.fromCircle(center: const Offset(50, 37), radius: 19), math.pi * 1.15, math.pi * 1.0, false, line);
  }

  void _heart(Canvas c) {
    final p = Path()
      ..moveTo(50, 88)
      ..cubicTo(8, 58, 6, 26, 30, 20)
      ..cubicTo(42, 17, 50, 26, 50, 33)
      ..cubicTo(50, 26, 58, 17, 70, 20)
      ..cubicTo(94, 26, 92, 58, 50, 88)
      ..close();
    c.drawShadow(p, const Color(0xFFE0245E), 4, false);
    c.drawPath(p, _grad(p.getBounds(), const Color(0xFFFF7A93), const Color(0xFFD9174F)));
    c.drawOval(Rect.fromCenter(center: const Offset(33, 33), width: 16, height: 10), _fill(Colors.white.withValues(alpha: 0.35)));
  }

  void _bouquet(Canvas c) {
    // Hojas
    _leaf(c, const Offset(50, 56), const Offset(20, 40), -5);
    _leaf(c, const Offset(50, 56), const Offset(80, 40), 5);

    void flower(Offset o, double r, Color petal, Color core) {
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * (r * 0.62), r * 0.5, _fill(petal));
      }
      c.drawCircle(o, r * 0.42, _fill(core));
    }

    flower(const Offset(33, 36), 15, const Color(0xFFFF8FB3), const Color(0xFFFFE066));
    flower(const Offset(67, 36), 15, const Color(0xFFFFC24B), const Color(0xFFFF7A2F));
    flower(const Offset(50, 24), 16, const Color(0xFFFF5677), const Color(0xFFFFE066));

    // Papel de envolver
    final paper = Path()
      ..moveTo(50, 94)
      ..lineTo(20, 50)
      ..quadraticBezierTo(50, 60, 80, 50)
      ..close();
    c.drawPath(paper, _grad(paper.getBounds(), const Color(0xFFB794F6), const Color(0xFF7C4DDB)));
    // Moño
    c.drawOval(Rect.fromCenter(center: const Offset(40, 70), width: 16, height: 10), _fill(const Color(0xFFFFE066)));
    c.drawOval(Rect.fromCenter(center: const Offset(60, 70), width: 16, height: 10), _fill(const Color(0xFFFFE066)));
    c.drawCircle(const Offset(50, 70), 4.5, _fill(const Color(0xFFF2A900)));
  }

  void _bear(Canvas c) {
    const brown = Color(0xFFB07445);
    const tan = Color(0xFFEBC9A3);

    // Cuerpo
    c.drawOval(Rect.fromCenter(center: const Offset(50, 82), width: 46, height: 32), _grad(const Rect.fromLTWH(27, 66, 46, 32), const Color(0xFFC08355), const Color(0xFF9A6236)));
    // Orejas
    for (final x in [27.0, 73.0]) {
      c.drawCircle(Offset(x, 26), 12, _fill(brown));
      c.drawCircle(Offset(x, 26), 6.5, _fill(tan));
    }
    // Cabeza
    c.drawCircle(const Offset(50, 46), 28, _grad(Rect.fromCircle(center: const Offset(50, 46), radius: 28), const Color(0xFFC98B5C), const Color(0xFF9F673A)));
    // Hocico
    c.drawOval(Rect.fromCenter(center: const Offset(50, 56), width: 22, height: 17), _fill(tan));
    c.drawOval(Rect.fromCenter(center: const Offset(50, 51), width: 9, height: 6), _fill(const Color(0xFF4A2A18)));
    // Ojos y sonrisa
    c.drawCircle(const Offset(39, 42), 3.2, _fill(const Color(0xFF3A2010)));
    c.drawCircle(const Offset(61, 42), 3.2, _fill(const Color(0xFF3A2010)));
    c.drawCircle(const Offset(40, 41), 1, _fill(Colors.white));
    c.drawCircle(const Offset(62, 41), 1, _fill(Colors.white));
    c.drawArc(Rect.fromCenter(center: const Offset(50, 57), width: 12, height: 8), 0.2, math.pi - 0.4, false,
        Paint()..color = const Color(0xFF4A2A18)..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.round);
    // Moño
    final bow = Path()
      ..moveTo(50, 72)
      ..lineTo(38, 66)
      ..lineTo(38, 78)
      ..close()
      ..moveTo(50, 72)
      ..lineTo(62, 66)
      ..lineTo(62, 78)
      ..close();
    c.drawPath(bow, _fill(const Color(0xFFE0244F)));
    c.drawCircle(const Offset(50, 72), 4, _fill(const Color(0xFFB80F3A)));
  }

  void _diamond(Canvas c) {
    const top1 = Offset(32, 26), top2 = Offset(68, 26);
    const l = Offset(10, 46), r = Offset(90, 46);
    const m1 = Offset(38, 46), m2 = Offset(62, 46);
    const bottom = Offset(50, 92);

    Path poly(List<Offset> pts) {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      return p..close();
    }

    final all = poly([top1, top2, r, bottom, l]);
    c.drawShadow(all, const Color(0xFF2F9BFF), 5, false);

    c.drawPath(poly([top1, top2, m2, m1]), _fill(const Color(0xFFBDF3FF)));
    c.drawPath(poly([top1, m1, l]), _fill(const Color(0xFF8FE3FF)));
    c.drawPath(poly([top2, r, m2]), _fill(const Color(0xFF6FCBFF)));
    c.drawPath(poly([l, m1, bottom]), _fill(const Color(0xFF4FB4FF)));
    c.drawPath(poly([m1, m2, bottom]), _fill(const Color(0xFF7AD2FF)));
    c.drawPath(poly([m2, r, bottom]), _fill(const Color(0xFF2F8CF0)));

    c.drawPath(
      all,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round,
    );
    // Destello
    c.drawCircle(const Offset(44, 35), 2.4, _fill(Colors.white));
  }

  void _crown(Canvas c) {
    final body = Path()
      ..moveTo(16, 76)
      ..lineTo(10, 32)
      ..lineTo(32, 52)
      ..lineTo(50, 22)
      ..lineTo(68, 52)
      ..lineTo(90, 32)
      ..lineTo(84, 76)
      ..close();
    c.drawShadow(body, const Color(0xFFF2A900), 5, false);
    c.drawPath(body, _grad(body.getBounds(), const Color(0xFFFFE680), const Color(0xFFF0A100)));

    // Banda inferior
    final band = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 70, 72, 14), const Radius.circular(4));
    c.drawRRect(band, _grad(band.outerRect, const Color(0xFFFFCF40), const Color(0xFFD78A00)));

    // Puntas y joyas
    for (final o in const [Offset(10, 30), Offset(50, 20), Offset(90, 30)]) {
      c.drawCircle(o, 5, _fill(const Color(0xFFFFF0A8)));
      c.drawCircle(o, 5, Paint()..color = const Color(0xFFD78A00)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }
    c.drawCircle(const Offset(50, 62), 6, _fill(const Color(0xFFE0244F)));
    c.drawCircle(const Offset(32, 77), 3.6, _fill(const Color(0xFF3B82F6)));
    c.drawCircle(const Offset(68, 77), 3.6, _fill(const Color(0xFF22C55E)));
    c.drawCircle(const Offset(48, 60), 1.6, _fill(Colors.white.withValues(alpha: 0.8)));
  }

  @override
  bool shouldRepaint(covariant _GiftPainter old) => old.code != code;
}
