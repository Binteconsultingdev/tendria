import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Reacciones propias dibujadas como vectores: se ven igual en cualquier teléfono
/// (no dependen de las emojis del sistema).
class ReactionIcon extends StatelessWidget {
  final String type;
  final double size;

  const ReactionIcon({super.key, required this.type, this.size = 28});

  static const Map<String, String> labels = {
    'me_encanta': 'Me encanta',
    'me_gusta': 'Me gusta',
    'jaja': 'Me divierte',
    'wow': 'Me asombra',
    'triste': 'Me entristece',
    'fuego': 'Fuego',
  };

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'me_encanta':
        return _badge(const [Color(0xFFFF7A93), Color(0xFFE0244F)], Icons.favorite_rounded);
      case 'me_gusta':
        return _badge(const [Color(0xFF6CB8FF), Color(0xFF2F6BFF)], Icons.thumb_up_rounded);
      case 'fuego':
        return _badge(const [Color(0xFFFFB347), Color(0xFFFF4E2A)], Icons.local_fire_department_rounded);
      case 'jaja':
      case 'wow':
      case 'triste':
        return SizedBox(width: size, height: size, child: CustomPaint(painter: _FacePainter(type)));
      default:
        return SizedBox(width: size, height: size);
    }
  }

  Widget _badge(List<Color> colors, IconData icon) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
        boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: size * 0.22, offset: Offset(0, size * 0.08))],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.56),
    );
  }
}

class _FacePainter extends CustomPainter {
  final String kind;
  _FacePainter(this.kind);

  static const Color _ink = Color(0xFF4A2A0C);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;

    // Cara amarilla con degradado y un leve brillo
    final face = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFE680), Color(0xFFFFB62E)],
      ).createShader(rect);
    canvas.drawShadow(Path()..addOval(rect), const Color(0x55FF9A00), s * 0.06, false);
    canvas.drawCircle(rect.center, s / 2, face);

    final stroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = _ink;

    switch (kind) {
      case 'jaja':
        // Ojos felices ^ ^ y boca abierta con lengua
        for (final cx in [0.31, 0.69]) {
          canvas.drawArc(Rect.fromCenter(center: Offset(cx * s, 0.42 * s), width: s * 0.2, height: s * 0.2), math.pi, math.pi, false, stroke);
        }
        final mouth = Path()
          ..moveTo(0.22 * s, 0.55 * s)
          ..lineTo(0.78 * s, 0.55 * s)
          ..arcToPoint(Offset(0.22 * s, 0.55 * s), radius: Radius.circular(0.28 * s), clockwise: true)
          ..close();
        canvas.drawPath(mouth, fill);
        canvas.save();
        canvas.clipPath(mouth);
        canvas.drawOval(Rect.fromCenter(center: Offset(0.5 * s, 0.84 * s), width: s * 0.34, height: s * 0.22), Paint()..color = const Color(0xFFFF6F8E));
        canvas.restore();
        break;

      case 'wow':
        canvas.drawCircle(Offset(0.33 * s, 0.42 * s), s * 0.075, fill);
        canvas.drawCircle(Offset(0.67 * s, 0.42 * s), s * 0.075, fill);
        // Cejas levantadas
        canvas.drawArc(Rect.fromCenter(center: Offset(0.33 * s, 0.30 * s), width: s * 0.2, height: s * 0.12), math.pi * 1.1, math.pi * 0.8, false, stroke..strokeWidth = s * 0.05);
        canvas.drawArc(Rect.fromCenter(center: Offset(0.67 * s, 0.30 * s), width: s * 0.2, height: s * 0.12), math.pi * 1.1, math.pi * 0.8, false, stroke);
        canvas.drawOval(Rect.fromCenter(center: Offset(0.5 * s, 0.71 * s), width: s * 0.2, height: s * 0.28), fill);
        break;

      case 'triste':
        canvas.drawCircle(Offset(0.34 * s, 0.46 * s), s * 0.06, fill);
        canvas.drawCircle(Offset(0.66 * s, 0.46 * s), s * 0.06, fill);
        // Cejas caídas hacia afuera
        final brows = stroke..strokeWidth = s * 0.05;
        canvas.drawLine(Offset(0.24 * s, 0.37 * s), Offset(0.42 * s, 0.31 * s), brows);
        canvas.drawLine(Offset(0.76 * s, 0.37 * s), Offset(0.58 * s, 0.31 * s), brows);
        // Boca curvada hacia abajo
        canvas.drawArc(Rect.fromLTWH(0.32 * s, 0.62 * s, 0.36 * s, 0.32 * s), math.pi * 1.1, math.pi * 0.8, false, stroke..strokeWidth = s * 0.07);
        // Lágrima
        final tear = Path()
          ..moveTo(0.75 * s, 0.52 * s)
          ..quadraticBezierTo(0.83 * s, 0.64 * s, 0.75 * s, 0.70 * s)
          ..quadraticBezierTo(0.67 * s, 0.64 * s, 0.75 * s, 0.52 * s);
        canvas.drawPath(tear, Paint()..color = const Color(0xFF5CC2FF));
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) => old.kind != kind;
}
