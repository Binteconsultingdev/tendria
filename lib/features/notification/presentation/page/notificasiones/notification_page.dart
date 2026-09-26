import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/chat/data/presence_repository.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/feed/presentation/widget/time_ago.dart';
import 'package:tendria/features/notification/domain/entities/notification_entity.dart';
import 'package:tendria/features/notification/presentation/page/notification_controller.dart';
import 'package:tendria/features/notification/presentation/widget/notification_modal_loading.dart';

/// Notificaciones: lista limpia agrupada por día, con icono suave por tipo y punto en las no leídas.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationController controller = Get.find<NotificationController>();
  LanguageController get _l => Get.find<LanguageController>();

  @override
  void dispose() {
    // Al salir se marcan como leídas en el servidor
    if (controller.notifications.any((n) => !n.read)) controller.markAllAsRead();
    super.dispose();
  }

  DateTime? _date(NotificationEntity n) => parseUtcDate(n.createdAt);

  String _groupLabel(DateTime? d) {
    if (d == null) return _l.t('notif_earlier');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return _l.t('notif_today');
    if (diff == 1) return _l.t('notif_yesterday');
    if (diff < 7) return _l.t('notif_this_week');
    return _l.t('notif_earlier');
  }

  ({IconData icon, Color color}) _style(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return (icon: LucideIcons.heart, color: const Color(0xFFEC4899));
      case 'reaccion':
        return (icon: LucideIcons.smilePlus, color: const Color(0xFFF59E0B));
      case 'match':
        return (icon: LucideIcons.sparkles, color: const Color(0xFF8B5CF6));
      case 'mensaje':
        return (icon: LucideIcons.messageCircle, color: const Color(0xFF3B82F6));
      case 'comentario':
        return (icon: LucideIcons.messageSquare, color: const Color(0xFF14B8A6));
      case 'regalo':
        return (icon: LucideIcons.gift, color: const Color(0xFFD4A017));
      case 'follow':
        return (icon: LucideIcons.userPlus, color: const Color(0xFF22C55E));
      case 'plan':
        return (icon: LucideIcons.calendarDays, color: const Color(0xFFF97316));
      case 'comunidad':
        return (icon: LucideIcons.users, color: const Color(0xFF6366F1));
      default:
        return (icon: LucideIcons.bell, color: ThemeColor.primaryColor);
    }
  }

  int? _int(dynamic v) => v is int ? v : int.tryParse('${v ?? ''}');

  /// Lleva a la pantalla relacionada con la notificación.
  void _open(NotificationEntity n) {
    controller.markAsRead(n.notificationId);
    final m = n.metadata;

    final planId = _int(m['PlanId']);
    final communityId = _int(m['ComunidadId']);
    final chatId = _int(m['ChatId']);
    final senderId = _int(m['SenderId']);

    switch (n.type.toLowerCase()) {
      case 'plan':
        if (planId != null) {
          Get.toNamed(RoutesNames.planDetailPage, arguments: {'planId': planId});
          return;
        }
        break;
      case 'comunidad':
        if (communityId != null) {
          Get.toNamed(RoutesNames.communityDetailPage, arguments: {'communityId': communityId});
          return;
        }
        break;
      case 'mensaje':
        if (chatId != null) {
          Get.toNamed(RoutesNames.chatPage, arguments: {'chatId': chatId, 'goHomeIndex': 3});
          return;
        }
        break;
    }
    if (senderId != null && senderId > 0) {
      Get.toNamed(RoutesNames.userProfileDetailPage, arguments: {'userId': senderId});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.backgroundColorfondo,
      appBar: AppBar(
        backgroundColor: FeedStyle.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: ThemeColor.textPrimary), onPressed: Get.back),
        title: Text(_l.t('notif_title'),
            style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w600, color: ThemeColor.textPrimary)),
        actions: [
          Obx(() => controller.notifications.any((n) => !n.read)
              ? IconButton(
                  tooltip: _l.t('notif_mark_all'),
                  icon: Icon(LucideIcons.checkCheck, size: 21, color: ThemeColor.primaryColor),
                  onPressed: controller.markAllAsRead,
                )
              : const SizedBox.shrink()),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: FeedStyle.hairline)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: NotificatioLoading());

        if (controller.error.value.isNotEmpty || controller.notifications.isEmpty) return _empty();

        // Filas: encabezado de día + notificaciones
        final rows = <Object>[];
        String? current;
        for (final n in controller.notifications) {
          final label = _groupLabel(_date(n));
          if (label != current) {
            rows.add(label);
            current = label;
          }
          rows.add(n);
        }

        return RefreshIndicator(
          onRefresh: controller.fetchNotifications,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 30),
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final row = rows[i];
              if (row is String) return _header(row);
              return _item(row as NotificationEntity);
            },
          ),
        );
      }),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.rubik(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: ThemeColor.textSecondary),
        ),
      );

  Widget _item(NotificationEntity n) {
    final style = _style(n.type);
    final date = _date(n);
    final unread = !n.read;
    final hasImage = n.imageUrl != null && n.imageUrl!.isNotEmpty;

    return InkWell(
      onTap: () => _open(n),
      child: Container(
        color: unread ? ThemeColor.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: style.color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(style.icon, size: 19, color: style.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title.isNotEmpty ? n.title : n.type,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.rubik(
                            fontSize: 14.5,
                            fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                            color: ThemeColor.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (date != null) Text(timeAgo(date), style: FeedStyle.meta.copyWith(fontSize: 11.5)),
                    ],
                  ),
                  if (n.message.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      n.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rubik(fontSize: 13, height: 1.35, color: ThemeColor.textSecondary),
                    ),
                  ],
                  if (hasImage) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        n.imageUrl!.replaceAll(' ', '%20'),
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (unread)
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: ThemeColor.primaryColor, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: ThemeColor.primaryColor.withValues(alpha: 0.10), shape: BoxShape.circle),
              child: Icon(LucideIcons.bellOff, size: 30, color: ThemeColor.primaryColor),
            ),
            const SizedBox(height: 18),
            Text(_l.t('notif_empty_title'), style: FeedStyle.name.copyWith(fontSize: 16)),
            const SizedBox(height: 6),
            Text(_l.t('notif_empty_sub'), textAlign: TextAlign.center, style: FeedStyle.meta.copyWith(fontSize: 13.5)),
          ],
        ),
      );
}
