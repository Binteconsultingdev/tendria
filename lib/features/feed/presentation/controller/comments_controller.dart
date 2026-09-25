import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';
import 'package:tendria/features/feed/domain/repositories/feed_repository.dart';

class CommentsController extends GetxController {
  final FeedRepository repository;
  final int postId;

  CommentsController({required this.repository, required this.postId});

  final TextEditingController textController = TextEditingController();
  final RxList<CommentEntity> comments = <CommentEntity>[].obs;
  final Rxn<CommentEntity> replyingTo = Rxn<CommentEntity>();
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxBool hasMore = true.obs;
  int? _nextCursor;

  LanguageController get _l => Get.find<LanguageController>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final page = await repository.getComments(postId, cursor: _nextCursor);
      comments.addAll(page.items);
      _nextCursor = page.nextCursor;
      hasMore.value = page.nextCursor != null;
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  /// Comentarios principales (en orden) y sus respuestas agrupadas debajo de cada uno.
  List<CommentEntity> get topLevel => comments.where((c) => c.parentId == null).toList();

  List<CommentEntity> repliesOf(CommentEntity parent) =>
      comments.where((c) => c.parentId == parent.id).toList();

  void startReply(CommentEntity comment) => replyingTo.value = comment;
  void cancelReply() => replyingTo.value = null;

  Future<void> send() async {
    final text = textController.text.trim();
    if (text.isEmpty || isSending.value) return;
    try {
      isSending.value = true;
      final created = await repository.addComment(postId, text, parentId: replyingTo.value?.id);
      comments.add(created);
      textController.clear();
      replyingTo.value = null;
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      isSending.value = false;
    }
  }

  Future<void> delete(CommentEntity comment) async {
    try {
      await repository.deleteComment(comment.id);
      comments.removeWhere((c) => c.id == comment.id || c.parentId == comment.id);
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    }
  }

  Future<void> report(CommentEntity comment) async {
    try {
      await repository.reportComment(comment.id);
      showSuccessSnackbarGetx(_l.t('feed_reported'));
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    }
  }
}
