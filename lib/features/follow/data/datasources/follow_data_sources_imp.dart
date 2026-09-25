import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/errors/api_errors.dart';
import 'package:tendria/features/follow/domain/entities/follow_status_entity.dart';

class FollowDataSourcesImp {
  String defaultApiServer = AppConstants.serverBase;

  Future<FollowStatusEntity> follow(int userId, String token) =>
      _send('POST', userId, token);

  Future<FollowStatusEntity> unfollow(int userId, String token) =>
      _send('DELETE', userId, token);

  Future<FollowStatusEntity> _send(String method, int userId, String token) async {
    try {
      final url = Uri.parse('$defaultApiServer/Seguidores/$userId');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = method == 'POST'
          ? await http.post(url, headers: headers)
          : await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return FollowStatusEntity.fromJson(data);
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
