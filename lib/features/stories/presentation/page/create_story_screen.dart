import 'package:tendria/features/stories/presentation/page/story_extras.dart';
import 'package:tendria/features/feed/presentation/widget/post_style.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/alert/custom_alert_type.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper.dart';
import 'package:tendria/features/stories/presentation/page/create_story_controller.dart';
import 'package:tendria/features/stories/presentation/page/story_controller.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class DraggableStoryText extends StatefulWidget {
  final String style;
  final String text;
  final Color color;
  final Offset position;
  final double scale;
  final bool isSelected;
  final Function(Offset) onPositionChanged;
  final Function(double) onScaleChanged;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DraggableStoryText({
    Key? key,
    this.style = 'none',
    required this.text,
    required this.color,
    required this.position,
    required this.scale,
    required this.isSelected,
    required this.onPositionChanged,
    required this.onScaleChanged,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  State<DraggableStoryText> createState() => _DraggableStoryTextState();
}

class _DraggableStoryTextState extends State<DraggableStoryText> {
  late Offset position;
  late double scale;
  double baseScale = 1.0;
  Offset basePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    position = widget.position;
    scale = widget.scale;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      left: position.dx * size.width - 100,
      top: position.dy * size.height - 50,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onScaleStart: (details) {
          baseScale = scale;
          basePosition = position;
        },
        onScaleUpdate: (details) {
          setState(() {
            if (details.scale != 1.0) {
              scale = (baseScale * details.scale).clamp(0.5, 3.0);
            }

            final newX =
                (basePosition.dx * size.width + details.focalPointDelta.dx) /
                size.width;
            final newY =
                (basePosition.dy * size.height + details.focalPointDelta.dy) /
                size.height;

            position = Offset(newX.clamp(0.0, 1.0), newY.clamp(0.0, 1.0));

            basePosition = position;
          });
        },
        onScaleEnd: (_) {
          widget.onPositionChanged(position);
          widget.onScaleChanged(scale);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.style == 'pill'
                ? Colors.black.withOpacity(0.6)
                : (widget.isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent),
            borderRadius: BorderRadius.circular(widget.style == 'none' ? 8 : 12),
            border: widget.style == 'outline'
                ? Border.all(color: widget.color, width: 2.5)
                : (widget.isSelected ? Border.all(color: Colors.white, width: 2) : null),
          ),
          child: Transform.scale(
            scale: scale,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Text(
                widget.text,
                style: GoogleFonts.rubik(
                  color: widget.color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: widget.style == 'neon'
                      ? [
                          Shadow(color: widget.color, blurRadius: 6),
                          Shadow(color: widget.color, blurRadius: 16),
                          Shadow(color: widget.color.withOpacity(0.8), blurRadius: 30),
                        ]
                      : (widget.style == 'outline'
                          ? const <Shadow>[]
                          : [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ]),
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({Key? key}) : super(key: key);

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen>
    with WidgetsBindingObserver {
  final CreateStoryController controller = Get.put(CreateStoryController());
  final StoryController storyController = Get.find<StoryController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Get.delete<CreateStoryController>();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    controller.handleAppLifecycleState(state);
  }

  Future<void> _publishStory() async {
    if (controller.capturedFile.value == null ||
        controller.contentType.value == null) {
      return;
    }

    File? finalFile = controller.capturedFile.value;

    if (controller.contentType.value ==CreateStoryController.kImagen) {
      showCustomAlert(
        context: context,
        title: '',
        message: 'Preparando imagen...',
        confirmText: '',
        type: CustomAlertType.warning,
        customWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 12),
            Text(
              'Preparando imagen...',
              style: GoogleFonts.rubik(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );

      if (controller.needsBaking) {
        finalFile = await controller.captureStoryWithTexts();
      } else {
        finalFile = await controller.convertToPng(finalFile!);
      }

      Get.back();
    }

    if (controller.contentType.value == CreateStoryController.kVideo) {
      final filePath = finalFile!.path;

      if (!filePath.endsWith('.mp4')) {
        showCustomAlert(
          context: context,
          title: '',
          message: '',
          confirmText: '',
          type: CustomAlertType.warning,
          customWidget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 12),
              Text(
                'Convirtiendo video a MP4...',
                style: GoogleFonts.rubik(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );

        final File? mp4File = await controller.convertToMp4(finalFile);
        Get.back();
        if (mp4File != null) finalFile = mp4File;
      } else if (controller.storyTexts.isNotEmpty) {
        showCustomAlert(
          context: context,
          title: '',
          message: '',
          confirmText: '',
          type: CustomAlertType.warning,
          customWidget: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 12),
              Text(
                'Procesando video con textos...',
                style: GoogleFonts.rubik(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        );

        finalFile = await controller.captureStoryWithTexts();
        Get.back();
      }
    }

    if (finalFile == null || !await finalFile.exists()) {
      showErrorSnackbar('No se pudo procesar la historia');
      return;
    }

    debugPrint('✅ Publicando: ${finalFile.path}');
    await storyController.createStory(finalFile, controller.contentType.value!);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.capturedFile.value != null) {
        return _buildPreviewScreen();
      }
      return _buildCameraScreen();
    });
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Obx(() {
            final camController = controller.cameraController.value;

            if (!controller.isCameraInitialized.value ||
                camController == null) {
              return Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Iniciando cámara...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!camController.value.isInitialized) {
              return Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            return Center(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height:
                        MediaQuery.of(context).size.width *
                        camController.value.aspectRatio,
                    child: CameraPreview(camController),
                  ),
                ),
              ),
            );
          }),

          Obx(() {
            if (controller.isRecording.value) {
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 4),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          _buildHeader(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 78,
            right: 16,
            child: GestureDetector(
              onTap: controller.startTextStory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(22)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.text_fields, color: Colors.white, size: 20),
                    const SizedBox(width: 7),
                    Text('Texto', style: GoogleFonts.rubik(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          _buildGallery(),
          _buildCaptureButton(),
          _buildInstructionText(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),

              Obx(() {
                if (controller.isRecording.value) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${controller.recordingSeconds.value}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              GestureDetector(
                onTap: () => controller.switchCamera(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGallery() {
    return Positioned(
      bottom: 140,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 50,
        child: Obx(() {
          if (controller.isLoadingGallery.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: controller.galleryAssets.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ThemeColor.widgetButton(
                  onPressed: () => controller.selectFromImagePicker(),
                  borderRadius: 50,
                  backgroundColor: ThemeColor.tertiaryColor,
                  text: 'Subir foto de galería',
                );
              }
            },
          );
        }),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Obx(() {
          return GestureDetector(
            onTap: controller.isRecording.value
                ? null
                : () => controller.takePicture(),
            onLongPressStart: (_) => controller.startRecording(),
            onLongPressEnd: (_) => controller.stopRecording(),
            onLongPressCancel: () => controller.stopRecording(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (controller.isRecording.value)
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value:
                          controller.recordingSeconds.value /
                          CreateStoryController.maxRecordingSeconds,
                      strokeWidth: 4,
                      color: Colors.red,
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                  ),

                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: controller.isRecording.value
                        ? Colors.red
                        : Colors.white.withOpacity(0.3),
                  ),
                  child: controller.isRecording.value
                      ? const Center(
                          child: Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 30,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInstructionText() {
    return Obx(() {
      if (!controller.isRecording.value) {
        return Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Toca para foto • Mantén para video',
              style: GoogleFonts.rubik(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildPreviewScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => controller.selectText(null),
        child: Stack(
          children: [
            RepaintBoundary(
              key: controller.repaintBoundaryKey,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Obx(() {
                      if (controller.contentType.value == CreateStoryController.kVideo) {
                        if (!controller.isVideoReady.value) {
                          return Container(
                            color: Colors.black,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Preparando video...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final videoCtrl = controller.videoController;
                        if (videoCtrl != null &&
                            videoCtrl.value.isInitialized) {
                          return Center(
                            child: AspectRatio(
                              aspectRatio: videoCtrl.value.aspectRatio,
                              child: VideoPlayer(videoCtrl),
                            ),
                          );
                        }
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                      return _buildImagePreview();
                    }),
                  ),
                  Positioned.fill(
                    child: Obx(() => CustomPaint(painter: StrokesPainter(controller.strokes.toList()))),
                  ),
                  ...controller.stickers.map((sticker) {
                    return Obx(() => DraggableSticker(
                          sticker: sticker,
                          selected: controller.selectedStickerId.value == sticker.id,
                          onMoved: (p) => controller.moveSticker(sticker.id, p),
                          onScaled: (s) => controller.scaleSticker(sticker.id, s),
                          onTap: () {
                            controller.selectedStickerId.value = sticker.id;
                            controller.selectText(null);
                          },
                        ));
                  }),
                  ...controller.storyTexts.map((storyText) {
                    return Obx(() {
                      return DraggableStoryText(
                        style: storyText.style,
                        text: storyText.text,
                        color: storyText.color,
                        position: storyText.position,
                        scale: storyText.scale,
                        isSelected:
                            controller.selectedTextId.value == storyText.id,
                        onPositionChanged: (newPosition) {
                          controller.updateTextPosition(
                            storyText.id,
                            newPosition,
                          );
                        },
                        onScaleChanged: (newScale) {
                          controller.updateTextScale(storyText.id, newScale);
                        },
                        onTap: () => controller.selectText(storyText.id),
                        onLongPress: () =>
                            controller.openTextEditor(textId: storyText.id),
                      );
                    });
                  }).toList(),
                ],
              ),
            ),

            // Modo dibujo: captura los dedos por encima de todo
            Obx(() => controller.activeTool.value == 'draw'
                ? Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (d) => controller.startStroke(_norm(d.localPosition)),
                      onPanUpdate: (d) => controller.extendStroke(_norm(d.localPosition)),
                      child: const SizedBox.expand(),
                    ),
                  )
                : const SizedBox.shrink()),

            _buildPreviewHeader(),

            _buildAddTextButton(),

            _buildToolBar(),

            Obx(
              () => controller.isEditingText.value
                  ? _FullscreenTextEditorOverlay(controller: controller)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildPreviewHeader() {
  return Positioned(
    top: 0, left: 0, right: 0,
    child: SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => controller.clearCapture(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
            Obx(() { 
              final isPhoto = controller.contentType.value == CreateStoryController.kImagen;
              final isVideoReady = controller.isVideoReady.value;
              final showPublish = isPhoto || isVideoReady;

              if (!showPublish) return const SizedBox.shrink();

              if (storyController.isCreatingStory.value) {
                return const CircularProgressIndicator(color: Colors.white);
              }

              return GestureDetector(
                onTap: _publishStory,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: ThemeColor.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.send, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Publicar',
                        style: GoogleFonts.rubik(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildAddTextButton() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: Obx(() {
        return Column(
          children: [
            // En fotos y historias de texto, el botón de texto está en la barra de herramientas
            if (controller.contentType.value == CreateStoryController.kVideo)
            GestureDetector(
              onTap: () => controller.openTextEditor(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.text_fields,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            if (controller.selectedTextId.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GestureDetector(
                  onTap: () {
                    controller.removeText(controller.selectedTextId.value!);
                    controller.selectText(null);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildImagePreview() {
    if (controller.capturedFile.value == null) return const SizedBox.shrink();

    if (controller.isTextStory.value) {
      final bg = PostBackground.of(controller.bgId.value) ?? PostBackground.all.first;
      return Container(decoration: BoxDecoration(gradient: bg.gradient));
    }

    return Center(
      child: StoryFilters.apply(
        controller.filterId.value,
        Image.file(controller.capturedFile.value!, fit: BoxFit.contain),
      ),
    );
  }

  /// Punto táctil -> coordenadas relativas a la pantalla.
  Offset _norm(Offset p) {
    final size = MediaQuery.of(context).size;
    return Offset((p.dx / size.width).clamp(0.0, 1.0), (p.dy / size.height).clamp(0.0, 1.0));
  }

  Widget _toolButton(IconData icon, VoidCallback onTap, {bool active = false, String? tooltip}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: active ? Colors.black : Colors.white, size: 23),
        ),
      ),
    );
  }

  /// Herramientas a la derecha (texto, stickers, dibujo, filtros y fondo) y barra inferior de la herramienta activa.
  Widget _buildToolBar() {
    return Obx(() {
      final tool = controller.activeTool.value;
      final isPhoto = controller.contentType.value == CreateStoryController.kImagen;
      final isText = controller.isTextStory.value;

      return Stack(
        children: [
          if (isPhoto)
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              right: 16,
              child: Column(
                children: [
                  _toolButton(Icons.text_fields, () => controller.openTextEditor()),
                  _toolButton(LucideIcons.smile, () async {
                    final kind = await showStickerSheet(context);
                    if (kind == null) return;
                    if (kind == 'location' || kind == 'tag') {
                      final text = await _askText(kind == 'location' ? 'Ubicación' : 'Etiqueta');
                      if (text == null || text.isEmpty) return;
                      controller.addSticker(StorySticker(kind: kind, text: kind == 'tag' && !text.startsWith('#') ? '#$text' : text, position: const Offset(0.5, 0.35)));
                    } else {
                      controller.addSticker(StorySticker(kind: kind, position: const Offset(0.5, 0.4)));
                    }
                  }),
                  _toolButton(LucideIcons.pencil, () => controller.toggleTool('draw'), active: tool == 'draw'),
                  if (!isText) _toolButton(LucideIcons.wandSparkles, () => controller.toggleTool('filter'), active: tool == 'filter'),
                  if (isText) _toolButton(LucideIcons.palette, () => controller.toggleTool('bg'), active: tool == 'bg'),
                  if (controller.selectedStickerId.value != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => controller.removeSticker(controller.selectedStickerId.value!),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.85), shape: BoxShape.circle),
                          child: const Icon(Icons.delete, color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (isPhoto && tool != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.75)]),
                ),
                child: tool == 'filter' ? _filterStrip() : (tool == 'bg' ? _bgStrip() : _drawBar()),
              ),
            ),
        ],
      );
    });
  }

  Future<String?> _askText(String title) {
    final input = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16171B),
        title: Text(title, style: GoogleFonts.rubik(color: Colors.white)),
        content: TextField(
          controller: input,
          autofocus: true,
          maxLength: 40,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(counterText: ''),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(input.text.trim()), child: const Text('Listo')),
        ],
      ),
    );
  }

  Widget _filterStrip() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: StoryFilters.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final f = StoryFilters.all[i];
          return Obx(() {
            final selected = controller.filterId.value == f.id;
            return GestureDetector(
              onTap: () => controller.filterId.value = f.id,
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? Colors.white : Colors.white24, width: selected ? 2.5 : 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: StoryFilters.apply(f.id, Image.file(controller.capturedFile.value!, fit: BoxFit.cover, cacheWidth: 160)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(f.label, style: GoogleFonts.rubik(color: selected ? Colors.white : Colors.white60, fontSize: 11.5, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _bgStrip() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final bg in PostBackground.all)
            Obx(() => GestureDetector(
                  onTap: () => controller.bgId.value = bg.id,
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 10, top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: bg.gradient,
                      border: Border.all(color: controller.bgId.value == bg.id ? Colors.white : Colors.white24, width: controller.bgId.value == bg.id ? 3 : 1.2),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  static const List<Color> _brushColors = [
    Colors.white, Colors.black, Color(0xFFFF3B55), Color(0xFFFF9A1F), Color(0xFFFFE14D), Color(0xFF3DDC97), Color(0xFF3AB0FF), Color(0xFFB86CFF), Color(0xFFFF8FB1),
  ];

  Widget _drawBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final c in _brushColors)
                      Obx(() => GestureDetector(
                            onTap: () => controller.brushColor.value = c,
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 10, top: 4),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(color: controller.brushColor.value == c ? Colors.white : Colors.white38, width: controller.brushColor.value == c ? 3 : 1.2),
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ),
            IconButton(onPressed: controller.undoStroke, icon: const Icon(LucideIcons.undo2, color: Colors.white)),
            TextButton(onPressed: () => controller.activeTool.value = null, child: Text('Listo', style: GoogleFonts.rubik(color: Colors.white, fontWeight: FontWeight.w600))),
          ],
        ),
        Obx(() => Slider(
              value: controller.brushSize.value,
              min: 3,
              max: 26,
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
              onChanged: (v) => controller.brushSize.value = v,
            )),
      ],
    );
  }

  void _showDeleteTextDialog(String textId) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          '¿Eliminar texto?',
          style: GoogleFonts.rubik(color: Colors.white),
        ),
        content: Text(
          'Este texto será eliminado de la historia',
          style: GoogleFonts.rubik(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: GoogleFonts.rubik(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.removeText(textId);
              controller.selectText(null);
              Get.back();
            },
            child: Text(
              'Eliminar',
              style: GoogleFonts.rubik(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenTextEditorOverlay extends StatefulWidget {
  final CreateStoryController controller;
  const _FullscreenTextEditorOverlay({required this.controller});

  @override
  State<_FullscreenTextEditorOverlay> createState() =>
      _FullscreenTextEditorOverlayState();
}

class _FullscreenTextEditorOverlayState
    extends State<_FullscreenTextEditorOverlay> {
  late final TextEditingController _textCtrl;

  final List<Color> _colors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.deepPurple,
    const Color(0xFFA2845E),
  ];

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(
      text: widget.controller.currentEditText.value,
    );
    _textCtrl.selection = TextSelection.collapsed(
      offset: _textCtrl.text.length,
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            widget.controller.isEditingText.value = false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                      const Spacer(),

                      ...['left', 'center', 'right'].map((a) {
                        return Obx(() {
                          final isActive =
                              widget.controller.currentEditAlign.value == a;
                          final icon = a == 'left'
                              ? Icons.format_align_left
                              : a == 'center'
                              ? Icons.format_align_center
                              : Icons.format_align_right;
                          return GestureDetector(
                            onTap: () =>
                                widget.controller.currentEditAlign.value = a,
                            child: Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withOpacity(0.35)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.25),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(icon, color: Colors.white, size: 16),
                            ),
                          );
                        });
                      }).toList(),

                      const Spacer(),

                      GestureDetector(
                        onTap: () =>
                            widget.controller.confirmTextEdit(_textCtrl.text),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Listo',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Obx(() {
                      final style = widget.controller.currentEditStyle.value;
                      final color = widget.controller.currentEditColor.value;
                      final align = widget.controller.currentEditAlign.value;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: style != 'none'
                            ? const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              )
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: style == 'pill'
                              ? Colors.black.withOpacity(0.6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: style == 'outline'
                              ? Border.all(color: color, width: 2.5)
                              : null,
                        ),
                        child: TextField(
                          controller: _textCtrl,
                          autofocus: true,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          textAlign: align == 'left'
                              ? TextAlign.left
                              : align == 'right'
                              ? TextAlign.right
                              : TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            shadows: style == 'neon'
                                ? [Shadow(color: color, blurRadius: 8), Shadow(color: color, blurRadius: 20)]
                                : style == 'outline'
                                ? []
                                : [
                                    Shadow(
                                      color: color == Colors.black
                                          ? Colors.white.withOpacity(0.4)
                                          : Colors.black.withOpacity(0.8),
                                      offset: const Offset(1, 1),
                                      blurRadius: 4,
                                    ),
                                  ],
                          ),
                          decoration: InputDecoration(
                            hintText: 'Escribe algo...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: true,
                            fillColor: Colors.transparent,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        [
                          {'id': 'none', 'label': 'Sin fondo'},
                          {'id': 'pill', 'label': 'Con fondo'},
                          {'id': 'outline', 'label': 'Contorno'},
                          {'id': 'neon', 'label': 'Neón'},
                        ].map((s) {
                          return Obx(() {
                            final isActive =
                                widget.controller.currentEditStyle.value ==
                                s['id'];
                            return GestureDetector(
                              onTap: () =>
                                  widget.controller.currentEditStyle.value =
                                      s['id']!,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white.withOpacity(0.25)
                                      : Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  s['label']!,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.55),
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          });
                        }).toList(),
                  ),
                ),

                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _colors.length,
                    itemBuilder: (ctx, i) {
                      final c = _colors[i];
                      return Obx(() {
                        final isSelected =
                            widget.controller.currentEditColor.value == c;
                        return GestureDetector(
                          onTap: () =>
                              widget.controller.currentEditColor.value = c,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: isSelected ? 38 : 32,
                            height: isSelected ? 38 : 32,
                            margin: EdgeInsets.only(
                              right: 10,
                              top: isSelected ? 0 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white38,
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: c.withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
