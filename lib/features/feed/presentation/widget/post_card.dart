import 'package:tendria/features/feed/presentation/widget/post_media_layouts.dart';
import 'package:tendria/features/feed/presentation/widget/post_style.dart';
import 'package:tendria/features/gift/presentation/widget/gift_sheet.dart';
import 'package:tendria/features/feed/presentation/widget/reaction_icon.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';
import 'package:tendria/features/feed/presentation/controller/feed_controller.dart';
import 'package:tendria/features/feed/presentation/widget/comments_sheet.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/feed/presentation/widget/post_video_player.dart';
import 'package:tendria/features/feed/presentation/widget/reaction_popover.dart';
import 'package:tendria/features/feed/presentation/widget/time_ago.dart';

const String _quickReaction = 'me_encanta';

class PostCard extends StatelessWidget {
  final PostEntity post;
  final FeedController controller;

  PostCard({super.key, required this.post, required this.controller});

  final GlobalKey _reactKey = GlobalKey();

  LanguageController get _l => Get.find<LanguageController>();

  bool get _isTextCard =>
      post.media.isEmpty &&
      post.text != null &&
      (post.background != null || (post.text!.trim().length <= 160 && !post.text!.contains('\n')));

  void _likeFromDoubleTap() {
    if (post.myReaction != _quickReaction) controller.react(post, type: _quickReaction);
  }

