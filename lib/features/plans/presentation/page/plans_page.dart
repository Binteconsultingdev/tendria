import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/feed/presentation/widget/feed_skeleton.dart';
import 'package:tendria/features/feed/presentation/widget/feed_style.dart';
import 'package:tendria/features/plans/domain/entities/plan_entities.dart';
import 'package:tendria/features/plans/presentation/controller/plans_controller.dart';
import 'package:tendria/features/plans/presentation/widget/plan_card.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> with SingleTickerProviderStateMixin {
  late final PlansController controller =
      Get.isRegistered<PlansController>() ? Get.find<PlansController>() : Get.put(PlansController());
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: ((Get.arguments as Map<String, dynamic>?)?['tab'] as int?) ?? 0,
  );
  final LanguageController _l = Get.find<LanguageController>();

  @override
  void dispose() {
    _tabs.dispose();
    Get.delete<PlansController>();
    super.dispose();
  }

  Future<void> _create() async {
    final created = await Get.toNamed(RoutesNames.createPlanPage);
    if (created is PlanEntity) {
      controller.refreshDiscover();
      controller.refreshMine();
      _tabs.animateTo(1);
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
        iconTheme: IconThemeData(color: ThemeColor.textPrimary),
        title: Text(_l.t('plans_title'), style: GoogleFonts.rubik(fontSize: 20, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: ThemeColor.primaryColor,
          unselectedLabelColor: ThemeColor.textSecondary,
          indicatorColor: ThemeColor.primaryColor,
          labelStyle: GoogleFonts.rubik(fontWeight: FontWeight.w600),
          tabs: [Tab(text: _l.t('plans_discover')), Tab(text: _l.t('plans_mine'))],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'plans_create',
        backgroundColor: ThemeColor.primaryColor,
        onPressed: _create,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text(_l.t('plans_create'), style: GoogleFonts.rubik(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(controller: _tabs, children: [_discoverTab(), _mineTab()]),
    );
  }

  Widget _discoverTab() {
    return Column(
      children: [
        SizedBox(
          height: 58,
          child: Obx(() => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                children: [
                  _chip(null, _l.t('plans_all'), LucideIcons.layoutGrid),
                  for (final c in PlanCategory.all) _chip(c.code, _l.t('plan_cat_${c.code}'), c.icon),
                ],
              )),
        ),
        Expanded(
          child: Obx(() {
            if (controller.loadingDiscover.value && controller.discover.isEmpty) {
              return const SingleChildScrollView(child: FeedSkeleton(count: 2));
            }
            return RefreshIndicator(
              color: ThemeColor.primaryColor,
              onRefresh: controller.refreshDiscover,
              child: controller.discover.isEmpty
                  ? _empty(_l.t('plans_empty_discover'))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) controller.loadMore();
                        return false;
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 4, bottom: 96),
                        itemCount: controller.discover.length + (controller.loadingMore.value ? 1 : 0),
                        itemBuilder: (_, i) => i >= controller.discover.length
                            ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)))
                            : PlanCard(plan: controller.discover[i]),
                      ),
                    ),
            );
          }),
        ),
      ],
    );
  }

  Widget _chip(String? code, String label, IconData icon) {
    final selected = controller.category.value == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => controller.setCategory(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? ThemeColor.primaryColor : FeedStyle.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? ThemeColor.primaryColor : FeedStyle.hairline),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : ThemeColor.textPrimary),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.rubik(
                      fontSize: 13.5, fontWeight: FontWeight.w500, color: selected ? Colors.white : ThemeColor.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mineTab() {
    return Obx(() {
      if (controller.loadingMine.value && controller.upcoming.isEmpty && controller.past.isEmpty) {
        return const SingleChildScrollView(child: FeedSkeleton(count: 1));
      }
      final hasAny = controller.upcoming.isNotEmpty || controller.past.isNotEmpty;

      return RefreshIndicator(
        color: ThemeColor.primaryColor,
        onRefresh: controller.refreshMine,
        child: !hasAny
            ? _empty(_l.t('plans_empty_mine'))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 12, bottom: 96),
                children: [
                  if (controller.upcoming.isNotEmpty) ...[
                    _section(_l.t('plans_upcoming')),
                    for (final p in controller.upcoming) PlanCard(plan: p),
                  ],
                  if (controller.past.isNotEmpty) ...[
                    _section(_l.t('plans_past')),
                    for (final p in controller.past) Opacity(opacity: 0.75, child: PlanCard(plan: p)),
                  ],
                ],
              ),
      );
    });
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
        child: Text(text, style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: ThemeColor.textPrimary)),
      );

  Widget _empty(String message) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(gradient: ThemeColor.primaryGradient, shape: BoxShape.circle),
              child: const Icon(LucideIcons.calendarDays, size: 40, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 22, 36, 0),
            child: Text(message, textAlign: TextAlign.center, style: FeedStyle.body.copyWith(color: ThemeColor.textSecondary)),
          ),
        ],
      );
}
