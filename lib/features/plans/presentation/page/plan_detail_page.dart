import 'package:tendria/features/feed/presentation/controller/feed_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper_getx.dart';
import 'package:tendria/features/feed/domain/entities/feed_entities.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/plans/data/plans_repository.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';
import 'package:tendria/features/plans/presentation/controller/plans_controller.dart';
import 'package:tendria/features/plans/presentation/widget/plan_format.dart';
import 'package:url_launcher/url_launcher.dart';

class PlanDetailPage extends StatefulWidget {
  const PlanDetailPage({super.key});

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  final PlansRepository _repo = PlansRepository.instance;
  final LanguageController _l = Get.find<LanguageController>();

  final Rxn<PlanEntity> _plan = Rxn<PlanEntity>();
  final RxBool _loading = true.obs;
  final RxBool _busy = false.obs;
  String? _error;
  late final int _planId;

  @override
  void initState() {
    super.initState();
    _planId = (Get.arguments as Map<String, dynamic>?)?['planId'] ?? 0;
    _load();
  }

  Future<void> _load() async {
    try {
      _loading.value = true;
      _error = null;
      _plan.value = await _repo.get(_planId);
    } catch (e) {
      _error = cleanExceptionMessage(e);
    } finally {
      _loading.value = false;
    }
  }

  void _sync(PlanEntity plan) {
    _plan.value = plan;
    if (Get.isRegistered<PlansController>()) {
      Get.find<PlansController>()
        ..upsert(plan)
        ..refreshMine();
    }
    if (Get.isRegistered<FeedController>()) Get.find<FeedController>().upsertPlan(plan);
  }

  Future<void> _run(Future<PlanEntity> Function() action) async {
    if (_busy.value) return;
    try {
      _busy.value = true;
      _sync(await action());
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      _busy.value = false;
    }
  }

