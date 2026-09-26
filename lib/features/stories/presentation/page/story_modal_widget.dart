import 'package:tendria/features/stories/presentation/widgets/story_reply_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/custom_alert_type.dart';
import 'package:tendria/features/stories/domain/entities/getstories/story_entity.dart';
import 'package:tendria/features/stories/presentation/page/story_controller.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tendria/features/user/presentation/controller/profile_controller.dart';
import 'package:video_player/video_player.dart';

void showStoryModal(
  BuildContext context, {
  required int userIndex,
  bool isMyStory = false,
}) async {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, _, __) {
        return StoryModalWidget(userIndex: userIndex, isMyStory: isMyStory);
      },
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class StoryModalWidget extends StatefulWidget {
  final int userIndex;
  final bool isMyStory;

  const StoryModalWidget({
    Key? key,
    required this.userIndex,
    this.isMyStory = false,
  }) : super(key: key);

  @override
  _StoryModalWidgetState createState() => _StoryModalWidgetState();
}

class _StoryModalWidgetState extends State<StoryModalWidget>
    with TickerProviderStateMixin {
  final StoryController controller = Get.find<StoryController>();
  final ProfileController _userController = Get.find<ProfileController>();
  @override
  void initState() {
    super.initState();
    if (widget.isMyStory) {
      controller.initializeMyStoryModal(this);
    } else {
      controller.initializeStoryModal(widget.userIndex, this);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: ThemeColor.textDarkColor,
          elevation: 4,
          shadowColor: ThemeColor.shadowColor,
        ),
      ),
      body: Obx(() {
        if (!controller.isModalActive.value) {
          return const SizedBox.shrink();
        }
        final isViewingMyStory = controller.isViewingMyStory.value;
        final currentStory = isViewingMyStory
            ? controller.currentMyStory
            : controller.currentStory;

        if (currentStory == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Material(
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
                  child: Container(
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
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isViewingMyStory) ...[
                          Row(
                            children: List.generate(
                              controller.myStories.length,
                              (index) => Expanded(
                                child: Container(
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: controller.progressAnimation!,
                                    builder: (context, child) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: controller
                                              .getMyStoryProgressAt(index),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Row(
                            children: List.generate(
                              controller.currentUserStories.length,
                              (index) => Expanded(
                                child: Container(
                                  height: 3,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: controller.progressAnimation!,
                                    builder: (context, child) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: controller
                                              .getStoryProgress(index),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: _buildStoryUserAvatar(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  if (isViewingMyStory) return;

                                  final senderId =
                                      controller.currentUser?.usuarioId;
                                  if (senderId == null) return;

                                  final myId = await AuthService().getUserId();
                                  if (myId != null && senderId == myId) return;

                                  Get.toNamed(
                                    RoutesNames.userProfileDetailPage,
                                    arguments: {'userId': senderId},
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isViewingMyStory
                                          ? "Mi historia"
                                          : controller
                                                .currentUser!
                                                .nombreUsuario,
                                      style: GoogleFonts.rubik(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 1),
                                            blurRadius: 3,
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      controller.getTimeAgo(
                                        currentStory.fechaCreacion,
                                      ),
                                      style: GoogleFonts.rubik(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 1),
                                            blurRadius: 3,
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom,
                      left: 16,
                      right: 16,
                      top: 16,
                    ),
                    child: isViewingMyStory
                        ? SizedBox(height: 50, child: _buildMyStoryFooter(currentStory))
                        : _buildOtherStoryFooter(currentStory),
                  ),
                ),

                Positioned(
                  top: 110,
                  bottom: 76 + MediaQuery.of(context).padding.bottom,
                  left: 0,
                  width: screenWidth * 0.3,
                  child: GestureDetector(
                    onTap: () {
                      if (controller.isViewingMyStory.value) {
                        controller.previousMyStory();
                      } else {
                        controller.previousStory();
                      }
                    },
                    onLongPress: () => controller.pauseStory(),
                    onLongPressEnd: (details) => controller.resumeStory(),
                    child: Container(color: Colors.transparent),
                  ),
                ),

                Positioned(
                  top: 110,
                  bottom: 76 + MediaQuery.of(context).padding.bottom,
                  right: 0,
                  width: screenWidth * 0.3,
                  child: GestureDetector(
                    onTap: () {
                      if (controller.isViewingMyStory.value) {
                        controller.nextMyStory();
                      } else {
                        controller.nextStory();
                      }
                    },
                    onLongPress: () => controller.pauseStory(),
                    onLongPressEnd: (details) => controller.resumeStory(),
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
                    onLongPressEnd: (details) => controller.resumeStory(),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.person, color: Colors.white54, size: 24),
    );
  }

  Widget _buildStoryUserAvatar() {
    final isMyStory = controller.isViewingMyStory.value;
    final String? photoUrl = isMyStory
        ? _userController.profilePhotoUrl
        : controller.currentUser?.fotoPerfilUrl;

    final int? senderId = isMyStory ? null : controller.currentUser?.usuarioId;

    return GestureDetector(
      onTap: () async {
        if (isMyStory || senderId == null) return;

        final myId = await AuthService().getUserId();
        if (myId != null && senderId == myId) return;

        Get.toNamed(
          RoutesNames.userProfileDetailPage,
          arguments: {'userId': senderId},
        );
      },
      child: ClipOval(
        child: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => _buildDefaultAvatar(),
                errorWidget: (context, url, error) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildStoryContent(StoryEntity story) {
    final isVideo = story.tipoContenido.toLowerCase() == StoryController.kVideo;

    if (isVideo) {
      return Obx(() {
        final initialized = controller.isVideoInitialized.value;
        final videoCtrl = controller.videoController;

        if (initialized && videoCtrl != null && videoCtrl.value.isInitialized) {
          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: videoCtrl.value.size.width,
                height: videoCtrl.value.size.height,
                child: VideoPlayer(videoCtrl),
              ),
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

  Widget _buildMyStoryFooter(StoryEntity story) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${story.vistas}',
                    style: GoogleFonts.rubik(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${story.likes}',
                    style: GoogleFonts.rubik(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        GestureDetector(
          onTap: () => _showDeleteOptions(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherStoryFooter(StoryEntity story) {
    // Responder y reaccionar (la barra se reinicia con cada historia)
    return StoryReplyBar(
      key: ValueKey('reply_${story.id}'),
      storyId: story.id,
      initialReaction: story.yaLikeada ? 'me_encanta' : null,
      onPause: controller.pauseStory,
      onResume: controller.resumeStory,
    );
  }

  void _showDeleteOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ThemeColor.backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Eliminar historia',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Get.back();
                _confirmDeleteStory(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.close, color: ThemeColor.textSecondaryColor),
              title: const Text('Cancelar'),
              onTap: () => Get.back(),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStory(BuildContext context) {
    showCustomAlert(
      context: context,
      title: 'Eliminar historia',
      message:
          '¿Estás seguro de que deseas eliminar tu historia? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      type: CustomAlertType.warning,
      onConfirm: () async {
        Get.back();
        await controller.deleteMyStory();
      },
      onCancel: () => Get.back(),
    );
  }
}
