import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/widgets/brand_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/chat/domain/entities/chat_entity.dart';
import 'package:tendria/features/like/presentation/controller/my_match_controller.dart';
import 'package:tendria/features/stories/presentation/page/storyring/my_story_ring_widget.dart';
import 'package:tendria/features/stories/presentation/page/storyring/story_ring_widget.dart';
import 'package:tendria/features/stories/presentation/page/story_controller.dart';

class MyMatchView extends GetView<MyMatchController> {
  const MyMatchView({Key? key}) : super(key: key);

  LanguageController get _l => Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: ThemeColor.backgroundColorfondo,
          appBar: BrandAppBar(
            extraActions: [
              if (controller.isSilentLoading.value)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ThemeColor.primaryColor),
                  ),
                ),
              IconButton(
                tooltip: 'Buscar',
                icon: Icon(controller.isSearching.value ? LucideIcons.x : LucideIcons.search,
                    size: 21, color: ThemeColor.textPrimary),
                onPressed: controller.toggleSearch,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Obx(() {
                  if (controller.isSearching.value) {
                    return _buildSearchBar();
                  }
                  return const SizedBox.shrink();
                }),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value && controller.chats.isEmpty) {
                      return _buildLoadingState();
                    }

                    if (controller.hasError.value && controller.chats.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: controller.refreshChats,
                        color: ThemeColor.primaryColor,
                        backgroundColor: ThemeColor.cardBackground,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(child: _buildErrorState())
                          ],
                        ),
                      );
                    }

                    if (controller.chats.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: controller.refreshChats,
                        color: ThemeColor.primaryColor,
                        backgroundColor: ThemeColor.cardBackground,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(child: _buildEmptyState())
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: controller.refreshChats,
                      color: ThemeColor.primaryColor,
                      backgroundColor: ThemeColor.cardBackground,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            if (!controller.isSearching.value) ...[
                              _buildStoriesSection(),
                              Container(
                                height: 8,
                                color: ThemeColor.backgroundColorfondo,
                              ),
                            ],
                            _buildChatsHeader(),
                            _buildChatsList(),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ));
  }
 

  Widget _buildHeader() {
    return Obx(
      () => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: ThemeColor.paddingMedium,
          vertical: ThemeColor.paddingSmall,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!controller.isSearching.value)
              ThemeColor.widgetLogo(width: 100, height: 100)
            else
              const SizedBox.shrink(),
            Row(
              children: [
                if (controller.isSilentLoading.value)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeColor.primaryColor,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    controller.isSearching.value ? Icons.close : Icons.search,
                    color: ThemeColor.iconColor,
                    size: 28,
                  ),
                  onPressed: controller.toggleSearch,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
 

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ThemeColor.paddingMedium,
        vertical: ThemeColor.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: ThemeColor.cardBackground,
        border: Border(
          bottom: BorderSide(color: ThemeColor.dividerColor, width: 1),
        ),
      ),
      child: TextField(
        autofocus: true,
        onChanged: controller.searchChats,
        style: ThemeColor.bodyMedium.copyWith(color: ThemeColor.textPrimary),
        decoration: InputDecoration(
          hintText: _l.t('search_hint'),
          hintStyle: ThemeColor.bodyMedium.copyWith(
            color: ThemeColor.textSecondary,
          ),
          prefixIcon: Icon(Icons.search, color: ThemeColor.textSecondary),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: Icon(Icons.clear, color: ThemeColor.textSecondary),
              onPressed: controller.clearSearch,
            );
          }),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: ThemeColor.backgroundColorfondo,
          contentPadding: EdgeInsets.symmetric(
            horizontal: ThemeColor.paddingMedium,
            vertical: ThemeColor.paddingSmall,
          ),
        ),
      ),
    );
  } 

  Widget _buildStoriesSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: ThemeColor.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ThemeColor.paddingMedium),
            child: Text(
              _l.t('stories'),
              style: ThemeColor.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeColor.textPrimary,
              ),
            ),
          ),
          SizedBox(height: ThemeColor.paddingMedium),
          SizedBox(
            height: 110,
            child: GetBuilder<StoryController>(
              init: Get.find<StoryController>(),
              builder: (storyController) {
                return Obx(() {
                  if (storyController.isLoading.value) {
                    return _buildStoriesLoading();
                  }

                  final totalUsers = storyController.allStories.length;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: ThemeColor.paddingMedium,
                    ),
                    itemCount: totalUsers + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            MyStoryRingWidget(size: 70),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 70,
                              child: Text(
                                _l.t('my_story'),
                                style: ThemeColor.caption.copyWith(
                                  color: ThemeColor.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }

                      final userIndex = index - 1;
                      return Column(
                        children: [
                          StoryRingWidget(index: userIndex, size: 70),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 70,
                            child: Text(
                              storyController.getUserName(userIndex) ??
                                  _l.t('user'),
                              style: ThemeColor.caption.copyWith(
                                color: ThemeColor.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: ThemeColor.paddingMedium),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(right: ThemeColor.paddingMedium),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeColor.loaddingwithOpacity1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: ThemeColor.loaddingwithOpacity1,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
 

  Widget _buildChatsHeader() {
    return Obx(() {
      if (controller.isSearching.value) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ThemeColor.paddingMedium,
          vertical: ThemeColor.paddingSmall,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  _l.t('chats'),
                  style: ThemeColor.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeColor.textPrimary,
                  ),
                ),
                if (controller.filterPendingOnly.value) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeColor.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ThemeColor.primaryColor.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _l.t('no_reply'),
                      style: TextStyle(
                        color: ThemeColor.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: controller.filterPendingOnly.value
                        ? ThemeColor.primaryColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: controller.filterPendingOnly.value
                          ? ThemeColor.primaryColor
                          : ThemeColor.iconColor,
                    ),
                    onPressed: _showFilterBottomSheet,
                  ),
                ),
                if (!controller.filterPendingOnly.value &&
                    controller.pendingCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: ThemeColor.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          controller.pendingCount > 9
                              ? '9+'
                              : '${controller.pendingCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
 

  void _showFilterBottomSheet() {
    Get.bottomSheet(
      Obx(
        () => Container(
          padding: EdgeInsets.symmetric(
            horizontal: ThemeColor.paddingLarge,
            vertical: ThemeColor.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: ThemeColor.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: ThemeColor.paddingMedium),
                  decoration: BoxDecoration(
                    color: ThemeColor.subtleBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _l.t('filter_chats'),
                style: ThemeColor.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeColor.textPrimary,
                ),
              ),
              SizedBox(height: ThemeColor.paddingMedium),
              _buildFilterOption(
                icon: Icons.mark_chat_unread_outlined,
                label: _l.t('filter_no_reply'),
                description: _l.t('filter_no_reply_desc'),
                isActive: controller.filterPendingOnly.value,
                count: controller.pendingCount,
                onTap: () {
                  controller.togglePendingFilter();
                  Get.back();
                },
              ),
              SizedBox(height: ThemeColor.paddingMedium),
              if (controller.filterPendingOnly.value)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      controller.togglePendingFilter();
                      Get.back();
                    },
                    icon: Icon(
                      Icons.filter_alt_off,
                      color: ThemeColor.primaryColor,
                    ),
                    label: Text(
                      _l.t('clear_filters'),
                      style: TextStyle(color: ThemeColor.primaryColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ThemeColor.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: ThemeColor.paddingMedium,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: ThemeColor.paddingMedium),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Widget _buildFilterOption({
    required IconData icon,
    required String label,
    required String description,
    required bool isActive,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(ThemeColor.paddingMedium),
        decoration: BoxDecoration(
          color: isActive
              ? ThemeColor.primaryColor.withOpacity(0.1)
              : ThemeColor.backgroundColorfondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? ThemeColor.primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive
                  ? ThemeColor.primaryColor
                  : ThemeColor.textSecondary,
            ),
            SizedBox(width: ThemeColor.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ThemeColor.subtitleLarge.copyWith(
                      color: isActive
                          ? ThemeColor.primaryColor
                          : ThemeColor.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: ThemeColor.bodyMedium.copyWith(
                      color: ThemeColor.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ThemeColor.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              color: isActive
                  ? ThemeColor.primaryColor
                  : ThemeColor.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
 

  Widget _buildChatsList() {
    return Obx(() {
      final chatsToShow = controller.filteredChats;

      if (chatsToShow.isEmpty) {
        return _buildChatsEmptyState();
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: ThemeColor.paddingMedium),
        itemCount: chatsToShow.length,
        separatorBuilder: (context, index) =>
            Divider(color: ThemeColor.dividerColor, height: 1, indent: 70),
        itemBuilder: (context, index) {
          final chat = chatsToShow[index];
          return _buildChatItem(chat);
        },
      );
    });
  }

  Widget _buildChatsEmptyState() {
    return Obx(() {
      final isFiltering = controller.filterPendingOnly.value;
      final hasQuery = controller.searchQuery.value.isNotEmpty;

      late String message;
      late IconData icon;

      if (isFiltering && hasQuery) {
        icon = Icons.search_off;
        message = '${_l.t('no_reply')} · "${controller.searchQuery.value}"';
      } else if (isFiltering) {
        icon = Icons.mark_chat_read_outlined;
        message = _l.t('all_caught_up');
      } else {
        icon = Icons.search_off;
        message = '"${controller.searchQuery.value}"';
      }

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ThemeColor.paddingLarge,
          vertical: ThemeColor.paddingLarge * 1.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: ThemeColor.textSecondary),
            SizedBox(height: ThemeColor.paddingMedium),
            Text(
              message,
              style: ThemeColor.bodyMedium.copyWith(
                color: ThemeColor.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltering) ...[
              SizedBox(height: ThemeColor.paddingMedium),
              OutlinedButton.icon(
                onPressed: controller.togglePendingFilter,
                icon: Icon(
                  Icons.filter_alt_off,
                  color: ThemeColor.primaryColor,
                  size: 18,
                ),
                label: Text(
                  _l.t('see_all'),
                  style: TextStyle(color: ThemeColor.primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ThemeColor.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: ThemeColor.paddingLarge,
                    vertical: ThemeColor.paddingSmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
 

  Widget _buildChatItem(ChatEntity chat) {
    final ultimoMensaje = chat.ultimoMensaje;

    return InkWell(
      onTap: () =>
          controller.navigateToChat(chat.chatId, chat.otroUsuario.nombre),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: ThemeColor.paddingSmall + 4),
        child: Row(
          children: [
            _buildAvatar(chat.otroUsuario.fotoUrl, chat.otroUsuario.isActive),
            SizedBox(width: ThemeColor.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.otroUsuario.nombre,
                          style: ThemeColor.subtitleLarge.copyWith(
                            color: ThemeColor.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ultimoMensaje != null && !ultimoMensaje.esPropio)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeColor.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _l.t('your_turn'),
                            style: ThemeColor.badgeText.copyWith(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ultimoMensaje?.mensaje ?? _l.t('start_chat'),
                    style: ThemeColor.bodyMedium.copyWith(
                      color: ThemeColor.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 

  Widget _buildAvatar(String? photoUrl, bool? isActive) {
    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: ThemeColor.storyGradient,
            boxShadow: [ThemeColor.lightShadow],
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ThemeColor.cardBackground, width: 2),
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                    )
                  : _buildDefaultAvatar(),
            ),
          ),
        ),
        if (isActive == true)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: ThemeColor.cardBackground, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: ThemeColor.backgroundColorfondo,
      child: Icon(Icons.person, size: 28, color: ThemeColor.textSecondary),
    );
  }
 

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(ThemeColor.primaryColor),
          ),
          SizedBox(height: ThemeColor.paddingLarge),
          Text(
            _l.t('loading_chats'),
            style: ThemeColor.bodyMedium.copyWith(
              color: ThemeColor.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ThemeColor.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ThemeColor.paddingLarge),
              decoration: BoxDecoration(
                color: ThemeColor.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: ThemeColor.errorColor,
              ),
            ),
            SizedBox(height: ThemeColor.paddingLarge),
            Text(
              _l.t('error_title'),
              style: ThemeColor.headingSmall.copyWith(
                color: ThemeColor.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ThemeColor.paddingSmall),
            Text(
              controller.errorMessage.value,
              style: ThemeColor.bodyMedium.copyWith(
                color: ThemeColor.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ThemeColor.paddingLarge),
            ThemeColor.widgetButton(
              text: _l.t('retry'),
              onPressed: controller.loadChats,
              backgroundColor: ThemeColor.primaryColor,
              textColor: ThemeColor.textLightColor,
              padding: EdgeInsets.symmetric(
                horizontal: ThemeColor.paddingLarge,
                vertical: ThemeColor.paddingMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ThemeColor.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ThemeColor.paddingLarge),
              decoration: BoxDecoration(
                color: ThemeColor.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: ThemeColor.primaryColor,
              ),
            ),
            SizedBox(height: ThemeColor.paddingLarge),
            Text(
              _l.t('empty_title_chats'),
              style: ThemeColor.headingSmall.copyWith(
                color: ThemeColor.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ThemeColor.paddingSmall),
            Text(
              _l.t('empty_subtitle_chats'),
              style: ThemeColor.bodyMedium.copyWith(
                color: ThemeColor.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ThemeColor.paddingLarge),
            ThemeColor.widgetButton(
              text: _l.t('explore'),
              onPressed: () => Get.offAllNamed(RoutesNames.preferencesPage),
              backgroundColor: ThemeColor.primaryColor,
              textColor: ThemeColor.textLightColor,
              padding: EdgeInsets.symmetric(
                horizontal: ThemeColor.paddingLarge,
                vertical: ThemeColor.paddingMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}