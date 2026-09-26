import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/controller/theme_controller.dart';
import 'package:tendria/common/services/notification_service.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/tutorial/startTutorial/start_tutorial_controller.dart';
import 'package:tendria/features/auth/presentation/page/home/start_controller.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';

/// Barra superior común de Feed, Descubrir y Chat: logo de Tatendria a la izquierda;
/// a la derecha, acciones propias de la pantalla, notificaciones y Radar.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Acciones que se muestran antes de notificaciones y radar (por ejemplo, la búsqueda del chat).
  final List<Widget> extraActions;

  /// Solo una barra puede llevar la llave del tutorial que señala el botón de Radar (la del Feed).
  final bool attachRadarKey;

  const BrandAppBar({super.key, this.extraActions = const [], this.attachRadarKey = false});

  @override
  Size get preferredSize => const Size.fromHeight(57);

  Widget _logo() {
    if (!Get.isRegistered<ThemeController>()) {
      return Image.asset('assets/logo/logo-wordmark.png', height: 26);
    }
    final ctrl = Get.find<ThemeController>();
    return Obx(() => Image.asset(
          ctrl.themeMode.value == AppThemeMode.light
              ? 'assets/logo/logo-wordmark.png'
              : 'assets/logo/logo-wordmark-dark.png',
          height: 26,
          fit: BoxFit.contain,
        ));
  }

  Widget _bell() {
    final service = NotificationService();
    return Obx(() {
      final unread = service.unreadNotificationsCount.value;
      return Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            tooltip: 'Notificaciones',
            icon: Icon(LucideIcons.bell, size: 21, color: ThemeColor.textPrimary),
            onPressed: () => Get.toNamed(RoutesNames.notificationPage),
          ),
          if (unread > 0)
            Positioned(
              top: 11,
              right: 11,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: ThemeColor.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: FeedStyle.surface, width: 1.5),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _radar() {
    return Obx(() {
      final pending = Get.isRegistered<StartTutorialController>() && Get.find<StartTutorialController>().pending.value;
      return IconButton(
        // El tutorial de inicio señala este botón como "Radar" (solo mientras está pendiente)
        key: attachRadarKey && pending ? Get.find<StartTutorialController>().navRadarKey : null,
        tooltip: 'Radar',
        icon: Icon(LucideIcons.radar, size: 21, color: ThemeColor.textPrimary),
        onPressed: () => Get.find<StartController>().openRadar(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: FeedStyle.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 18,
      title: _logo(),
      actions: [
        ...extraActions,
        _bell(),
        _radar(),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: FeedStyle.hairline),
      ),
    );
  }
}
