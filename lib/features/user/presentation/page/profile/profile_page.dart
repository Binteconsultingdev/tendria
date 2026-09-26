import 'package:tendria/features/moderation/moderation_repository.dart';
import 'package:tendria/common/theme/elite.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tendria/features/profile_social/presentation/widget/profile_social_section.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/controller/theme_controller.dart';
import 'package:tendria/common/tutorial/tutorialPerfil/profile_tutorial_controller.dart';
import 'package:tendria/common/tutorial/tutorialPerfil/profile_tutorial_overlay.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/stories/presentation/page/storyring/my_story_ring_widget.dart';
import 'package:tendria/features/user/domain/entities/get_user_entity.dart';
import 'package:tendria/features/user/presentation/controller/balance_controller.dart';
import 'package:tendria/features/user/presentation/controller/profile_controller.dart';
import 'package:tendria/features/user/presentation/controller/update_profile_controller.dart';
import 'package:tendria/features/user/presentation/widget/interests_section_widget.dart';
import 'package:tendria/features/user/presentation/widget/qualities_section_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileController controller = Get.find<ProfileController>();
  ProfileTutorialController tutorialCtrl =
      Get.find<ProfileTutorialController>();

  UpdateProfileController get _updater => Get.find<UpdateProfileController>();
  BalanceController get _balanceController => Get.find<BalanceController>();
  LanguageController get _l => Get.find<LanguageController>();
  ThemeController get _themeCtrl => Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tutorialCtrl.notifyPageReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: ThemeColor.backgroundColorfondo,
        body: Stack(
          children: [
            SafeArea(
              child: Obx(() {
                if (controller.isLoading.value &&
                    controller.userEntity.value == null) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ThemeColor.primaryColor,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.loadUserProfile,
                  color: ThemeColor.primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildSocialSection(),
                        const SizedBox(height: 14),
                        _buildPhotosSection(),
                        const SizedBox(height: 14),
                        _buildBiographySection(),
                        const SizedBox(height: 14),
                        InterestsSectionWidget(isEditable: true),
                        const SizedBox(height: 14),
                        QualitiesSectionWidget(isEditable: true),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                );
              }),
            ),
            Obx(
              () => tutorialCtrl.isVisible.value
                  ? const ProfileTutorialOverlay()
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 204,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Portada con degradado de marca
              Container(
                height: 140,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: ThemeColor.primaryGradient,
                  borderRadius: BorderRadius.circular(Elite.rXl),
                  boxShadow: Elite.softShadow,
                ),
                child: Stack(
                  children: [
                    Positioned(top: -50, right: -30, child: _bubble(150, 0.09)),
                    Positioned(bottom: -70, left: -20, child: _bubble(130, 0.07)),
                  ],
                ),
              ),
              // Título y accesos
              Positioned(
                top: 20,
                left: 32,
                right: 22,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_l.t('profile'),
                          style: GoogleFonts.rubik(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                          overflow: TextOverflow.ellipsis),
                    ),
                    // Solo las cuentas administradoras ven el acceso a moderación
                    FutureBuilder<bool>(
                      future: ModerationRepository.instance.isAdmin(),
                      builder: (_, snap) => snap.data == true
                          ? _barButton(null, LucideIcons.shieldCheck, () => Get.toNamed(RoutesNames.moderationPage))
                          : const SizedBox.shrink(),
                    ),
                    _barButton(tutorialCtrl.blockedUsersKey, LucideIcons.userX, controller.onViewBlockedUsers),
                    _barButton(tutorialCtrl.notificationsKey, LucideIcons.bell, controller.onViewNotifications),
                    _barButton(tutorialCtrl.editProfileKey, LucideIcons.pencil, controller.onHelpTap),
                    _barButton(tutorialCtrl.settingsKey, LucideIcons.settings, controller.onSettingsTap),
                    Obx(() {
                      final isDark = _themeCtrl.themeMode.value != AppThemeMode.light;
                      return _barButton(null, isDark ? LucideIcons.moon : LucideIcons.sun, _themeCtrl.toggleTheme);
                    }),
                  ],
                ),
              ),
              // Foto con anillo de historia, montada sobre la portada
              Positioned(
                left: 24,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: ThemeColor.backgroundColorfondo, shape: BoxShape.circle),
                  child: MyStoryRingWidget(size: 84),
                ),
              ),
              // Contadores, junto a la foto
              Positioned(
                left: 128,
                right: 16,
                bottom: 0,
                height: 52,
                child: FutureBuilder<int?>(
                  future: AuthService().getUserId(),
                  builder: (_, snapshot) {
                    final id = snapshot.data;
                    if (id == null) return const SizedBox.shrink();
                    return Obx(() {
                      final u = controller.userEntity.value;
                      return ProfileStatsRow(
                        userId: id,
                        posts: u?.publications ?? 0,
                        followers: u?.followers ?? 0,
                        following: u?.following ?? 0,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Obx(() {
            final user = controller.userEntity.value;
            final status = user?.status ?? '';
            final verified = user?.verified ?? false;
            final city = controller.city;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('${controller.userName}, ${controller.userAge}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: Elite.title(size: 24)),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 7),
                      const Icon(LucideIcons.badgeCheck, size: 22, color: Elite.gold),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Ciudad y estado en una misma línea
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (city.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: ThemeColor.textSecondary),
                          const SizedBox(width: 5),
                          Text(city, style: Elite.caption(size: 13.5)),
                        ],
                      ),
                    GestureDetector(
                      key: tutorialCtrl.statusKey,
                      onTap: () => _updater.showEditStatus(status),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: status.isNotEmpty ? ThemeColor.colorstatus.withValues(alpha: 0.10) : ThemeColor.subtleBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: status.isNotEmpty ? ThemeColor.colorstatus.withValues(alpha: 0.28) : ThemeColor.subtleBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status.isNotEmpty ? LucideIcons.messageCircle : LucideIcons.plus,
                                size: 13, color: status.isNotEmpty ? ThemeColor.colorstatus : ThemeColor.textSecondary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(status.isNotEmpty ? status : _l.t('add_status'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Elite.body(size: 12.5, color: status.isNotEmpty ? ThemeColor.colorstatus : ThemeColor.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 12),
        // Créditos: franja delgada de una línea
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: InkWell(
            key: tutorialCtrl.creditsKey,
            borderRadius: BorderRadius.circular(Elite.rMd),
            onTap: () => Get.offAllNamed(RoutesNames.purchasePage),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFF6DC), Color(0xFFF6E7BB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(Elite.rMd),
                border: Border.all(color: Elite.gold.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE8C766), Color(0xFFC9A24B)]), shape: BoxShape.circle),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Obx(() => Text('${_balanceController.currentBalance.toStringAsFixed(0)}  ${_l.t('gift_credits')}',
                        style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF3E3210)))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: const Color(0xFF3E3210), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.plus, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(_l.t('gift_recharge_short'), style: GoogleFonts.rubik(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
      );

  Widget _barButton(Key? key, IconData icon, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(left: 7),
        child: GestureDetector(
          key: key,
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      );

  /// Seguidores, seguidos, publicaciones, planes, comunidades y regalos recibidos.
  Widget _buildSocialSection() {
    return FutureBuilder<int?>(
      future: AuthService().getUserId(),
      builder: (_, snapshot) {
        final id = snapshot.data;
        if (id == null) return const SizedBox.shrink();

        return Obx(() {
          final u = controller.userEntity.value;
          return ProfileSocialSection(
            key: ValueKey('social_own_$id'),
            userId: id,
            isOwn: true,
            followers: u?.followers ?? 0,
            following: u?.following ?? 0,
            posts: u?.publications ?? 0,
            showCounters: false,
          );
        });
      },
    );
  }

  Widget _buildPhotosSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ThemeColor.paddingLarge),
      padding: EdgeInsets.all(ThemeColor.paddingLarge),
      decoration: BoxDecoration(
        color: ThemeColor.cardBackground,
        borderRadius: BorderRadius.circular(Elite.rLg),
        boxShadow: Elite.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final count = controller.assets.length;
            final max = controller.maxPhotos;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _l.t('photos'),
                  style: ThemeColor.subtitleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeColor.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: count < max
                        ? ThemeColor.primaryColor.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count / $max',
                    style: ThemeColor.bodySmall.copyWith(
                      color: count < max
                          ? ThemeColor.primaryColor
                          : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          }),
          SizedBox(height: ThemeColor.paddingSmall),
          Text(
            _l.t('photos_hint'),
            style: ThemeColor.bodySmall.copyWith(
              color: ThemeColor.textSecondary,
            ),
          ),
          SizedBox(height: ThemeColor.paddingMedium),

          Obx(() {
            final photosCount = controller.assets.length;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: ThemeColor.paddingSmall,
                mainAxisSpacing: ThemeColor.paddingSmall,
                childAspectRatio: 1,
              ),
              itemCount: controller.maxPhotos,
              itemBuilder: (context, index) {
                if (index < photosCount) {
                  return _buildPhotoItem(controller.assets[index]);
                } else {
                  return _buildAddPhotoButton();
                }
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(AssetEntity asset) {
    return Obx(() {
      final isDeleting = controller.isDeletingPhoto.value;

      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: ThemeColor.cardBackground,
              borderRadius: BorderRadius.circular(Elite.rMd),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Elite.rMd),
              child: CachedNetworkImage(
                imageUrl: asset.url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ThemeColor.primaryColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: ThemeColor.backgroundColorfondo,
                  child: Icon(
                    Icons.broken_image,
                    color: ThemeColor.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: isDeleting
                  ? null
                  : () => controller.confirmDeletePhoto(asset.id),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: isDeleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildAddPhotoButton() {
    return Obx(() {
      final isUploading = controller.isUploadingPhoto.value;

      return GestureDetector(
        onTap: isUploading ? null : controller.addPhoto,
        child: Container(
          decoration: BoxDecoration(
            color: ThemeColor.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Elite.rMd),
            border: Border.all(color: ThemeColor.primaryColor.withValues(alpha: 0.25), width: 1.4),
          ),
          child: isUploading
              ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ThemeColor.primaryColor,
                      ),
                    ),
                  ),
                )
              : Icon(LucideIcons.plus, color: ThemeColor.primaryColor, size: 28),
        ),
      );
    });
  }

  Widget _buildBiographySection() {
    return Obx(() {
      final bio = controller.profileBio;

      if (bio.isEmpty) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => _updater.showEditBio(bio),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: ThemeColor.paddingLarge),
          padding: EdgeInsets.all(ThemeColor.paddingLarge),
          decoration: BoxDecoration(
            color: ThemeColor.cardBackground,
            borderRadius: BorderRadius.circular(Elite.rLg),
            boxShadow: Elite.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      _l.t('my_biography'),
                      style: ThemeColor.subtitleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeColor.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: ThemeColor.textSecondary,
                  ),
                ],
              ),
              SizedBox(height: ThemeColor.paddingSmall),
              Text(
                bio,
                style: ThemeColor.bodyMedium.copyWith(
                  color: ThemeColor.textPrimary,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    });
  }
}
