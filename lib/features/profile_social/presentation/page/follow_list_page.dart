import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/profile_social/data/profile_social_repository.dart';

/// Quién sigue a una persona y a quién sigue (dos pestañas).
class FollowListPage extends StatefulWidget {
  const FollowListPage({super.key});

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> with SingleTickerProviderStateMixin {
  final LanguageController _l = Get.find<LanguageController>();
  late final int _userId;
  late final TabController _tabs;
  int? _me;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _userId = args?['userId'] ?? 0;
    _tabs = TabController(length: 2, vsync: this, initialIndex: (args?['tab'] as int?) ?? 0);
    AuthService().getUserId().then((id) {
      if (mounted) setState(() => _me = id);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
        iconTheme: IconThemeData(color: ThemeColor.textPrimary),
        title: Text(_l.t('profile_connections'), style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: ThemeColor.primaryColor,
          unselectedLabelColor: ThemeColor.textSecondary,
          indicatorColor: ThemeColor.primaryColor,
          labelStyle: GoogleFonts.rubik(fontWeight: FontWeight.w600),
          tabs: [Tab(text: _l.t('profile_followers')), Tab(text: _l.t('profile_following'))],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _FollowList(userId: _userId, me: _me, followers: true),
          _FollowList(userId: _userId, me: _me, followers: false),
        ],
      ),
    );
  }
}

class _FollowList extends StatefulWidget {
  final int userId;
  final int? me;
  final bool followers;

  const _FollowList({required this.userId, required this.me, required this.followers});

  @override
  State<_FollowList> createState() => _FollowListState();
}

class _FollowListState extends State<_FollowList> with AutomaticKeepAliveClientMixin {
  final ProfileSocialRepository _repo = ProfileSocialRepository.instance;
  final LanguageController _l = Get.find<LanguageController>();

  final RxList<FollowUserEntity> _items = <FollowUserEntity>[].obs;
  final RxBool _loading = false.obs;
  final RxBool _hasMore = true.obs;
  String? _error;
  int _page = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading.value) return;
    if (reset) {
      _page = 0;
      _hasMore.value = true;
      _items.clear();
    }
    if (!_hasMore.value) return;

    try {
      _loading.value = true;
      _error = null;
      final result = widget.followers
          ? await _repo.followers(widget.userId, page: _page + 1)
          : await _repo.following(widget.userId, page: _page + 1);
      _page++;
      _items.addAll(result.items);
      _hasMore.value = result.hasNext;
    } catch (e) {
      _error = cleanExceptionMessage(e);
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _toggle(int index) async {
    final user = _items[index];
    final target = !user.iFollow;
    _items[index] = user.copyWith(iFollow: target); // respuesta inmediata
    try {
      await _repo.setFollow(user.userId, follow: target);
    } catch (e) {
      _items[index] = user;
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      if (_loading.value && _items.isEmpty) return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));

      if (_items.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => _load(reset: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 110),
              Icon(LucideIcons.users, size: 44, color: ThemeColor.textSecondary.withValues(alpha: 0.5)),
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 14, 36, 0),
                child: Text(_error ?? (widget.followers ? _l.t('follow_list_empty_followers') : _l.t('follow_list_empty_following')),
                    textAlign: TextAlign.center, style: FeedStyle.body.copyWith(color: ThemeColor.textSecondary)),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) _load();
            return false;
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _items.length + 1,
            itemBuilder: (_, i) {
              if (i == _items.length) {
                return _loading.value
                    ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)))
                    : const SizedBox(height: 24);
              }
              return _tile(i);
            },
          ),
        ),
      );
    });
  }

  Widget _tile(int i) {
    final u = _items[i];
    final isMe = u.userId == widget.me;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: isMe ? null : () => Get.toNamed(RoutesNames.userProfileDetailPage, arguments: {'userId': u.userId}),
      leading: UserAvatar(url: u.photoUrl, radius: 24),
      title: Text(u.name, style: FeedStyle.name.copyWith(fontSize: 15.5), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: u.bio != null && u.bio!.isNotEmpty ? Text(u.bio!, maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.meta) : null,
      trailing: isMe
          ? null
          : GestureDetector(
              onTap: () => _toggle(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: u.iFollow ? Colors.transparent : ThemeColor.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ThemeColor.primaryColor),
                ),
                child: Text(u.iFollow ? _l.t('following_btn') : _l.t('follow_btn'),
                    style: GoogleFonts.rubik(fontSize: 12.5, fontWeight: FontWeight.w600, color: u.iFollow ? ThemeColor.primaryColor : Colors.white)),
              ),
            ),
    );
  }
}
