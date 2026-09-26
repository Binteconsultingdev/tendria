import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';

/// Pregunta al servidor si un correo todavía se puede usar para registrarse.
/// Si no se puede comprobar (sin red, servidor sin la ruta), devuelve true para no bloquear el registro:
/// el servidor vuelve a validarlo al crear la cuenta.
Future<bool> isEmailAvailable(String email) async {
  try {
    final uri = Uri.parse('${AppConstants.serverBase}/Auth/correo-disponible').replace(queryParameters: {'email': email});
    final r = await http.get(uri).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) return true;
    final data = jsonDecode(utf8.decode(r.bodyBytes));
    return data['disponible'] != false;
  } catch (_) {
    return true;
  }
}
