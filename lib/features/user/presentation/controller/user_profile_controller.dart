import 'package:tendria/features/gift/presentation/widget/gift_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/custom_alert_type.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper.dart';
import 'package:tendria/features/facebookEvent/domain/usecase/log_view_profile_usecase.dart';
import 'package:tendria/features/like/domain/entities/pending_chat_entity.dart';
import 'package:tendria/features/like/presentation/controller/liked_by_users_controller.dart';
import 'package:tendria/features/like/presentation/controller/my_match_controller.dart';
import 'package:tendria/features/stories/presentation/page/story_controller.dart';
import 'package:tendria/features/user/domain/entities/create_reports_user_entity.dart';
import 'package:tendria/features/user/domain/entities/get_user_entity.dart';
import 'package:tendria/features/user/domain/usecase/create_reports_user_usecase.dart';
import 'package:tendria/features/user/domain/usecase/get_user_by_id_usecase.dart';
import 'package:tendria/features/like/domain/usecase/toggle_like_usecase.dart';
import 'package:tendria/features/follow/domain/usecase/follow_user_usecase.dart';
import 'package:tendria/features/follow/domain/usecase/unfollow_user_usecase.dart';
import 'package:tendria/features/unlock/domain/usecase/block_user_usecase.dart';
import 'package:tendria/features/user/presentation/controller/nearby_users_controller.dart';
import 'package:tendria/features/user/presentation/controller/profile_controller.dart';

class UserProfileController extends GetxController {
  final GetUserByIdUsecase getUserByIdUsecase;
  final ToggleLikeUsecase toggleLikeUsecase;
  final BlockUserUsecase blockUserUsecase;
  final LogViewProfileUsecase logViewProfileUsecase;
  final CreateReportsUserUsecase createReportsUserUsecase;
  final FollowUserUsecase followUserUsecase;
  final UnfollowUserUsecase unfollowUserUsecase;

  UserProfileController({
    required this.getUserByIdUsecase,
    required this.toggleLikeUsecase,
    required this.blockUserUsecase,
    required this.logViewProfileUsecase,
    required this.createReportsUserUsecase,
    required this.followUserUsecase,
    required this.unfollowUserUsecase,
  });

  final RxBool isLoading = false.obs;
  final RxBool isFavorite = false.obs;
  final RxInt currentImageIndex = 0.obs;
  final RxBool isProcessingLike = false.obs;
  final RxBool isProcessingBlock = false.obs;
  final RxBool isProcessingFollow = false.obs;
  final RxInt giftsVersion = 0.obs; // se incrementa al enviar un regalo para refrescar la franja de recibidos
  final RxBool iFollow = false.obs;
  final RxInt followersCount = 0.obs;
  final RxInt followingCount = 0.obs;
  final RxBool hasStories = false.obs;
  final descError = false.obs;
  LanguageController get _l => Get.find<LanguageController>();
  final Rxn<GetUserEntity> currentUser = Rxn<GetUserEntity>();
  final RxInt userId = 0.obs;
  late PageController pageController;

  String get userName => currentUser.value?.name ?? 'Usuario';
  int get userAge => currentUser.value?.age ?? 0;
  String get userBio => currentUser.value?.bio ?? '';
  List<String> get userInterests =>
      currentUser.value?.interestsIds?.map((i) => i.name).toList() ?? [];
  List<String> get userQualities =>
      currentUser.value?.qualitiesIds?.map((q) => q.name).toList() ?? [];
  List<String> get userGallery => _buildGallery(currentUser.value);


  bool get alreadyInteracted {
    final like = currentUser.value?.likeStatus;
    if (like == null) return false;
    return like.id1DioLikeAId2 || like.id2DioLikeAId1;
  }

