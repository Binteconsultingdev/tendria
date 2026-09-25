import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/feed/data/datasources/feed_data_sources_imp.dart';
import 'package:tendria/features/feed/data/repositories/feed_repository_imp.dart';
import 'package:tendria/features/feed/domain/repositories/feed_repository.dart';
import 'package:tendria/features/feed/presentation/controller/create_post_controller.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/user/presentation/controller/profile_controller.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  late final CreatePostController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<FeedRepository>()) {
      Get.put<FeedRepository>(FeedRepositoryImp(dataSource: FeedDataSourcesImp()), permanent: true);
    }
    controller = Get.put(CreatePostController(repository: Get.find<FeedRepository>()));
  }

  @override
  void dispose() {
    Get.delete<CreatePostController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = Get.find<LanguageController>();
    final profile = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;

    return Scaffold(
      backgroundColor: FeedStyle.surface,
      appBar: AppBar(
        backgroundColor: FeedStyle.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.x, size: 22, color: ThemeColor.textPrimary), onPressed: Get.back),
        title: Text(l.t('feed_create_title'), style: FeedStyle.name.copyWith(fontSize: 17)),
        centerTitle: true,
        actions: [
          Obx(() {
            final enabled = controller.canPublish;
            return Padding(
              padding: const EdgeInsets.only(right: 14, top: 9, bottom: 9),
              child: GestureDetector(
                onTap: enabled ? controller.publish : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: enabled ? ThemeColor.primaryGradient : null,
                    color: enabled ? null : FeedStyle.hairline,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l.t('feed_publish'),
                    style: FeedStyle.name.copyWith(color: enabled ? Colors.white : ThemeColor.textSecondary, fontSize: 14),
                  ),
                ),
              ),
            );
          }),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Obx(() => controller.isPublishing.value
              ? LinearProgressIndicator(minHeight: 2, color: ThemeColor.primaryColor, backgroundColor: FeedStyle.hairline)
              : Divider(height: 1, thickness: 1, color: FeedStyle.hairline)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                Row(
                  children: [
                    profile == null
                        ? const UserAvatar(url: null, radius: 22)
                        : Obx(() => UserAvatar(url: profile.userEntity.value?.fotoUrl, radius: 22)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.userName ?? '', style: FeedStyle.name.copyWith(fontSize: 15.5)),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: ThemeColor.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.users, size: 13, color: ThemeColor.primaryColor),
                              const SizedBox(width: 5),
                              Text(((Get.arguments as Map<String, dynamic>?)?['communityName'] as String?) ?? l.t('feed_audience'),
                                  style: FeedStyle.meta.copyWith(color: ThemeColor.primaryColor, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller.textController,
                  autofocus: true,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 12,
                  textCapitalization: TextCapitalization.sentences,
                  style: FeedStyle.body.copyWith(fontSize: 18, height: 1.5),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: l.t('feed_write'),
                    hintStyle: FeedStyle.body.copyWith(fontSize: 18, color: ThemeColor.textSecondary.withValues(alpha: 0.7)),
                  ),
                ),
                Obx(() => controller.media.isEmpty
                    ? const SizedBox.shrink()
                    : SizedBox(
                        height: 170,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.media.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, index) {
                            final item = controller.media[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: SizedBox(
                                    width: 130,
                                    height: 170,
                                    child: item.isVideo
                                        ? Container(
                                            color: Colors.black,
                                            child: const Center(
                                              child: Icon(LucideIcons.circlePlay, color: Colors.white, size: 46),
                                            ),
                                          )
                                        : Image.file(item.file, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => controller.removeMedia(item),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                                      child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: FeedStyle.hairline))),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _ToolButton(icon: LucideIcons.image, label: l.t('feed_add_photo'), onTap: controller.pickPhotos),
                    _ToolButton(icon: LucideIcons.video, label: l.t('feed_add_video'), onTap: controller.pickVideo),
                    const Spacer(),
                    Obx(() => Text('${controller.media.length}/${CreatePostController.maxMedia}', style: FeedStyle.meta)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: ThemeColor.primaryColor),
      label: Text(label, style: FeedStyle.name.copyWith(color: ThemeColor.primaryColor, fontSize: 14)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
    );
  }
}
