import 'package:tendria/features/stories/presentation/page/story_extras.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

import 'package:image_picker/image_picker.dart';
  
class StoryText {
  final String text;
  final Color color;
  Offset position;
  double scale;
  final String id;
  final String style;

  StoryText({
    required this.text,
    required this.color,
    required this.position,
    this.scale = 1.0,
    this.style = 'none',
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  StoryText copyWith({
    String? text,
    Color? color,
    Offset? position,
    double? scale,
    String? style,
  }) {
    return StoryText(
      text: text ?? this.text,
      color: color ?? this.color,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      style: style ?? this.style,
      id: id,
    );
  }
}
 
class CreateStoryController extends GetxController {
  
  Rx<CameraController?> cameraController = Rx<CameraController?>(null);
  final RxList<CameraDescription> cameras = <CameraDescription>[].obs;
  final RxBool isCameraInitialized = false.obs;
  final RxBool isFrontCamera = false.obs;

 
  final RxBool isRecording = false.obs;
  final RxInt recordingSeconds = 0.obs;
  Timer? recordingTimer;
  static const int maxRecordingSeconds = 30;
 
  final Rx<File?> capturedFile = Rx<File?>(null);
  final Rx<String?> contentType = Rx<String?>(null);
  VideoPlayerController? videoController;
 
  final RxBool isVideoReady = false.obs;
 
  final RxList<AssetEntity> galleryAssets = <AssetEntity>[].obs;
  final RxBool isLoadingGallery = false.obs;
 
  final RxList<StoryText> storyTexts = <StoryText>[].obs;
  final Rx<String?> selectedTextId = Rx<String?>(null);

  final GlobalKey repaintBoundaryKey = GlobalKey();

  // ---- personalización ----
  /// Historia solo de texto: fondo de color en lugar de una foto
  final RxBool isTextStory = false.obs;
  final RxString bgId = 'sunset'.obs;
  final RxString filterId = 'none'.obs;
  final RxList<StorySticker> stickers = <StorySticker>[].obs;
  final Rxn<String> selectedStickerId = Rxn<String>();
  final RxList<StoryStroke> strokes = <StoryStroke>[].obs;
  final Rx<Color> brushColor = Colors.white.obs;
  final RxDouble brushSize = 7.0.obs;

  /// Herramienta abierta: filter | draw | bg | null
  final RxnString activeTool = RxnString();

  /// ¿Hay algo que "hornear" en la imagen final? (textos, stickers, dibujo, filtro o fondo de color)
  bool get needsBaking =>
      storyTexts.isNotEmpty ||
      (_isImagen && (isTextStory.value || stickers.isNotEmpty || strokes.isNotEmpty || filterId.value != 'none'));
  final RxBool isProcessingVideo = false.obs;
 
  final RxBool isEditingText = false.obs;
  final RxString editingTextId = ''.obs;
  final RxString currentEditText = ''.obs;
  final Rx<Color> currentEditColor = Colors.white.obs;
  final RxString currentEditAlign = 'center'.obs;
  final RxString currentEditStyle = 'none'.obs;
  final RxBool _isDraggingText = false.obs;
 
  double previewScreenWidth  = 0;
  double previewScreenHeight = 0;
 
  static const String kVideo  = 'Video';
  static const String kImagen = 'Foto';

  bool get _isVideo  => contentType.value == kVideo;
  bool get _isImagen => contentType.value == kImagen;

  // 1x1 transparente: sirve de "archivo" base para una historia de solo texto
  static const String _blankPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

  Future<void> startTextStory() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/text_story_base_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(base64Decode(_blankPngBase64));
    isTextStory.value = true;
    contentType.value = kImagen;
    capturedFile.value = file;
    activeTool.value = 'bg';
    openTextEditor();
  }

  void addSticker(StorySticker sticker) {
    stickers.add(sticker);
    selectedStickerId.value = sticker.id;
    selectedTextId.value = null;
  }

  void removeSticker(String id) {
    stickers.removeWhere((s) => s.id == id);
    if (selectedStickerId.value == id) selectedStickerId.value = null;
  }

  void moveSticker(String id, Offset position) {
    final i = stickers.indexWhere((s) => s.id == id);
    if (i != -1) stickers[i].position = position;
  }

  void scaleSticker(String id, double scale) {
    final i = stickers.indexWhere((s) => s.id == id);
    if (i != -1) stickers[i].scale = scale;
  }

  void startStroke(Offset p) {
    strokes.add(StoryStroke(color: brushColor.value, width: brushSize.value, points: [p]));
  }

  void extendStroke(Offset p) {
    if (strokes.isEmpty) return;
    strokes.last.points.add(p);
    strokes.refresh();
  }

  void undoStroke() {
    if (strokes.isNotEmpty) strokes.removeLast();
  }

  void toggleTool(String tool) {
    activeTool.value = activeTool.value == tool ? null : tool;
    if (activeTool.value == 'draw') {
      selectedTextId.value = null;
      selectedStickerId.value = null;
    }
  }
  

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
    loadGalleryAssets();
  }

