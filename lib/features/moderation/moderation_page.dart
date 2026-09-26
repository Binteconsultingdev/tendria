import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/feed/presentation/widget/time_ago.dart';
import 'package:tendria/features/moderation/moderation_repository.dart';

/// Cola de reportes pendientes para administradores: se oculta el contenido o se descarta el reporte.
class ModerationPage extends StatefulWidget {
  const ModerationPage({super.key});

  @override
  State<ModerationPage> createState() => _ModerationPageState();
}

class _ModerationPageState extends State<ModerationPage> {
  final LanguageController _l = Get.find<LanguageController>();
  final ModerationRepository _repo = ModerationRepository.instance;
  final ScrollController _scroll = ScrollController();

  final RxList<ReportItem> _items = <ReportItem>[].obs;
  final RxBool _loading = true.obs;
  final RxBool _loadingMore = false.obs;
  final RxnString _error = RxnString();
  int? _nextCursor;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) _loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _loading.value = true;
      _error.value = null;
      final page = await _repo.pending();
      _items.assignAll(page.items);
      _nextCursor = page.nextCursor;
    } catch (e) {
      _error.value = cleanExceptionMessage(e);
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _loadMore() async {
    if (_nextCursor == null || _loadingMore.value || _loading.value) return;
    try {
      _loadingMore.value = true;
      final page = await _repo.pending(cursor: _nextCursor);
      _items.addAll(page.items);
      _nextCursor = page.nextCursor;
    } catch (_) {
    } finally {
      _loadingMore.value = false;
    }
  }

  Future<void> _resolve(ReportItem item, String action) async {
    try {
      await _repo.resolve(item.reportId, action);
      _items.removeWhere((i) => i.reportId == item.reportId);
      showSuccessSnackbarGetx(_l.t(action == 'ocultar' ? 'mod_hidden' : 'mod_dismissed'));
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    }
  }

  IconData _icon(String type) => switch (type) {
        'post' => LucideIcons.image,
        'comentario' => LucideIcons.messageCircle,
        'plan' => LucideIcons.calendarDays,
        'comunidad' => LucideIcons.users,
        _ => LucideIcons.flag,
      };

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
        title: Text(_l.t('mod_title'), style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w600, color: ThemeColor.textPrimary)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Divider(height: 1, color: FeedStyle.hairline)),
      ),
      body: Obx(() {
        if (_loading.value) return const Center(child: CircularProgressIndicator());

        if (_error.value != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error.value!, style: FeedStyle.meta),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: Text(_l.t('feed_retry'))),
              ],
            ),
          );
        }

        if (_items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.shieldCheck, size: 44, color: ThemeColor.primaryColor),
                const SizedBox(height: 12),
                Text(_l.t('mod_empty'), style: FeedStyle.name),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
            itemCount: _items.length + (_loadingMore.value ? 1 : 0),
            itemBuilder: (_, i) => i >= _items.length
                ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : _card(_items[i]),
          ),
        );
      }),
    );
  }

  Widget _card(ReportItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FeedStyle.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FeedStyle.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(item.type), size: 16, color: ThemeColor.primaryColor),
              const SizedBox(width: 6),
              Text(_l.t('mod_type_${item.type}'), style: FeedStyle.name.copyWith(fontSize: 13.5)),
              const Spacer(),
              if (item.totalReports > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Text('${item.totalReports} ${_l.t('mod_reports')}',
                      style: GoogleFonts.rubik(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                ),
              if (item.hidden) ...[
                const SizedBox(width: 6),
                Icon(LucideIcons.eyeOff, size: 15, color: ThemeColor.textSecondary),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text('${timeAgo(item.createdAt)} · ${_l.t('mod_author')} #${item.authorId}', style: FeedStyle.meta),
          if (item.reason != null && item.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${_l.t('mod_reason')}: ${item.reason}', style: FeedStyle.meta.copyWith(color: ThemeColor.textPrimary)),
          ],
          if (item.description != null && item.description!.isNotEmpty) Text(item.description!, style: FeedStyle.meta),
          if (item.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.mediaUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: item.mediaUrls[i].replaceAll(' ', '%20'),
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    memCacheWidth: 330,
                    errorWidget: (_, __, ___) => Container(
                      width: 110,
                      color: FeedStyle.hairline,
                      child: Icon(LucideIcons.video, color: ThemeColor.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (item.text != null && item.text!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: ThemeColor.backgroundColorfondo, borderRadius: BorderRadius.circular(12)),
              child: Text(item.text!, maxLines: 6, overflow: TextOverflow.ellipsis, style: FeedStyle.body.copyWith(fontSize: 14)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _resolve(item, 'descartar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ThemeColor.textPrimary,
                    side: BorderSide(color: FeedStyle.hairline),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_l.t('mod_dismiss')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _resolve(item, 'ocultar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_l.t('mod_hide')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
