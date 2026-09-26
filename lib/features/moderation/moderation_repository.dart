import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/services/auth_service.dart';

class ReportItem {
  final int reportId;
  final String type; // post | comentario | plan | comunidad
  final int objectId;
  final int authorId;
  final String? reason;
  final String? description;
  final DateTime createdAt;
  final String? text;
  final List<String> mediaUrls;
  final bool hidden;
  final int totalReports;

  ReportItem({
    required this.reportId,
    required this.type,
    required this.objectId,
    required this.authorId,
    required this.reason,
    required this.description,
    required this.createdAt,
    required this.text,
    required this.mediaUrls,
    required this.hidden,
    required this.totalReports,
  });

  factory ReportItem.fromJson(Map<String, dynamic> j) => ReportItem(
        reportId: j['reporteId'],
        type: j['tipoObjeto'] ?? '',
        objectId: j['objetoId'] ?? 0,
        authorId: j['autorId'] ?? 0,
        reason: j['motivo'],
        description: j['descripcion'],
        createdAt: DateTime.tryParse('${j['creadoEn']}Z')?.toLocal() ?? DateTime.now(),
        text: j['textoContenido'],
        mediaUrls: (j['mediaUrls'] as List? ?? const []).map((e) => e.toString()).toList(),
        hidden: j['contenidoOculto'] ?? false,
        totalReports: j['totalReportesPendientes'] ?? 1,
      );
}

class ReportsPage {
  final List<ReportItem> items;
  final int? nextCursor;
  ReportsPage(this.items, this.nextCursor);
}

/// Cola de moderación: solo funciona para las cuentas listadas como administradoras en el API.
class ModerationRepository {
  final AuthService _auth = AuthService();

  static ModerationRepository get instance {
    if (!Get.isRegistered<ModerationRepository>()) Get.put(ModerationRepository(), permanent: true);
    return Get.find<ModerationRepository>();
  }

  String get _base => AppConstants.serverBase;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    if (token == null) throw Exception('Sin sesión');
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<bool>? _adminCheck;

  /// ¿Esta cuenta es administradora? Se consulta una vez por sesión de la app.
  Future<bool> isAdmin() => _adminCheck ??= _fetchIsAdmin();

  Future<bool> _fetchIsAdmin() async {
    try {
      final r = await http.get(Uri.parse('$_base/Moderacion/soy-admin'), headers: await _headers());
      return r.statusCode == 200;
    } catch (_) {
      _adminCheck = null; // reintenta en la próxima consulta
      return false;
    }
  }

  Future<ReportsPage> pending({int? cursor, int pageSize = 20}) async {
    final query = {'pageSize': '$pageSize', if (cursor != null) 'cursor': '$cursor'};
    final r = await http.get(Uri.parse('$_base/Moderacion/pendientes').replace(queryParameters: query), headers: await _headers());
    if (r.statusCode != 200) throw Exception('No se pudo cargar la cola de moderación');

    final data = jsonDecode(utf8.decode(r.bodyBytes));
    return ReportsPage(
      (data['items'] as List).map((e) => ReportItem.fromJson(e)).toList(),
      data['nextCursor'],
    );
  }

  /// accion: "ocultar" (retira el contenido) o "descartar" (el reporte no procede).
  Future<void> resolve(int reportId, String action) async {
    final r = await http.put(
      Uri.parse('$_base/Moderacion/$reportId/resolver'),
      headers: await _headers(),
      body: jsonEncode({'accion': action}),
    );
    if (r.statusCode != 200) throw Exception('No se pudo resolver el reporte');
  }
}
