import 'package:get/get.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';
import 'package:tendria/features/feed/domain/repositories/feed_repository.dart';
import 'package:tendria/features/communities/data/communities_repository.dart';
import 'package:tendria/features/communities/domain/entities/community_entities.dart';
import 'package:tendria/features/plans/data/plans_repository.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';

enum FeedFilter { all, posts, plans, communities }

/// Lista del Feed. Con [userId] muestra solo las publicaciones de esa persona;
/// sin él, mezcla publicaciones de a quienes sigo con planes próximos.
class FeedController extends GetxController {
  final FeedRepository repository;
  final int? userId;
  final int? communityId; // publicaciones de una comunidad

  FeedController({required this.repository, this.userId, this.communityId});

  // ── Publicaciones ──
  final RxList<PostEntity> posts = <PostEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasMore = true.obs;
  int? _nextCursor;

  // ── Planes dentro del Feed ──
  final Rx<FeedFilter> filter = FeedFilter.all.obs;
  final RxList<PlanEntity> plans = <PlanEntity>[].obs;
  final RxBool plansLoading = false.obs;
  final RxBool plansLoadingMore = false.obs;
  final RxBool plansHasMore = true.obs;
  final RxnString plansCategory = RxnString();
  int _plansPage = 1;

  bool get includesPlans => userId == null && communityId == null;

  LanguageController get _l => Get.find<LanguageController>();

  @override
  void onInit() {
    super.onInit();
    refreshFeed();

    // Las comunidades se cargan la primera vez que se abre ese filtro
    if (includesPlans) {
      ever(filter, (f) {
        if (f == FeedFilter.communities && !_communitiesLoaded) {
          refreshCommunities();
          refreshMyCommunities();
        }
      });
    }
  }

  Future<CursorPage<PostEntity>> _fetch({int? cursor}) => communityId != null
      ? repository.getCommunityPosts(communityId!, cursor: cursor)
      : userId == null
          ? repository.getFeed(cursor: cursor)
          : repository.getUserPosts(userId!, cursor: cursor);

  Future<void> refreshFeed() async {
    await Future.wait([_refreshPosts(), if (includesPlans) refreshPlans()]);
  }

