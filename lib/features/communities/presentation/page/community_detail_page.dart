import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/communities/data/communities_repository.dart';
import 'package:tendria/features/communities/domain/entities/community_entities.dart';
import 'package:tendria/features/communities/presentation/widget/community_card.dart';
import 'package:tendria/features/feed/data/datasources/feed_data_sources_imp.dart';
import 'package:tendria/features/feed/data/repositories/feed_repository_imp.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';
import 'package:tendria/features/feed/domain/repositories/feed_repository.dart';
import 'package:tendria/features/feed/presentation/controller/feed_controller.dart';
import 'package:tendria/features/feed/presentation/page/feed_page.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/user/presentation/controller/profile_controller.dart';

class CommunityDetailPage extends StatefulWidget {
  const CommunityDetailPage({super.key});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  final CommunitiesRepository _repo = CommunitiesRepository.instance;
  final LanguageController _l = Get.find<LanguageController>();

  final Rxn<CommunityEntity> _community = Rxn<CommunityEntity>();
  final RxBool _loading = true.obs;
  final RxBool _busy = false.obs;
  final RxInt _tab = 0.obs; // 0 = publicaciones, 1 = miembros
  String? _error;

  final RxList<MemberEntity> _members = <MemberEntity>[].obs;
  final RxBool _membersLoading = false.obs;
  final RxBool _membersHasMore = true.obs;
  int _membersPage = 0;

  late final int _id;
  late final String _feedTag;
  FeedController? _feed;

  @override
  void initState() {
    super.initState();
    _id = (Get.arguments as Map<String, dynamic>?)?['communityId'] ?? 0;
    _feedTag = 'community_$_id';
    _load();
  }

  @override
  void dispose() {
    if (Get.isRegistered<FeedController>(tag: _feedTag)) Get.delete<FeedController>(tag: _feedTag);
    super.dispose();
  }

  FeedRepository get _feedRepository {
    if (!Get.isRegistered<FeedRepository>()) {
      Get.put<FeedRepository>(FeedRepositoryImp(dataSource: FeedDataSourcesImp()), permanent: true);
    }
    return Get.find<FeedRepository>();
  }

  Future<void> _load() async {
    try {
      _loading.value = true;
      _error = null;
      final c = await _repo.get(_id);
      _community.value = c;
      _ensureFeed(c);
    } catch (e) {
      _error = cleanExceptionMessage(e);
    } finally {
      _loading.value = false;
    }
  }

  /// Las publicaciones solo se piden si la persona puede ver el contenido de la comunidad.
  void _ensureFeed(CommunityEntity c) {
    if (c.canViewContent && _feed == null) {
      _feed = Get.put(FeedController(repository: _feedRepository, communityId: _id), tag: _feedTag);
    }
  }

  void _sync(CommunityEntity c) {
    _community.value = c;
    _ensureFeed(c);
    if (Get.isRegistered<FeedController>()) {
      final main = Get.find<FeedController>();
      main.upsertCommunity(c);
      main.refreshMyCommunities();
    }
  }

  Future<void> _run(Future<CommunityEntity> Function() action) async {
    if (_busy.value) return;
    try {
      _busy.value = true;
      _sync(await action());
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      _busy.value = false;
    }
  }

  Future<void> _leave() async {
    try {
      _busy.value = true;
      await _repo.leave(_id);
      await _load();
      if (Get.isRegistered<FeedController>()) Get.find<FeedController>().refreshMyCommunities();
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      _busy.value = false;
    }
  }

