import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tendria/common/theme/App_Theme.dart'; 
import 'explore_vip_controller.dart';
 
class _NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const _NetImage(this.url, {this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: ThemeColor.subtleBackground,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ThemeColor.primaryColor,
                ),
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: ThemeColor.subtleBackground,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: ThemeColor.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
  
class ExploreVipPage extends StatelessWidget {
  const ExploreVipPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExploreVipController());

    return Scaffold(
      backgroundColor: ThemeColor.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _ExploreTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _SearchField(controller: controller),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Tendencias',
                    actionLabel: 'VER TODO',
                    onAction: controller.openTrendingAll,
                    showAccentBar: true,
                  ),
                  const SizedBox(height: 12),
                  _TrendingGrid(controller: controller),
                  const SizedBox(height: 24),
                  _LiveSectionHeader(),
                  const SizedBox(height: 12),
                  _LiveCreatorsRow(controller: controller),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Recomendados para ti'),
                  const SizedBox(height: 12),
                  ...controller.recommendedItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecommendedCard(
                        item: item,
                        controller: controller,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionHeader(
                    title: 'Nuevos creadores',
                    actionLabel: 'Sugeridos',
                    onAction: controller.openSuggestedCreators,
                  ),
                  const SizedBox(height: 12),
                  _NewCreatorsRow(controller: controller),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Más populares'),
                  const SizedBox(height: 12),
                  ...controller.popularItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PopularRow(item: item, controller: controller),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ), 
    );
  }
}
 
