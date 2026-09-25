import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';
import 'package:tendria/features/feed/domain/repositories/feed_repository.dart';
import 'package:tendria/features/feed/presentation/controller/comments_controller.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/feed/presentation/widget/time_ago.dart';
import 'package:tendria/features/user/presentation/controller/profile_controller.dart';

Future<void> showCommentsSheet(BuildContext context, int postId) async {
  final tag = 'comments_$postId';
  Get.put(CommentsController(repository: Get.find<FeedRepository>(), postId: postId), tag: tag);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FeedStyle.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _CommentsSheet(tag: tag),
  );
}

class _CommentsSheet extends StatefulWidget {
  final String tag;
  const _CommentsSheet({required this.tag});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late final CommentsController c = Get.find<CommentsController>(tag: widget.tag);
  LanguageController get _l => Get.find<LanguageController>();

  @override
  void dispose() {
    // Se libera cuando la hoja ya terminó de cerrarse (no antes, o falla durante la animación)
    Get.delete<CommentsController>(tag: widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(color: FeedStyle.hairline.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(_l.t('feed_comments'), style: FeedStyle.name.copyWith(fontSize: 16.5)),
            ),
            Divider(height: 1, color: FeedStyle.hairline),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value && c.comments.isEmpty) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
                }
                if (c.comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.messageCircle, size: 48, color: ThemeColor.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(_l.t('feed_no_comments'), style: FeedStyle.link),
                      ],
                    ),
                  );
                }
                final top = c.topLevel;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  children: [
                    for (final comment in top) ...[
                      _CommentTile(comment: comment, controller: c),
                      for (final reply in c.repliesOf(comment))
                        Padding(
                          padding: const EdgeInsets.only(left: 44),
                          child: _CommentTile(comment: reply, controller: c, isReply: true),
                        ),
                    ],
                    if (c.hasMore.value)
                      TextButton(onPressed: c.load, child: Text(_l.t('feed_load_more'))),
                  ],
                );
              }),
            ),
            _input(),
          ],
        ),
      ),
    );
  }

  Widget _input() {
    final profile = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;

    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: FeedStyle.hairline))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 10, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final target = c.replyingTo.value;
                if (target == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(color: ThemeColor.backgroundColorfondo, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${_l.t('feed_replying_to')} ${target.author.name}', style: FeedStyle.meta),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: c.cancelReply,
                      ),
                    ],
                  ),
                );
              }),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  profile == null
                      ? const UserAvatar(url: null, radius: 17)
                      : Obx(() => UserAvatar(url: profile.userEntity.value?.fotoUrl, radius: 17)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: c.textController,
                      maxLength: 1000,
                      minLines: 1,
                      maxLines: 4,
                      style: FeedStyle.body.copyWith(fontSize: 14.5),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        counterText: '',
                        isDense: true,
                        hintText: _l.t('feed_comment_hint'),
                        hintStyle: FeedStyle.meta.copyWith(fontSize: 14.5),
                        filled: true,
                        fillColor: ThemeColor.backgroundColorfondo,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => GestureDetector(
                        onTap: c.isSending.value ? null : c.send,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(gradient: ThemeColor.primaryGradient, shape: BoxShape.circle),
                          child: c.isSending.value
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(LucideIcons.arrowUp, color: Colors.white, size: 20),
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentEntity comment;
  final CommentsController controller;
  final bool isReply;

  const _CommentTile({required this.comment, required this.controller, this.isReply = false});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(url: comment.author.photoUrl, radius: isReply ? 13 : 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: ThemeColor.backgroundColorfondo,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.author.name, style: FeedStyle.name.copyWith(fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(comment.text, style: FeedStyle.body.copyWith(fontSize: 14.5)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 4),
                  child: Row(
                    children: [
                      Text(timeAgo(comment.createdAt), style: FeedStyle.meta.copyWith(fontSize: 11.5)),
                      if (!isReply) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => controller.startReply(comment),
                          child: Text(l.t('feed_reply'),
                              style: FeedStyle.meta.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(LucideIcons.ellipsis, size: 20, color: ThemeColor.textSecondary),
            color: FeedStyle.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'delete') controller.delete(comment);
              if (value == 'report') controller.report(comment);
            },
            itemBuilder: (_) => [
              if (comment.isMine)
                PopupMenuItem(value: 'delete', child: Text(l.t('feed_delete')))
              else
                PopupMenuItem(value: 'report', child: Text(l.t('feed_report'))),
            ],
          ),
        ],
      ),
    );
  }
}
