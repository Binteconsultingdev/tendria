import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/services/auth_service.dart';

/// Reacciones y respuestas a historias de otras personas.
class StoryInteractionRepository {
  final AuthService _auth = AuthService();

  static StoryInteractionRepository get instance {
    if (!Get.isRegistered<StoryInteractionRepository>()) Get.put(StoryInteractionRepository(), permanent: true);
    return Get.find<StoryInteractionRepository>();
  }

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    if (token == null) throw Exception('Sin sesión');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  String _message(http.Response r) {
    try {
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      if (data is Map && data['message'] != null) return data['message'].toString();
    } catch (_) {}
    return 'No se pudo completar la acción';
  }

  Future<void> react(int storyId, String type) async {
    final r = await http.put(
      Uri.parse('${AppConstants.serverBase}/Historias/$storyId/reaccion'),
      headers: await _headers(),
      body: jsonEncode({'tipo': type}),
    );
    if (r.statusCode != 200) throw Exception(_message(r));
  }

  Future<void> removeReaction(int storyId) async {
    final r = await http.delete(
      Uri.parse('${AppConstants.serverBase}/Historias/$storyId/reaccion'),
      headers: await _headers(),
    );
    if (r.statusCode != 204 && r.statusCode != 200) throw Exception(_message(r));
  }

  Future<void> reply(int storyId, String text) async {
    final r = await http.post(
      Uri.parse('${AppConstants.serverBase}/Historias/$storyId/responder'),
      headers: await _headers(),
      body: jsonEncode({'texto': text}),
    );
    if (r.statusCode != 200) throw Exception(_message(r));
  }
}
