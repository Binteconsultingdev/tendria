import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tendria/common/theme/App_Theme.dart';

/// Base de diseño "Elite": espaciado, radios, sombras y componentes comunes para que toda la app
/// se vea y se sienta igual (limpia, con aire, tipografía Rubik, burdeos con acentos dorados).
class Elite {
  // Acento dorado, para detalles premium (insignias, destacados)
  static const Color gold = Color(0xFFC9A24B);
  static const Color goldSoft = Color(0xFFF3E7C4);

  // Espaciado (cuadrícula de 4)
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20, s6 = 24, s8 = 32;

  // Radios
  static const double rSm = 12, rMd = 18, rLg = 24, rXl = 32;

  static List<BoxShadow> get softShadow => [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6)),
      ];

  static List<BoxShadow> get liftedShadow => [
        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 28, offset: const Offset(0, 12)),
      ];

  static Color get hairline => ThemeColor.textSecondary.withValues(alpha: 0.14);

  // Tipografía
  static TextStyle title({double size = 22, Color? color}) =>
      GoogleFonts.rubik(fontSize: size, fontWeight: FontWeight.w700, height: 1.2, color: color ?? ThemeColor.textPrimary);

  static TextStyle heading({double size = 17, Color? color}) =>
      GoogleFonts.rubik(fontSize: size, fontWeight: FontWeight.w600, color: color ?? ThemeColor.textPrimary);

  static TextStyle body({double size = 15, Color? color}) =>
      GoogleFonts.rubik(fontSize: size, height: 1.45, color: color ?? ThemeColor.textPrimary);

  static TextStyle caption({double size = 12.5, Color? color}) =>
      GoogleFonts.rubik(fontSize: size, color: color ?? ThemeColor.textSecondary);
}

/// Botón principal: degradado de marca, altura cómoda, estado de carga y vibración suave.
class EliteButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;
  final bool expand;
  final Color? color;

  const EliteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.outlined = false,
    this.expand = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final accent = color ?? ThemeColor.primaryColor;
    final fg = outlined ? accent : Colors.white;

    final content = loading
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: outlined ? accent : Colors.white))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 19, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.rubik(fontSize: 15.5, fontWeight: FontWeight.w600, color: enabled ? fg : ThemeColor.textSecondary)),
              ),
            ],
          );

    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: expand ? double.infinity : null,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: !outlined && enabled ? LinearGradient(colors: [accent, Color.lerp(accent, Colors.black, 0.18)!], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
          color: outlined ? Colors.transparent : (enabled ? null : Elite.hairline),
          border: outlined ? Border.all(color: enabled ? accent : Elite.hairline, width: 1.6) : null,
          borderRadius: BorderRadius.circular(Elite.rMd),
          boxShadow: !outlined && enabled ? [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))] : null,
        ),
        child: content,
      ),
    );
  }
}

/// Tarjeta base: superficie limpia con esquinas amplias y sombra suave.
class EliteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const EliteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Elite.s4),
    this.margin = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: ThemeColor.cardBackground,
        borderRadius: BorderRadius.circular(Elite.rLg),
        boxShadow: Elite.softShadow,
      ),
      child: child,
    );
    return onTap == null ? card : GestureDetector(onTap: onTap, child: card);
  }
}

/// Título de sección con acción opcional ("Ver todo").
class EliteSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const EliteSectionTitle({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Elite.s5, Elite.s6, Elite.s5, Elite.s3),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Elite.heading(size: 18))),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: GoogleFonts.rubik(fontSize: 13.5, fontWeight: FontWeight.w600, color: ThemeColor.primaryColor)),
            ),
        ],
      ),
    );
  }
}
