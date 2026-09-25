import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/errors/api_errors.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/features/gift/domain/entities/gift_entities.dart';

/// Acceso a la API de regalos (catálogo, envío y regalos recibidos).
class GiftRepository {
  final AuthService _auth = AuthService();

  static GiftRepository get instance {
    if (!Get.isRegistered<GiftRepository>()) Get.put(GiftRepository(), permanent: true);
    return Get.find<GiftRepository>();
  }

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken() ??
        (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return jsonDecode(utf8.decode(r.bodyBytes));
    final exception = ApiExceptionCustom(response: r);
    exception.validateMesage();
    throw exception;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      if (e is SocketException || e is http.ClientException || e is TimeoutException) {
        throw Exception(convertMessageException(error: e));
      }
      throw Exception('$e');
    }
  }

  Future<List<GiftEntity>> getCatalog() => _guard(() async {
        final r = await http.get(Uri.parse('${AppConstants.serverBase}/Regalos/catalogo'), headers: await _headers());
        return (_decode(r) as List).map((e) => GiftEntity.fromJson(e)).toList();
      });

  Future<SendGiftResult> send({
    required int toUserId,
    required String code,
    required String origin,
    int? postId,
  }) =>
      _guard(() async {
        final r = await http.post(
          Uri.parse('${AppConstants.serverBase}/Regalos/enviar'),
          headers: await _headers(),
          body: jsonEncode({'toUserId': toUserId, 'codigo': code, 'origen': origin, 'postId': postId}),
        );
        return SendGiftResult.fromJson(_decode(r));
      });

  Future<List<ReceivedGiftEntity>> getReceived(int userId) => _guard(() async {
        final r = await http.get(Uri.parse('${AppConstants.serverBase}/Regalos/recibidos/$userId'),
            headers: await _headers());
        return (_decode(r) as List).map((e) => ReceivedGiftEntity.fromJson(e)).toList();
      });
}
