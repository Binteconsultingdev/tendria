import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/features/discover/discover_filters_sheet.dart';
import 'package:tendria/features/discover/discover_filters.dart';
import 'package:tendria/common/widgets/brand_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tendria/features/discover/discover_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/like/presentation/controller/liked_by_users_controller.dart';
import 'package:tendria/features/like/domain/entities/pending_chat_entity.dart';
import 'package:tendria/features/like/domain/entities/liked_by_users_entity.dart';

class LikedByUsersView extends GetView<LikedByUsersController> {
  const LikedByUsersView({Key? key}) : super(key: key);

  LanguageController get _l => Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: ThemeColor.backgroundColorfondo,
          appBar: const BrandAppBar(),
          body: SafeArea(
            child: Column(
              children: [
                _buildTabs(),
                Expanded(
                  child: Obx(() {
                    switch (controller.activeTab.value) {
                      case 2:
                        return const DiscoverView();
                      default:
                        return _buildLikesSection();
                    }
                  }),
                ),
              ],
            ),
          ),
        ));
  }
 

  /// Barra superior mínima: dos pestañas de texto con subrayado y una línea fina debajo.
  Widget _buildTabs() {
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: ThemeColor.cardBackground,
            border: Border(bottom: BorderSide(color: ThemeColor.textSecondary.withValues(alpha: 0.14))),
          ),
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
          child: Row(
            children: [
              _tab(index: 2, label: _l.t('discover_title')),
              const SizedBox(width: 28),
              _tab(index: 1, label: 'Les gusté', count: controller.likedByUsers.length),
              const Spacer(),
              if (controller.activeTab.value == 2) _filterButton(),
            ],
          ),
        ));
  }

  /// Botón de filtros de Descubrir, con un globito que indica cuántos filtros están activos.
  Widget _filterButton() {
    return ValueListenableBuilder<DiscoverFilters>(
      valueListenable: DiscoverState.instance.filters,
      builder: (context, f, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showDiscoverFilters(context),
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: f.isActive ? ThemeColor.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.slidersHorizontal, size: 19, color: f.isActive ? ThemeColor.primaryColor : ThemeColor.textPrimary),
              ),
              if (f.isActive)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: ThemeColor.primaryColor, shape: BoxShape.circle),
                    child: Text('${f.activeCount}', style: GoogleFonts.rubik(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab({required int index, required String label, int count = 0}) {
    final active = controller.activeTab.value == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.switchTab(index),
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.rubik(
                    fontSize: 18,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? ThemeColor.textPrimary : ThemeColor.textSecondary,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(color: ThemeColor.primaryColor, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: GoogleFonts.rubik(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2.5,
              width: active ? 26 : 0,
              decoration: BoxDecoration(color: ThemeColor.primaryColor, borderRadius: BorderRadius.circular(2)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingChatsSection() {
    if (controller.isLoading.value && controller.pendingChats.isEmpty) {
      return _buildLoadingState();
    }
    if (controller.hasError.value && controller.pendingChats.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refreshPendingChats,
        color: ThemeColor.primaryColor,
        backgroundColor: ThemeColor.cardBackground,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [SliverFillRemaining(child: _buildErrorState())],
        ),
      );
    }
    if (controller.pendingChats.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refreshPendingChats,
        color: ThemeColor.primaryColor,
        backgroundColor: ThemeColor.cardBackground,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [SliverFillRemaining(child: _buildEmptyState())],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refreshPendingChats,
      color: ThemeColor.primaryColor,
      backgroundColor: ThemeColor.cardBackground,
      child: _buildChatGrid(),
    );
  }
 

  Widget _buildLikesSection() {
    if (controller.isLoadingLikes.value && controller.likedByUsers.isEmpty) {
      return _buildLoadingState();
    }
    if (controller.hasErrorLikes.value && controller.likedByUsers.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refreshLikedByUsers,
        color: ThemeColor.primaryColor,
        backgroundColor: ThemeColor.cardBackground,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [SliverFillRemaining(child: _buildLikesErrorState())],
        ),
      );
    }
    if (controller.likedByUsers.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refreshLikedByUsers,
        color: ThemeColor.primaryColor,
        backgroundColor: ThemeColor.cardBackground,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [SliverFillRemaining(child: _buildLikesEmptyState())],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: controller.refreshLikedByUsers,
      color: ThemeColor.primaryColor,
      backgroundColor: ThemeColor.cardBackground,
      child: _buildLikesGrid(),
    );
  }

  Widget _buildLikesGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(ThemeColor.paddingMedium),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: ThemeColor.paddingMedium,
        mainAxisSpacing: ThemeColor.paddingMedium,
      ),
      itemCount: controller.likedByUsers.length,
      itemBuilder: (context, index) {
        final user = controller.likedByUsers[index];
        return _buildLikeCard(user);
      },
    );
  }

  Widget _buildLikeCard(LikedByUsersEntity user) {
    return GestureDetector(
      onTap: () => controller.navigateToUserProfile(user.fromusererId),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColor.cardBackground,
          borderRadius: ThemeColor.mediumBorderRadius,
          boxShadow: [ThemeColor.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ThemeColor.mediumRadius),
                      topRight: Radius.circular(ThemeColor.mediumRadius),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: ThemeColor.backgroundColorfondo,
                      child: user.profilePictureUrl.isNotEmpty
                          ? Image.network(
                              user.profilePictureUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        ThemeColor.primaryColor),
                                  ),
                                );
                              },
                            )
                          : _buildDefaultAvatar(),
                    ),
                  ),
 
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.getTimeAgo(user.likedAt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
 
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.pinkAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
 
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
 
            Padding(
              padding: EdgeInsets.all(ThemeColor.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.username}, ${user.ega}',
                    style: ThemeColor.subtitleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColor.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ThemeColor.widgetButton(
                      text: 'Ver perfil',
                      onPressed: () =>
                          controller.navigateToUserProfile(user.fromusererId),
                      backgroundColor: Colors.pinkAccent,
                      textColor: Colors.white,
                      fontSize: 12,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      borderRadius: ThemeColor.smallRadius,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 

  Widget _buildChatGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(ThemeColor.paddingMedium),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: ThemeColor.paddingMedium,
        mainAxisSpacing: ThemeColor.paddingMedium,
      ),
      itemCount: controller.pendingChats.length,
      itemBuilder: (context, index) {
        final chat = controller.pendingChats[index];
        return _buildChatCard(chat);
      },
    );
  }

  Widget _buildChatCard(PendingChatEntity chat) {
    return GestureDetector(
      onTap: () => controller.navigateToProfile(chat.userId),
      child: Container(
        decoration: BoxDecoration(
          color: ThemeColor.cardBackground,
          borderRadius: ThemeColor.mediumBorderRadius,
          boxShadow: [ThemeColor.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ThemeColor.mediumRadius),
                      topRight: Radius.circular(ThemeColor.mediumRadius),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: ThemeColor.backgroundColorfondo,
                      child: chat.photoUrl != null && chat.photoUrl!.isNotEmpty
                          ? Image.network(
                              chat.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        ThemeColor.primaryColor),
                                  ),
                                );
                              },
                            )
                          : _buildDefaultAvatar(),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        controller.getTimeAgo(chat.createdAt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ThemeColor.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, color: Colors.white, size: 16),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (chat.hiddenMessage != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.message,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                chat.hiddenMessage!,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(ThemeColor.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.age != null
                        ? '${chat.name ?? _l.t('user')}, ${chat.age}'
                        : chat.name ?? _l.t('user'),
                    style: ThemeColor.subtitleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColor.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ThemeColor.widgetButton(
                      text: _l.t('connect'),
                      onPressed: () => controller.unlockChat(chat),
                      backgroundColor: ThemeColor.primaryColor,
                      textColor: ThemeColor.textLightColor,
                      fontSize: 12,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      borderRadius: ThemeColor.smallRadius,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: ThemeColor.backgroundColorfondo,
      child: Center(
        child: Icon(Icons.person, size: 60, color: ThemeColor.textSecondary),
      ),
    );
  }
 
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ThemeColor.primaryColor),
          ),
          SizedBox(height: ThemeColor.paddingLarge),
          Text(
            _l.t('loading_pending'),
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
              child: Icon(Icons.error_outline,
                  size: 60, color: ThemeColor.errorColor),
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
              onPressed: controller.loadPendingChats,
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

  Widget _buildLikesErrorState() {
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
              child: Icon(Icons.error_outline,
                  size: 60, color: ThemeColor.errorColor),
            ),
            SizedBox(height: ThemeColor.paddingLarge),
            Text(
              'Error al cargar likes',
              style: ThemeColor.headingSmall.copyWith(
                color: ThemeColor.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ThemeColor.paddingSmall),
            Text(
              controller.errorMessageLikes.value,
              style: ThemeColor.bodyMedium.copyWith(
                color: ThemeColor.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ThemeColor.paddingLarge),
            ThemeColor.widgetButton(
              text: _l.t('retry'),
              onPressed: controller.refreshLikedByUsers,
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
              child: Icon(Icons.chat_bubble_outline,
                  size: 60, color: ThemeColor.primaryColor),
            ),
            SizedBox(height: ThemeColor.paddingLarge),
            Text(
              _l.t('empty_title_pending'),
              style: ThemeColor.headingSmall.copyWith(
                color: ThemeColor.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ThemeColor.paddingSmall),
            Text(
              _l.t('empty_subtitle_pending'),
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

  Widget _buildLikesEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ThemeColor.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ThemeColor.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  size: 60, color: Colors.pinkAccent),
            ),
            SizedBox(height: ThemeColor.paddingLarge),
            Text(
              'Nadie te ha dado like aún',
              style: ThemeColor.headingSmall.copyWith(
                color: ThemeColor.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ThemeColor.paddingSmall),
            Text(
              'Sigue explorando para conseguir más matches',
              style: ThemeColor.bodyMedium.copyWith(
                color: ThemeColor.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}