  final RxInt goPerfilIndex = (-1).obs;
  @override
  void onInit() {
    final args = Get.arguments as Map<String, dynamic>?;
    super.onInit();
    pageController = PageController();
    print('UserProfileController initialized with arguments: ${Get.arguments}');
    if (Get.arguments != null && Get.arguments['userId'] != null) {
      userId.value = Get.arguments['userId'];
      loadUserProfile(userId.value);
    }
    final index = args?['goPerfilIndex'];
    debugPrint('user id from arguments: ${userId.value}, index: $index');
    
    debugPrint(
      'alreadyInteracted: $alreadyInteracted likeStatus: ${currentUser.value?.likeStatus}',
    );
    if (index is RxInt) {
      goPerfilIndex.value = index.value;
    } else if (index is int) {
      goPerfilIndex.value = index;
    } else {
      goPerfilIndex.value = -1;
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  Future<void> loadUserProfile(int idUser) async {
    try {
      isLoading.value = true;
      final user = await getUserByIdUsecase.execute(idUser);
      print('User profile loaded: ${user.name}, id: ${user.id}');
      currentUser.value = user;
      iFollow.value = user.iFollow ?? false;
      followersCount.value = user.followers ?? 0;
      followingCount.value = user.following ?? 0;
      currentImageIndex.value = 0;
      if (pageController.hasClients) {
        pageController.jumpToPage(0);
      }
      isFavorite.value = false;

      final storyController = Get.find<StoryController>();
      final result = await storyController.fetchStoriesForUser(idUser);
      hasStories.value = result;

      await logViewProfileUsecase(targetUserId: idUser.toString());
    } catch (e) {
      print('Error cargando perfil de usuario: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<String> _buildGallery(GetUserEntity? user) {
    if (user == null) return [''];
    final gallery = <String>[];

    if (user.fotoUrl != null && user.fotoUrl!.isNotEmpty) {
      gallery.add(user.fotoUrl!);
    }

    if (user.assets != null && user.assets!.isNotEmpty) {
      final sortedAssets = user.assets!.toList()
        ..sort((a, b) => a.orden.compareTo(b.orden));
      for (var asset in sortedAssets) {
        if (!gallery.contains(asset.url)) {
          gallery.add(asset.url);
        }
      }
    }

    if (gallery.isEmpty) gallery.add('');
    return gallery;
  }

  void onPageChanged(int index) {
    currentImageIndex.value = index;
  }

  Future<void> toggleFavorite() async {
    if (currentUser.value == null || isProcessingLike.value) return;

    final previousState = isFavorite.value;
    isFavorite.value = !isFavorite.value;

    try {
      isProcessingLike.value = true;
      await toggleLikeUsecase.execute(
        currentUser.value!.id ?? 0,
        isFavorite.value,
      );
      if (isFavorite.value) {
        showSuccessSnackbar('¡Te gusta $userName!');
      } else {
        showInfoSnackbar('$userName removido de favoritos');
      }
    } catch (e) {
      isFavorite.value = previousState;
      showErrorSnackbar('Error al procesar: ${cleanExceptionMessage(e)}');
    } finally {
      isProcessingLike.value = false;
    }
  }

  Future<void> sendGift(BuildContext context) async {
    if (userId.value == 0) return;
    final result = await showGiftSheet(
      context,
      toUserId: userId.value,
      toName: userName,
      origin: 'perfil',
    );
    if (result != null) giftsVersion.value++;
  }

  Future<void> toggleFollow() async {
    if (isProcessingFollow.value || userId.value == 0) return;

    try {
      isProcessingFollow.value = true;
      final status = iFollow.value
          ? await unfollowUserUsecase.execute(userId.value)
          : await followUserUsecase.execute(userId.value);

      iFollow.value = status.iFollow;
      followersCount.value = status.followers;
      followingCount.value = status.following;
    } catch (e) {
      showErrorSnackbar(cleanExceptionMessage(e));
    } finally {
      isProcessingFollow.value = false;
    }
  }

  Future<void> sendLike() async {
    if (isProcessingLike.value) return;

    try {
      isProcessingLike.value = true;
      await toggleLikeUsecase.execute(userId.value ?? 0, true);
      showSuccessSnackbar('¡Le diste like a $userName!');
      final nearbyController = Get.find<NearbyUsersController>();
      nearbyController.noMoreUsers.value = false;
      await nearbyController.loadNearbyUsers();

      Get.offAllNamed(RoutesNames.nearbyProfilesPage);
    } catch (e) {
      showErrorSnackbar('Error al dar like: ${cleanExceptionMessage(e)}');
    } finally {
      isProcessingLike.value = false;
    }
  }

  Future<void> rejectUser() async {
    if (isProcessingLike.value) return;

    try {
      isProcessingLike.value = true;

      await toggleLikeUsecase.execute(userId.value, false);
      showInfoSnackbar('Usuario rechazado');

      final nearbyController = Get.find<NearbyUsersController>();
      nearbyController.noMoreUsers.value = false;
      await nearbyController.loadNearbyUsers();

      Get.offAllNamed(RoutesNames.nearbyProfilesPage);
    } catch (e) {
      showErrorSnackbar('Error al rechazar: ${cleanExceptionMessage(e)}');
    } finally {
      isProcessingLike.value = false;
    }
  }

  void sendMensaje() {
    final chat = currentUser.value?.chat;

    if (chat != null && chat.pendingAcepted) {
      final likedByController = Get.find<LikedByUsersController>();
      likedByController.unlockChat(
        PendingChatEntity(
          chatId: chat.id,
          userId: userId.value,
          name: userName,
          photoUrl: currentUser.value?.fotoUrl,
          age: currentUser.value?.age,
          hiddenMessage: null,
          createdAt: DateTime.now(),
          unlockCost: 0,
        ),
      );
      return;
    }

    if (chat == null || chat.id == 0) {
      Get.toNamed(
        RoutesNames.chatPage,
        arguments: {'userid': userId.value, 'name': userName, 'goHomeIndex': 2},
      );
      return;
    }

    Get.toNamed(
      RoutesNames.chatPage,
      arguments: {'chatId': chat.id, 'name': userName, 'goHomeIndex': 2},
    );
  }

  void skipUser() => Get.back();

  void blockUser() {
    if (Get.context == null) return;
    showCustomAlert(
      context: Get.context!,
      title: _l.t('nearby_block_title'),
      message: '${_l.t('nearby_block_msg')} $userName?',
      confirmText: _l.t('nearby_block_confirm'),
      cancelText: _l.t('cancel'),
      type: CustomAlertType.warning,
      onConfirm: _confirmBlock,
    );
  }

  Future<void> _confirmBlock() async {
    if (userId.value == 0 || isProcessingBlock.value) return;
    try {
      isProcessingBlock.value = true;
      final name = userName;
      await blockUserUsecase.execute(userId.value);
      Get.find<MyMatchController>().loadChats();
      Get.back();
      showSuccessSnackbar('$name ${_l.t('nearby_blocked')}');
      Get.back();
    } catch (e) {
      showErrorSnackbar('${_l.t('error')}: ${cleanExceptionMessage(e)}');
      Get.back();
    } finally {
      isProcessingBlock.value = false;
    }
  }

  bool get showRejectButton {
    final chat = currentUser.value?.chat;

    if (chat != null && chat.id != 0) return false;
    return true;
  }

  void reportAndBlockUser() {
    if (Get.context == null) return;
    _showReportBottomSheet(Get.context!, alsoBlock: true);
  }

  void reportUser() {
    if (Get.context == null) return;
    _showReportBottomSheet(Get.context!);
  }

  void _showReportBottomSheet(BuildContext context, {bool alsoBlock = false}) {
    final reasons = [
      _l.t('report_harassment'),
      _l.t('report_inappropriate'),
      _l.t('report_fake'),
      _l.t('report_offensive'),
      _l.t('report_minor'),
      _l.t('report_other'),
    ];

    final selectedReason = RxnString();
    final descController = TextEditingController();
    final shouldBlock = alsoBlock.obs;
    final shouldReport = true.obs;
    final descError = false.obs;
    final userName = (currentUser.value?.name ?? _l.t('user')).split(' ').first;

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: ThemeColor.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Obx(
            () => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ThemeColor.subtleBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '${_l.t('report_title')} $userName',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _l.t('report_select_reason'),
                    style: TextStyle(
                      fontSize: 13,
                      color: ThemeColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (alsoBlock) ...[
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => shouldReport.value = true,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: shouldReport.value
                                    ? ThemeColor.primaryColor.withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: shouldReport.value
                                      ? ThemeColor.primaryColor
                                      : ThemeColor.subtleBorder,
                                  width: shouldReport.value ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.flag_rounded,
                                    color: shouldReport.value
                                        ? ThemeColor.primaryColor
                                        : ThemeColor.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _l.t('report_send'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: shouldReport.value
                                          ? ThemeColor.primaryColor
                                          : ThemeColor.textSecondary,
                                      fontWeight: shouldReport.value
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => shouldReport.value = false,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: !shouldReport.value
                                    ? Colors.red.withOpacity(0.08)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: !shouldReport.value
                                      ? Colors.red.shade400
                                      : ThemeColor.subtleBorder,
                                  width: !shouldReport.value ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.block_rounded,
                                    color: !shouldReport.value
                                        ? Colors.red.shade400
                                        : ThemeColor.textSecondary,
                                   size: 32,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _l.t('nearby_block_confirm'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: !shouldReport.value
                                          ? Colors.red.shade400
                                          : ThemeColor.textSecondary,
                                      fontWeight: !shouldReport.value
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (shouldReport.value) ...[
                    ...reasons.map(
                      (reason) => GestureDetector(
                        onTap: () => selectedReason.value = reason,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedReason.value == reason
                                  ? ThemeColor.primaryColor
                                  : ThemeColor.subtleBorder,
                              width: selectedReason.value == reason ? 1.5 : 1,
                            ),
                            color: selectedReason.value == reason
                                ? ThemeColor.primaryColor.withOpacity(0.06)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selectedReason.value == reason
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 18,
                                color: selectedReason.value == reason
                                    ? ThemeColor.primaryColor
                                    : ThemeColor.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ThemeColor.textPrimary,
                                  fontWeight: selectedReason.value == reason
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descController,
                      onChanged: (_) => descError.value = false,
                      maxLines: 3,
                      maxLength: 300,
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeColor.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: _l.t('report_desc_hint'),
                        hintStyle: TextStyle(
                          color: ThemeColor.textSecondary,
                          fontSize: 13,
                        ),
                        errorText: descError.value
                            ? _l.t('report_desc_required')
                            : null,
                        filled: true,
                        fillColor: ThemeColor.backgroundColorfondo,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: ThemeColor.subtleBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: ThemeColor.subtleBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: ThemeColor.primaryColor,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ThemeColor.errorColor),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: ThemeColor.errorColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (alsoBlock)
                      GestureDetector(
                        onTap: () => shouldBlock.value = !shouldBlock.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: shouldBlock.value
                                  ? Colors.red.shade400
                                  : ThemeColor.subtleBorder,
                              width: shouldBlock.value ? 1.5 : 1,
                            ),
                            color: shouldBlock.value
                                ? Colors.red.withOpacity(0.06)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                shouldBlock.value
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 20,
                                color: shouldBlock.value
                                    ? Colors.red.shade400
                                    : ThemeColor.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_l.t('report_also_block')} $userName',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: ThemeColor.textPrimary,
                                      fontWeight: shouldBlock.value
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    _l.t('report_block_hint'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ThemeColor.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  if (!shouldReport.value) const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          shouldReport.value && selectedReason.value == null
                          ? null
                          : () {
                              if (!shouldReport.value) {
                                Get.back();
                                _confirmBlock();
                                return;
                              }
                              if (descController.text.trim().isEmpty) {
                                descError.value = true;
                                return;
                              }
                              descError.value = false;
                              _confirmReport(
                                selectedReason.value!,
                                descController.text.trim(),
                                alsoBlock: shouldBlock.value,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !shouldReport.value
                            ? Colors.red.shade600
                            : shouldBlock.value
                            ? Colors.red.shade600
                            : ThemeColor.primaryColor,
                        disabledBackgroundColor: ThemeColor.subtleBorder,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        !shouldReport.value
                            ? _l.t('nearby_block_confirm')
                            : shouldBlock.value
                            ? _l.t('report_send_and_block')
                            : _l.t('report_send'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReport(
    String reason,
    String description, {
    bool alsoBlock = false,
  }) async {
    try {
      Get.back();
      await createReportsUserUsecase.execute(
        CreateReportsUserEntity(
          reportedid: userId.value,
          reason: reason,
          description: description,
        ),
      );
      if (alsoBlock) {
        await blockUserUsecase.execute(userId.value);
        Get.find<MyMatchController>().loadChats();
        showSuccessSnackbar('$userName ${_l.t('report_block_success')}');
        Get.back();
      } else {
        showSuccessSnackbar('${_l.t('report_success')} $userName');
      }
    } catch (e) {
      showErrorSnackbar('${_l.t('error')}: ${cleanExceptionMessage(e)}');
    }
  }
}
