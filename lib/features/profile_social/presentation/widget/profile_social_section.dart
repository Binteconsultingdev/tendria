import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/communities/domain/entities/community_entities.dart';
import 'package:tendria/features/communities/presentation/widget/community_card.dart';
import 'package:tendria/features/feed/data/datasources/feed_data_sources_imp.dart';
import 'package:tendria/features/feed/data/repositories/feed_repository_imp.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';
import 'package:tendria/features/feed/domain/repositories/feed_repository.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/gift/data/gift_repository.dart';
import 'package:tendria/features/gift/domain/entities/gift_entities.dart';
import 'package:tendria/features/gift/presentation/widget/gift_icon.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';
import 'package:tendria/features/plans/presentation/widget/plan_card.dart';
import 'package:tendria/features/profile_social/data/profile_social_repository.dart';

enum _SocialTab { posts, plans, communities, gifts }

class _SocialController extends GetxController {
  final int userId;
  _SocialController(this.userId);

  final Rx<_SocialTab> tab = _SocialTab.posts.obs;
  final RxBool loading = false.obs;
  final RxnString error = RxnString();

  final RxList<PostEntity> posts = <PostEntity>[].obs;
  final RxList<PlanEntity> plans = <PlanEntity>[].obs;
  final RxList<CommunityEntity> communities = <CommunityEntity>[].obs;
  final RxList<ReceivedGiftEntity> gifts = <ReceivedGiftEntity>[].obs;
  final Set<_SocialTab> _loaded = {};

  FeedRepository get _feed {
    if (!Get.isRegistered<FeedRepository>()) {
      Get.put<FeedRepository>(FeedRepositoryImp(dataSource: FeedDataSourcesImp()), permanent: true);
    }
    return Get.find<FeedRepository>();
  }

  @override
  void onInit() {
    super.onInit();
    select(_SocialTab.posts);
  }

  Future<void> select(_SocialTab value) async {
    tab.value = value;
    if (_loaded.contains(value)) return;

    try {
      loading.value = true;
      error.value = null;
      switch (value) {
        case _SocialTab.posts:
          posts.assignAll((await _feed.getUserPosts(userId, pageSize: 9)).items);
          break;
        case _SocialTab.plans:
          plans.assignAll(await ProfileSocialRepository.instance.plansOf(userId));
          break;
        case _SocialTab.communities:
          communities.assignAll(await ProfileSocialRepository.instance.communitiesOf(userId));
          break;
        case _SocialTab.gifts:
          gifts.assignAll(await GiftRepository.instance.getReceived(userId));
          break;
      }
      _loaded.add(value);
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading.value = false;
    }
  }
}

/// Parte social de un perfil: contadores (publicaciones, seguidores, siguiendo) y pestañas con
/// las publicaciones, planes, comunidades y regalos recibidos de esa persona.
class ProfileSocialSection extends StatefulWidget {
  final int userId;
  final bool isOwn;
  final int followers;
  final int following;
  final int posts;

  /// Si el perfil ya muestra los contadores en su cabecera, se ocultan aquí para no repetirlos.
  final bool showCounters;

  const ProfileSocialSection({
    super.key,
    required this.userId,
    required this.isOwn,
    required this.followers,
    required this.following,
    required this.posts,
    this.showCounters = true,
  });

  @override
  State<ProfileSocialSection> createState() => _ProfileSocialSectionState();
}

class _ProfileSocialSectionState extends State<ProfileSocialSection> {
  final LanguageController _l = Get.find<LanguageController>();
  late final String _tag = 'social_${widget.userId}_${identityHashCode(this)}';
  late final _SocialController _c = Get.put(_SocialController(widget.userId), tag: _tag);

  @override
  void dispose() {
    Get.delete<_SocialController>(tag: _tag);
    super.dispose();
  }

