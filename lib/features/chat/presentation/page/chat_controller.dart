import 'package:tendria/features/chat/data/presence_repository.dart';
import 'dart:async';
 
import 'package:tendria/features/gift/presentation/widget/gift_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/widgets/alert/custom_alert_type.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper.dart';
import 'package:tendria/features/chat/domain/entities/chat_entity.dart';
import 'package:tendria/features/chat/domain/entities/mensaje_entity.dart';
import 'package:tendria/features/chat/domain/entities/post_chat_entity.dart';
import 'package:tendria/features/chat/domain/entities/usuario_chat_entity.dart';
import 'package:tendria/features/chat/domain/usecase/get_chat_mensaje_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/send_message_usecase.dart';
import 'package:tendria/features/chat/presentation/page/connect.dart';
import 'package:tendria/features/like/domain/usecase/payments_chat_usecase.dart';
import 'package:tendria/features/like/domain/usecase/start_conversations_usecase.dart';
import 'package:tendria/features/like/presentation/controller/my_match_controller.dart';
import 'package:tendria/features/user/presentation/controller/balance_controller.dart';
import 'package:tendria/features/user/presentation/controller/nearby_users_controller.dart';

class ChatController extends GetxController {
  final StartConversationsUsecase startConversationsUsecase;
  final PaymentsChatUsecase paymentsChatUsecase;
  final GetChatMensajeUsecase getChatMensajeUsecase;
  final SendMessageUsecase sendMessageUsecase;
  final AuthService authService;

  ChatController({
    required this.startConversationsUsecase,
    required this.paymentsChatUsecase,
    required this.getChatMensajeUsecase,
    required this.sendMessageUsecase,
    required this.authService,
  });
 
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
 
  BalanceController get balanceController => Get.find<BalanceController>();
  final mensajes = RxList<MensajeEntity>([]);
  final Rx<UsuarioChatEntity?> otroUsuario = Rx<UsuarioChatEntity?>(null);
  final Rx<ChatEntity?> chat = Rx<ChatEntity?>(null);

  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isTyping = false.obs;
  final RxBool isSignalRConnected = false.obs;
  final RxBool isRetrying = false.obs;

  final RxBool isNewConversation = true.obs;
  final RxBool firstMessageSent = false.obs;

  late int targetUserId;
  int? chatId;
  String? userName;
  String? userPhoto;
  String? myPhoto;
  final RxInt goHomeIndex = (-1).obs;
  final RxInt goPerfilIndex = (-1).obs;

  Offset pointerDown = Offset.zero;
  DateTime pointerDownTime = DateTime.now();

  late final SignalRService _signalRService;
 

  @override
  void onInit() {
    super.onInit();
    _signalRService = Get.find<SignalRService>();
    _loadArguments();

    if (!isNewConversation.value) {
      _setupSignalR();
      loadChatMessages().then((_) => _marcarComoLeidos());
    }
    _startPresence();
  }

  // ── Presencia: si la otra persona tiene la app abierta ahora ──
  final RxBool presenceOnline = false.obs;
  final Rxn<DateTime> presenceLastSeen = Rxn<DateTime>();
  Timer? _presenceTimer;

  int get _otherUserId => otroUsuario.value?.id ?? targetUserId;

  void _syncPresenceFromUser() {
    final u = otroUsuario.value;
    if (u == null) return;
    presenceOnline.value = u.isActive ?? false;
    if (u.lastSeen != null) presenceLastSeen.value = u.lastSeen;
  }

