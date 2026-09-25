import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/errors/api_errors.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';

class PlanPageResult {
  final List<PlanEntity> items;
  final bool hasNext;
  PlanPageResult(this.items, this.hasNext);
}

/// Acceso a la API de planes.
class PlansRepository {
  final AuthService _auth = AuthService();

  static PlansRepository get instance {
    if (!Get.isRegistered<PlansRepository>()) Get.put(PlansRepository(), permanent: true);
    return Get.find<PlansRepository>();
  }

  String get _base => AppConstants.serverBase;

  Future<String> _token() async =>
      await _auth.getToken() ?? (throw Exception('No hay sesión activa. El usuario debe iniciar sesión.'));

  Future<Map<String, String>> _headers() async =>
      {'Content-Type': 'application/json', 'Authorization': 'Bearer ${await _token()}'};

  dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(r.bodyBytes));
    }
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

  Future<PlanPageResult> discover({String? category, int page = 1, int pageSize = 10}) => _guard(() async {
        final query = 'pageNumber=$page&pageSize=$pageSize${category != null ? '&categoria=$category' : ''}';
        final r = await http.get(Uri.parse('$_base/Planes/descubrir?$query'), headers: await _headers());
        final data = _decode(r);
        return PlanPageResult(
          (data['items'] as List).map((e) => PlanEntity.fromJson(e)).toList(),
          data['hasNextPage'] ?? false,
        );
      });

  Future<List<PlanEntity>> myPlans({bool past = false}) => _guard(() async {
        final r = await http.get(Uri.parse('$_base/Planes/mis-planes?pasados=$past'), headers: await _headers());
        return (_decode(r) as List).map((e) => PlanEntity.fromJson(e)).toList();
      });

  Future<PlanEntity> get(int id) => _guard(() async {
        final r = await http.get(Uri.parse('$_base/Planes/$id'), headers: await _headers());
        return PlanEntity.fromJson(_decode(r));
      });

  Future<PlanEntity> create({
    required String title,
    String? description,
    required String category,
    required DateTime startsAt,
    required String placeName,
    double? lat,
    double? lng,
    String? city,
    int? capacity,
    required String privacy,
    File? image,
  }) =>
      _guard(() async {
        final request = http.MultipartRequest('POST', Uri.parse('$_base/Planes'));
        request.headers['Authorization'] = 'Bearer ${await _token()}';
        request.fields['titulo'] = title;
        if (description != null && description.trim().isNotEmpty) request.fields['descripcion'] = description.trim();
        request.fields['categoria'] = category;
        request.fields['fechaInicio'] = startsAt.toUtc().toIso8601String();
        request.fields['ubicacionNombre'] = placeName;
        if (lat != null) request.fields['lat'] = lat.toString();
        if (lng != null) request.fields['lng'] = lng.toString();
        if (city != null && city.isNotEmpty) request.fields['ciudad'] = city;
        if (capacity != null) request.fields['cupo'] = capacity.toString();
        request.fields['privacidad'] = privacy;
        if (image != null) request.files.add(await http.MultipartFile.fromPath('imagen', image.path));

        final streamed = await request.send().timeout(const Duration(minutes: 2));
        return PlanEntity.fromJson(_decode(await http.Response.fromStream(streamed)));
      });

  Future<PlanEntity> join(int id) => _guard(() async {
        final r = await http.post(Uri.parse('$_base/Planes/$id/unirse'), headers: await _headers());
        return PlanEntity.fromJson(_decode(r));
      });

  Future<PlanEntity> leave(int id) => _guard(() async {
        final r = await http.delete(Uri.parse('$_base/Planes/$id/salir'), headers: await _headers());
        return PlanEntity.fromJson(_decode(r));
      });

  Future<PlanEntity> respond(int planId, int userId, {required bool accept}) => _guard(() async {
        final r = await http.put(Uri.parse('$_base/Planes/$planId/solicitudes/$userId'),
            headers: await _headers(), body: jsonEncode({'aceptar': accept}));
        return PlanEntity.fromJson(_decode(r));
      });

  Future<void> cancel(int id) => _guard(() async {
        final r = await http.delete(Uri.parse('$_base/Planes/$id'), headers: await _headers());
        _decode(r);
      });

  Future<void> report(int id, {String? reason}) => _guard(() async {
        final r = await http.post(Uri.parse('$_base/Planes/$id/reportar'),
            headers: await _headers(), body: jsonEncode({'motivo': reason}));
        _decode(r);
      });
}