  void _openFollowList(int tab) =>
      Get.toNamed(RoutesNames.followListPage, arguments: {'userId': widget.userId, 'tab': tab});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: FeedStyle.surface,
        borderRadius: ThemeColor.mediumBorderRadius,
        boxShadow: [ThemeColor.lightShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showCounters) ...[
            _counters(),
            Divider(height: 1, color: FeedStyle.hairline),
          ],
          _tabs(),
          Obx(_content),
        ],
      ),
    );
  }

  Widget _counters() {
    Widget stat(int value, String label, VoidCallback? onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text('$value', style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
                  const SizedBox(height: 2),
                  Text(label, style: FeedStyle.meta.copyWith(fontSize: 12.5)),
                ],
              ),
            ),
          ),
        );

    return Row(
      children: [
        stat(widget.posts, _l.t('feed_user_posts'), () => _c.select(_SocialTab.posts)),
        stat(widget.followers, _l.t('profile_followers'), () => _openFollowList(0)),
        stat(widget.following, _l.t('profile_following'), () => _openFollowList(1)),
      ],
    );
  }

  Widget _tabs() {
    Widget item(_SocialTab value, IconData icon, String label) => Expanded(
          child: Obx(() {
            final selected = _c.tab.value == value;
            return GestureDetector(
              onTap: () => _c.select(value),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: selected ? ThemeColor.primaryColor : Colors.transparent, width: 2.5)),
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 21, color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary),
                    const SizedBox(height: 3),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rubik(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary)),
                  ],
                ),
              ),
            );
          }),
        );

    return Row(
      children: [
        item(_SocialTab.posts, LucideIcons.layoutGrid, _l.t('feed_user_posts')),
        item(_SocialTab.plans, LucideIcons.calendarDays, _l.t('feed_filter_plans')),
        item(_SocialTab.communities, LucideIcons.users, _l.t('feed_filter_communities')),
        item(_SocialTab.gifts, LucideIcons.gift, _l.t('profile_gifts')),
      ],
    );
  }

  Widget _content() {
    final current = _c.tab.value;

    if (_c.loading.value) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 36), child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)));
    }
    if (_c.error.value != null) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Text(_c.error.value!, textAlign: TextAlign.center, style: FeedStyle.meta),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: () => _c.select(current), child: Text(_l.t('feed_retry'))),
          ],
        ),
      );
    }

    switch (current) {
      case _SocialTab.posts:
        return _postsGrid();
      case _SocialTab.plans:
        return _plans();
      case _SocialTab.communities:
        return _communities();
      case _SocialTab.gifts:
        return _gifts();
    }
  }

  Widget _empty(IconData icon, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 34, 32, 40),
        child: Column(
          children: [
            Icon(icon, size: 38, color: ThemeColor.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: FeedStyle.meta.copyWith(fontSize: 14)),
          ],
        ),
      );

  // ───────────── Publicaciones ─────────────

  Widget _postsGrid() {
    final posts = _c.posts;
    if (posts.isEmpty) return _empty(LucideIcons.image, widget.isOwn ? _l.t('profile_no_posts_own') : _l.t('profile_no_posts'));

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: posts.length > 9 ? 9 : posts.length,
          itemBuilder: (_, i) => _postTile(posts[i]),
        ),
        TextButton(
          onPressed: () => Get.toNamed(RoutesNames.userPostsPage, arguments: {'userId': widget.userId}),
          child: Text(_l.t('profile_see_all_posts'), style: GoogleFonts.rubik(fontWeight: FontWeight.w600, color: ThemeColor.primaryColor)),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _postTile(PostEntity post) {
    final first = post.media.isNotEmpty ? post.media.first : null;

    Widget base;
    if (first != null && !first.isVideo) {
      base = CachedNetworkImage(imageUrl: first.url, fit: BoxFit.cover, memCacheWidth: 400, placeholder: (_, __) => ColoredBox(color: FeedStyle.hairline));
    } else if (first != null) {
      base = const ColoredBox(color: Colors.black, child: Center(child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 34)));
    } else {
      base = Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: ThemeColor.primaryGradient),
        child: Text(post.text ?? '',
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white, height: 1.25)),
      );
    }

    return GestureDetector(
      onTap: () => Get.toNamed(RoutesNames.userPostsPage, arguments: {'userId': widget.userId}),
      child: Stack(
        fit: StackFit.expand,
        children: [
          base,
          if (post.media.length > 1)
            const Positioned(top: 6, right: 6, child: Icon(LucideIcons.images, size: 16, color: Colors.white, shadows: [Shadow(blurRadius: 6, color: Colors.black54)])),
        ],
      ),
    );
  }

  // ───────────── Planes ─────────────

  Widget _plans() {
    final plans = _c.plans;
    if (plans.isEmpty) return _empty(LucideIcons.calendarDays, widget.isOwn ? _l.t('profile_no_plans_own') : _l.t('profile_no_plans'));

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          for (final p in plans.take(5)) PlanCard(key: ValueKey('profile_plan_${p.id}'), plan: p),
          if (widget.isOwn)
            TextButton(
              onPressed: () => Get.toNamed(RoutesNames.plansPage, arguments: {'tab': 1}),
              child: Text(_l.t('profile_see_all_plans'), style: GoogleFonts.rubik(fontWeight: FontWeight.w600, color: ThemeColor.primaryColor)),
            ),
        ],
      ),
    );
  }

  // ───────────── Comunidades ─────────────

  Widget _communities() {
    final list = _c.communities;
    if (list.isEmpty) {
      return _empty(LucideIcons.users, widget.isOwn ? _l.t('profile_no_communities_own') : _l.t('profile_no_communities'));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(children: [for (final c in list) CommunityCard(key: ValueKey('profile_community_${c.id}'), community: c)]),
    );
  }

  // ───────────── Regalos ─────────────

  Widget _gifts() {
    final gifts = _c.gifts;
    if (gifts.isEmpty) return _empty(LucideIcons.gift, widget.isOwn ? _l.t('profile_no_gifts_own') : _l.t('profile_no_gifts'));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final g in gifts)
            Container(
              width: 96,
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
              decoration: BoxDecoration(color: ThemeColor.backgroundColorfondo, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  GiftIcon(code: g.code, size: 54),
                  const SizedBox(height: 8),
                  Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.name.copyWith(fontSize: 13)),
                  Text('×${g.count}', style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w700, color: ThemeColor.primaryColor)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


/// Contadores compactos (publicaciones, seguidores, siguiendo) para la cabecera de un perfil.
class ProfileStatsRow extends StatelessWidget {
  final int userId;
  final int posts;
  final int followers;
  final int following;

  const ProfileStatsRow({
    super.key,
    required this.userId,
    required this.posts,
    required this.followers,
    required this.following,
  });

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();

    Widget stat(int value, String label, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$value', style: GoogleFonts.rubik(fontSize: 19, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
                const SizedBox(height: 1),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.meta.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
        );

    return Row(
      children: [
        stat(posts, l.t('profile_posts_short'), () => Get.toNamed(RoutesNames.userPostsPage, arguments: {'userId': userId})),
        stat(followers, l.t('profile_followers'), () => Get.toNamed(RoutesNames.followListPage, arguments: {'userId': userId, 'tab': 0})),
        stat(following, l.t('profile_following'), () => Get.toNamed(RoutesNames.followListPage, arguments: {'userId': userId, 'tab': 1})),
      ],
    );
  }
}