  Future<void> _deleteCommunity() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l.t('community_delete_confirm')),
        content: Text(_l.t('community_delete_hint')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_l.t('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_l.t('feed_delete'), style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;

    try {
      _busy.value = true;
      await _repo.delete(_id);
      if (Get.isRegistered<FeedController>()) {
        final main = Get.find<FeedController>();
        main.removeCommunity(_id);
        main.refreshMyCommunities();
      }
      Get.back();
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      _busy.value = false;
    }
  }

  Future<void> _loadMembers({bool reset = false}) async {
    if (_membersLoading.value) return;
    if (reset) {
      _membersPage = 0;
      _membersHasMore.value = true;
      _members.clear();
    }
    if (!_membersHasMore.value) return;

    try {
      _membersLoading.value = true;
      final result = await _repo.members(_id, page: _membersPage + 1);
      _membersPage++;
      _members.addAll(result.items);
      _membersHasMore.value = result.hasNext;
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      _membersLoading.value = false;
    }
  }

  Future<void> _newPost(CommunityEntity c) async {
    final result = await Get.toNamed(RoutesNames.createPostPage, arguments: {'communityId': c.id, 'communityName': c.name});
    if (result is PostEntity) _feed?.addPost(result);
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.backgroundColorfondo,
      body: Obx(() {
        if (_loading.value && _community.value == null) return const Center(child: CircularProgressIndicator());
        final c = _community.value;
        if (c == null) {
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? '', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _load, child: Text(_l.t('feed_retry'))),
                    TextButton(onPressed: Get.back, child: Text(_l.t('cancel'))),
                  ],
                ),
              ),
            ),
          );
        }
        return _content(c);
      }),
    );
  }

  Widget _content(CommunityEntity c) {
    final header = _header(c);

    if (!c.canViewContent) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 30, 36, 40),
            child: Column(
              children: [
                Icon(LucideIcons.lock, size: 44, color: ThemeColor.textSecondary.withValues(alpha: 0.6)),
                const SizedBox(height: 14),
                Text(_l.t('community_locked'), textAlign: TextAlign.center, style: FeedStyle.body.copyWith(color: ThemeColor.textSecondary)),
              ],
            ),
          ),
        ],
      );
    }

    if (_tab.value == 1) {
      if (_members.isEmpty && !_membersLoading.value && _membersHasMore.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadMembers(reset: true));
      }
      return _membersList(c, header);
    }

    final feed = _feed;
    if (feed == null) return ListView(children: [header]);

    return PostListView(
      controller: feed,
      header: header,
      onRefresh: () async {
        await Future.wait([feed.refreshFeed(), _load()]);
      },
      emptyBuilder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
        child: Text(_l.t('community_no_posts'), textAlign: TextAlign.center, style: FeedStyle.body.copyWith(color: ThemeColor.textSecondary)),
      ),
    );
  }

  Widget _header(CommunityEntity c) {
    final cat = CommunityCategory.of(c.category);
    final top = MediaQuery.of(context).padding.top;

    return Container(
      color: FeedStyle.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190 + 38,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: c.coverUrl != null && c.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: c.coverUrl!, fit: BoxFit.cover)
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cat.colors),
                          ),
                          child: Icon(cat.icon, size: 70, color: Colors.white.withValues(alpha: 0.25)),
                        ),
                ),
                Positioned(
                  top: top + 6,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _roundButton(LucideIcons.arrowLeft, Get.back),
                      const Spacer(),
                      _roundButton(LucideIcons.ellipsis, () => _menu(c)),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: FeedStyle.surface, width: 4),
                    ),
                    child: CommunityAvatar(community: c, size: 84),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(c.name, style: GoogleFonts.rubik(fontSize: 23, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
                    ),
                    if (c.isPrivate) ...[
                      const SizedBox(width: 8),
                      Icon(LucideIcons.lock, size: 17, color: ThemeColor.textSecondary),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(cat.icon, size: 14, color: cat.colors.last),
                      const SizedBox(width: 5),
                      Text(_l.t('community_cat_${cat.code}'), style: FeedStyle.meta.copyWith(color: cat.colors.last, fontWeight: FontWeight.w600)),
                    ]),
                    Text('${c.members} ${_l.t('community_members').toLowerCase()}', style: FeedStyle.meta),
                    if (c.city != null && c.city!.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(LucideIcons.mapPin, size: 13, color: ThemeColor.textSecondary),
                        const SizedBox(width: 4),
                        Text(c.city!, style: FeedStyle.meta),
                      ]),
                  ],
                ),
                if (c.description != null && c.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(c.description!, style: FeedStyle.body.copyWith(height: 1.5)),
                ],
                const SizedBox(height: 16),
                _actions(c),
                const SizedBox(height: 14),
              ],
            ),
          ),
          if (c.canViewContent) _segments(),
          if (c.isMember && _tab.value == 0) _composer(c),
        ],
      ),
    );
  }

  /// Barra para publicar en la comunidad (solo miembros), visible al inicio de las publicaciones.
  Widget _composer(CommunityEntity c) {
    final profile = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: FeedStyle.hairline),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              profile == null
                  ? const UserAvatar(url: null, radius: 20)
                  : Obx(() => UserAvatar(url: profile.userEntity.value?.fotoUrl, radius: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _newPost(c),
                  child: Container(
                    height: 44,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(color: ThemeColor.backgroundColorfondo, borderRadius: BorderRadius.circular(24)),
                    child: Text('${_l.t('community_post_in')} ${c.name}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.meta.copyWith(fontSize: 14.5)),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _newPost(c),
                icon: Icon(LucideIcons.image, size: 25, color: ThemeColor.primaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.42), shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      );

  Widget _actions(CommunityEntity c) {
    Widget primary(String label, VoidCallback? onTap, {bool outlined = false, IconData? icon}) {
      final enabled = onTap != null && !_busy.value;
      return GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: !outlined && enabled ? ThemeColor.primaryGradient : null,
            color: outlined ? Colors.transparent : (enabled ? null : FeedStyle.hairline),
            border: outlined ? Border.all(color: ThemeColor.primaryColor, width: 1.5) : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: outlined ? ThemeColor.primaryColor : Colors.white),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: GoogleFonts.rubik(
                      fontSize: 14.5, fontWeight: FontWeight.w600, color: outlined ? ThemeColor.primaryColor : Colors.white)),
            ],
          ),
        ),
      );
    }

    final buttons = <Widget>[];
    if (c.isMember) {
      buttons.add(primary(_l.t('community_joined'), () => _memberSheet(c), outlined: true, icon: LucideIcons.check));
    } else if (c.isPending) {
      buttons.add(primary(_l.t('plan_cancel_request'), _leave, outlined: true));
    } else {
      buttons.add(primary(c.isPrivate ? _l.t('plan_request') : _l.t('plan_join'), () => _run(() => _repo.join(c.id)), icon: LucideIcons.userPlus));
    }

    if (c.canModerate && (c.pendingRequests ?? 0) > 0) {
      buttons.add(primary('${_l.t('plan_requests')} (${c.pendingRequests})', () => _requestsSheet(c), outlined: true, icon: LucideIcons.userCheck));
    }

    return Wrap(spacing: 10, runSpacing: 10, children: buttons);
  }

  Widget _segments() {
    Widget segment(int index, String label, IconData icon) {
      final selected = _tab.value == index;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            _tab.value = index;
            if (index == 1) _loadMembers(reset: true);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: selected ? ThemeColor.primaryColor : Colors.transparent, width: 2.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 17, color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary),
                const SizedBox(width: 7),
                Text(label,
                    style: GoogleFonts.rubik(
                        fontSize: 14, fontWeight: FontWeight.w600, color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Divider(height: 1, color: FeedStyle.hairline),
        Row(children: [
          segment(0, _l.t('feed_filter_posts'), LucideIcons.image),
          segment(1, _l.t('community_members'), LucideIcons.users),
        ]),
      ],
    );
  }

  Widget _membersList(CommunityEntity c, Widget header) {
    return Obx(() {
      final me = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>().userEntity.value?.id : null;

      return RefreshIndicator(
        color: ThemeColor.primaryColor,
        onRefresh: () async {
          await Future.wait([_loadMembers(reset: true), _load()]);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) _loadMembers();
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 30),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _members.length + 2,
            itemBuilder: (_, i) {
              if (i == 0) return header;
              if (i == _members.length + 1) {
                return _membersLoading.value
                    ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)))
                    : const SizedBox.shrink();
              }
              return _memberTile(c, _members[i - 1], me);
            },
          ),
        ),
      );
    });
  }

  Widget _memberTile(CommunityEntity c, MemberEntity m, int? me) {
    final isMe = m.user.id == me;
    final role = m.role;
    final creatorRow = m.user.id == c.creator.id;

    // Quién puede actuar sobre esta persona
    final canManageRole = c.isAdmin && !isMe && !creatorRow;
    final canKick = !isMe && !creatorRow && ((c.isAdmin && role != 'admin') || (c.canModerate && role == 'miembro'));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: isMe ? null : () => Get.toNamed(RoutesNames.userProfileDetailPage, arguments: {'userId': m.user.id}),
      leading: UserAvatar(url: m.user.photoUrl, radius: 22),
      title: Row(
        children: [
          Flexible(child: Text(m.user.name, style: FeedStyle.name.copyWith(fontSize: 15.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (role != 'miembro') ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: ThemeColor.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(role == 'admin' ? _l.t('community_role_admin') : _l.t('community_role_moderator'),
                  style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: ThemeColor.primaryColor)),
            ),
          ],
        ],
      ),
      trailing: canManageRole || canKick
          ? PopupMenuButton<String>(
              icon: Icon(LucideIcons.ellipsis, color: ThemeColor.textSecondary),
              color: FeedStyle.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (value) async {
                try {
                  if (value == 'kick') {
                    await _repo.kick(c.id, m.user.id);
                  } else {
                    _sync(await _repo.changeRole(c.id, m.user.id, value));
                  }
                  _loadMembers(reset: true);
                } catch (e) {
                  showErrorSnackbarGetx(cleanExceptionMessage(e));
                }
              },
              itemBuilder: (_) => [
                if (canManageRole && role != 'admin') PopupMenuItem(value: 'admin', child: Text(_l.t('community_make_admin'))),
                if (canManageRole && role != 'moderador') PopupMenuItem(value: 'moderador', child: Text(_l.t('community_make_moderator'))),
                if (canManageRole && role != 'miembro') PopupMenuItem(value: 'miembro', child: Text(_l.t('community_make_member'))),
                if (canKick) PopupMenuItem(value: 'kick', child: Text(_l.t('community_kick'), style: const TextStyle(color: Colors.redAccent))),
              ],
            )
          : null,
    );
  }

  void _menu(CommunityEntity c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FeedStyle.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.isAdmin)
                ListTile(
                  leading: Icon(LucideIcons.pencil, color: ThemeColor.textPrimary),
                  title: Text(_l.t('community_edit')),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final updated = await Get.toNamed(RoutesNames.createCommunityPage, arguments: {'community': c});
                    if (updated is CommunityEntity) _load();
                  },
                ),
              if (c.isCreator)
                ListTile(
                  leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                  title: Text(_l.t('community_delete'), style: const TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _deleteCommunity();
                  },
                )
              else
                ListTile(
                  leading: Icon(LucideIcons.flag, color: ThemeColor.textPrimary),
                  title: Text(_l.t('feed_report')),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      await _repo.report(c.id);
                      showSuccessSnackbarGetx(_l.t('feed_reported'));
                    } catch (e) {
                      showErrorSnackbarGetx(cleanExceptionMessage(e));
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _memberSheet(CommunityEntity c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FeedStyle.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(LucideIcons.squarePen, color: ThemeColor.primaryColor),
                title: Text(_l.t('community_post_here')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _newPost(c);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.logOut, color: Colors.redAccent),
                title: Text(_l.t('community_leave'), style: const TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _leave();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestsSheet(CommunityEntity c) async {
    List<MemberEntity> requests;
    try {
      requests = await _repo.requests(c.id);
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
      return;
    }
    if (!mounted) return;

    final list = requests.obs;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FeedStyle.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(_l.t('plan_requests'), style: FeedStyle.name.copyWith(fontSize: 17)),
            ),
            Expanded(
              child: Obx(() => list.isEmpty
                  ? Center(child: Text(_l.t('community_no_requests'), style: FeedStyle.meta))
                  : ListView(
                      children: [
                        for (final m in list.toList())
                          ListTile(
                            leading: UserAvatar(url: m.user.photoUrl, radius: 22),
                            title: Text(m.user.name, style: FeedStyle.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.x, color: Colors.redAccent),
                                  onPressed: () async {
                                    try {
                                      _sync(await _repo.respond(c.id, m.user.id, accept: false));
                                      list.remove(m);
                                    } catch (e) {
                                      showErrorSnackbarGetx(cleanExceptionMessage(e));
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.check, color: Color(0xFF1F9D57)),
                                  onPressed: () async {
                                    try {
                                      _sync(await _repo.respond(c.id, m.user.id, accept: true));
                                      list.remove(m);
                                    } catch (e) {
                                      showErrorSnackbarGetx(cleanExceptionMessage(e));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    )),
            ),
          ],
        ),
      ),
    );
  }
}
