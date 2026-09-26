import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/features/feed/presentation/widget/post_style.dart';

/// Sticker colocado sobre la historia (se puede arrastrar y cambiar de tamaño).
class StorySticker {
  final String id;

  /// feeling:<id> | time | date | location | tag
  final String kind;
  final String text;
  Offset position; // relativa (0..1) al tamaño de la pantalla
  double scale;

  StorySticker({required this.kind, this.text = '', this.position = const Offset(0.5, 0.5), this.scale = 1.0, String? id})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();
}

/// Trazo dibujado a mano. Los puntos van en coordenadas relativas para que salgan igual al guardar la imagen.
class StoryStroke {
  final Color color;
  final double width;
  final List<Offset> points;

  StoryStroke({required this.color, required this.width, required this.points});
}

class StrokesPainter extends CustomPainter {
  final List<StoryStroke> strokes;
  StrokesPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (s.points.length == 1) {
        canvas.drawCircle(Offset(s.points.first.dx * size.width, s.points.first.dy * size.height), s.width / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(s.points.first.dx * size.width, s.points.first.dy * size.height);
      for (var i = 1; i < s.points.length; i++) {
        final p = s.points[i];
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokesPainter old) => true;
}

/// Filtros de color para fotos (matrices 5x4).
class StoryFilter {
  final String id;
  final String label;
  final List<double>? matrix;
  const StoryFilter(this.id, this.label, this.matrix);
}

class StoryFilters {
  static List<double> _saturation(double s) => [
        0.2126 + 0.7874 * s, 0.7152 - 0.7152 * s, 0.0722 - 0.0722 * s, 0, 0,
        0.2126 - 0.2126 * s, 0.7152 + 0.2848 * s, 0.0722 - 0.0722 * s, 0, 0,
        0.2126 - 0.2126 * s, 0.7152 - 0.7152 * s, 0.0722 + 0.9278 * s, 0, 0,
        0, 0, 0, 1, 0,
      ];

  static final List<StoryFilter> all = [
    const StoryFilter('none', 'Normal', null),
    StoryFilter('vivid', 'Vívido', _saturation(1.45)),
    const StoryFilter('warm', 'Cálido', [
      1.10, 0, 0, 0, 8,
      0, 1.0, 0, 0, 0,
      0, 0, 0.88, 0, -6,
      0, 0, 0, 1, 0,
    ]),
    const StoryFilter('cool', 'Frío', [
      0.90, 0, 0, 0, -4,
      0, 1.0, 0, 0, 2,
      0, 0, 1.12, 0, 10,
      0, 0, 0, 1, 0,
    ]),
    const StoryFilter('fade', 'Suave', [
      0.85, 0, 0, 0, 30,
      0, 0.85, 0, 0, 30,
      0, 0, 0.85, 0, 30,
      0, 0, 0, 1, 0,
    ]),
    const StoryFilter('sepia', 'Sepia', [
      0.393, 0.769, 0.189, 0, 0,
      0.349, 0.686, 0.168, 0, 0,
      0.272, 0.534, 0.131, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    const StoryFilter('bw', 'B/N', [
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    const StoryFilter('noir', 'Noir', [
      0.32, 1.02, 0.11, 0, -42,
      0.32, 1.02, 0.11, 0, -42,
      0.32, 1.02, 0.11, 0, -42,
      0, 0, 0, 1, 0,
    ]),
  ];

  static StoryFilter of(String id) => all.firstWhere((f) => f.id == id, orElse: () => all.first);

  /// Aplica el filtro al widget (sin filtro devuelve el mismo widget).
  static Widget apply(String id, Widget child) {
    final m = of(id).matrix;
    if (m == null) return child;
    return ColorFiltered(colorFilter: ColorFilter.matrix(m), child: child);
  }
}

/// Aspecto de cada tipo de sticker.
class StickerView extends StatelessWidget {
  final StorySticker sticker;
  const StickerView({super.key, required this.sticker});

  Widget _pill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFFE0245E)),
            const SizedBox(width: 7),
            Text(text, style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1B1B1F))),
          ],
        ),
      );

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    if (sticker.kind.startsWith('feeling:')) {
      final f = PostFeeling.of(sticker.kind.substring(8));
      if (f == null) return const SizedBox.shrink();
      return Container(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: f.colors.last.withValues(alpha: 0.5), blurRadius: 18)]),
        child: FeelingBadge(feeling: f, size: 78),
      );
    }
    switch (sticker.kind) {
      case 'time':
        return _pill(LucideIcons.clock, '${_two(now.hour)}:${_two(now.minute)}');
      case 'date':
        return _pill(LucideIcons.calendarDays, '${_two(now.day)}/${_two(now.month)}/${now.year}');
      case 'location':
        return _pill(LucideIcons.mapPin, sticker.text);
      case 'tag':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF9A5A), Color(0xFFE0245E)]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Text(sticker.text, style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Sticker arrastrable: un dedo lo mueve y dos dedos cambian su tamaño.
class DraggableSticker extends StatefulWidget {
  final StorySticker sticker;
  final bool selected;
  final ValueChanged<Offset> onMoved;
  final ValueChanged<double> onScaled;
  final VoidCallback onTap;

  const DraggableSticker({
    super.key,
    required this.sticker,
    required this.selected,
    required this.onMoved,
    required this.onScaled,
    required this.onTap,
  });

  @override
  State<DraggableSticker> createState() => _DraggableStickerState();
}

class _DraggableStickerState extends State<DraggableSticker> {
  late Offset _pos = widget.sticker.position;
  late double _scale = widget.sticker.scale;
  double _baseScale = 1;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned.fill(
      child: Align(
        alignment: Alignment(_pos.dx * 2 - 1, _pos.dy * 2 - 1),
        child: GestureDetector(
          onTap: widget.onTap,
          onScaleStart: (_) => _baseScale = _scale,
          onScaleUpdate: (d) {
            setState(() {
              if (d.scale != 1.0) _scale = (_baseScale * d.scale).clamp(0.4, 3.5);
              _pos = Offset(
                (_pos.dx + d.focalPointDelta.dx / size.width).clamp(0.02, 0.98),
                (_pos.dy + d.focalPointDelta.dy / size.height).clamp(0.03, 0.97),
              );
            });
          },
          onScaleEnd: (_) {
            widget.onMoved(_pos);
            widget.onScaled(_scale);
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: widget.selected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Transform.scale(scale: _scale, child: StickerView(sticker: widget.sticker)),
          ),
        ),
      ),
    );
  }
}

/// Hoja para elegir un sticker. Devuelve el tipo elegido (feeling:<id>, time, date, location o tag).
Future<String?> showStickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: const Color(0xFF16171B),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stickers', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final entry in const [
                  ('time', LucideIcons.clock, 'Hora'),
                  ('date', LucideIcons.calendarDays, 'Fecha'),
                  ('location', LucideIcons.mapPin, 'Ubicación'),
                  ('tag', LucideIcons.hash, 'Etiqueta'),
                ])
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(entry.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(entry.$2, size: 16, color: Colors.white),
                          const SizedBox(width: 7),
                          Text(entry.$3, style: GoogleFonts.rubik(fontSize: 13.5, fontWeight: FontWeight.w500, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Estados de ánimo', style: GoogleFonts.rubik(fontSize: 13, color: Colors.white60)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final f in PostFeeling.all)
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop('feeling:${f.id}'),
                    child: FeelingBadge(feeling: f, size: 50),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
