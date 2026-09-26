 
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/features/chat/domain/entities/mensaje_entity.dart';
import 'package:tendria/features/chat/domain/usecase/connect_signalr_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/disconnect_signalr_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/join_chat_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/leave_chat_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/marcar_mensajes_leidos_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/on_mensajes_leidos_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/setup_message_listener_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/set_on_disconnected_callback_usecase.dart';

class SignalRService extends GetxService with WidgetsBindingObserver {
  final ConnectSignalRUsecase connectSignalRUsecase;
  final DisconnectSignalRUsecase disconnectSignalRUsecase;
  final JoinChatUsecase joinChatUsecase;
  final LeaveChatUsecase leaveChatUsecase;
  final SetupMessageListenerUsecase setupMessageListenerUsecase;
  final SetOnDisconnectedCallbackUsecase setOnDisconnectedCallbackUsecase;
  final OnMensajesLeidosUsecase onMensajesLeidosUsecase;
  final MarcarMensajesLeidosUsecase marcarMensajesLeidosUsecase;
  AuthService authService = AuthService();

  SignalRService({
    required this.connectSignalRUsecase,
    required this.disconnectSignalRUsecase,
    required this.joinChatUsecase,
    required this.leaveChatUsecase,
    required this.setupMessageListenerUsecase,
    required this.setOnDisconnectedCallbackUsecase,
    required this.onMensajesLeidosUsecase,
    required this.marcarMensajesLeidosUsecase,
  });

  final RxBool isConnected = false.obs;
  final RxBool isReconnecting = false.obs;

  final Map<int, Function(MensajeEntity)> _chatListeners = {};
  Function(MensajeEntity)? _globalListener;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 8;

