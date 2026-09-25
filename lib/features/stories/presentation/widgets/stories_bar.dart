import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/stories/presentation/page/story_controller.dart';
import 'package:tendria/features/stories/presentation/page/storyring/my_story_ring_widget.dart';
import 'package:tendria/features/stories/presentation/page/storyring/story_ring_widget.dart';
import 'package:tendria/features/stories/presentation/widgets/story_ring_loading.dart';

/// Fila horizontal de historias (la mía primero) para la parte superior del Feed.
class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();
    final storyController = Get.find<StoryController>();

    return SizedBox(
      height: 110,
      child: Obx(() {
        if (storyController.isLoading.value) {
          // Este widget ya incluye su propia lista horizontal
          return const StoryRingLoading(size: 70, multiple: true);
        }

        final totalUsers = storyController.allStories.length;

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: ThemeColor.paddingMedium),
          itemCount: totalUsers + 1,
          itemBuilder: (context, index) {
            final isMine = index == 0;
            final userIndex = index - 1;

            return Column(
              children: [
                isMine
                    ? const MyStoryRingWidget(size: 70)
                    : StoryRingWidget(index: userIndex, size: 70),
                const SizedBox(height: 4),
                SizedBox(
                  width: 70,
                  child: Text(
                    isMine ? l.t('my_story') : (storyController.getUserName(userIndex) ?? l.t('user')),
                    style: ThemeColor.caption.copyWith(color: ThemeColor.textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