  void _openReactionPicker(BuildContext context) {
    final box = _reactKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    showReactionPopover(
      context: context,
      anchor: anchor,
      current: post.myReaction,
      onSelected: (type) => controller.react(post, type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: FeedStyle.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          if (_isTextCard) _textCard(),
          if (post.media.length >= 2 && (post.layout == PostLayouts.mosaic || post.layout == PostLayouts.grid))
            PostMediaGallery(media: post.media, layout: post.layout!)
          else if (post.media.isNotEmpty)
            _MediaCarousel(media: post.media, onDoubleTapLike: _likeFromDoubleTap),
          _actions(context),
          if (!_isTextCard && post.text != null && post.text!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
              child: post.media.isNotEmpty
                  ? _Caption(author: post.author.name, text: post.text!, moreLabel: _l.t('feed_see_more'))
                  : Text(post.text!, style: FeedStyle.body),
            ),
          if (post.totalComments > 0)
            GestureDetector(
              onTap: () => _openComments(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  post.totalComments == 1
                      ? _l.t('feed_view_one')
                      : '${_l.t('feed_view_all')} ${post.totalComments} ${_l.t('feed_comments').toLowerCase()}',
                  style: FeedStyle.link,
                ),
              ),
            ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Future<void> _openComments(BuildContext context) async {
    await showCommentsSheet(context, post.id);
    controller.reloadPost(post.id);
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: post.isMine
                  ? null
                  : () => Get.toNamed(RoutesNames.userProfileDetailPage, arguments: {'userId': post.author.id}),
              child: Row(
                children: [
                  UserAvatar(url: post.author.photoUrl, radius: 17),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _nameLine(),
                        Row(
                          children: [
                            Text(timeAgo(post.createdAt), style: FeedStyle.meta),
                            if (post.location != null && post.location!.isNotEmpty) ...[
                              Text('  ·  ', style: FeedStyle.meta),
                              Icon(LucideIcons.mapPin, size: 12, color: ThemeColor.textSecondary),
                              const SizedBox(width: 2),
                              Flexible(child: Text(post.location!, maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.meta)),
                            ],
                            if (post.community != null) ...[
                              Text('  ·  ', style: FeedStyle.meta),
                              Flexible(
                                child: GestureDetector(
                                  onTap: () => Get.toNamed(RoutesNames.communityDetailPage, arguments: {'communityId': post.community!.id}),
                                  child: Text(post.community!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: FeedStyle.meta.copyWith(color: ThemeColor.primaryColor, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(LucideIcons.ellipsis, size: 19, color: ThemeColor.textSecondary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: FeedStyle.surface,
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(context);
              if (value == 'report') controller.reportPost(post);
            },
            itemBuilder: (_) => [
              if (post.canDelete)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(LucideIcons.trash2, size: 20, color: Colors.redAccent),
                    const SizedBox(width: 10),
                    Text(_l.t('feed_delete')),
                  ]),
                )
              else
                PopupMenuItem(
                  value: 'report',
                  child: Row(children: [
                    Icon(LucideIcons.flag, size: 20, color: ThemeColor.textPrimary),
                    const SizedBox(width: 10),
                    Text(_l.t('feed_report')),
                  ]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Nombre del autor y, si lo indicó, "se siente <sentimiento>".
  Widget _nameLine() {
    final feeling = PostFeeling.of(post.feeling);
    if (feeling == null) {
      return Text(post.author.name, style: FeedStyle.name, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return Text.rich(
      TextSpan(
        style: FeedStyle.name,
        children: [
          TextSpan(text: post.author.name),
          TextSpan(text: ' ${_l.t('post_feels')} ', style: FeedStyle.meta.copyWith(fontSize: 13.5)),
          WidgetSpan(alignment: PlaceholderAlignment.middle, child: FeelingBadge(feeling: feeling, size: 17)),
          TextSpan(text: ' ${_l.t('feeling_${feeling.id}')}', style: FeedStyle.name.copyWith(fontSize: 13.5)),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _textCard() {
    final bg = PostBackground.of(post.background);
    final text = post.text!.trim();
    // Cuanto más largo el texto, más chica la letra
    final size = text.length <= 60 ? 26.0 : (text.length <= 140 ? 22.0 : (text.length <= 260 ? 19.0 : 16.5));

    return GestureDetector(
      onDoubleTap: _likeFromDoubleTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: bg != null ? 250 : 150),
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: bg?.gradient ?? ThemeColor.primaryGradient,
          borderRadius: BorderRadius.circular(bg != null ? 22 : 18),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.rubik(
            fontSize: bg != null ? size : 18,
            height: 1.35,
            fontWeight: bg != null ? FontWeight.w600 : FontWeight.w500,
            color: bg?.textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final mine = post.myReaction;
    final top = post.reactions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            key: _reactKey,
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              controller.react(post);
            },
            onLongPress: () => _openReactionPicker(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                  child: child,
                ),
                child: mine != null
                    ? ReactionIcon(key: ValueKey(mine), type: mine, size: 24)
                    : Icon(LucideIcons.heart,
                        key: const ValueKey('none'), size: 22, color: ThemeColor.textSecondary),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openComments(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(LucideIcons.messageCircle, size: 21, color: ThemeColor.textSecondary),
                  if (post.totalComments > 0) ...[
                    const SizedBox(width: 6),
                    Text('${post.totalComments}', style: FeedStyle.meta.copyWith(fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          if (!post.isMine)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showGiftSheet(
                context,
                toUserId: post.author.id,
                toName: post.author.name,
                origin: 'post',
                postId: post.id,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(LucideIcons.gift, size: 20, color: ThemeColor.textSecondary),
              ),
            ),
          const Spacer(),
          if (post.totalReactions > 0) _ReactionStack(types: top.take(3).map((e) => e.key).toList(), total: post.totalReactions),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FeedStyle.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_l.t('feed_confirm_delete'), style: FeedStyle.name.copyWith(fontSize: 17)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    controller.deletePost(post);
                  },
                  child: Text(_l.t('feed_delete')),
                ),
              ),
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(_l.t('cancel'))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionStack extends StatelessWidget {
  final List<String> types;
  final int total;

  const _ReactionStack({required this.types, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22.0 + (types.length - 1) * 12,
          height: 22,
          child: Stack(
            children: [
              for (var i = types.length - 1; i >= 0; i--)
                Positioned(
                  left: i * 12.0,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: FeedStyle.surface,
                      border: Border.all(color: FeedStyle.surface, width: 2),
                    ),
                    child: ReactionIcon(type: types[i], size: 17),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('$total', style: FeedStyle.meta.copyWith(fontSize: 13)),
      ],
    );
  }
}

class _Caption extends StatefulWidget {
  final String author;
  final String text;
  final String moreLabel;

  const _Caption({required this.author, required this.text, required this.moreLabel});

  @override
  State<_Caption> createState() => _CaptionState();
}

class _CaptionState extends State<_Caption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final long = widget.text.length > 110;

    return GestureDetector(
      onTap: long && !_expanded ? () => setState(() => _expanded = true) : null,
      child: RichText(
        maxLines: _expanded ? null : 3,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: FeedStyle.body,
          children: [
            TextSpan(text: '${widget.author} ', style: FeedStyle.name.copyWith(fontSize: 15)),
            TextSpan(text: widget.text),
            if (long && !_expanded) TextSpan(text: '  ${widget.moreLabel}', style: FeedStyle.link),
          ],
        ),
      ),
    );
  }
}

class _MediaCarousel extends StatefulWidget {
  final List<PostMediaEntity> media;
  final VoidCallback onDoubleTapLike;

  const _MediaCarousel({required this.media, required this.onDoubleTapLike});

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> with SingleTickerProviderStateMixin {
  int _index = 0;

  late final AnimationController _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.25).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 20),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
  ]).animate(_burst);

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
  ]).animate(_burst);

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  void _doubleTap() {
    HapticFeedback.mediumImpact();
    _burst.forward(from: 0);
    widget.onDoubleTapLike();
  }

  @override
  Widget build(BuildContext context) {
    final many = widget.media.length > 1;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                itemCount: widget.media.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final item = widget.media[i];
                  if (item.isVideo) return PostVideoPlayer(url: item.url, onDoubleTap: _doubleTap);
                  return GestureDetector(
                    onDoubleTap: _doubleTap,
                    child: CachedNetworkImage(
                      imageUrl: item.url,
                      fit: BoxFit.cover,
                      memCacheWidth: 1080,
                      fadeInDuration: const Duration(milliseconds: 250),
                      placeholder: (_, __) => ColoredBox(color: FeedStyle.hairline),
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: FeedStyle.hairline,
                        child: Center(child: Icon(LucideIcons.imageOff, size: 40, color: ThemeColor.textSecondary)),
                      ),
                    ),
                  );
                },
              ),
              if (many)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(14)),
                    child: Text('${_index + 1}/${widget.media.length}',
                        style: GoogleFonts.rubik(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                ),
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (_, __) => _burst.isAnimating
                      ? Center(
                          child: Opacity(
                            opacity: _opacity.value,
                            child: Transform.scale(
                              scale: _scale.value,
                              child: const Icon(
                                Icons.favorite_rounded,
                                size: 84,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black38, blurRadius: 24)],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
        if (many)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.media.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _index ? 8 : 6,
                  height: i == _index ? 8 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? ThemeColor.primaryColor : ThemeColor.textSecondary.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