class _ExploreTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeColor.backgroundColor,
        border: Border(
          bottom: BorderSide(color: ThemeColor.subtleBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.menu, color: ThemeColor.iconColor),
          const SizedBox(width: 8),
          Text(
            'Tatendria VIP',
            style: GoogleFonts.rubik(
              color: ThemeColor.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          CircleAvatar(
            radius: 16,
            backgroundColor: ThemeColor.subtleBackground,
            child: Icon(
              Icons.person,
              size: 18,
              color: ThemeColor.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
 

class _SearchField extends StatelessWidget {
  final ExploreVipController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: ThemeColor.cardBackground,
        borderRadius: ThemeColor.circularBorderRadius,
        border: Border.all(color: ThemeColor.subtleBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: ThemeColor.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: controller.updateSearchQuery,
              style: GoogleFonts.rubik(
                color: ThemeColor.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: 'Buscar creadores o contenido exclusivo...',
                hintStyle: GoogleFonts.rubik(
                  color: ThemeColor.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: controller.openFilters,
            child: Icon(
              Icons.tune,
              color: ThemeColor.primaryColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
 

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showAccentBar;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.showAccentBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (showAccentBar) ...[
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: ThemeColor.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                color: ThemeColor.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: GoogleFonts.rubik(
                color: ThemeColor.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
      ],
    );
  }
}
 

class _TrendingGrid extends StatelessWidget {
  final ExploreVipController controller;
  const _TrendingGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: _FeaturedTrendingCard(item: controller.featuredTrending),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: _SecondaryTrendingCard(
                    item: controller.secondaryTrending[0],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _SecondaryTrendingCard(
                    item: controller.secondaryTrending[1],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedTrendingCard extends StatelessWidget {
  final TrendingItem item;
  const _FeaturedTrendingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: ThemeColor.largeBorderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _NetImage(item.imageUrl),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.badge != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ThemeColor.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.badge!,
                      style: GoogleFonts.rubik(
                        color: Colors.black87,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                if (item.title != null)
                  Text(
                    item.title!,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (item.author != null || item.viewsLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [
                        item.author,
                        item.viewsLabel,
                      ].where((e) => e != null).join(' • '),
                      style: GoogleFonts.rubik(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryTrendingCard extends StatelessWidget {
  final TrendingItem item;
  const _SecondaryTrendingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: ThemeColor.mediumBorderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _NetImage(item.imageUrl),
          if (item.title != null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
          if (item.title != null)
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                item.title!,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
 

class _LiveSectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'En vivo',
          style: GoogleFonts.playfairDisplay(
            color: ThemeColor.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ThemeColor.errorColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'LIVE',
                style: GoogleFonts.rubik(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveCreatorsRow extends StatelessWidget {
  final ExploreVipController controller;
  const _LiveCreatorsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: controller.liveCreators
            .map(
              (creator) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => controller.openLiveCreator(creator),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ThemeColor.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: ThemeColor.subtleBackground,
                            backgroundImage: NetworkImage(creator.avatarUrl),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          creator.name,
                          style: GoogleFonts.rubik(
                            color: ThemeColor.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          creator.viewersLabel,
                          style: ThemeColor.caption.copyWith(
                            color: ThemeColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
 

class _RecommendedCard extends StatelessWidget {
  final RecommendedItem item;
  final ExploreVipController controller;
  const _RecommendedCard({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ThemeColor.cardBackground,
        borderRadius: ThemeColor.mediumBorderRadius,
        border: Border.all(color: ThemeColor.subtleBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: _NetImage(item.imageUrl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, color: ThemeColor.primaryColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      item.tag,
                      style: GoogleFonts.rubik(
                        color: ThemeColor.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: GoogleFonts.rubik(
                    color: ThemeColor.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Por ${item.author}',
                  style: ThemeColor.caption.copyWith(
                    color: ThemeColor.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.rubik(
                    color: ThemeColor.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => GestureDetector(
              onTap: () => controller.toggleBookmark(item),
              child: Icon(
                item.isBookmarked.value
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: ThemeColor.primaryColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 

class _NewCreatorsRow extends StatelessWidget {
  final ExploreVipController controller;
  const _NewCreatorsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: controller.newCreators
            .map(
              (creator) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _NewCreatorCard(
                    creator: creator,
                    controller: controller,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NewCreatorCard extends StatelessWidget {
  final NewCreator creator;
  final ExploreVipController controller;
  const _NewCreatorCard({required this.creator, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ThemeColor.cardBackground,
        borderRadius: ThemeColor.mediumBorderRadius,
        border: Border.all(color: ThemeColor.subtleBorder),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: ThemeColor.subtleBackground,
            backgroundImage: NetworkImage(creator.avatarUrl),
          ),
          const SizedBox(height: 10),
          Text(
            creator.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.rubik(
              color: ThemeColor.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            creator.category,
            textAlign: TextAlign.center,
            style: ThemeColor.caption.copyWith(
              color: ThemeColor.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ThemeColor.widgetButton(
                text: creator.isFollowing.value ? 'Siguiendo' : 'Seguir',
                backgroundColor: creator.isFollowing.value
                    ? ThemeColor.subtleBackground
                    : ThemeColor.primaryColor,
                textColor: creator.isFollowing.value
                    ? ThemeColor.primaryColor
                    : Colors.black87,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(vertical: 8),
                borderRadius: 10,
                onPressed: () => controller.toggleFollow(creator),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 

class _PopularRow extends StatelessWidget {
  final PopularItem item;
  final ExploreVipController controller;
  const _PopularRow({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.openPopularItem(item),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ThemeColor.cardBackground,
          borderRadius: ThemeColor.mediumBorderRadius,
          border: Border.all(color: ThemeColor.subtleBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                item.rank.toString().padLeft(2, '0'),
                style: GoogleFonts.playfairDisplay(
                  color: ThemeColor.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: _NetImage(item.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.rubik(
                      color: ThemeColor.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${item.handle} • ${item.viewsLabel}',
                    style: ThemeColor.caption.copyWith(
                      color: ThemeColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.trending_up, color: ThemeColor.primaryColor, size: 18),
          ],
        ),
      ),
    );
  }
}
 

class _ExploreBottomNav extends StatelessWidget {
  final ExploreVipController controller;
  const _ExploreBottomNav({required this.controller});

  static const _items = [
    (icon: Icons.home_filled, label: 'Inicio'),
    (icon: Icons.search, label: 'Explorar'),
    (icon: Icons.add, label: 'Publicar'),
    (icon: Icons.account_balance_wallet_outlined, label: 'Balance'),
    (icon: Icons.person_outline, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColor.cardBackground,
        border: Border(
          top: BorderSide(color: ThemeColor.subtleBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_items.length, (index) {
                final item = _items[index];
                final isCenter = index == 2;
                final isSelected = controller.currentNavIndex.value == index;

                if (isCenter) {
                  return GestureDetector(
                    onTap: () => controller.changeNavIndex(index),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ThemeColor.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [ThemeColor.darkShadow],
                      ),
                      child: Icon(item.icon, color: Colors.black87, size: 26),
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () => controller.changeNavIndex(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isSelected
                            ? ThemeColor.primaryColor
                            : ThemeColor.textSecondary,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: GoogleFonts.rubik(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? ThemeColor.primaryColor
                              : ThemeColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}