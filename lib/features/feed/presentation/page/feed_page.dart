import 'package:tendria/features/communities/presentation/widget/community_card.dart';
import 'package:tendria/features/communities/domain/entities/community_entities.dart';
import 'package:tendria/features/plans/presentation/widget/plan_card.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/tutorial/startTutorial/start_tutorial_controller.dart';
import 'package:tendria/features/auth/presentation/page/home/start_controller.dart';
import 'package:tendria/features/feed/data/datasources/feed_data_sources_imp.dart';
import 'package:tendria/features/feed/data/repositories/feed_repository_imp.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';
import 'package:tendria/features/feed/domain/repositories/feed_repository.dart';
import 'package:tendria/features/feed/presentation/controller/feed_controller.dart';
import 'package:tendria/features/feed/presentation/widget/feed_skeleton.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/feed/presentation/widget/post_card.dart';
import 'package:tendria/features/stories/presentation/page/story_controller.dart';
import 'package:tendria/features/stories/presentation/widgets/stories_bar.dart';
import 'package:tendria/features/user/presentation/controller/profile_controller.dart';

FeedRepository _repository() {
  if (!Get.isRegistered<FeedRepository>()) {
    Get.put<FeedRepository>(FeedRepositoryImp(dataSource: FeedDataSourcesImp()), permanent: true);
  }
  return Get.find<FeedRepository>();
}

/// Pestaña principal del Feed: publicaciones de las personas que sigo y las mías.
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  late final FeedController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<FeedController>()
        ? Get.find<FeedController>()
        : Get.put(FeedController(repository: _repository()));
  }

  Future<void> _newPost() async {
    final result = await Get.toNamed(RoutesNames.createPostPage);
    if (result is PostEntity) controller.addPost(result);
  }

  Future<void> _newPlan() async {
    final created = await Get.toNamed(RoutesNames.createPlanPage);
    if (created is PlanEntity) {
      controller.filter.value = FeedFilter.plans;
      controller.refreshPlans();
    }
  }

  Future<void> _newCommunity() async {
    final created = await Get.toNamed(RoutesNames.createCommunityPage);
    if (created is CommunityEntity) {
      controller.refreshCommunities();
      controller.refreshMyCommunities();
      Get.toNamed(RoutesNames.communityDetailPage, arguments: {'communityId': created.id});
    }
  }

  Future<void> _refreshAll() async {
    final stories = Get.find<StoryController>();
    await Future.wait([
      controller.refreshFeed(),
      stories.fetchStories(),
      stories.fetchMyStory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.backgroundColorfondo,
      appBar: AppBar(
        backgroundColor: FeedStyle.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        title: Text(
          'Tatendria',
          style: GoogleFonts.rubik(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: ThemeColor.primaryColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            icon: Icon(LucideIcons.bell, size: 21, color: ThemeColor.textPrimary),
            onPressed: () => Get.toNamed(RoutesNames.notificationPage),
          ),
          Obx(() => IconButton(
                // El tutorial de inicio señala este botón como "Radar" (solo mientras está pendiente)
                key: Get.isRegistered<StartTutorialController>() && Get.find<StartTutorialController>().pending.value
                    ? Get.find<StartTutorialController>().navRadarKey
                    : null,
                tooltip: 'Radar',
                icon: Icon(LucideIcons.radar, size: 21, color: ThemeColor.textPrimary),
                onPressed: () => Get.find<StartController>().openRadar(),
              )),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: FeedStyle.hairline),
        ),
      ),
      body: PostListView(
        controller: controller,
        onRefresh: _refreshAll,
        header: _FeedHeader(
          controller: controller,
          onCompose: _newPost,
          onCreatePlan: _newPlan,
          onCreateCommunity: _newCommunity,
        ),
        emptyBuilder: (_) {
          switch (controller.filter.value) {
            case FeedFilter.plans:
              return _EmptyPlans(onCreate: _newPlan);
            case FeedFilter.communities:
              return _EmptyCommunities(onCreate: _newCommunity);
            default:
              return _EmptyFeed(
                onDiscover: () => Get.find<StartController>().openRadar(),
                onCreate: _newPost,
              );
          }
        },
      ),
    );
  }
}

/// Historias, accesos para publicar y filtros (Todo / Publicaciones / Planes), al inicio del Feed.
class _FeedHeader extends StatelessWidget {
  final FeedController controller;
  final VoidCallback onCompose;
  final VoidCallback onCreatePlan;
  final VoidCallback onCreateCommunity;

  const _FeedHeader({
    required this.controller,
    required this.onCompose,
    required this.onCreatePlan,
    required this.onCreateCommunity,
  });

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();
    final profile = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;

