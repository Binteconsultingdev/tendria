import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/communities/domain/entities/community_entities.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';

/// Avatar cuadrado redondeado de una comunidad (imagen, o el icono de su categoría sobre degradado).
class CommunityAvatar extends StatelessWidget {
  final CommunityEntity? community;
  final String? imageUrl;
  final String category;
  final double size;

  const CommunityAvatar({super.key, this.community, this.imageUrl, this.category = 'otro', this.size = 56});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? community?.imageUrl;
    final cat = CommunityCategory.of(community?.category ?? category);

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: SizedBox(
        width: size,
        height: size,
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, memCacheWidth: (size * 3).round())
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cat.colors),
                ),
                child: Icon(cat.icon, size: size * 0.5, color: Colors.white),
              ),
      ),
    );
  }
}

class CommunityCard extends StatelessWidget {
  final CommunityEntity community;
  const CommunityCard({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();
    final cat = CommunityCategory.of(community.category);

    String? stateLabel;
    Color stateColor = ThemeColor.primaryColor;
    if (community.isCreator || community.myRole == 'admin') {
      stateLabel = l.t('community_role_admin');
    } else if (community.myRole == 'moderador') {
      stateLabel = l.t('community_role_moderator');
    } else if (community.isMember) {
      stateLabel = l.t('community_joined');
      stateColor = const Color(0xFF1F9D57);
    } else if (community.isPending) {
      stateLabel = l.t('plan_pending');
      stateColor = const Color(0xFFC77A00);
    }

    return GestureDetector(
      onTap: () => Get.toNamed(RoutesNames.communityDetailPage, arguments: {'communityId': community.id}),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FeedStyle.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 5))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommunityAvatar(community: community, size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(community.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.rubik(fontSize: 16.5, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
                      ),
                      if (community.isPrivate) ...[
                        const SizedBox(width: 6),
                        Icon(LucideIcons.lock, size: 14, color: ThemeColor.textSecondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(cat.icon, size: 13, color: cat.colors.last),
                      const SizedBox(width: 5),
                      Text(l.t('community_cat_${cat.code}'),
                          style: FeedStyle.meta.copyWith(color: cat.colors.last, fontWeight: FontWeight.w600)),
                      Text('  ·  ${community.members} ${l.t('community_members').toLowerCase()}', style: FeedStyle.meta),
                    ],
                  ),
                  if (community.description != null && community.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(community.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: FeedStyle.meta.copyWith(fontSize: 13.5, height: 1.35)),
                  ],
                  if (stateLabel != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: stateColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Text(stateLabel, style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w600, color: stateColor)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