  @override
  void onClose() {
    cameraController.value?.dispose();
    videoController?.dispose();
    recordingTimer?.cancel();
    super.onClose();
  }
 

  void openTextEditor({String? textId}) {
    if (textId != null) {
      final existing = storyTexts.firstWhereOrNull((t) => t.id == textId);
      if (existing != null) {
        editingTextId.value = textId;
        currentEditText.value = existing.text;
        currentEditColor.value = existing.color;
        currentEditStyle.value = existing.style;
        currentEditAlign.value = 'center';
      }
    } else {
      editingTextId.value = '';
      currentEditText.value = '';
      currentEditColor.value = Colors.white;
      currentEditAlign.value = 'center';
      currentEditStyle.value = 'none';
    }
    isEditingText.value = true;
  }

  void confirmTextEdit(String text) {
    if (text.trim().isEmpty) {
      isEditingText.value = false;
      return;
    }
    if (editingTextId.value.isNotEmpty) {
      final idx = storyTexts.indexWhere((t) => t.id == editingTextId.value);
      if (idx >= 0) {
        storyTexts[idx] = storyTexts[idx].copyWith(
          text: text,
          color: currentEditColor.value,
          style: currentEditStyle.value,
        );
        storyTexts.refresh();
      }
    } else {
      addText(
        text,
        currentEditColor.value,
        const Offset(0.5, 0.45),
        1.0,
        style: currentEditStyle.value,
      );
    }
    isEditingText.value = false;
  }

  void addText(
    String text,
    Color color,
    Offset position,
    double scale, {
    String style = 'none',
  }) {
    storyTexts.add(StoryText(
      text: text,
      color: color,
      position: position,
      scale: scale,
      style: style,
    ));
  }

  void updateTextPosition(String textId, Offset newPosition) {
    final index = storyTexts.indexWhere((t) => t.id == textId);
    if (index != -1) {
      storyTexts[index].position = newPosition;
      storyTexts.refresh();
    }
  }

  void updateTextScale(String textId, double newScale) {
    final index = storyTexts.indexWhere((t) => t.id == textId);
    if (index != -1) {
      storyTexts[index].scale = newScale;
      storyTexts.refresh();
    }
  }

  void removeText(String textId) {
    storyTexts.removeWhere((t) => t.id == textId);
  }

  void selectText(String? textId) {
    selectedTextId.value = textId;
  }
 

Future<File?> captureStoryWithTexts() async {
  debugPrint('═══════════════════════════════════');
  debugPrint('📸 captureStoryWithTexts()');
  debugPrint('   contentType   = ${contentType.value}');
  debugPrint('   storyTexts    = ${storyTexts.length}');
  debugPrint('   capturedFile  = ${capturedFile.value?.path}');
  debugPrint('   previewScreen = ${previewScreenWidth}x$previewScreenHeight');
  debugPrint('═══════════════════════════════════');

  try {
    if (!needsBaking) {
      debugPrint('ℹ️ Nada que combinar, devolviendo original');
      return capturedFile.value;
    }

    if (_isVideo) {
      debugPrint('🎬 VIDEO → processVideoWithTexts()');
      return await processVideoWithTexts(); 
    }

    debugPrint('🖼️ IMAGEN → _captureImageWithTexts()');
    return await _captureImageWithTexts();
  } catch (e, st) {
    debugPrint('💥 captureStoryWithTexts error: $e\n$st');
    return capturedFile.value;
  }
}

  Future<File?> _captureImageWithTexts() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;

    if (boundary == null) {
      debugPrint('❌ RepaintBoundary not found');
      return capturedFile.value;
    }