    return Container(
      color: FeedStyle.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          const SizedBox(height: 12),
          const StoriesBar(),
          Divider(height: 1, thickness: 1, color: FeedStyle.hairline),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                profile == null
                    ? const UserAvatar(url: null, radius: 17)
                    : Obx(() => UserAvatar(url: profile.userEntity.value?.fotoUrl, radius: 17)),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onCompose,
                    child: Container(
                      height: 38,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: ThemeColor.backgroundColorfondo,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(l.t('feed_write'), style: FeedStyle.meta.copyWith(fontSize: 13.5)),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.t('feed_add_photo'),
                  onPressed: onCompose,
                  icon: Icon(LucideIcons.image, size: 20, color: ThemeColor.primaryColor),
                ),
                IconButton(
                  tooltip: l.t('plans_create'),
                  onPressed: onCreatePlan,
                  icon: Icon(LucideIcons.calendarPlus, size: 20, color: ThemeColor.primaryColor),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: FeedStyle.hairline),
          _FilterBar(controller: controller, onCreatePlan: onCreatePlan, onCreateCommunity: onCreateCommunity),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final FeedController controller;
  final VoidCallback onCreatePlan;
  final VoidCallback onCreateCommunity;

  const _FilterBar({required this.controller, required this.onCreatePlan, required this.onCreateCommunity});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();

    Widget chip(FeedFilter value, String label, IconData icon) {
      final selected = controller.filter.value == value;
      // Todos los chips comparten tipografía y tamaño; la fila se desliza si no caben en pantallas angostas
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => controller.filter.value = value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? ThemeColor.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary),
                const SizedBox(width: 5),
                Text(label,
                    style: GoogleFonts.rubik(
                        fontSize: 12.5, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Obx(() {
      final inPlans = controller.filter.value == FeedFilter.plans;
      final inCommunities = controller.filter.value == FeedFilter.communities;

      return Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
            child: Row(
              children: [
                chip(FeedFilter.all, l.t('feed_filter_all'), LucideIcons.layoutGrid),
                chip(FeedFilter.posts, l.t('feed_filter_posts'), LucideIcons.image),
                chip(FeedFilter.plans, l.t('feed_filter_plans'), LucideIcons.calendarDays),
                chip(FeedFilter.communities, l.t('feed_filter_communities'), LucideIcons.users),
              ],
            ),
          ),
          if (inPlans) ...[
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _categoryChip(null, l.t('plans_all'), LucideIcons.layoutGrid),
                  for (final c in PlanCategory.all) _categoryChip(c.code, l.t('plan_cat_${c.code}'), c.icon),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCreatePlan,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: Text(l.t('plans_create')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeColor.primaryColor,
                        side: BorderSide(color: ThemeColor.primaryColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Get.toNamed(RoutesNames.plansPage, arguments: {'tab': 1}),
                      icon: const Icon(LucideIcons.ticket, size: 18),
                      label: Text(l.t('plans_mine')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeColor.textPrimary,
                        side: BorderSide(color: FeedStyle.hairline),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (inCommunities) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l.t('community_my'),
                    style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
              ),
            ),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  GestureDetector(
                    onTap: onCreateCommunity,
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(color: ThemeColor.primaryColor.withValues(alpha: 0.5), width: 1.6),
                            ),
                            child: Icon(LucideIcons.plus, color: ThemeColor.primaryColor),
                          ),
                          const SizedBox(height: 6),
                          Text(l.t('community_new'), style: FeedStyle.meta.copyWith(fontSize: 11.5, color: ThemeColor.primaryColor)),
                        ],
                      ),
                    ),
                  ),
                  for (final c in controller.myCommunities.where((c) => c.isMember))
                    GestureDetector(
                      onTap: () => Get.toNamed(RoutesNames.communityDetailPage, arguments: {'communityId': c.id}),
                      child: SizedBox(
                        width: 72,
                        child: Column(
                          children: [
                            CommunityAvatar(community: c, size: 56),
                            const SizedBox(height: 6),
                            Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.meta.copyWith(fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _communityCategoryChip(null, l.t('plans_all'), LucideIcons.layoutGrid),
                  for (final c in CommunityCategory.all) _communityCategoryChip(c.code, l.t('community_cat_${c.code}'), c.icon),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    });
  }

  Widget _communityCategoryChip(String? code, String label, IconData icon) {
    final selected = controller.communitiesCategory.value == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => controller.setCommunitiesCategory(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected ? ThemeColor.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? ThemeColor.primaryColor : FeedStyle.hairline),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.rubik(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String? code, String label, IconData icon) {
    final selected = controller.plansCategory.value == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => controller.setPlansCategory(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected ? ThemeColor.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? ThemeColor.primaryColor : FeedStyle.hairline),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.rubik(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCommunities extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyCommunities({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(gradient: ThemeColor.primaryGradient, shape: BoxShape.circle),
            child: const Icon(LucideIcons.users, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(l.t('community_empty'), textAlign: TextAlign.center, style: FeedStyle.body.copyWith(color: ThemeColor.textSecondary)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(LucideIcons.plus),
            label: Text(l.t('community_create')),
            style: FilledButton.styleFrom(
              backgroundColor: ThemeColor.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyPlans({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(gradient: ThemeColor.primaryGradient, shape: BoxShape.circle),
            child: const Icon(LucideIcons.calendarDays, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(l.t('plans_empty_discover'),
              textAlign: TextAlign.center, style: FeedStyle.body.copyWith(color: ThemeColor.textSecondary)),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(LucideIcons.plus),
            label: Text(l.t('plans_create')),
            style: FilledButton.styleFrom(
              backgroundColor: ThemeColor.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final VoidCallback onDiscover;
  final VoidCallback onCreate;

  const _EmptyFeed({required this.onDiscover, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(gradient: ThemeColor.primaryGradient, shape: BoxShape.circle),
            child: const Icon(LucideIcons.sparkles, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 22),
          Text(l.t('feed_empty_title'),
              textAlign: TextAlign.center,
              style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w600, color: ThemeColor.textPrimary)),
          const SizedBox(height: 8),
          Text(l.t('feed_empty'), textAlign: TextAlign.center, style: FeedStyle.body.copyWith(color: ThemeColor.textSecondary)),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onDiscover,
              icon: const Icon(LucideIcons.radar),
              label: Text(l.t('feed_discover')),
              style: FilledButton.styleFrom(
                backgroundColor: ThemeColor.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onCreate,
            child: Text(l.t('feed_create_first'), style: TextStyle(color: ThemeColor.primaryColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Publicaciones de una persona (se abre desde su perfil).
class UserPostsPage extends StatefulWidget {
  const UserPostsPage({super.key});

  @override
  State<UserPostsPage> createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  late final int userId;
  late final String tag;
  late final FeedController controller;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    userId = args?['userId'] ?? 0;
    tag = 'user_posts_$userId';
    controller = Get.put(FeedController(repository: _repository(), userId: userId), tag: tag);
  }

  @override
  void dispose() {
    Get.delete<FeedController>(tag: tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();
    return Scaffold(
      backgroundColor: ThemeColor.backgroundColorfondo,
      appBar: AppBar(
        backgroundColor: FeedStyle.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: ThemeColor.textPrimary),
        title: Text(l.t('feed_user_posts'), style: FeedStyle.name.copyWith(fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: FeedStyle.hairline),
        ),
      ),
      body: PostListView(controller: controller),
    );
  }
}

class PostListView extends StatelessWidget {
  final FeedController controller;

  /// Contenido fijo al inicio de la lista (por ejemplo, las historias).
  final Widget? header;
  final Future<void> Function()? onRefresh;
  final WidgetBuilder? emptyBuilder;

  const PostListView({super.key, required this.controller, this.header, this.onRefresh, this.emptyBuilder});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();

    return Obx(() {
      final filter = controller.filter.value;
      final items = controller.items;
      final loadingFirst = (filter == FeedFilter.plans
              ? controller.plansLoading.value
              : filter == FeedFilter.communities
                  ? controller.communitiesLoading.value
                  : controller.isLoading.value) &&
          items.isEmpty;
      final loadingMore = filter == FeedFilter.plans
          ? controller.plansLoadingMore.value
          : filter == FeedFilter.communities
              ? controller.communitiesLoadingMore.value
              : controller.isLoadingMore.value;
      final headerCount = header != null ? 1 : 0;

      return RefreshIndicator(
        color: ThemeColor.primaryColor,
        onRefresh: onRefresh ?? controller.refreshFeed,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
              switch (filter) {
                case FeedFilter.plans:
                  controller.loadMorePlans();
                  break;
                case FeedFilter.communities:
                  controller.loadMoreCommunities();
                  break;
                default:
                  controller.loadMore();
              }
            }
            return false;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: headerCount + (items.isEmpty ? 1 : items.length + 1),
            itemBuilder: (context, position) {
              if (header != null && position == 0) return header!;
              final i = position - headerCount;

              if (items.isEmpty) {
                if (loadingFirst) return const FeedSkeleton();
                if (controller.hasError.value && (filter == FeedFilter.all || filter == FeedFilter.posts)) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(controller.errorMessage.value, textAlign: TextAlign.center, style: FeedStyle.body),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: controller.refreshFeed, child: Text(l.t('feed_retry'))),
                      ],
                    ),
                  );
                }
                return emptyBuilder?.call(context) ??
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 80, 32, 0),
                      child: Text(l.t('feed_empty_user'),
                          textAlign: TextAlign.center,
                          style: FeedStyle.body.copyWith(color: ThemeColor.textSecondary)),
                    );
              }

              if (i >= items.length) {
                // Pie de lista: cargando más o fin
                return loadingMore
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4))),
                      )
                    : const SizedBox(height: 8);
              }

              final item = items[i];
              if (item is PlanEntity) return PlanCard(key: ValueKey('plan_${item.id}'), plan: item);
              if (item is CommunityEntity) return CommunityCard(key: ValueKey('community_${item.id}'), community: item);
              return PostCard(post: item as PostEntity, controller: controller);
            },
          ),
        ),
      );
    });
  }
}
