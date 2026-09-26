import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/discover/discover_filters.dart';
import 'package:tendria/features/discover/discover_repository.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';

Future<void> showDiscoverFilters(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: FeedStyle.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => const _FiltersSheet(),
  );
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  final LanguageController _l = Get.find<LanguageController>();
  late DiscoverFilters _f = DiscoverState.instance.filters.value;
  List<InterestItem> _interests = [];
  bool _interestsFailed = false;

  @override
  void initState() {
    super.initState();
    DiscoverRepository.instance.interests().then((list) {
      if (mounted) setState(() => _interests = list);
    }).catchError((_) {
      if (mounted) setState(() => _interestsFailed = true);
    });
  }

  Future<void> _apply() async {
    await DiscoverState.instance.update(_f);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _title(String text, {String? trailing}) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(text, style: GoogleFonts.rubik(fontSize: 14.5, fontWeight: FontWeight.w600, color: ThemeColor.textPrimary))),
            if (trailing != null)
              Text(trailing, style: GoogleFonts.rubik(fontSize: 13.5, fontWeight: FontWeight.w600, color: ThemeColor.primaryColor)),
          ],
        ),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap, {IconData? icon}) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? ThemeColor.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? ThemeColor.primaryColor : FeedStyle.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? ThemeColor.primaryColor : ThemeColor.textSecondary),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: GoogleFonts.rubik(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? ThemeColor.primaryColor : ThemeColor.textPrimary)),
            ],
          ),
        ),
      );

  Widget _switchRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ThemeColor.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: FeedStyle.name.copyWith(fontWeight: FontWeight.w500))),
            Switch(value: value, onChanged: onChanged, activeThumbColor: ThemeColor.primaryColor),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final ageLabel = _f.ageMin <= DiscoverFilters.ageFloor && _f.ageMax >= DiscoverFilters.ageCeil
        ? _l.t('filters_any')
        : '${_f.ageMin} – ${_f.ageMax >= DiscoverFilters.ageCeil ? '${DiscoverFilters.ageCeil}+' : _f.ageMax}';

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 10, 22, 14 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 38, height: 4, decoration: BoxDecoration(color: FeedStyle.hairline, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: Text(_l.t('filters_title'), style: GoogleFonts.rubik(fontSize: 19, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary))),
                  if (_f.isActive)
                    GestureDetector(
                      onTap: () => setState(() => _f = const DiscoverFilters()),
                      child: Text(_l.t('filters_clear'), style: GoogleFonts.rubik(fontSize: 13.5, fontWeight: FontWeight.w500, color: ThemeColor.textSecondary)),
                    ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title(_l.t('filters_age'), trailing: ageLabel),
                      RangeSlider(
                        values: RangeValues(_f.ageMin.toDouble(), _f.ageMax.toDouble()),
                        min: DiscoverFilters.ageFloor.toDouble(),
                        max: DiscoverFilters.ageCeil.toDouble(),
                        divisions: DiscoverFilters.ageCeil - DiscoverFilters.ageFloor,
                        activeColor: ThemeColor.primaryColor,
                        inactiveColor: FeedStyle.hairline,
                        onChanged: (v) => setState(() => _f = _f.copyWith(ageMin: v.start.round(), ageMax: v.end.round())),
                      ),
                      _title(_l.t('filters_distance'),
                          trailing: _f.distanceKm == null ? _l.t('filters_any') : '${_f.distanceKm!.round()} km'),
                      Slider(
                        value: (_f.distanceKm ?? DiscoverFilters.distanceCeil).clamp(1, DiscoverFilters.distanceCeil),
                        min: 1,
                        max: DiscoverFilters.distanceCeil,
                        activeColor: ThemeColor.primaryColor,
                        inactiveColor: FeedStyle.hairline,
                        onChanged: (v) => setState(() => _f = v >= DiscoverFilters.distanceCeil
                            ? _f.copyWith(clearDistance: true)
                            : _f.copyWith(distanceKm: v.roundToDouble())),
                      ),
                      _title(_l.t('filters_gender')),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip(_l.t('filters_all'), _f.gender == null, () => setState(() => _f = _f.copyWith(clearGender: true))),
                          _chip(_l.t('filters_women'), _f.gender == 'Mujer', () => setState(() => _f = _f.copyWith(gender: 'Mujer'))),
                          _chip(_l.t('filters_men'), _f.gender == 'Hombre', () => setState(() => _f = _f.copyWith(gender: 'Hombre'))),
                          _chip(_l.t('filters_nonbinary'), _f.gender == 'No_binario', () => setState(() => _f = _f.copyWith(gender: 'No_binario'))),
                        ],
                      ),
                      _title(_l.t('filters_more')),
                      _switchRow(LucideIcons.badgeCheck, _l.t('filters_verified'), _f.onlyVerified, (v) => setState(() => _f = _f.copyWith(onlyVerified: v))),
                      _switchRow(LucideIcons.circleDot, _l.t('filters_online'), _f.onlyOnline, (v) => setState(() => _f = _f.copyWith(onlyOnline: v))),
                      if (_interests.isNotEmpty || _interestsFailed) ...[
                        _title(_l.t('filters_interests'), trailing: _f.interests.isEmpty ? null : '${_f.interests.length}'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final i in _interests)
                              _chip(i.name, _f.interests.contains(i.id), () {
                                final next = {..._f.interests};
                                next.contains(i.id) ? next.remove(i.id) : next.add(i.id);
                                setState(() => _f = _f.copyWith(interests: next));
                              }),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _apply,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: ThemeColor.primaryGradient, borderRadius: BorderRadius.circular(18)),
                  child: Text(_l.t('filters_apply'), style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