    final image    = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      debugPrint('❌ Failed to convert image to bytes');
      return capturedFile.value;
    }

    final pngBytes  = byteData.buffer.asUint8List();
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imagePath = '${directory.path}/story_with_text_$timestamp.png';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(pngBytes);

    debugPrint('✅ Story image saved: $imagePath');
    return imageFile;
  }
 

  Future<File?> processVideoWithTexts() async {
    if (capturedFile.value == null || storyTexts.isEmpty) {
      debugPrint('❌ processVideoWithTexts: no file or no texts');
      return capturedFile.value;
    }

    try {
      isProcessingVideo.value = true;

      final inputFile = capturedFile.value!;

      if (!await inputFile.exists()) {
        debugPrint('❌ Input file does not exist: ${inputFile.path}');
        isProcessingVideo.value = false;
        return capturedFile.value;
      }

      final inputSize = await inputFile.length();
      debugPrint('📥 Input: ${inputFile.path}');
      debugPrint('📦 Input: ${(inputSize / 1024 / 1024).toStringAsFixed(2)} MB');

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/story_video_$timestamp.mp4';
 
      double videoWidth  = 1080;
      double videoHeight = 1920;

      if (videoController != null && videoController!.value.isInitialized) {
        videoWidth  = videoController!.value.size.width;
        videoHeight = videoController!.value.size.height;
        debugPrint('📐 Video real: ${videoWidth}x$videoHeight');
      } else {
        debugPrint('⚠️ VideoController no inicializado, usando ${videoWidth}x$videoHeight por defecto');
      }
 
      final double screenW =
          previewScreenWidth  > 0 ? previewScreenWidth  : 390.0;
      final double screenH =
          previewScreenHeight > 0 ? previewScreenHeight : 844.0;

      final double scaleX = videoWidth  / screenW;
      final double scaleY = videoHeight / screenH;

      debugPrint('📐 Pantalla lógica : ${screenW}x$screenH');
      debugPrint('📐 scaleX=$scaleX  scaleY=$scaleY');
 
      const fontPath = '/system/fonts/Roboto-Regular.ttf';
      final List<String> textFilters = [];

      for (int i = 0; i < storyTexts.length; i++) {
        final st = storyTexts[i];
 
        final int xPos = (st.position.dx * videoWidth).toInt();
        final int yPos = (st.position.dy * videoHeight).toInt();

        final String colorHex = st.color.value
            .toRadixString(16)
            .padLeft(8, '0')
            .substring(2);
 
        final double fontSizeF = 28.0 * st.scale * scaleX;
        final int    fontSize  = fontSizeF.clamp(10.0, 600.0).toInt();

        debugPrint('  [texto $i] "${st.text}"  pos=(${st.position.dx.toStringAsFixed(2)},${st.position.dy.toStringAsFixed(2)})  scale=${st.scale}  → fontSize=$fontSize');

        final List<String> lines = st.text.split('\n');

        for (int li = 0; li < lines.length; li++) {
          String cleanLine = lines[li]
              .replaceAll('\\', '')
              .replaceAll("'", '')
              .replaceAll('"', '')
              .replaceAll(':', ' ')
              .replaceAll('%', ' ')
              .trim();

          if (cleanLine.isEmpty) continue;

          final int lineYPos = yPos + (li * (fontSize + 4));

          textFilters.add(
            'drawtext='
            'fontfile=$fontPath:'
            "text='$cleanLine':"
            'fontsize=$fontSize:'
            'fontcolor=$colorHex:'
            'x=$xPos:'
            'y=$lineYPos:'
            'shadowcolor=black@0.8:'
            'shadowx=2:'
            'shadowy=2:'
            'borderw=3:'
            'bordercolor=black@0.9',
          );
        }
      }

      if (textFilters.isEmpty) {
        debugPrint('⚠️ No valid text filters, returning original');
        isProcessingVideo.value = false;
        return capturedFile.value;
      }

      final String allFilters = textFilters.join(',');
      debugPrint('🔧 ${textFilters.length} filtro(s) generados');
 
      final String command =
          '-i "${inputFile.path}" '
          '-vf "$allFilters" '
          '-c:v libx264 '
          '-preset ultrafast '
          '-c:a copy '
          '-y "$outputPath"';

      debugPrint('🚀 Ejecutando FFmpeg...');

      FFmpegKitConfig.enableLogCallback((log) {
        debugPrint('[FFmpeg] ${log.getMessage()}');
      });

      final session    = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final logs       = await session.getAllLogsAsString();

      debugPrint('📊 FFmpeg return code: ${returnCode?.getValue()}');

      if (!ReturnCode.isSuccess(returnCode)) {
        debugPrint('❌ FFmpeg FAILED');
        debugPrint('📋 Logs:\n$logs');
        isProcessingVideo.value = false;
        return capturedFile.value;
      }

      final outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        debugPrint('❌ Output file not found');
        isProcessingVideo.value = false;
        return capturedFile.value;
      }

      final outputSize = await outputFile.length();
      debugPrint('✅ FFmpeg completado');
      debugPrint('📦 Output: $outputPath (${(outputSize / 1024 / 1024).toStringAsFixed(2)} MB)');

      isProcessingVideo.value = false;
      return outputFile;
    } catch (e, st) {
      debugPrint('💥 processVideoWithTexts error: $e\n$st');
      isProcessingVideo.value = false;
      return capturedFile.value;
    }
  }
 

