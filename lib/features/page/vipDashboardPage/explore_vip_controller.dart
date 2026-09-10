import 'package:get/get.dart';
 
class TrendingItem {
  final String imageUrl;
  final String? badge;
  final String? title;
  final String? author;
  final String? viewsLabel;

  TrendingItem({
    required this.imageUrl,
    this.badge,
    this.title,
    this.author,
    this.viewsLabel,
  });
}

class LiveCreatorPreview {
  final String name;
  final String avatarUrl;
  final String viewersLabel;

  LiveCreatorPreview({
    required this.name,
    required this.avatarUrl,
    required this.viewersLabel,
  });
}

class RecommendedItem {
  final String title;
  final String author;
  final double price;
  final String imageUrl;
  final String tag;
  final RxBool isBookmarked;

  RecommendedItem({
    required this.title,
    required this.author,
    required this.price,
    required this.imageUrl,
    this.tag = 'VIP SELECTION',
    bool isBookmarked = false,
  }) : isBookmarked = isBookmarked.obs;
}

class NewCreator {
  final String name;
  final String category;
  final String avatarUrl;
  final RxBool isFollowing;

  NewCreator({
    required this.name,
    required this.category,
    required this.avatarUrl,
    bool isFollowing = false,
  }) : isFollowing = isFollowing.obs;
}

class PopularItem {
  final int rank;
  final String title;
  final String handle;
  final String viewsLabel;
  final String imageUrl;

  PopularItem({
    required this.rank,
    required this.title,
    required this.handle,
    required this.viewsLabel,
    required this.imageUrl,
  });
}

class ExploreVipController extends GetxController {
   
  final RxString searchQuery = ''.obs;
  final RxInt currentNavIndex = 1.obs;  

  final TrendingItem featuredTrending = TrendingItem(
    imageUrl: 'https://picsum.photos/seed/opalo-vip/600/900',
    badge: 'TRENDING',
    title: 'Colección Ópalo',
    author: '@elena_vogue',
    viewsLabel: '1.2M vistas',
  );

  final List<TrendingItem> secondaryTrending = [
    TrendingItem(
      imageUrl: 'https://picsum.photos/seed/medianoche-vip/500/500',
      title: 'Escapes de Medianoche',
    ),
    TrendingItem(imageUrl: 'https://picsum.photos/seed/relojeria-vip/500/500'),
  ];

  final RxList<LiveCreatorPreview> liveCreators = <LiveCreatorPreview>[
    LiveCreatorPreview(
      name: '@marcos_art',
      avatarUrl: 'https://picsum.photos/seed/marcos-art/200/200',
      viewersLabel: '8.4k espectadores',
    ),
    LiveCreatorPreview(
      name: '@silvia_glam',
      avatarUrl: 'https://picsum.photos/seed/silvia-glam/200/200',
      viewersLabel: '12k espectadores',
    ),
  ].obs;

  final RxList<RecommendedItem> recommendedItems = <RecommendedItem>[
    RecommendedItem(
      title: 'Secretos de Diseño creativo: Edición Limitada',
      author: '@julian_arch',
      price: 24.99,
      imageUrl: 'https://picsum.photos/seed/design-vip/200/200',
    ),
    RecommendedItem(
      title: 'Audio Inmersivo: Paisajes Sonoros Urbanos',
      author: '@sound_master',
      price: 15.00,
      imageUrl: 'https://picsum.photos/seed/audio-vip/200/200',
    ),
  ].obs;

  final RxList<NewCreator> newCreators = <NewCreator>[
    NewCreator(
      name: 'Carla Montes',
      category: 'Fotografía Minimal',
      avatarUrl: 'https://picsum.photos/seed/carla-montes/200/200',
    ),
    NewCreator(
      name: 'Viktor Strauss',
      category: 'Neoclásico VIP',
      avatarUrl: 'https://picsum.photos/seed/viktor-strauss/200/200',
    ),
  ].obs;

  final RxList<PopularItem> popularItems = <PopularItem>[
    PopularItem(
      rank: 1,
      title: 'Arquitectura del Futuro',
      handle: '@ARCH_DIGEST',
      viewsLabel: '2.5M',
      imageUrl: 'https://picsum.photos/seed/arch-future/200/200',
    ),
    PopularItem(
      rank: 2,
      title: 'Vida Nocturna VIP',
      handle: '@EXCLUSIVE_NIGHT',
      viewsLabel: '1.8M',
      imageUrl: 'https://picsum.photos/seed/night-life/200/200',
    ),
    PopularItem(
      rank: 3,
      title: 'Ingredientes Prohibidos',
      handle: '@CHEF_SECRET',
      viewsLabel: '950K',
      imageUrl: 'https://picsum.photos/seed/chef-secret/200/200',
    ),
  ].obs;
 
  void updateSearchQuery(String value) => searchQuery.value = value;

  void openFilters() { 
  }

  void openTrendingAll() { 
  }

  void openLiveCreator(LiveCreatorPreview creator) { 
  }

  void toggleBookmark(RecommendedItem item) {
    item.isBookmarked.value = !item.isBookmarked.value;
  }

  void toggleFollow(NewCreator creator) {
    creator.isFollowing.value = !creator.isFollowing.value;
  }

  void openSuggestedCreators() { 
  }

  void openPopularItem(PopularItem item) { 
  }

  void changeNavIndex(int index) {
    currentNavIndex.value = index;
  }
}