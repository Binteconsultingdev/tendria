import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/services/auth_service.dart';

class PresenceInfo {
  final bool online;
  final DateTime? lastSeen;
  PresenceInfo({required this.online, this.lastSeen});
}

/// Consulta si una persona tiene la app abierta ahora y cuándo se le vio por última vez.
class PresenceRepository {
  final AuthService _auth = AuthService();

  static PresenceRepository get instance {
    if (!Get.isRegistered<PresenceRepository>()) Get.put(PresenceRepository(), permanent: true);
    return Get.find<PresenceRepository>();
  }

  Future<PresenceInfo> get(int userId) async {
    final token = await _auth.getToken();
    if (token == null) throw Exception('Sin sesión');

    final r = await http.get(
      Uri.parse('${AppConstants.serverBase}/Mensajes/presencia/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (r.statusCode != 200) throw Exception('Presencia no disponible');

    final data = jsonDecode(utf8.decode(r.bodyBytes));
    return PresenceInfo(
      online: data['enLinea'] ?? false,
      lastSeen: parseUtcDate(data['ultimaConexion']),
    );
  }
}

/// El servidor manda fechas en UTC; se convierten a la hora del teléfono.
DateTime? parseUtcDate(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(s);
  return DateTime.tryParse(hasZone ? s : '${s}Z')?.toLocal();
}
