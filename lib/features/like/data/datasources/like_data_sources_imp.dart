import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/errors/api_errors.dart';
import 'package:tendria/features/chat/data/model/post_chat_model.dart';
import 'package:tendria/features/chat/domain/entities/post_chat_entity.dart';
import 'package:tendria/features/like/data/model/liked_by_users_model.dart';
import 'package:tendria/features/like/data/model/pending_chat_model.dart';
import 'package:tendria/features/like/domain/entities/liked_by_users_entity.dart';
import 'package:tendria/features/like/domain/entities/pending_chat_entity.dart';

class LikeDataSourcesImp {
  String defaultApiServer = AppConstants.serverBase;

  Future<List<LikedByUsersEntity>> getLikedByUsers(int postId,String token) async {
      try {
      Uri url = Uri.parse('$defaultApiServer/Likes/usuarios-interesados');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.statusCode == 200) {
          final dataUTF8 = utf8.decode(response.bodyBytes);
          final responseDecode = jsonDecode(dataUTF8);

          final List data = responseDecode;
          return data.map((json) => LikedByUsersModel.fromJson(json)).toList();
        }
      }

      ApiExceptionCustom exception = ApiExceptionCustom(response: response);
      exception.validateMesage();
      throw exception;
    } catch (e) {
      if (e is SocketException ||
          e is http.ClientException ||
          e is TimeoutException) {
        throw Exception(convertMessageException(error: e));
      }

      throw Exception('$e');
    }
  }


  Future<List<PendingChatEntity>> getPendingLikedChats(String token)  async{
    try {
      Uri url = Uri.parse('$defaultApiServer/Likes/chats-pendientes');

      final response = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.statusCode == 200) {
          final dataUTF8 = utf8.decode(response.bodyBytes);
          final responseDecode = jsonDecode(dataUTF8);

          final List data = responseDecode;
          return data.map((json) => PendingChatModel.fromJson(json)).toList();
        }
      }

      ApiExceptionCustom exception = ApiExceptionCustom(response: response);
      exception.validateMesage();
      throw exception;
    } catch (e) {
      if (e is SocketException ||
          e is http.ClientException ||
          e is TimeoutException) {
        throw Exception(convertMessageException(error: e));
      }

      throw Exception('$e');
    }
  }
Future<void> toggleLike(int userId, bool liked, String token) async {
  try {
    Uri url = Uri.parse('$defaultApiServer/Likes/dar-like');

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode({
        'to_user': userId,
        'liked': liked,
      }),
    );
 
    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE BODY: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    ApiExceptionCustom exception = ApiExceptionCustom(response: response);
    exception.validateMesage();
    throw exception;

  } catch (e) {
 
    print('ERROR EN toggleLike: $e');

    if (e is SocketException ||
        e is http.ClientException ||
        e is TimeoutException) {
      throw Exception(convertMessageException(error: e));
    }

    throw Exception('$e');
  }
}

  Future<void> unlockChat(int chatId, String token) async {
    try {
      Uri url = Uri.parse('$defaultApiServer/Likes/desbloquear-chat/$chatId');

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
       
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      ApiExceptionCustom exception = ApiExceptionCustom(response: response);
      exception.validateMesage();
      throw exception;
    } catch (e) {
      if (e is SocketException ||
          e is http.ClientException ||
          e is TimeoutException) {
        throw Exception(convertMessageException(error: e));
      }
      throw Exception('$e');
    }
  }
  
  Future<void> paymentsChat(int chatId, String token) async {
    try {
      Uri url = Uri.parse('$defaultApiServer/Likes/pagar-chat/$chatId');

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
       
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      ApiExceptionCustom exception = ApiExceptionCustom(response: response);
      exception.validateMesage();
      throw exception;
    } catch (e) {
      if (e is SocketException ||
          e is http.ClientException ||
          e is TimeoutException) {
        throw Exception(convertMessageException(error: e));
      }
      throw Exception('$e');
    }
  }
  Future<int?> startConversations(PostChatEntity entity, String token) async {
    try {
      Uri url = Uri.parse('$defaultApiServer/Likes/iniciar-chat');

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(PostChatModel.fromEntity(entity).toJsonfirstMessage()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          return data['chatId'] as int?;
        } catch (_) {
          return null;
        }
      }

      ApiExceptionCustom exception = ApiExceptionCustom(response: response);
      exception.validateMesage();
      throw exception;
    } catch (e) {
      if (e is SocketException ||
          e is http.ClientException ||
          e is TimeoutException) {
        throw Exception(convertMessageException(error: e));
      }
      throw Exception('$e');
    }
  }
}