  Future<void> _cancelPlan(PlanEntity plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l.t('plan_cancel_confirm')),
        content: Text(_l.t('plan_cancel_hint')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_l.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_l.t('plan_cancel_action'), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      _busy.value = true;
      await _repo.cancel(plan.id);
      if (Get.isRegistered<PlansController>()) {
        Get.find<PlansController>()
          ..remove(plan.id)
          ..refreshMine();
      }
      if (Get.isRegistered<FeedController>()) Get.find<FeedController>().removePlan(plan.id);
      Get.back();
    } catch (e) {
      showErrorSnackbarGetx(cleanExceptionMessage(e));
    } finally {
      _busy.value = false;
    }
  }

  Future<void> _openMap(PlanEntity plan) async {
    final query = plan.lat != null && plan.lng != null
        ? '${plan.lat},${plan.lng}'
        : Uri.encodeComponent('${plan.placeName} ${plan.city ?? ''}');
    await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.backgroundColorfondo,
      body: Obx(() {
        if (_loading.value && _plan.value == null) return const Center(child: CircularProgressIndicator());
        final plan = _plan.value;
        if (plan == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? '', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: Text(_l.t('feed_retry'))),
                ],
              ),
            ),
          );
        }
        return _content(plan);
      }),
    );
  }

  Widget _content(PlanEntity plan) {
    final cat = PlanCategory.of(plan.category);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 270,
              pinned: true,
              backgroundColor: FeedStyle.surface,
              surfaceTintColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: _roundButton(LucideIcons.arrowLeft, Get.back),
              actions: [
                if (!plan.isMine)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _roundButton(LucideIcons.flag, () async {
                      try {
                        await _repo.report(plan.id);
                        showSuccessSnackbarGetx(_l.t('feed_reported'));
                      } catch (e) {
                        showErrorSnackbarGetx(cleanExceptionMessage(e));
                      }
                    }),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    plan.imageUrl != null && plan.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(imageUrl: plan.imageUrl!, fit: BoxFit.cover)
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cat.colors),
                            ),
                            child: Center(child: Icon(cat.icon, size: 90, color: Colors.white.withValues(alpha: 0.85))),
                          ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent, Colors.black.withValues(alpha: 0.2)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: cat.colors.first.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 15, color: cat.colors.last),
                          const SizedBox(width: 6),
                          Text(_l.t('plan_cat_${cat.code}'),
                              style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w600, color: cat.colors.last)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(plan.title, style: GoogleFonts.rubik(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2, color: ThemeColor.textPrimary)),
                    const SizedBox(height: 18),
                    _organizer(plan),
                    const SizedBox(height: 18),
                    _infoTile(LucideIcons.calendarDays, PlanFormat.full(plan.startsAt),
                        sub: plan.requiresApproval ? _l.t('plan_needs_approval') : _l.t('plan_open')),
                    const SizedBox(height: 10),
                    _infoTile(
                      LucideIcons.mapPin,
                      plan.placeName,
                      sub: [if (plan.city != null) plan.city!, if (plan.distanceKm != null) PlanFormat.distance(plan.distanceKm!)].join(' · '),
                      onTap: () => _openMap(plan),
                      trailing: LucideIcons.navigation,
                    ),
                    if (plan.description != null && plan.description!.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text(plan.description!, style: FeedStyle.body.copyWith(fontSize: 15.5, height: 1.55)),
                    ],
                    const SizedBox(height: 26),
                    _participants(plan),
                    if (plan.isMine && plan.pending.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _requests(plan),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _actionBar(plan)),
      ],
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      );

  Widget _organizer(PlanEntity plan) => GestureDetector(
        onTap: plan.isMine ? null : () => Get.toNamed(RoutesNames.userProfileDetailPage, arguments: {'userId': plan.creator.id}),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            UserAvatar(url: plan.creator.photoUrl, radius: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_l.t('plan_organizer'), style: FeedStyle.meta),
                Text(plan.creator.name, style: FeedStyle.name.copyWith(fontSize: 16)),
              ],
            ),
          ],
        ),
      );

  Widget _infoTile(IconData icon, String title, {String? sub, VoidCallback? onTap, IconData? trailing}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: FeedStyle.surface, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: ThemeColor.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, size: 20, color: ThemeColor.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: FeedStyle.name.copyWith(fontSize: 15)),
                    if (sub != null && sub.isNotEmpty) Text(sub, style: FeedStyle.meta),
                  ],
                ),
              ),
              if (trailing != null) Icon(trailing, size: 18, color: ThemeColor.primaryColor),
            ],
          ),
        ),
      );

  Widget _participants(PlanEntity plan) {
    final count = plan.capacity != null ? '${plan.confirmed}/${plan.capacity}' : '${plan.confirmed}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_l.t('plan_going_title')} · $count', style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            for (final p in plan.participants)
              GestureDetector(
                onTap: () => p.id == plan.creator.id && plan.isMine
                    ? null
                    : Get.toNamed(RoutesNames.userProfileDetailPage, arguments: {'userId': p.id}),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      UserAvatar(url: p.photoUrl, radius: 26),
                      const SizedBox(height: 5),
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.meta.copyWith(fontSize: 11.5)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _requests(PlanEntity plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_l.t('plan_requests')} · ${plan.pending.length}',
            style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
        const SizedBox(height: 10),
        for (final AuthorEntity p in plan.pending)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: FeedStyle.surface, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                UserAvatar(url: p.photoUrl, radius: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(p.name, style: FeedStyle.name)),
                IconButton(
                  onPressed: () => _run(() => _repo.respond(plan.id, p.id, accept: false)),
                  icon: const Icon(LucideIcons.x, color: Colors.redAccent),
                ),
                IconButton(
                  onPressed: () => _run(() => _repo.respond(plan.id, p.id, accept: true)),
                  icon: const Icon(LucideIcons.check, color: Color(0xFF1F9D57)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _actionBar(PlanEntity plan) {
    Widget button(String label, VoidCallback? onTap, {bool outlined = false, Color? color}) {
      final enabled = onTap != null && !_busy.value;
      return GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: !outlined && enabled ? ThemeColor.primaryGradient : null,
            color: outlined ? Colors.transparent : (enabled ? null : FeedStyle.hairline),
            border: outlined ? Border.all(color: color ?? ThemeColor.primaryColor, width: 1.6) : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: _busy.value
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
              : Text(label,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: outlined ? (color ?? ThemeColor.primaryColor) : (enabled ? Colors.white : ThemeColor.textSecondary),
                  )),
        ),
      );
    }

    Widget child;
    if (plan.cancelled) {
      child = button(_l.t('plan_cancelled'), null);
    } else if (plan.isPast) {
      child = button(_l.t('plan_finished'), null);
    } else if (plan.isMine) {
      child = button(_l.t('plan_cancel_action'), () => _cancelPlan(plan), outlined: true, color: Colors.redAccent);
    } else if (plan.joined) {
      child = button(_l.t('plan_leave'), () => _run(() => _repo.leave(plan.id)), outlined: true);
    } else if (plan.requested) {
      child = button(_l.t('plan_cancel_request'), () => _run(() => _repo.leave(plan.id)), outlined: true);
    } else if (plan.myState == 'rechazado') {
      child = button(_l.t('plan_rejected'), null);
    } else if (plan.isFull && !plan.requiresApproval) {
      child = button(_l.t('plan_full'), null);
    } else {
      child = button(plan.requiresApproval ? _l.t('plan_request') : _l.t('plan_join'), () => _run(() => _repo.join(plan.id)));
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: FeedStyle.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: child,
    );
  }
}
