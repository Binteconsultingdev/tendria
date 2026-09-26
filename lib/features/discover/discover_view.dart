import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/communities/domain/entities/community_entities.dart';
import 'package:tendria/features/discover/discover_filters.dart';
import 'package:tendria/features/discover/discover_repository.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';

/// Descubrir: perfiles, planes y comunidades destacados en carruseles horizontales.
class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> with AutomaticKeepAliveClientMixin {
  final LanguageController _l = Get.find<LanguageController>();

  DiscoverData? _data;
  String? _error;
  bool _loading = true;
  bool _refreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    DiscoverState.instance.filters.addListener(_onFiltersChanged);
    DiscoverState.instance.ensureLoaded().then((_) => _load());
  }

  @override
  void dispose() {
    DiscoverState.instance.filters.removeListener(_onFiltersChanged);
    super.dispose();
  }

  void _onFiltersChanged() => _load();

  Future<void> _load() async {
    try {
      if (mounted) setState(() => _data == null ? _loading = true : _refreshing = true);
      final data = await DiscoverRepository.instance.load(DiscoverState.instance.filters.value);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = cleanExceptionMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading && _data == null) return const Center(child: CircularProgressIndicator());

    if (_data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? '', style: FeedStyle.meta),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text(_l.t('feed_retry'))),
          ],
        ),
      );
    }

    final data = _data!;
    final filters = DiscoverState.instance.filters.value;

    final city = (data.city ?? '').trim();
    final country = (data.country ?? '').trim();

    return Column(
      children: [
        if (_refreshing) LinearProgressIndicator(minHeight: 2, color: ThemeColor.primaryColor, backgroundColor: FeedStyle.hairline),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                if (filters.isActive) _activeFiltersBar(filters),
                if (data.noProfiles && filters.isActive)
                  _noResults()
                else ...[
                  _profileSection(_l.t('discover_compatible'), LucideIcons.heartHandshake, data.compatible, showCompatibility: true),
                  _profileSection(_l.t('discover_nearby'), LucideIcons.mapPin, data.nearby),
                  if (city.isNotEmpty) _profileSection('${_l.t('discover_in')} $city', LucideIcons.building2, data.inCity),
                  if (country.isNotEmpty) _profileSection('${_l.t('discover_in')} $country', LucideIcons.globe, data.inCountry),
                  _profileSection(_l.t('discover_profiles'), LucideIcons.sparkles, data.featured),
                ],
                if (data.plans.isNotEmpty) ...[
                  _sectionTitle(_l.t('discover_plans'), LucideIcons.calendarDays, onSeeAll: () => Get.toNamed(RoutesNames.plansPage)),
                  SizedBox(
                    height: 168,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: data.plans.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _planCard(data.plans[i]),
                    ),
                  ),
                ],
                if (data.communities.isNotEmpty) ...[
                  _sectionTitle(_l.t('discover_communities'), LucideIcons.users),
                  SizedBox(
                    height: 178,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: data.communities.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _communityCard(data.communities[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileSection(String title, IconData icon, List<FeaturedProfile> profiles, {bool showCompatibility = false}) {
    if (profiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title, icon),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _profileCard(profiles[i], showCompatibility: showCompatibility),
          ),
        ),
      ],
    );
  }

  /// Resumen de los filtros aplicados, con acceso rápido para quitarlos.
  Widget _activeFiltersBar(DiscoverFilters f) {
    final parts = <String>[
      if (f.ageMin > DiscoverFilters.ageFloor || f.ageMax < DiscoverFilters.ageCeil)
        '${f.ageMin}–${f.ageMax >= DiscoverFilters.ageCeil ? '${DiscoverFilters.ageCeil}+' : f.ageMax}',
      if (f.distanceKm != null) '${f.distanceKm!.round()} km',
      if (f.gender != null) _l.t(f.gender == 'Mujer' ? 'filters_women' : f.gender == 'Hombre' ? 'filters_men' : 'filters_nonbinary'),
      if (f.onlyVerified) _l.t('filters_verified'),
      if (f.onlyOnline) _l.t('filters_online'),
      if (f.interests.isNotEmpty) '${f.interests.length} ${_l.t('filters_interests').toLowerCase()}',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
      child: Row(
        children: [
          Icon(LucideIcons.slidersHorizontal, size: 14, color: ThemeColor.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(parts.join(' · '),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: FeedStyle.meta.copyWith(fontSize: 12.5, color: ThemeColor.textPrimary)),
          ),
          GestureDetector(
            onTap: () => DiscoverState.instance.update(const DiscoverFilters()),
            child: Text(_l.t('filters_clear'), style: GoogleFonts.rubik(fontSize: 12.5, fontWeight: FontWeight.w600, color: ThemeColor.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _noResults() => Padding(
        padding: const EdgeInsets.fromLTRB(30, 60, 30, 30),
        child: Column(
          children: [
            Icon(LucideIcons.searchX, size: 40, color: ThemeColor.textSecondary),
            const SizedBox(height: 14),
            Text(_l.t('discover_no_results'), textAlign: TextAlign.center, style: FeedStyle.name.copyWith(fontSize: 15.5)),
            const SizedBox(height: 6),
            Text(_l.t('discover_no_results_hint'), textAlign: TextAlign.center, style: FeedStyle.meta.copyWith(fontSize: 13)),
          ],
        ),
      );

  String _distanceLabel(double km) => km < 1 ? '${(km * 1000).round().clamp(50, 999)} m' : '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';

  Widget _sectionTitle(String text, IconData icon, {VoidCallback? onSeeAll}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ThemeColor.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: GoogleFonts.rubik(fontSize: 17, fontWeight: FontWeight.w600, color: ThemeColor.textPrimary)),
            ),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Text(_l.t('discover_see_all'),
                    style: GoogleFonts.rubik(fontSize: 13, fontWeight: FontWeight.w500, color: ThemeColor.primaryColor)),
              ),
          ],
        ),
      );

  Widget _image(String? url, {required List<Color> fallback}) {
    if (url == null || url.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: fallback)),
      );
    }
    return CachedNetworkImage(
      imageUrl: url.replaceAll(' ', '%20'),
      fit: BoxFit.cover,
      memCacheWidth: 500,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => ColoredBox(color: FeedStyle.hairline),
      errorWidget: (_, __, ___) => DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(colors: fallback)),
      ),
    );
  }

  /// Degradado oscuro en la parte baja para que el texto blanco se lea sobre cualquier foto.
  Widget _shade() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.transparent, Color(0xCC000000)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      );

  Widget _pill({required IconData icon, required String text, Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: (color ?? Colors.black).withValues(alpha: color == null ? 0.38 : 0.92), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11.5, color: Colors.white),
            const SizedBox(width: 4),
            Text(text, style: GoogleFonts.rubik(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      );

  Widget _profileCard(FeaturedProfile p, {bool showCompatibility = false}) {
    return GestureDetector(
      onTap: () => Get.toNamed(RoutesNames.userProfileDetailPage, arguments: {'userId': p.id}),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _image(p.photoUrl, fallback: [ThemeColor.primaryColor, ThemeColor.primaryColor.withValues(alpha: 0.6)]),
              _shade(),
              Positioned(
                top: 10,
                left: 10,
                child: showCompatibility && p.compatibility != null
                    ? _pill(icon: LucideIcons.heart, text: '${p.compatibility}%', color: ThemeColor.primaryColor)
                    : (p.distanceKm != null ? _pill(icon: LucideIcons.mapPin, text: _distanceLabel(p.distanceKm!)) : const SizedBox.shrink()),
              ),
              if (p.verified)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.badgeCheck, size: 15, color: Colors.white),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.age > 0 ? '${p.name.split(' ').first}, ${p.age}' : p.name.split(' ').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                        if (p.online) ...[
                          const SizedBox(width: 6),
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                        ],
                      ],
                    ),
                    Text(
                      showCompatibility && p.commonInterests > 0
                          ? '${p.commonInterests} ${_l.t('discover_in_common')}'
                          : (p.city != null && p.city!.isNotEmpty ? p.city! : (p.country ?? '')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rubik(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime d) {
    final local = d.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'pm' : 'am';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} · $hour:$minute $ampm';
  }

  Widget _planCard(PlanEntity plan) {
    final cat = PlanCategory.of(plan.category);
    return GestureDetector(
      onTap: () => Get.toNamed(RoutesNames.planDetailPage, arguments: {'planId': plan.id}),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _image(plan.imageUrl, fallback: cat.colors),
              _shade(),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(_l.t('plan_cat_${cat.code}'),
                          style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rubik(fontSize: 15.5, height: 1.2, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 12, color: Colors.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 4),
                        Text(_dateLabel(plan.startsAt),
                            style: GoogleFonts.rubik(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9))),
                        const Spacer(),
                        Icon(LucideIcons.users, size: 12, color: Colors.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 4),
                        Text('${plan.confirmed}', style: GoogleFonts.rubik(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _communityCard(CommunityEntity c) {
    final cat = CommunityCategory.all.firstWhere((x) => x.code == c.category, orElse: () => CommunityCategory.all.last);
    return GestureDetector(
      onTap: () => Get.toNamed(RoutesNames.communityDetailPage, arguments: {'communityId': c.id}),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _image(c.coverUrl ?? c.imageUrl, fallback: cat.colors),
              _shade(),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                  child: Icon(cat.icon, size: 14, color: Colors.white),
                ),
              ),
              if (c.privacy == 'privada')
                Positioned(
                  top: 14,
                  right: 12,
                  child: const Icon(LucideIcons.lock, size: 14, color: Colors.white),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rubik(fontSize: 14.5, height: 1.2, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('${c.members} ${_l.t('discover_members')}',
                        style: GoogleFonts.rubik(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