  Future<void> _refreshPosts() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      final page = await _fetch();
      posts.assignAll(page.items);
      _nextCursor = page.nextCursor;
      hasMore.value = page.nextCursor != null;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = cleanExceptionMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value || _nextCursor == null) return;
    try {
      isLoadingMore.value = true;
      final page = await _fetch(cursor: _nextCursor);
      posts.addAll(page.items);
      _nextCursor = page.nextCursor;
      hasMore.value = page.nextCursor != null;
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ───────────────────────── Planes ─────────────────────────

  Future<void> refreshPlans() async {
    try {
      plansLoading.value = true;
      _plansPage = 1;
      final result = await PlansRepository.instance.discover(category: plansCategory.value, page: 1);
      plans.assignAll(result.items);
      plansHasMore.value = result.hasNext;
    } catch (e) {
      // El Feed sigue funcionando aunque no carguen los planes
    } finally {
      plansLoading.value = false;
    }
  }

  Future<void> loadMorePlans() async {
    if (plansLoading.value || plansLoadingMore.value || !plansHasMore.value) return;
    try {
      plansLoadingMore.value = true;
      final result = await PlansRepository.instance.discover(category: plansCategory.value, page: _plansPage + 1);
      _plansPage++;
      plans.addAll(result.items);
      plansHasMore.value = result.hasNext;
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      plansLoadingMore.value = false;
    }
  }

  void setPlansCategory(String? category) {
    plansCategory.value = category;
    refreshPlans();
  }

  void upsertPlan(PlanEntity plan) {
    final i = plans.indexWhere((p) => p.id == plan.id);
    if (i != -1) plans[i] = plan;
  }

  void removePlan(int planId) => plans.removeWhere((p) => p.id == planId);

  // ───────────────────────── Comunidades ─────────────────────────

  final RxList<CommunityEntity> communities = <CommunityEntity>[].obs;
  final RxList<CommunityEntity> myCommunities = <CommunityEntity>[].obs;
  final RxBool communitiesLoading = false.obs;
  final RxBool communitiesLoadingMore = false.obs;
  final RxBool communitiesHasMore = true.obs;
  final RxnString communitiesCategory = RxnString();
  int _communitiesPage = 1;
  bool _communitiesLoaded = false;

  Future<void> refreshCommunities() async {
    try {
      communitiesLoading.value = true;
      _communitiesPage = 1;
      final result = await CommunitiesRepository.instance.discover(category: communitiesCategory.value, page: 1);
      communities.assignAll(result.items);
      communitiesHasMore.value = result.hasNext;
      _communitiesLoaded = true;
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      communitiesLoading.value = false;
    }
  }

  Future<void> loadMoreCommunities() async {
    if (communitiesLoading.value || communitiesLoadingMore.value || !communitiesHasMore.value) return;
    try {
      communitiesLoadingMore.value = true;
      final result =
          await CommunitiesRepository.instance.discover(category: communitiesCategory.value, page: _communitiesPage + 1);
      _communitiesPage++;
      communities.addAll(result.items);
      communitiesHasMore.value = result.hasNext;
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      communitiesLoadingMore.value = false;
    }
  }

  Future<void> refreshMyCommunities() async {
    try {
      myCommunities.assignAll(await CommunitiesRepository.instance.mine());
    } catch (_) {}
  }

  void setCommunitiesCategory(String? category) {
    communitiesCategory.value = category;
    refreshCommunities();
  }

  void upsertCommunity(CommunityEntity community) {
    final i = communities.indexWhere((c) => c.id == community.id);
    if (i != -1) communities[i] = community;
  }

  void removeCommunity(int id) {
    communities.removeWhere((c) => c.id == id);
    myCommunities.removeWhere((c) => c.id == id);
  }

  /// Elementos a mostrar según el filtro. En "Todo" se intercala un plan cada 3 publicaciones.
  List<Object> get items {
    final p = posts.toList();
    final pl = plans.toList();

    switch (filter.value) {
      case FeedFilter.posts:
        return p;
      case FeedFilter.plans:
        return pl;
      case FeedFilter.communities:
        return communities.toList();
      case FeedFilter.all:
        if (!includesPlans) return p;
        final out = <Object>[];
        var next = 0;
        for (var i = 0; i < p.length; i++) {
          out.add(p[i]);
          if ((i + 1) % 3 == 0 && next < pl.length) out.add(pl[next++]);
        }
        // Sin más publicaciones que cargar, los planes restantes cierran la lista
        if (!hasMore.value) out.addAll(pl.skip(next).take(5));
        return out;
    }
  }

  // ───────────────────────── Publicaciones: acciones ─────────────────────────

  void addPost(PostEntity post) => posts.insert(0, post);

  void _replace(PostEntity updated) {
    final index = posts.indexWhere((p) => p.id == updated.id);
    if (index != -1) posts[index] = updated;
  }

  /// Vuelve a pedir una publicación (por ejemplo tras comentar) para actualizar contadores.
  Future<void> reloadPost(int postId) async {
    try {
      _replace(await repository.getPost(postId));
    } catch (_) {}
  }

  /// Toque corto: alterna el corazón (me_encanta). Al elegir en el selector se pasa el tipo.
  Future<void> react(PostEntity post, {String? type}) async {
    try {
      final PostEntity updated;
      if (type == null && post.myReaction != null) {
        updated = await repository.removeReaction(post.id);
      } else if (type != null && type == post.myReaction) {
        updated = await repository.removeReaction(post.id);
      } else {
        updated = await repository.react(post.id, type ?? 'me_encanta');
      }
      _replace(updated);
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    }
  }

  Future<void> deletePost(PostEntity post) async {
    try {
      await repository.deletePost(post.id);
      posts.removeWhere((p) => p.id == post.id);
      showSuccessSnackbarGetx(_l.t('feed_deleted'));
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    }
  }

  Future<void> reportPost(PostEntity post) async {
    try {
      await repository.reportPost(post.id);
      showSuccessSnackbarGetx(_l.t('feed_reported'));
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    }
  }
}
