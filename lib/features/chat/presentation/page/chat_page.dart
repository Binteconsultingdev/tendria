import 'package:tendria/features/feed/presentation/widget/time_ago.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/features/gift/presentation/widget/gift_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/chat/domain/entities/mensaje_entity.dart';
import 'package:tendria/features/chat/presentation/page/chat_controller.dart';
import 'package:tendria/features/chat/presentation/page/connect.dart';
import 'package:tendria/features/like/presentation/controller/my_match_controller.dart';

class ChatPage extends GetView<ChatController> {
  const ChatPage({Key? key}) : super(key: key);

  MyMatchController get mycontroller => Get.find<MyMatchController>();
  LanguageController get _l => Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            FocusScope.of(context).unfocus();
            mycontroller.loadChats();
            if (controller.goHomeIndex.value >= 0) {
              Get.offAllNamed(
                RoutesNames.homePage,
                arguments: {'tab': controller.goHomeIndex.value},
              );
            } else {
              Get.back();
              mycontroller.loadChats();
            }
          },
          child: Listener(
            onPointerDown: (e) {
              controller.setPointerDown(e.position);
              controller.setPointerDownTime(DateTime.now());
            },
            onPointerUp: (e) {
              final distance =
                  (e.position - controller.pointerDown).distance;
              final duration = DateTime.now().difference(
                controller.pointerDownTime,
              );
              if (distance < 10 && duration.inMilliseconds < 200) {
                FocusScope.of(context).unfocus();
              }
            },
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              backgroundColor: ThemeColor.backgroundColor,
              appBar: _buildAppBar(),
              body: Column(
                children: [
                  _buildConnectionIndicator(),
                  Expanded(child: _buildBody()),
                  _buildMessageInput(),
                ],
              ),
            ),
          ),
        ));
  }
 

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ThemeColor.cardBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowLeft, color: ThemeColor.textPrimary),
        onPressed: () {
          FocusScope.of(Get.context!).unfocus();
          if (controller.goHomeIndex.value >= 0) {
            mycontroller.loadChats(silent: true);
            Get.offAllNamed(
              RoutesNames.homePage,
              arguments: {'tab': controller.goHomeIndex.value},
            );
          } else {
            Get.back();
            mycontroller.loadChats(silent: true);
          }
        },
      ),
      title: Obx(() {
        final usuario = controller.otroUsuario.value;
        final online = controller.presenceOnline.value;
        final lastSeen = controller.presenceLastSeen.value;
        final photo = usuario?.fotoUrl?.isNotEmpty == true ? usuario!.fotoUrl! : controller.userPhoto;

        String status = '';
        if (online) {
          status = _l.t('chat_online');
        } else if (lastSeen != null) {
          status = '${_l.t('chat_last_seen')} ${timeAgo(lastSeen)}';
        }

        return InkWell(
          onTap: () {
            FocusScope.of(Get.context!).unfocus();
            controller.navigateToProfile();
          },
          child: Row(
            children: [
              Stack(
                children: [
                  UserAvatar(url: photo, radius: 20),
                  if (online)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: ThemeColor.cardBackground, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario?.nombre ?? controller.userName ?? _l.t('user'),
                      style: GoogleFonts.rubik(fontSize: 16.5, fontWeight: FontWeight.w600, color: ThemeColor.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (status.isNotEmpty)
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          fontWeight: online ? FontWeight.w600 : FontWeight.w400,
                          color: online ? const Color(0xFF16A34A) : ThemeColor.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: ThemeColor.textSecondary.withValues(alpha: 0.12)),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: ThemeColor.backgroundColorfondo,
      child: Icon(
        Icons.person,
        size: 24,
        color: ThemeColor.textSecondary,
      ),
    );
  } 

  Widget _buildConnectionIndicator() {
    return Obx(() {
      if (controller.isNewConversation.value) return const SizedBox.shrink();
      if (controller.isSignalRConnected.value) return const SizedBox.shrink();

      final isRetrying = controller.isRetrying.value ||
          Get.find<SignalRService>().isReconnecting.value;

      return GestureDetector(
        onTap: isRetrying ? null : controller.retrySignalRConnection,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: ThemeColor.warningColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRetrying)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ThemeColor.warningColor,
                  ),
                )
              else
                Icon(Icons.refresh, size: 16, color: ThemeColor.warningColor),
              const SizedBox(width: 8),
              Text(
                isRetrying
                    ? _l.t('chat_reconnecting')
                    : _l.t('chat_no_connection'),
                style: ThemeColor.caption.copyWith(
                  color: ThemeColor.warningColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
 

  Widget _buildBody() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/fodochat.jpeg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.15)),
        ),
        Obx(() {
          if (!controller.isNewConversation.value) {
            if (controller.isLoading.value && controller.mensajes.isEmpty) {
              return _buildLoadingState();
            }
            if (controller.hasError.value && controller.mensajes.isEmpty) {
              return _buildErrorState();
            }
          }
          if (controller.mensajes.isEmpty) return _buildEmptyState();
          return _buildMessagesList();
        }),
      ],
    );
  }
 

  Widget _buildMessagesList() {
    return RefreshIndicator(
      onRefresh: controller.refreshChat,
      color: ThemeColor.primaryColor,
      backgroundColor: ThemeColor.cardBackground,
      child: ListView.builder(
        controller: controller.scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: controller.mensajes.length,
        itemBuilder: (_, index) {
          final msg = controller.mensajes[index];
          return Column(
            children: [
              if (controller.shouldShowDateSeparator(index))
                _buildDateSeparator(msg.enviadoEn),
              _buildMessageBubble(msg),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateSeparator(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            controller.formatDateSeparator(dt),
            style: GoogleFonts.rubik(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// Regalo: una tarjeta pequeña de una línea (icono, nombre y hora), no un bloque grande.
  Widget _buildGiftBubble(MensajeEntity mensaje) {
    final isOwn = mensaje.esPropio;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ThemeColor.primaryColor.withValues(alpha: 0.13),
                ThemeColor.primaryColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ThemeColor.primaryColor.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GiftIcon(code: mensaje.giftCode!, size: 40),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    mensaje.giftName ?? '',
                    style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary),
                  ),
                  Text(
                    isOwn ? _l.t('gift_you_sent') : _l.t('gift_sent_to_you'),
                    style: GoogleFonts.rubik(fontSize: 11.5, color: ThemeColor.textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Text(
                controller.formatMessageTime(mensaje.enviadoEn),
                style: GoogleFonts.rubik(fontSize: 10.5, color: ThemeColor.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MensajeEntity mensaje) {
    if (mensaje.giftCode != null) return _buildGiftBubble(mensaje);

    final isOwn = mensaje.esPropio;
    final hasText = mensaje.mensaje != null && mensaje.mensaje!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: Get.width * 0.78),
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 7),
          decoration: BoxDecoration(
            gradient: isOwn ? ThemeColor.primaryGradient : null,
            color: isOwn ? null : ThemeColor.cardBackground,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isOwn ? 20 : 6),
              bottomRight: Radius.circular(isOwn ? 6 : 20),
            ),
            boxShadow: isOwn
                ? null
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasText)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    mensaje.mensaje!,
                    style: GoogleFonts.rubik(
                      fontSize: 15,
                      height: 1.35,
                      color: isOwn ? Colors.white : ThemeColor.textPrimary,
                    ),
                  ),
                ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.formatMessageTime(mensaje.enviadoEn),
                    style: GoogleFonts.rubik(
                      fontSize: 10.5,
                      color: isOwn ? Colors.white.withValues(alpha: 0.75) : ThemeColor.textSecondary,
                    ),
                  ),
                  if (isOwn) ...[
                    const SizedBox(width: 4),
                    Icon(
                      mensaje.leidoEn != null ? LucideIcons.checkCheck : LucideIcons.check,
                      size: 14,
                      color: mensaje.leidoEn != null ? const Color(0xFF8FD6FF) : Colors.white.withValues(alpha: 0.75),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Obx(() {
      final isNew = controller.isNewConversation.value;
      final blocked = isNew && controller.firstMessageSent.value;
      final canSend = !blocked && (isNew ? !controller.isSending.value : controller.isTyping.value && !controller.isSending.value);

      return Container(
        decoration: BoxDecoration(
          color: ThemeColor.cardBackground,
          border: Border(top: BorderSide(color: ThemeColor.textSecondary.withValues(alpha: 0.12))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (blocked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _l.t('chat_first_msg_sent'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rubik(fontSize: 12.5, color: ThemeColor.primaryColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Regalo: un solo botón discreto; la selección se abre en una hoja
                    GestureDetector(
                      onTap: blocked ? null : () => controller.sendGift(Get.context!),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ThemeColor.primaryColor.withValues(alpha: blocked ? 0.04 : 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.gift, size: 21, color: ThemeColor.primaryColor.withValues(alpha: blocked ? 0.4 : 1)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: ThemeColor.backgroundColorfondo,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: controller.messageController,
                          enabled: !blocked,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          style: GoogleFonts.rubik(fontSize: 15, color: ThemeColor.textPrimary),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            hintText: blocked ? _l.t('chat_hint_blocked') : _l.t('chat_hint'),
                            hintStyle: GoogleFonts.rubik(fontSize: 15, color: ThemeColor.textSecondary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: canSend
                          ? () {
                              FocusScope.of(Get.context!).unfocus();
                              controller.sendMessage();
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: canSend ? ThemeColor.primaryGradient : null,
                          color: canSend ? null : ThemeColor.textSecondary.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          boxShadow: canSend
                              ? [BoxShadow(color: ThemeColor.primaryColor.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 4))]
                              : null,
                        ),
                        child: controller.isSending.value
                            ? const Padding(
                                padding: EdgeInsets.all(13),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(LucideIcons.arrowUp, size: 22, color: canSend ? Colors.white : ThemeColor.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 24),
            Text(
              _l.t('chat_empty_title'),
              style: ThemeColor.headingSmall.copyWith(
                color: ThemeColor.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _l.t('chat_empty_subtitle'),
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

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor:
            AlwaysStoppedAnimation<Color>(ThemeColor.primaryColor),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: ThemeColor.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              _l.t('chat_error_title'),
              style: ThemeColor.headingSmall.copyWith(
                color: ThemeColor.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              style: ThemeColor.bodyMedium.copyWith(
                color: ThemeColor.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.loadChatMessages,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColor.primaryColor,
              ),
              child: Text(
                _l.t('retry'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}