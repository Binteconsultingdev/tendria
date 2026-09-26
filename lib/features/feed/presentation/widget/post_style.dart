import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Fondos de color para publicaciones de texto. Los ids coinciden con los que acepta el API.
class PostBackground {
  final String id;
  final List<Color> colors;
  final Color textColor;

  const PostBackground(this.id, this.colors, {this.textColor = Colors.white});

  static const List<PostBackground> all = [
    PostBackground('sunset', [Color(0xFFFF9A5A), Color(0xFFE0245E)]),
    PostBackground('ocean', [Color(0xFF3AB0FF), Color(0xFF3A47D5)]),
    PostBackground('forest', [Color(0xFF3DDC97), Color(0xFF0B6E4F)]),
    PostBackground('violet', [Color(0xFFB86CFF), Color(0xFF5B2BD9)]),
    PostBackground('midnight', [Color(0xFF2A2F4F), Color(0xFF0B0D1A)]),
    PostBackground('rose', [Color(0xFFFF8FB1), Color(0xFFD6336C)]),
    PostBackground('gold', [Color(0xFFFFD86B), Color(0xFFE08E0B)], textColor: Color(0xFF3B2600)),
    PostBackground('mint', [Color(0xFFB8F2E6), Color(0xFF5FC9B4)], textColor: Color(0xFF0B3B33)),
    PostBackground('fire', [Color(0xFFFF6B35), Color(0xFFB80F0A)]),
    PostBackground('graphite', [Color(0xFF4B5563), Color(0xFF1F2937)]),
    PostBackground('sky', [Color(0xFFCFE8FF), Color(0xFF8EC5FF)], textColor: Color(0xFF0B2A4A)),
    PostBackground('lavender', [Color(0xFFE9D8FF), Color(0xFFC3A6FF)], textColor: Color(0xFF2C1A55)),
  ];

  static PostBackground? of(String? id) {
    if (id == null) return null;
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }

  LinearGradient get gradient => LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors);
}

/// "Cómo te sientes": iconos vectoriales con degradado (no dependen de las emojis del sistema).
class PostFeeling {
  final String id;
  final IconData icon;
  final List<Color> colors;

  const PostFeeling(this.id, this.icon, this.colors);

  static const List<PostFeeling> all = [
    PostFeeling('feliz', LucideIcons.smile, [Color(0xFFFFD36B), Color(0xFFFF9F1C)]),
    PostFeeling('enamorado', LucideIcons.heart, [Color(0xFFFF7A93), Color(0xFFE0244F)]),
    PostFeeling('agradecido', LucideIcons.handHeart, [Color(0xFFFFA8C5), Color(0xFFE05A93)]),
    PostFeeling('emocionado', LucideIcons.partyPopper, [Color(0xFFB57BFF), Color(0xFF6A3DE8)]),
    PostFeeling('bendecido', LucideIcons.sparkles, [Color(0xFFFFE27A), Color(0xFFE0A100)]),
    PostFeeling('relajado', LucideIcons.leaf, [Color(0xFF6FE3B0), Color(0xFF1F9E6B)]),
    PostFeeling('divertido', LucideIcons.laugh, [Color(0xFFFFC46B), Color(0xFFFF7A1C)]),
    PostFeeling('orgulloso', LucideIcons.award, [Color(0xFF7FC4FF), Color(0xFF2F6BFF)]),
    PostFeeling('triste', LucideIcons.frown, [Color(0xFF8FA6C8), Color(0xFF4B628C)]),
    PostFeeling('cansado', LucideIcons.moon, [Color(0xFF8B93C9), Color(0xFF454C8F)]),
    PostFeeling('pensativo', LucideIcons.lightbulb, [Color(0xFFFFE07A), Color(0xFFD69A00)]),
    PostFeeling('motivado', LucideIcons.zap, [Color(0xFFFFB347), Color(0xFFFF4E2A)]),
    PostFeeling('nostalgico', LucideIcons.history, [Color(0xFFC9A27E), Color(0xFF8A5A33)]),
    PostFeeling('romantico', LucideIcons.flower2, [Color(0xFFFF9EC7), Color(0xFFD23C82)]),
  ];

  static PostFeeling? of(String? id) {
    if (id == null) return null;
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}

/// Insignia redonda del sentimiento.
class FeelingBadge extends StatelessWidget {
  final PostFeeling feeling;
  final double size;

  const FeelingBadge({super.key, required this.feeling, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: feeling.colors),
      ),
      child: Icon(feeling.icon, size: size * 0.58, color: Colors.white),
    );
  }
}

/// Disposiciones de varias fotos: carrete (deslizable), mosaico (una grande + pequeñas) y cuadrícula.
class PostLayouts {
  static const String carousel = 'carrete';
  static const String mosaic = 'mosaico';
  static const String grid = 'cuadricula';

  static const List<String> all = [carousel, mosaic, grid];

  static IconData icon(String id) => switch (id) {
        mosaic => LucideIcons.layoutDashboard,
        grid => LucideIcons.layoutGrid,
        _ => LucideIcons.galleryHorizontal,
      };
}
