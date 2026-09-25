import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tendria/common/constants/constants.dart';
import 'package:tendria/common/settings/language_controller.dart';

enum TutorialAnchor { top, bottom, left, right }

class StartTutorialStep {
  final String message;
  final GlobalKey? targetKey;
  final TutorialAnchor anchor;

  const StartTutorialStep({
    required this.message,
    this.targetKey,
    this.anchor = TutorialAnchor.bottom,
  });
}

class StartTutorialController extends GetxController {
  final RxBool isVisible      = false.obs;
  final RxInt  currentStep    = 0.obs;
  final RxBool isAnimatingOut = false.obs;

  /// Las GlobalKey solo se enlazan a la interfaz mientras el tutorial siga pendiente.
  /// Si dos pantallas de inicio coinciden (p. ej. al navegar con Get.offAllNamed) y comparten llaves, Flutter falla.
  final RxBool pending = true.obs;

  final GlobalKey navProfileKey  = GlobalKey();
  final GlobalKey navRadarKey    = GlobalKey();
  final GlobalKey navMatchKey    = GlobalKey();
  final GlobalKey navChatKey     = GlobalKey();
  final GlobalKey panicButtonKey = GlobalKey();

  late final List<StartTutorialStep> steps;

  static const String _prefKey =  AppConstants.startTutorialKey;  

@override
void onInit() {
  super.onInit();
  SharedPreferences.getInstance().then((prefs) {
    pending.value = !(prefs.getBool(_prefKey) ?? false);
  });
  final l = Get.find<LanguageController>();
  steps = [
    StartTutorialStep(
      message: l.t('tutorial_start_radar'),
      targetKey: navRadarKey, // botón de radar en la barra superior del Feed
      anchor: TutorialAnchor.bottom,
    ),
    StartTutorialStep(
      message: l.t('tutorial_start_match'),
      targetKey: navMatchKey,
      anchor: TutorialAnchor.top,
    ),
    StartTutorialStep(
      message: l.t('tutorial_start_chat'),
      targetKey: navChatKey,
      anchor: TutorialAnchor.top,
    ),
    StartTutorialStep(
      message: l.t('tutorial_start_profile'),
      targetKey: navProfileKey,
      anchor: TutorialAnchor.top,
    ),
    StartTutorialStep(
      message: l.t('tutorial_start_panic'),
      targetKey: panicButtonKey,
      anchor: TutorialAnchor.top,
    ),
  ];
}

  void notifyPageReady() => _checkAndShow();

  Future<void> _checkAndShow() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) ?? false) return;

    await Future.delayed(const Duration(milliseconds: 800));

    if (navProfileKey.currentContext == null) {
      await Future.delayed(const Duration(milliseconds: 400));
    }

    showTutorial();
  }

  void showTutorial() {
    currentStep.value    = 0;
    isAnimatingOut.value = false;
    isVisible.value      = true;
  }

  void nextStep() {
    if (currentStep.value < steps.length - 1) {
      isAnimatingOut.value = true;
      Future.delayed(const Duration(milliseconds: 250), () {
        currentStep.value++;
        isAnimatingOut.value = false;
      });
    } else {
      _complete();
    }
  }

  void skipTutorial() => _complete();

 Future<void> _complete() async {
  isAnimatingOut.value = true;
  await Future.delayed(const Duration(milliseconds: 300));
  isVisible.value      = false;
  isAnimatingOut.value = false;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_prefKey, true);
  
   completed.value = true;
   pending.value = false;
}

final RxBool completed = false.obs;

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
 
 StartTutorialStep get currentStepData {
  if (currentStep.value < 0 || currentStep.value >= steps.length) {
    return steps.last;
  }
  return steps[currentStep.value];
} 
  bool get isLastStep => currentStep.value == steps.length - 1;

  Rect? getTargetRect(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}