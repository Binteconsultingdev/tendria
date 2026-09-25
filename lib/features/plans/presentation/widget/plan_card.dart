import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';
import 'package:tendria/features/plans/presentation/widget/plan_format.dart';

class PlanCard extends StatelessWidget {
  final PlanEntity plan;
  const PlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();
    final cat = PlanCategory.of(plan.category);

    return GestureDetector(
      onTap: () => Get.toNamed(RoutesNames.planDetailPage, arguments: {'planId': plan.id}),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: FeedStyle.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 170,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  plan.imageUrl != null && plan.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: plan.imageUrl!, fit: BoxFit.cover, memCacheWidth: 900)
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cat.colors),
                          ),
                          child: Center(child: Icon(cat.icon, size: 64, color: Colors.white.withValues(alpha: 0.85))),
                        ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.25), Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                      ),
                    ),
                  ),
                  Positioned(top: 12, left: 12, child: _DateBadge(date: plan.startsAt)),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(l.t('plan_cat_${cat.code}'),
                              style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  if (plan.cancelled)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      alignment: Alignment.center,
                      child: Text(l.t('plan_cancelled'),
                          style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
                  const SizedBox(height: 8),
                  _line(LucideIcons.clock, PlanFormat.full(plan.startsAt)),
                  const SizedBox(height: 4),
                  _line(
                    LucideIcons.mapPin,
                    plan.distanceKm != null ? '${plan.placeName} · ${PlanFormat.distance(plan.distanceKm!)}' : plan.placeName,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Avatars(plan: plan),
                      const Spacer(),
                      _StateChip(plan: plan),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 15, color: ThemeColor.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.meta.copyWith(fontSize: 13.5)),
          ),
        ],
      );
}

class _DateBadge extends StatelessWidget {
  final DateTime date;
  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(PlanFormat.monthShort(date).toUpperCase(),
              style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w700, color: ThemeColor.primaryColor)),
          Text('${date.day}', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.1)),
        ],
      ),
    );
  }
}

class _Avatars extends StatelessWidget {
  final PlanEntity plan;
  const _Avatars({required this.plan});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();
    final shown = plan.participants.take(4).toList();
    final countText = plan.capacity != null
        ? '${plan.confirmed}/${plan.capacity} ${l.t('plan_going')}'
        : '${plan.confirmed} ${l.t('plan_going')}';

    return Row(
      children: [
        if (shown.isNotEmpty)
          SizedBox(
            width: 26.0 + (shown.length - 1) * 18,
            height: 30,
            child: Stack(
              children: [
                for (var i = shown.length - 1; i >= 0; i--)
                  Positioned(
                    left: i * 18.0,
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: FeedStyle.surface, width: 2)),
                      child: UserAvatar(url: shown[i].photoUrl, radius: 13),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        Text(countText, style: FeedStyle.meta.copyWith(fontSize: 13)),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  final PlanEntity plan;
  const _StateChip({required this.plan});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();
    String? label;
    Color color = ThemeColor.primaryColor;

    if (plan.cancelled) {
      label = null;
    } else if (plan.isMine) {
      label = l.t('plan_yours');
    } else if (plan.joined) {
      label = l.t('plan_you_go');
      color = const Color(0xFF1F9D57);
    } else if (plan.requested) {
      label = l.t('plan_pending');
      color = const Color(0xFFC77A00);
    } else if (plan.isFull) {
      label = l.t('plan_full');
      color = ThemeColor.textSecondary;
    }

    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
