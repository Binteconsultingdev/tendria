import 'package:get/get.dart';
import 'package:tendria/common/settings/language_controller.dart';

/// Formatos de fecha y hora para planes (sin depender de paquetes de internacionalización).
class PlanFormat {
  static LanguageController get _l => Get.find<LanguageController>();

  static List<String> get _months => _l.t('plan_months').split(',');
  static List<String> get _weekdays => _l.t('plan_weekdays').split(',');

  static String monthShort(DateTime d) => _months[d.month - 1];

  static String weekday(DateTime d) => _weekdays[d.weekday - 1];

  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Ej.: "sáb 12 oct · 20:30"
  static String full(DateTime d) => '${weekday(d)} ${d.day} ${monthShort(d)} · ${time(d)}';

  static String distance(double km) => km < 1 ? '<1 km' : '${km.round()} km';
}
