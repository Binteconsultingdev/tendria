import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tendria/common/theme/App_Theme.dart';

/// Tokens visuales del Feed (tipografía y colores tomados del tema de la app).
class FeedStyle {
  static TextStyle get name =>
      GoogleFonts.rubik(fontSize: 14.5, fontWeight: FontWeight.w600, color: ThemeColor.textPrimary);

  static TextStyle get body =>
      GoogleFonts.rubik(fontSize: 15, height: 1.45, color: ThemeColor.textPrimary);

  static TextStyle get meta => GoogleFonts.rubik(fontSize: 12, color: ThemeColor.textSecondary);

  static TextStyle get link => GoogleFonts.rubik(fontSize: 13.5, color: ThemeColor.textSecondary);

  static Color get hairline => ThemeColor.textSecondary.withValues(alpha: 0.16);
  static Color get surface => ThemeColor.cardBackground;
}

class UserAvatar extends StatelessWidget {
  final String? url;
  final double radius;

  const UserAvatar({super.key, required this.url, this.radius = 19});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = url != null && url!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: ThemeColor.textSecondary.withValues(alpha: 0.15),
      backgroundImage: hasPhoto ? CachedNetworkImageProvider(url!, maxWidth: (radius * 6).round()) : null,
      child: hasPhoto ? null : Icon(Icons.person_rounded, size: radius, color: ThemeColor.textSecondary),
    );
  }
}
