import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/tutorial/startTutorial/start_tutorial_controller.dart';
import 'package:tendria/common/tutorial/startTutorial/start_tutorial_overlay.dart';
import 'package:tendria/common/tutorial/tutorialPerfil/profile_tutorial_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/common/widgets/panic_button.dart';
import 'start_controller.dart';


class StartPage extends StatefulWidget {
  const StartPage({Key? key}) : super(key: key);

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  late final StartController controller;
  late final StartTutorialController tutorialCtrl;

  @override
  void initState() {
    super.initState();
    controller   = Get.find<StartController>();
    tutorialCtrl =  Get.find<StartTutorialController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tutorialCtrl.notifyPageReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Obx(() => ThemeColor.createMainScaffold(
          body: controller.currentPage,
          currentIndex: controller.navSelected,
          onNavigationTap: controller.onNavTap,
          icons: controller.navIconData,
          labels: controller.navLabels,
          backgroundColor: ThemeColor.backgroundColorfondo,
          bottomNavBackgroundColor: Colors.white, 
          navKeys: tutorialCtrl.pending.value
              ? [
                  null, // Feed
                  tutorialCtrl.navMatchKey,
                  tutorialCtrl.navChatKey,
                  tutorialCtrl.navProfileKey,
                ]
              : null,
          floatingActionButton: KeyedSubtree(
            key: tutorialCtrl.pending.value ? tutorialCtrl.panicButtonKey : null,
            child: const PanicButton(),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        )),
 
        Obx(
          () => tutorialCtrl.isVisible.value
              ? const StartTutorialOverlay()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}