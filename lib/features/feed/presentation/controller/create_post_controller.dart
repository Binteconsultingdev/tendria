import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/feed/domain/repositories/feed_repository.dart';
import 'package:video_player/video_player.dart';

class PickedMedia {
  final File file;
  final bool isVideo;
  PickedMedia({required this.file, required this.isVideo});
}

class CreatePostController extends GetxController {
  static const int maxMedia = 10;
  static const int maxVideoSeconds = 60;
  static const int maxVideoBytes = 50 * 1024 * 1024;
  static const int maxPhotoBytes = 10 * 1024 * 1024;

  final FeedRepository repository;
  CreatePostController({required this.repository});

  /// Si se abre desde una comunidad, la publicación se hace dentro de ella.
  final int? communityId = (Get.arguments as Map<String, dynamic>?)?['communityId'];

  final TextEditingController textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final RxList<PickedMedia> media = <PickedMedia>[].obs;
  final RxBool isPublishing = false.obs;
  final RxBool hasText = false.obs;

  LanguageController get _l => Get.find<LanguageController>();

  @override
  void onInit() {
    super.onInit();
    textController.addListener(() => hasText.value = textController.text.trim().isNotEmpty);
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  bool get canPublish =>
      !isPublishing.value && (hasText.value || media.isNotEmpty);

  Future<void> pickPhotos() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1440);
      for (final image in images) {
        if (media.length >= maxMedia) {
          showErrorSnackbarGetx(_l.t('feed_max_media'));
          break;
        }
        final file = File(image.path);
        if (await file.length() > maxPhotoBytes) {
          showErrorSnackbarGetx('${image.name}: max 10 MB');
          continue;
        }
        media.add(PickedMedia(file: file, isVideo: false));
      }
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    }
  }

  Future<void> pickVideo() async {
    if (media.length >= maxMedia) {
      showErrorSnackbarGetx(_l.t('feed_max_media'));
      return;
    }
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: maxVideoSeconds),
      );
      if (picked == null) return;

      final file = File(picked.path);
      if (await file.length() > maxVideoBytes) {
        showErrorSnackbarGetx(_l.t('feed_video_too_big'));
        return;
      }

      final probe = VideoPlayerController.file(file);
      try {
        await probe.initialize();
        if (probe.value.duration.inSeconds > maxVideoSeconds) {
          showErrorSnackbarGetx(_l.t('feed_video_too_long'));
          return;
        }
      } finally {
        await probe.dispose();
      }

      media.add(PickedMedia(file: file, isVideo: true));
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    }
  }

  void removeMedia(PickedMedia item) => media.remove(item);

  Future<void> publish() async {
    if (!canPublish) return;
    try {
      isPublishing.value = true;
      final post = await repository.createPost(
        text: textController.text,
        files: media.map((m) => m.file).toList(),
        communityId: communityId,
      );
      Get.back(result: post);
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      isPublishing.value = false;
    }
  }
}