Future<void> initializeCamera() async {
  try {
    isCameraInitialized.value = false;

    final availableCamerasList = await availableCameras();
    if (availableCamerasList.isEmpty) {
      debugPrint('❌ No se encontraron cámaras');
      return;
    }

    cameras.value = availableCamerasList;
    final camera = _getCamera();

    final newController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await newController.initialize();
    await newController.lockCaptureOrientation(DeviceOrientation.portraitUp);
    await Future.delayed(const Duration(milliseconds: 100));

    if (newController.value.isInitialized) {
      cameraController.value = newController;
      await Future.delayed(const Duration(milliseconds: 50));
      isCameraInitialized.value = true;
      debugPrint('✅ Cámara inicializada');
    }
  } on CameraException catch (e) {
    debugPrint('💥 CameraException: ${e.code} - ${e.description}');
    isCameraInitialized.value = false;
    showErrorSnackbar('Error al iniciar la cámara: ${e.description}');
  } catch (e) {
    debugPrint('💥 Error: $e');
    isCameraInitialized.value = false;
  }
}

  CameraDescription _getCamera() {
    final direction = isFrontCamera.value
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    final match =
        cameras.firstWhereOrNull((c) => c.lensDirection == direction);

    if (match == null) {
      isFrontCamera.value = !isFrontCamera.value;
      return cameras.first;
    }

    debugPrint('📷 Usando cámara: ${match.name} - ${match.lensDirection}');
    return match;
  }

  Future<void> switchCamera() async {
    if (cameras.length < 2) return;
    isFrontCamera.value = !isFrontCamera.value;
    final old = cameraController.value;
    cameraController.value = null;
    await old?.dispose();
    await initializeCamera();
  }
 

  Future<void> startRecording() async {
    if (cameraController.value == null ||
        !cameraController.value!.value.isInitialized) return;
    if (isRecording.value) return;

    try {
      await cameraController.value!.startVideoRecording();
      isRecording.value = true;
      recordingSeconds.value = 0;

      recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (recordingSeconds.value >= maxRecordingSeconds) {
          stopRecording();
        } else {
          recordingSeconds.value++;
        }
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording.value) return;

    try {
      recordingTimer?.cancel();
      final XFile video = await cameraController.value!.stopVideoRecording();

      debugPrint('📹 Video grabado: ${video.path}');

      final File tempFile = File(video.path);
      showInfoSnackbar('Procesando video...');

      final File? mp4File = await convertToMp4(tempFile);
      final File finalFile = mp4File ?? tempFile;

      isRecording.value = false;
      recordingSeconds.value = 0;
      capturedFile.value = finalFile;
      contentType.value = kVideo;

      debugPrint('📌 contentType = ${contentType.value}');
      debugPrint('📌 capturedFile = ${capturedFile.value?.path}');

      await initializeVideoController();
    } catch (e) {
      debugPrint('❌ Error deteniendo grabación: $e');
      isRecording.value = false;
      showErrorSnackbar('Error al procesar el video');
    }
  }

  Future<void> takePicture() async {
    if (cameraController.value == null ||
        !cameraController.value!.value.isInitialized) return;

    try {
      final XFile photo = await cameraController.value!.takePicture();
      capturedFile.value = File(photo.path);
      contentType.value = kImagen;
      debugPrint('📌 contentType = ${contentType.value}');
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  void clearCapture() {
    capturedFile.value = null;
    contentType.value = null;
    videoController?.dispose();
    videoController = null;
    isVideoReady.value = false;
    storyTexts.clear();
    selectedTextId.value = null;
    isTextStory.value = false;
    bgId.value = 'sunset';
    filterId.value = 'none';
    stickers.clear();
    selectedStickerId.value = null;
    strokes.clear();
    activeTool.value = null;
    previewScreenWidth  = 0;
    previewScreenHeight = 0;
  } 

  Future<void> loadGalleryAssets() async {
    isLoadingGallery.value = true;

    final permission = await PhotoManager.requestPermissionExtend();

    if (permission.isAuth) {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        final media = await albums[0].getAssetListRange(start: 0, end: 20);
        galleryAssets.value = media;
      }
    }

    isLoadingGallery.value = false;
  }
Future<void> selectFromGallery(AssetEntity asset) async {
  try {
    final File? file = await asset.file;
    if (file == null) return;

    contentType.value =
        asset.type == AssetType.image ? kImagen : kVideo;

    debugPrint('📌 contentType = ${contentType.value}');

    if (contentType.value == kVideo) { 
      capturedFile.value = file;
      showInfoSnackbar('Procesando video...');
 
      final File? mp4File = await convertToMp4(file);
      capturedFile.value = mp4File ?? file;

      debugPrint('📌 capturedFile = ${capturedFile.value?.path}');
      await initializeVideoController();
    } else { 
      final File? pngFile = await convertToPng(file);
      capturedFile.value = pngFile ?? file;
      debugPrint('📌 capturedFile = ${capturedFile.value?.path}');
    }
  } catch (e) {
    debugPrint('Error selecting from gallery: $e');
    showErrorSnackbar('No se pudo seleccionar el archivo');
  }
}
Future<void> selectFromImagePicker() async {
  try {
    final picker = ImagePicker();
    final XFile? file = await picker.pickMedia();
    if (file == null) return;

    final path = file.path.toLowerCase();
    final isVid = path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv') ||
        path.endsWith('.hevc');

    contentType.value = isVid ? kVideo : kImagen;
    debugPrint('📌 contentType = ${contentType.value}');

    if (isVid) {
      capturedFile.value = File(file.path);
      showInfoSnackbar('Procesando video...');
      final File? mp4File = await convertToMp4(File(file.path));
      capturedFile.value = mp4File ?? File(file.path);
      debugPrint('📌 capturedFile = ${capturedFile.value?.path}');
      await initializeVideoController();
    } else {
      final File? pngFile = await convertToPng(File(file.path));
      capturedFile.value = pngFile ?? File(file.path);
      debugPrint('📌 capturedFile = ${capturedFile.value?.path}');
    }
  } catch (e) {
    debugPrint('Error seleccionando de galería: $e');
    showErrorSnackbar('No se pudo seleccionar el archivo');
  }
}
 

  Future<void> initializeVideoController() async {
    if (capturedFile.value == null || contentType.value != kVideo) return;

    try {
      isVideoReady.value = false;
      videoController?.dispose();
      videoController = null;

      debugPrint('🎬 Inicializando video: ${capturedFile.value!.path}');

      if (!await capturedFile.value!.exists()) {
        debugPrint('❌ El archivo de video no existe');
        return;
      }

      final fileSize = await capturedFile.value!.length();
      debugPrint(
          '📦 Tamaño: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      videoController = VideoPlayerController.file(capturedFile.value!);

      await videoController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Timeout inicializando video');
          throw TimeoutException('Video initialization timeout');
        },
      );

      if (videoController!.value.isInitialized) {
        videoController!.setLooping(true);
        await videoController!.play();
        isVideoReady.value = true;

        debugPrint('✅ Video inicializado');
        debugPrint('   Duración:    ${videoController!.value.duration}');
        debugPrint('   Tamaño:      ${videoController!.value.size}');
        debugPrint('   AspectRatio: ${videoController!.value.aspectRatio}');
      } else {
        debugPrint('❌ Video no se pudo inicializar');
      }
    } catch (e, st) {
      debugPrint('💥 Error inicializando video: $e\n$st');
      videoController?.dispose();
      videoController = null;
      isVideoReady.value = false;
      showErrorSnackbar('No se pudo cargar el video. Intenta de nuevo.');
    }
  }
 

  Future<File?> convertToMp4(File inputFile) async {
    try {
      debugPrint('🔄 Convirtiendo a MP4: ${inputFile.path}');

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/video_$timestamp.mp4';

      final command =
          '-i "${inputFile.path}" '
          '-c:v libx264 '
          '-preset ultrafast '
          '-c:a aac '
          '-strict experimental '
          '-y "$outputPath"';

      final session    = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          debugPrint('✅ Convertido a MP4: $outputPath');
          return outputFile;
        }
      }

      debugPrint('❌ convertToMp4 falló');
      return null;
    } catch (e) {
      debugPrint('💥 convertToMp4 error: $e');
      return null;
    }
  }

  Future<File?> convertToPng(File inputFile) async {
    try {
      final ext = inputFile.path.toLowerCase().split('.').last;
      if (ext == 'png') return inputFile;

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/story_$timestamp.png';

      final command    = '-i "${inputFile.path}" -y "$outputPath"';
      final session    = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        if (await outputFile.exists()) return outputFile;
      }

      return inputFile;
    } catch (e) {
      return inputFile;
    }
  }
 

  void handleAppLifecycleState(AppLifecycleState state) {
    if (cameraController.value == null ||
        !cameraController.value!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.value?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initializeCamera();
    }
  }
}