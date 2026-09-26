import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/widgets/alert/custom_alert_type.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/facebookEvent/domain/usecase/log_match_usecase.dart';
import 'package:tendria/features/like/domain/usecase/get_pending_liked_chats_usecase.dart';
import 'package:tendria/features/like/domain/usecase/get_like_by_users_usecase.dart';
import 'package:tendria/features/like/domain/usecase/unlock_chat_usecase.dart';
import 'package:tendria/features/like/domain/entities/pending_chat_entity.dart';
import 'package:tendria/features/like/domain/entities/liked_by_users_entity.dart';
import 'package:tendria/common/settings/routes_names.dart';

class LikedByUsersController extends GetxController {
  final GetPendingLikedChatsUsecase getPendingLikedChatsUsecase;
  final UnlockChatUsecase unlockChatUsecase;
  final LogMatchUsecase logMatchUsecase;
  final GetLikeByUsersUsecase getLikeByUsersUsecase;

  LikedByUsersController({
    required this.getPendingLikedChatsUsecase,
    required this.unlockChatUsecase,
    required this.logMatchUsecase,
    required this.getLikeByUsersUsecase,
  });
 
  /// 2 = Descubrir, 1 = Les gusté
  final RxInt activeTab = 2.obs;

  final RxList<PendingChatEntity> pendingChats = <PendingChatEntity>[].obs;
  final RxList<LikedByUsersEntity> likedByUsers = <LikedByUsersEntity>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingLikes = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessageLikes = ''.obs;
  final RxBool hasErrorLikes = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLikedByUsers();
  }

  void switchTab(int index) {
    activeTab.value = index;
  }
 

  Future<void> loadPendingChats() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';
      final result = await getPendingLikedChatsUsecase.execute();
      pendingChats.value = result;
    } catch (e) {
      hasError.value = true;
      errorMessage.value = cleanExceptionMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPendingChats() async => loadPendingChats();
 

  Future<void> loadLikedByUsers() async {
    try {
      isLoadingLikes.value = true;
      hasErrorLikes.value = false;
      errorMessageLikes.value = '';
       final result = await getLikeByUsersUsecase.execute(0);
      likedByUsers.value = result;
    } catch (e) {
      hasErrorLikes.value = true;
      errorMessageLikes.value = cleanExceptionMessage(e);
    } finally {
      isLoadingLikes.value = false;
    }
  }

  Future<void> refreshLikedByUsers() async => loadLikedByUsers();
 

  void navigateToUserProfile(int userId) {
    Get.toNamed(
      RoutesNames.userProfileDetailPage,
      arguments: {'userId': userId},
    );
  }

  void navigateToProfile(int userId) => navigateToUserProfile(userId);
 

  Future<void> unlockChat(PendingChatEntity chat) async {
    _showUnlockConfirmation(chat);
  }

  void _showUnlockConfirmation(PendingChatEntity chat) {
    showCustomAlert(
      context: Get.context!,
      title: '¡Conecta con ${chat.name ?? 'este usuario'}!',
      message:
          '${chat.name ?? 'Este usuario'} quiere conectar contigo. ¿Aceptas iniciar la conversación?',
      confirmText: 'Conectar',
      cancelText: 'Ahora no',
      type: CustomAlertType.confirm,
      customWidget: chat.hiddenMessage != null
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColor.backgroundColorfondo,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ThemeColor.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_open,
                          size: 16, color: ThemeColor.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Te envió un mensaje:',
                        style: ThemeColor.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ThemeColor.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chat.hiddenMessage!,
                    style: ThemeColor.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                      color: ThemeColor.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            )
          : null,
      onConfirm: () => _performUnlock(chat),
      onCancel: () => Get.back(),
    );
  }

  Future<void> _performUnlock(PendingChatEntity chat) async {
    try {
      showCustomAlert(
        context: Get.context!,
        title: '',
        message: 'Desbloqueando chat...',
        confirmText: '',
        type: CustomAlertType.warning,
        customWidget: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(ThemeColor.primaryColor),
          ),
        ),
      );
      await unlockChatUsecase.execute(chat.chatId);
      await logMatchUsecase(targetUserId: chat.userId.toString());
      Get.back();
      showSuccessSnackbar('Chat desbloqueado correctamente');
      await loadPendingChats();
      navigateToChat(chat.chatId, chat.name ?? 'Usuario');
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      showErrorSnackbar('Error al desbloquear chat: ${cleanExceptionMessage(e)}');
    }
  }

  void navigateToChat(int chatId, String name) {
    Get.toNamed(RoutesNames.chatPage, arguments: {
      'chatId': chatId,
      'name': name,
      'goHomeIndex': 2,
    });
  }

  String getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) return 'Hace ${(diff.inDays / 365).floor()}a';
    if (diff.inDays > 30) return 'Hace ${(diff.inDays / 30).floor()}m';
    if (diff.inDays > 0) return 'Hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'Hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Hace ${diff.inMinutes}min';
    return 'Ahora';
  }
}