  bool _isConnecting = false; 
  Completer<void>? _connectCompleter; 

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _connectIfAuthenticated();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onAppResumed();
  }

  Future<void> _onAppResumed() async {
    print('📱 App en primer plano');
    if (isConnected.value) {
      print('✅ SignalR sigue conectado, sin acción necesaria');
      return;
    }
    _reconnectAttempts = 0;
    isReconnecting.value = false;
    print('🔄 Reconectando tras volver al primer plano...');
    await _reconnect();
  }
 

  Future<void> _connectIfAuthenticated() async {
    final token = await authService.getToken();
    if (token != null) await connect(token);
  }

  Future<void> connect(String token) async {
    if (isConnected.value) return;
    if (_isConnecting) {
      print('⏳ Conexión en curso, esperando...');
      await _awaitCompleter();
      return;
    }
    await _doConnect(token);
  }
 
  Future<void> _doConnect(String token) async {
    _isConnecting = true;
    _connectCompleter = Completer<void>();
    _connectCompleter!.future.ignore();

    try {
      await connectSignalRUsecase.execute(token);
      setupMessageListenerUsecase.execute(_routeMessage);
      setOnDisconnectedCallbackUsecase.execute(_onUnexpectedDisconnect);
      onMensajesLeidosUsecase.execute(_noop);

      isConnected.value = true;
      isReconnecting.value = false;
      _reconnectAttempts = 0;

      _connectCompleter!.complete();
      print('✅ SignalR conectado');
    } catch (e) {
      isConnected.value = false;
      print('❌ Error conectando SignalR: $e');
      _connectCompleter!.completeError(e);
      if (!isReconnecting.value) unawaited(_scheduleReconnect());
    } finally {
      _isConnecting = false;
      _connectCompleter = null;
    }
  }
 
  Future<void> _awaitCompleter() async {
    final c = _connectCompleter;
    if (c == null || c.isCompleted) return;
    try {
      await c.future.timeout(const Duration(seconds: 20));
    } catch (_) {}
  }
 

  void _onUnexpectedDisconnect() {
    if (isReconnecting.value || _isConnecting) return;
    print('⚠️ SignalR desconectado inesperadamente');
    isConnected.value = false;
    _scheduleReconnect();
  }

  Future<void> _scheduleReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Máximo de reintentos alcanzado');
      _reconnectAttempts = 0;
      isReconnecting.value = false;
      return;
    }

    isReconnecting.value = true;
    final seconds = _reconnectAttempts < 4 ? (2 << _reconnectAttempts) : 30;
    _reconnectAttempts++;

    print('⏳ Reintento $_reconnectAttempts en ${seconds}s...');
    await Future.delayed(Duration(seconds: seconds));
    await _reconnect();
  }

  Future<void> _reconnect() async {
    if (isConnected.value || _isConnecting) return;

    final token = await authService.getToken();
    if (token == null) {
      print('⚠️ No hay token para reconectar');
      isReconnecting.value = false;
      return;
    }

    _isConnecting = true; 
    _connectCompleter = Completer<void>();
    _connectCompleter!.future.ignore();

    try {
      await connectSignalRUsecase.execute(token);
      setupMessageListenerUsecase.execute(_routeMessage);
      setOnDisconnectedCallbackUsecase.execute(_onUnexpectedDisconnect);
      onMensajesLeidosUsecase.execute(_noop);

      isConnected.value = true;
      isReconnecting.value = false;
      _reconnectAttempts = 0;
 
      _connectCompleter!.complete();

      await _rejoinActiveChats();
      print('✅ SignalR reconectado con ${_chatListeners.length} chats activos');
    } catch (e) {
      isConnected.value = false;
      print('❌ Reintento $_reconnectAttempts falló: $e');
 
      if (!_connectCompleter!.isCompleted) {
        _connectCompleter!.completeError(e);
      }
      _connectCompleter = null;
      _isConnecting = false;

      await _scheduleReconnect();
      return;
    }
 
    _connectCompleter = null;
    _isConnecting = false;
  }

  Future<void> _rejoinActiveChats() async {
    for (final chatId in List<int>.from(_chatListeners.keys)) {
      try {
        await joinChatUsecase.execute(chatId);
        print('✅ Re-unido al chat #$chatId');
      } catch (e) {
        print('❌ Error re-uniéndose al chat #$chatId: $e');
      }
    }
  }
 
  Future<void> waitUntilConnected({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (isConnected.value) return;

    if (_isConnecting) {
      await _awaitCompleter();
      if (isConnected.value) return;
    }

    if (!isConnected.value && !_isConnecting) {
      final token = await authService.getToken();
      if (token != null) await _doConnect(token);
      if (isConnected.value) return;
    }
 
    final waiter = Completer<void>();
    ever(isConnected, (bool connected) {
      if (connected && !waiter.isCompleted) waiter.complete();
    });

    await waiter.future.timeout(
      timeout,
      onTimeout: () =>
          throw Exception('Timeout: no se pudo conectar a SignalR'),
    );
  }
 

  Future<void> subscribeToChat(
      int chatId, Function(MensajeEntity) callback) async {
    if (_isConnecting) {
      print('⏳ Esperando conexión para suscribirse al chat #$chatId...');
      await _awaitCompleter();
    }

    if (!isConnected.value) {
      await _reconnect();
      if (!isConnected.value) {
        throw Exception('SignalR no disponible para chat #$chatId');
      }
    }

    _chatListeners[chatId] = callback;
    await joinChatUsecase.execute(chatId);
    print('✅ Suscrito al chat #$chatId');
  }

  Future<void> unsubscribeFromChat(int chatId) async {
    _chatListeners.remove(chatId);
    try {
      await leaveChatUsecase.execute(chatId);
      print('👋 Desuscrito del chat #$chatId');
    } catch (e) {
      print('⚠️ Error desuscribiéndose del chat #$chatId: $e');
    }
  }

  void setGlobalListener(Function(MensajeEntity) callback) =>
      _globalListener = callback;

  void removeGlobalListener() => _globalListener = null;
 

  void _routeMessage(MensajeEntity mensaje) {
    _chatListeners[mensaje.chatId]?.call(mensaje);
    _globalListener?.call(mensaje);
  } 
  void _noop(DateTime _) {}
 

  Future<void> disconnect() async {
    _reconnectAttempts = _maxReconnectAttempts;
    isReconnecting.value = false;
    _isConnecting = false;
    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      _connectCompleter!.completeError('logout');
    }
    _connectCompleter = null;

    for (final chatId in List<int>.from(_chatListeners.keys)) {
      try {
        await leaveChatUsecase.execute(chatId);
      } catch (_) {}
    }
    _chatListeners.clear();
    _globalListener = null;

    await disconnectSignalRUsecase.execute();
    isConnected.value = false;
    print('✅ SignalR desconectado por logout');
  } 

  Future<void> marcarMensajesLeidos(int chatId, int otroUserId) async {
    if (!isConnected.value) return;
    await marcarMensajesLeidosUsecase.execute(chatId, otroUserId);
  }

  void escucharMensajesLeidos(Function(DateTime) callback) {
    onMensajesLeidosUsecase.execute(callback);
  } 

  Future<void> retryConnection() async {
    if (isConnected.value || _isConnecting) return;
    _reconnectAttempts = 0;
    isReconnecting.value = false;
    await _reconnect();
  }
}