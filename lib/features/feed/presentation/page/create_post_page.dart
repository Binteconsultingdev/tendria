import 'package:tendria/features/feed/presentation/widget/post_style.dart';
import 'package:google_fonts/google_fonts.dart';
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
                _chipsRow(l),
                Obx(() {
                  final bg = controller.media.isEmpty ? PostBackground.of(controller.background.value) : null;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints: BoxConstraints(minHeight: bg != null ? 260 : 0),
                    padding: bg != null ? const EdgeInsets.all(24) : EdgeInsets.zero,
                    alignment: Alignment.center,
                    decoration: bg != null ? BoxDecoration(gradient: bg.gradient, borderRadius: BorderRadius.circular(22)) : null,
                    child: TextField(
                      controller: controller.textController,
                      autofocus: true,
                      maxLength: 2000,
                      minLines: bg != null ? 1 : 3,
                      maxLines: 12,
                      textAlign: bg != null ? TextAlign.center : TextAlign.start,
                      textCapitalization: TextCapitalization.sentences,
                      cursorColor: bg?.textColor,
                      style: bg != null
                          ? GoogleFonts.rubik(fontSize: 24, height: 1.35, fontWeight: FontWeight.w600, color: bg.textColor)
                          : FeedStyle.body.copyWith(fontSize: 18, height: 1.5),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: l.t('feed_write'),
                        hintStyle: bg != null
                            ? GoogleFonts.rubik(fontSize: 24, fontWeight: FontWeight.w600, color: bg.textColor.withValues(alpha: 0.6))
                            : FeedStyle.body.copyWith(fontSize: 18, color: ThemeColor.textSecondary.withValues(alpha: 0.7)),
                      ),
                    ),
                  );
                }),
                Obx(() => controller.media.isEmpty ? _backgroundPalette(l) : _layoutPicker(l)),
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
                    IconButton(
                      tooltip: l.t('post_feeling'),
                      icon: Icon(LucideIcons.smilePlus, color: ThemeColor.primaryColor),
                      onPressed: () => _pickFeeling(context, l),
                    ),
                    IconButton(
                      tooltip: l.t('post_location'),
                      icon: Icon(LucideIcons.mapPin, color: ThemeColor.primaryColor),
                      onPressed: () => _askLocation(context, l),
                    ),
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

extension _CreatePostExtras on _CreatePostPageState {
  /// Sentimiento y ubicación elegidos, como fichas que se pueden quitar.
  Widget _chipsRow(LanguageController l) {
    return Obx(() {
      final feeling = PostFeeling.of(controller.feeling.value);
      final location = controller.location.value;
      if (feeling == null && location.isEmpty) return const SizedBox.shrink();

      Widget chip({required Widget leading, required String text, required VoidCallback onClear}) => Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
            decoration: BoxDecoration(color: ThemeColor.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                leading,
                const SizedBox(width: 6),
                Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.name.copyWith(fontSize: 13))),
                const SizedBox(width: 6),
                GestureDetector(onTap: onClear, child: Icon(LucideIcons.x, size: 14, color: ThemeColor.textSecondary)),
              ],
            ),
          );

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (feeling != null)
              chip(
                leading: FeelingBadge(feeling: feeling, size: 20),
                text: '${l.t('post_feels')} ${l.t('feeling_${feeling.id}')}',
                onClear: () => controller.feeling.value = null,
              ),
            if (location.isNotEmpty)
              chip(
                leading: Icon(LucideIcons.mapPin, size: 16, color: ThemeColor.primaryColor),
                text: location,
                onClear: () => controller.location.value = '',
              ),
          ],
        ),
      );
    });
  }

  /// Fondos de color para publicaciones de solo texto.
  Widget _backgroundPalette(LanguageController l) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 44,
        child: Obx(() => ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _swatch(null, controller.background.value == null),
                for (final bg in PostBackground.all) _swatch(bg, controller.background.value == bg.id),
              ],
            )),
      ),
    );
  }

  Widget _swatch(PostBackground? bg, bool selected) {
    return GestureDetector(
      onTap: () => controller.background.value = bg?.id,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: bg?.gradient,
          color: bg == null ? FeedStyle.hairline : null,
          border: Border.all(color: selected ? ThemeColor.primaryColor : Colors.transparent, width: 2.5),
        ),
        child: bg == null ? Text('Aa', style: FeedStyle.name.copyWith(fontSize: 13)) : null,
      ),
    );
  }

  /// Disposición cuando hay 2 o más fotos.
  Widget _layoutPicker(LanguageController l) {
    return Obx(() {
      if (controller.media.length < 2) return const SizedBox.shrink();
      String label(String id) => l.t(switch (id) {
            PostLayouts.mosaic => 'post_layout_mosaic',
            PostLayouts.grid => 'post_layout_grid',
            _ => 'post_layout_carousel',
          });
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          children: [
            for (final id in PostLayouts.all)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => controller.layout.value = id,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: controller.layout.value == id ? ThemeColor.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: controller.layout.value == id ? ThemeColor.primaryColor : FeedStyle.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PostLayouts.icon(id), size: 15, color: controller.layout.value == id ? ThemeColor.primaryColor : ThemeColor.textSecondary),
                        const SizedBox(width: 6),
                        Text(label(id),
                            style: FeedStyle.name.copyWith(
                                fontSize: 12.5, color: controller.layout.value == id ? ThemeColor.primaryColor : ThemeColor.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _pickFeeling(BuildContext context, LanguageController l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: FeedStyle.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.t('post_feeling'), style: FeedStyle.name.copyWith(fontSize: 17)),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final f in PostFeeling.all)
                        GestureDetector(
                          onTap: () {
                            controller.feeling.value = f.id;
                            Navigator.of(ctx).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                            decoration: BoxDecoration(
                              color: controller.feeling.value == f.id ? ThemeColor.primaryColor.withValues(alpha: 0.10) : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: controller.feeling.value == f.id ? ThemeColor.primaryColor : FeedStyle.hairline),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FeelingBadge(feeling: f, size: 26),
                                const SizedBox(width: 8),
                                Text(l.t('feeling_${f.id}'), style: FeedStyle.name.copyWith(fontSize: 13.5, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _askLocation(BuildContext context, LanguageController l) async {
    final input = TextEditingController(text: controller.location.value);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FeedStyle.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(l.t('post_location'), style: FeedStyle.name.copyWith(fontSize: 17)),
        content: TextField(
          controller: input,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l.t('post_location_hint'), counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l.t('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(input.text.trim()), child: Text(l.t('accept'))),
        ],
      ),
    );
    input.dispose();
    if (result != null) controller.location.value = result;
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