  void _startPresence() {
    _refreshPresence();
    _presenceTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refreshPresence());
  }

  Future<void> _refreshPresence() async {
    final id = _otherUserId;
    if (id == 0) return;
    try {
      final p = await PresenceRepository.instance.get(id);
      presenceOnline.value = p.online;
      presenceLastSeen.value = p.lastSeen ?? presenceLastSeen.value;
    } catch (_) {}
  }

  @override
  void onClose() {
    _presenceTimer?.cancel();
    messageController.removeListener(_onMessageChanged);
    messageController.dispose();
    scrollController.dispose();

    if (!isNewConversation.value && chatId != null) {
      _signalRService.unsubscribeFromChat(chatId!);
    }

    super.onClose();
  }
 

  void _setupSignalR() {
    isSignalRConnected.value = _signalRService.isConnected.value;

    ever(_signalRService.isConnected, (bool connected) {
      isSignalRConnected.value = connected;
      if (connected) {
        isRetrying.value = false;
        _resubscribeIfNeeded();
      }
    });

    ever(_signalRService.isReconnecting, (bool reconnecting) {
      if (reconnecting) isRetrying.value = true;
    });

    _signalRService.escucharMensajesLeidos(_onMensajesLeidos);
    _subscribeToChat();
    messageController.addListener(_onMessageChanged);
  }

  Future<void> _subscribeToChat() async {
    if (chatId == null) return;
    try {
      await _signalRService.subscribeToChat(chatId!, _handleIncomingMessage);
    } catch (e) {
      print('⚠️ Error suscribiéndose al chat: $e');
    }
  }

  Future<void> _resubscribeIfNeeded() async {
    if (chatId == null) return;
    try {
      await _signalRService.subscribeToChat(chatId!, _handleIncomingMessage);
      print('🔄 Re-suscripción al chat #$chatId tras reconexión');
    } catch (e) {
      print('⚠️ Error re-suscribiéndose al chat #$chatId: $e');
    }
  } 

  void _loadArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    chatId = args?['chatId'] as int?;
    targetUserId = args?['userid'] ?? args?['userId'] ?? 0;
    userName = args?['name'];
    isNewConversation.value = (chatId == null);
    userPhoto = args?['photo'];
    myPhoto = args?['MyPhoto'];
    goHomeIndex.value = args?['goHomeIndex'] ?? -1;
    goPerfilIndex.value = args?['goPerfilIndex'] ?? -1;

    if (args?['otroUsuario'] != null) {
      otroUsuario.value = args!['otroUsuario'] as UsuarioChatEntity;
    }
  }
 

  Future<void> _marcarComoLeidos() async {
    if (chatId == null) return;
    final otroId = otroUsuario.value?.id ?? 0;
    if (otroId == 0) return;
    await _signalRService.marcarMensajesLeidos(chatId!, otroId);
  }

  void _onMensajesLeidos(DateTime leidoEn) {
    mensajes.value = mensajes.map((m) {
      if (m.esPropio && m.leidoEn == null) {
        return MensajeEntity(
          id: m.id,
          chatId: m.chatId,
          senderId: m.senderId,
          senderNombre: m.senderNombre,
          senderFoto: m.senderFoto,
          mensaje: m.mensaje,
          enviadoEn: m.enviadoEn,
          esPropio: m.esPropio,
          leidoEn: leidoEn,
          giftCode: m.giftCode,
          giftName: m.giftName,
          storyUrl: m.storyUrl,
        );
      }
      return m;
    }).toList();
  }
 

  void _handleIncomingMessage(MensajeEntity mensaje) {
    if (mensajes.any((m) => m.id == mensaje.id)) return;
    mensajes.value = [
      ...mensajes,
      MensajeEntity(
        id: mensaje.id,
        chatId: mensaje.chatId,
        senderId: mensaje.senderId,
        senderNombre: mensaje.senderNombre,
        senderFoto: mensaje.senderFoto,
        mensaje: mensaje.mensaje,
        enviadoEn: mensaje.enviadoEn,
        esPropio: mensaje.esPropio,
        giftCode: mensaje.giftCode,
        giftName: mensaje.giftName,
        storyUrl: mensaje.storyUrl,
      ),
    ];
    if (mensaje.esPropio || _isNearBottom()) {
      Future.delayed(const Duration(milliseconds: 100), scrollToBottom);
    }
  }

  bool _isNearBottom() {
    if (!scrollController.hasClients) return false;
    return (scrollController.position.maxScrollExtent -
            scrollController.position.pixels) <
        100;
  }
 

  Future<void> loadChatMessages() async {
    if (chatId == null) return;
    try {
      isLoading.value = true;
      hasError.value = false;
      final result = await getChatMensajeUsecase.execute(chatId!);
      chat.value = result;
      mensajes.value = (result.mensajes ?? [])
          .map((m) => MensajeEntity(
                id: m.id,
                chatId: m.chatId,
                senderId: m.senderId,
                senderNombre: m.senderNombre,
                senderFoto: m.senderFoto,
                mensaje: m.mensaje,
                enviadoEn: m.enviadoEn,
                esPropio: m.esPropio,
                leidoEn: m.leidoEn,
                giftCode: m.giftCode,
                giftName: m.giftName,
                storyUrl: m.storyUrl,
              ))
          .toList();
      otroUsuario.value = result.otroUsuario;
      _syncPresenceFromUser();
      Future.delayed(const Duration(milliseconds: 300), scrollToBottom);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error al cargar mensajes: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshChat() => loadChatMessages();

  /// Abre la hoja de regalos. Si la conversación aún no existe, el regalo la crea.
  Future<void> sendGift(BuildContext context) async {
    final toId = otroUsuario.value?.id ?? targetUserId;
    if (toId == 0) return;

    final result = await showGiftSheet(
      context,
      toUserId: toId,
      toName: otroUsuario.value?.nombre ?? userName ?? '',
      origin: 'chat',
    );
    if (result == null) return;

    if (isNewConversation.value && result.chatId != null) {
      chatId = result.chatId;
      isNewConversation.value = false;
      _setupSignalR();
      await loadChatMessages();
    } else if (result.message != null) {
      _handleIncomingMessage(result.message!);
    }
  }
 

  void _onMessageChanged() {
    if (isNewConversation.value && firstMessageSent.value) {
      if (messageController.text.isNotEmpty) messageController.clear();
      isTyping.value = false;
      return;
    }
    isTyping.value = messageController.text.trim().isNotEmpty;
  }

  Future<void> sendMessage() async {
    if (isNewConversation.value) {
      await _sendFirstMessage();
    } else {
      await _sendRegularMessage();
    }
  }

  Future<void> _sendFirstMessage() async {
    if (firstMessageSent.value || isSending.value) return;
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    try {
      isSending.value = true;
      messageController.clear();

      final postEntity = PostChatEntity(chatId: targetUserId, menssage: message);
      final newChatId = await startConversationsUsecase.execute(postEntity);
      isTyping.value = false;

      if (Get.isRegistered<NearbyUsersController>()) {
        Get.find<NearbyUsersController>().loadNearbyUsers();
      }

      if (newChatId != null && newChatId > 0) {
        // El chat es libre: pasa a conversación normal y se puede seguir escribiendo.
        chatId = newChatId;
        isNewConversation.value = false;
        _setupSignalR();
        await loadChatMessages();
      } else {
        _addLocalMessage(message);
        firstMessageSent.value = true;
        showSuccessSnackbar('Mensaje enviado.');
      }
      Future.delayed(const Duration(milliseconds: 100), scrollToBottom);
    } catch (e) {
      messageController.text = message;
      showErrorSnackbar(cleanExceptionMessage(e));
    } finally {
      isSending.value = false;
    }
  }

  Future<void> _sendRegularMessage() async {
    final message = messageController.text.trim();
    if (message.isEmpty || isSending.value) return;

    try {
      isSending.value = true;
      messageController.clear();
 
      if (!_signalRService.isConnected.value) {
        print('📡 Sin conexión — esperando antes de enviar...');
        try {
          await _signalRService.waitUntilConnected(
            timeout: const Duration(seconds: 15),
          );
        } catch (e) { 
          messageController.text = message;
          isSending.value = false;
          showErrorSnackbar('Sin conexión. Verifica tu internet e inténtalo de nuevo.');
          return;
        }
      }
 
      final postEntity = PostChatEntity(chatId: chatId!, menssage: message);
      await sendMessageUsecase.execute(postEntity); 
    } catch (e) {
      messageController.text = message;
      print('Error enviando mensaje: $e');
      showErrorSnackbar('No se pudo enviar el mensaje');
    } finally {
      isSending.value = false;
    }
  }

  void _addLocalMessage(String messageText, {int? tempId}) {
    final nuevo = MensajeEntity(
      id: tempId ?? DateTime.now().millisecondsSinceEpoch,
      chatId: chatId ?? targetUserId,
      senderId: 0,
      senderNombre: null,
      senderFoto: myPhoto,
      mensaje: messageText,
      enviadoEn: DateTime.now(),
      esPropio: true,
    );
    mensajes.value = [...mensajes, nuevo];
  }
 

  Future<void> retrySignalRConnection() async {
    if (isSignalRConnected.value || isRetrying.value) return;
    isRetrying.value = true;
    try {
      await _signalRService.retryConnection();
      if (_signalRService.isConnected.value && chatId != null) {
        await _signalRService.subscribeToChat(chatId!, _handleIncomingMessage);
      }
    } catch (e) {
      print('❌ Error en retry manual: $e');
    } finally {
      isRetrying.value = false;
    }
  }
 

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void navigateToProfile() {
    final uid = otroUsuario.value?.id ?? targetUserId;
    Get.toNamed(
      RoutesNames.userProfileDetailPage,
      arguments: {'userId': uid, 'goPerfilIndex': goPerfilIndex},
    );
  }

  String formatMessageTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (diff.inDays == 0) return '$hh:$mm';
    if (diff.inDays == 1) return 'Ayer $hh:$mm';
    if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return '${days[local.weekday - 1]} $hh:$mm';
    }
    return '${local.day}/${local.month}/${local.year}';
  }

  String formatDateSeparator(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msg = DateTime(local.year, local.month, local.day);
    if (msg == today) return 'Hoy';
    if (msg == today.subtract(const Duration(days: 1))) return 'Ayer';
    if (now.difference(msg).inDays < 7) {
      const days = [
        'Lunes', 'Martes', 'Miércoles', 'Jueves',
        'Viernes', 'Sábado', 'Domingo'
      ];
      return days[local.weekday - 1];
    }
    return '${local.day}/${local.month}/${local.year}';
  }

  bool shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final cur = mensajes[index].enviadoEn.toLocal();
    final prev = mensajes[index - 1].enviadoEn.toLocal();
    return DateTime(cur.year, cur.month, cur.day) !=
        DateTime(prev.year, prev.month, prev.day);
  }

  void setPointerDown(Offset position) => pointerDown = position;
  void setPointerDownTime(DateTime time) => pointerDownTime = time;
}