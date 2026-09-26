import 'package:tendria/features/stories/presentation/widgets/story_reply_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/stories/domain/entities/getstories/story_entity.dart';
import 'package:tendria/features/stories/presentation/page/story_controller.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

void showTargetUserStoryModal(
  BuildContext context, {
  required int userId,
  required String userName,
  String? userPhoto,
}) async {
  final StoryController controller = Get.find<StoryController>();
  final hasStories = await controller.fetchStoriesForUser(userId);
  if (!hasStories) return;

  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, _, __) {
        return TargetUserStoryModal(userName: userName, userPhoto: userPhoto);
      },
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class TargetUserStoryModal extends StatefulWidget {
  final String userName;
  final String? userPhoto;

  const TargetUserStoryModal({Key? key, required this.userName, this.userPhoto})
    : super(key: key);

  @override
  _TargetUserStoryModalState createState() => _TargetUserStoryModalState();
}

class _TargetUserStoryModalState extends State<TargetUserStoryModal>
    with TickerProviderStateMixin {
  final StoryController controller = Get.find<StoryController>();
 
  late final Worker _modalActiveWorker;
  late final Worker _storyIndexWorker;

  @override
  void initState() {
    super.initState();
    controller.initializeTargetUserStoryModal(this);
    controller.progressAnimation?.addListener(_onAnimationTick);
 
    _modalActiveWorker = ever(controller.isModalActive, (_) {
      if (mounted) setState(() {});
    });
    _storyIndexWorker = ever(controller.currentTargetStoryIndex, (_) {
      
      controller.progressAnimation?.removeListener(_onAnimationTick);
      controller.progressAnimation?.addListener(_onAnimationTick);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _modalActiveWorker.dispose();
    _storyIndexWorker.dispose();
    controller.progressAnimation?.removeListener(_onAnimationTick);
    super.dispose();
  }

  void _onAnimationTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
 
    if (!controller.isModalActive.value) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final currentStory = controller.currentTargetStory;
    if (currentStory == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final stories = controller.targetUserStories;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: ThemeColor.textDarkColor,
          elevation: 4,
          shadowColor: ThemeColor.shadowColor,
        ),
      ),
      body: Material(
        color: Colors.black,
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              Positioned.fill(child: _buildStoryContent(currentStory)),
              Positioned(
                top: -30,
                left: 0,
                right: 0,
                child: _buildHeader(currentStory, stories),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildFooter(currentStory),
              ),
              Positioned(
                top: 110,
                bottom: 76 + MediaQuery.of(context).padding.bottom,
                left: 0,
                width: screenWidth * 0.3,
                child: GestureDetector(
                  onTap: () => controller.previousTargetStory(),
                  onLongPress: () => controller.pauseStory(),
                  onLongPressEnd: (_) => controller.resumeStory(),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                top: 110,
                bottom: 76 + MediaQuery.of(context).padding.bottom,
                right: 0,
                width: screenWidth * 0.3,
                child: GestureDetector(
                  onTap: () => controller.nextTargetStory(),
                  onLongPress: () => controller.pauseStory(),
                  onLongPressEnd: (_) => controller.resumeStory(),
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                top: 110,
                bottom: 76 + MediaQuery.of(context).padding.bottom,
                left: screenWidth * 0.3,
                right: screenWidth * 0.3,
                child: GestureDetector(
                  onLongPress: () => controller.pauseStory(),
                  onLongPressEnd: (_) => controller.resumeStory(),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(StoryEntity currentStory, List<StoryEntity> stories) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8,
        right: 8,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(stories.length, (index) {
              final currentIndex = controller.currentTargetStoryIndex.value;
              double progress = 0.0;
              if (index < currentIndex) {
                progress = 1.0;
              } else if (index == currentIndex) {
                progress = controller.progressAnimation?.value ?? 0.0;
              }
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white.withOpacity(0.3),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child:
                      widget.userPhoto != null && widget.userPhoto!.isNotEmpty
                      ? Image.network(
                          widget.userPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackAvatar(),
                        )
                      : _fallbackAvatar(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: GoogleFonts.rubik(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      controller.getTimeAgo(currentStory.fechaCreacion),
                      style: GoogleFonts.rubik(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  controller.disposeStoryModal();
                  Get.back();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.close, size: 20, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(StoryEntity currentStory) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: StoryReplyBar(
        key: ValueKey('reply_${currentStory.id}'),
        storyId: currentStory.id,
        initialReaction: currentStory.yaLikeada ? 'me_encanta' : null,
        onPause: controller.pauseStory,
        onResume: controller.resumeStory,
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: ThemeColor.primaryColor.withOpacity(0.3),
      child: const Icon(Icons.person, color: Colors.white, size: 24),
    );
  }

  Widget _buildStoryContent(StoryEntity story) {
    final isVideo = story.tipoContenido == 'Video';

    if (isVideo) {
      return Obx(() {
        final initialized = controller.isVideoInitialized.value;
        final videoCtrl = controller.videoController;

        if (initialized && videoCtrl != null && videoCtrl.value.isInitialized) {
          return Center(
            child: AspectRatio(
              aspectRatio: videoCtrl.value.aspectRatio,
              child: VideoPlayer(videoCtrl),
            ),
          );
        }

        return Container(
          color: Colors.grey[900],
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Cargando video...',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      });
    } else {
      return CachedNetworkImage(
        imageUrl: story.urlContenido,
        fit: BoxFit.contain,  
        width: double.infinity,
        height: double.infinity,
        fadeInDuration: Duration.zero,
        placeholder: (context, url) => Container(
          color: Colors.grey[900],
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.white, size: 50),
          ),
        ),
      );
    }
  }
}
