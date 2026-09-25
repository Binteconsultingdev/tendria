import 'dart:async';
import 'package:get/get.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/features/chat/domain/usecase/get_my_chats_usecase.dart';
import 'package:tendria/features/chat/domain/entities/chat_entity.dart';

class MyMatchController extends GetxController {
  final GetMyChatsUsecase getMyChatsUsecase;
  MyMatchController({required this.getMyChatsUsecase});

   final RxList<ChatEntity> chats = <ChatEntity>[].obs;
  final RxList<ChatEntity> filteredChats = <ChatEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;
  final RxBool isSearching = false.obs;
  final RxString searchQuery = ''.obs;
 
  final RxBool filterPendingOnly = false.obs;
bool _hasLoadedOnce = false;  
final RxBool isSilentLoading = false.obs;
  Timer? _presenceTimer;

  @override
  void onInit() {
    super.onInit();
    loadChats();
    // El indicador "en línea" se actualiza solo cada 20 s
    _presenceTimer = Timer.periodic(const Duration(seconds: 20), (_) => loadChats(silent: true));
  }

  @override
  void onClose() {
    _presenceTimer?.cancel();
    super.onClose();
  }
 

Future<void> loadChats({bool silent = false}) async {
  try { 
    if (silent || _hasLoadedOnce) {
      isSilentLoading.value = true;
    } else {
      isLoading.value = true;
    }
    hasError.value = false;
    errorMessage.value = '';

    final result = await getMyChatsUsecase.execute();
    chats.value = result;
    _hasLoadedOnce = true;  
    _applyFilters();
  } catch (e) {
    if (chats.isEmpty && !_hasLoadedOnce) {
      hasError.value = true;
      errorMessage.value = 'Error al cargar chats: $e';
    }
    print('Error loading chats: $e');
  } finally {
    isLoading.value = false;
    isSilentLoading.value = false;
  }
}


Future<void> refreshChats() async {
  await loadChats(silent: true);
}

 
  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      clearSearch();
    }
  }
 
  void searchChats(String query) {
    searchQuery.value = query;
    _applyFilters();
  }
 
  void clearSearch() {
    searchQuery.value = '';
    _applyFilters();
  }
 
  void togglePendingFilter() {
    filterPendingOnly.value = !filterPendingOnly.value;
    _applyFilters();
  }
 
  void _applyFilters() {
    List<ChatEntity> result = List.from(chats);
 
    if (filterPendingOnly.value) {
      result = result.where((chat) {
        final ultimo = chat.ultimoMensaje;
        return ultimo != null && !ultimo.esPropio;
      }).toList();
    }
 
    if (searchQuery.value.isNotEmpty) {
      final searchLower = searchQuery.value.toLowerCase();
      result = result.where((chat) {
        final nombre = chat.otroUsuario.nombre.toLowerCase();
        final mensaje = chat.ultimoMensaje?.mensaje?.toLowerCase() ?? '';
        return nombre.contains(searchLower) || mensaje.contains(searchLower);
      }).toList();
    }

    filteredChats.value = result;
  }
 
  int get pendingCount => chats
      .where((c) => c.ultimoMensaje != null && !c.ultimoMensaje!.esPropio)
      .length;
 
  void navigateToChat(int chatId, String name) {
    print('Navigating to chat with ID: $chatId and name: $name');
    Get.toNamed(RoutesNames.chatPage, arguments: {
      'chatId': chatId,
      'name': name,
      'goHomeIndex': 3,
      'goPerfilIndex': 3,
    });
  }
 
  void navigateToProfile(int userId) {
    Get.toNamed('/profile', arguments: {'userId': userId});
  }
}