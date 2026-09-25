import 'package:tendria/features/follow/domain/usecase/follow_user_usecase.dart';
import 'package:tendria/features/follow/domain/usecase/unfollow_user_usecase.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/controller/theme_controller.dart';
import 'package:tendria/common/tutorial/startTutorial/start_tutorial_controller.dart';
import 'package:tendria/common/tutorial/tutorialPerfil/profile_tutorial_controller.dart';
import 'package:tendria/common/tutorial/tutorial_controller.dart';
import 'package:tendria/common/tutorial/updateProfile/update_profile_tutorial_controller.dart';
import 'package:tendria/common/routes/router.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/common/services/translation_service.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/theme/App_Theme.dart';
import 'package:tendria/features/auth/presentation/page/Splash/splash_controller.dart';
import 'package:tendria/features/auth/presentation/page/home/start_controller.dart';
import 'package:tendria/features/auth/presentation/page/login/login_controller.dart';
import 'package:tendria/features/auth/presentation/page/register/register_controller.dart';
import 'package:tendria/features/chat/presentation/page/chat_controller.dart';
import 'package:tendria/features/chat/presentation/page/connect.dart';
import 'package:tendria/features/like/presentation/controller/liked_by_users_controller.dart';
import 'package:tendria/features/like/presentation/controller/my_match_controller.dart';
import 'package:tendria/features/like/presentation/controller/start_conversations_controller.dart';
import 'package:tendria/features/notification/presentation/page/notification_controller.dart';
import 'package:tendria/features/page/startPage/start_controller_vip.dart';
import 'package:tendria/features/purchase/presentation/controller/purchase_controller.dart';
import 'package:tendria/features/stories/presentation/page/story_controller.dart';
import 'package:tendria/features/unlock/presentation/controller/blocked_users_controller.dart';
import 'package:tendria/features/user/presentation/controller/balance_controller.dart';
import 'package:tendria/features/user/presentation/controller/nearby_users_controller.dart';
import 'package:tendria/features/user/presentation/controller/preferences_controller.dart';
import 'package:tendria/features/user/presentation/controller/profile_controller.dart';
import 'package:tendria/features/user/presentation/controller/update_profile_controller.dart';
import 'package:tendria/features/user/presentation/controller/user_profile_controller.dart';
import 'package:tendria/features/verifications/presentation/controller/verification_controller.dart';
import 'package:tendria/usecase_config.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

UsecaseConfig usecaseConfig = UsecaseConfig();

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

        Get.lazyPut(() => ThemeController(), fenix: true);
      return Obx(() { 
      final themeCtrl = Get.find<ThemeController>();
      return GetMaterialApp(
      
      locale: const Locale('es', 'ES'),
      supportedLocales: [const Locale('es', 'ES')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 260),
     
        themeMode: themeCtrl.themeMode.value == AppThemeMode.light
        ? ThemeMode.light
        : ThemeMode.dark,
        theme: ThemeColor.themeData,
        darkTheme: ThemeColor.darkThemeData,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthService(), permanent: true);
        Get.put(usecaseConfig.loginUsecase!, permanent: true);
        Get.put(usecaseConfig.createUserUsecase!, permanent: true);
        Get.put(usecaseConfig.fetchInterestsUsecase!, permanent: true);
        Get.put(usecaseConfig.fetchQualitiesUsecase!, permanent: true);
        Get.put(usecaseConfig.postInterestsUsecase!, permanent: true);
        Get.put(usecaseConfig.postQualitiesUsecase!, permanent: true);
        Get.put(usecaseConfig.deleteInterestsUsecase!, permanent: true);
        Get.put(usecaseConfig.deleteQualitiesUsecase!, permanent: true);
        Get.put(usecaseConfig.getUserUsecase!, permanent: true);
        Get.put(usecaseConfig.getBalanceUsecase!, permanent: true);
        Get.put(usecaseConfig.updateUserUsecase!, permanent: true);
        Get.put(usecaseConfig.getUserByIdUsecase!, permanent: true);
        Get.put(usecaseConfig.deleteUserUsecase!, permanent: true);
        Get.put(usecaseConfig.preferencesUserUsecase!, permanent: true);
        Get.put(usecaseConfig.putPreferencesUserUsecase!, permanent: true);
        Get.put(usecaseConfig.createReportsUserUsecase!, permanent: true);
        Get.put(usecaseConfig.deleteMediaUsecase!, permanent: true);
        Get.put(usecaseConfig.uploadMediaUsecase!, permanent: true);
        Get.put(usecaseConfig.uploadPicturePerfileUsecase!, permanent: true);
        Get.put(usecaseConfig.validateCouponsUsecase!, permanent: true);
        Get.put(usecaseConfig.addLikeToStoryUsecase!, permanent: true);
        Get.put(usecaseConfig.createStroryUsecase!, permanent: true);
        Get.put(usecaseConfig.fetchStoriesByIdUsecase!, permanent: true);
        Get.put(usecaseConfig.fetchStoriesUsecase!, permanent: true);
        Get.put(usecaseConfig.removeStoryUsecase!, permanent: true);
        Get.put(usecaseConfig.setStoryAsSeenUsecase!, permanent: true);
        Get.put(usecaseConfig.fetchNearbyUsersUsecase!, permanent: true);
        Get.put(usecaseConfig.getChatMensajeUsecase!, permanent: true);
        Get.put(usecaseConfig.getMyChatsUsecase!, permanent: true);
        Get.put(usecaseConfig.connectSignalRUsecase!, permanent: true);
        Get.put(usecaseConfig.disconnectSignalRUsecase!, permanent: true);
        Get.put(usecaseConfig.joinChatUsecase!, permanent: true);
        Get.put(usecaseConfig.onMensajesLeidosUsecase!, permanent: true);
        Get.put(usecaseConfig.marcarMensajesLeidosUsecase!, permanent: true);
        Get.put(usecaseConfig.leaveChatUsecase!, permanent: true);
        Get.put(
          usecaseConfig.setOnDisconnectedCallbackUsecase!,
          permanent: true,
        );
        Get.put(usecaseConfig.setMessageCallbackUsecase!, permanent: true);
        Get.put(usecaseConfig.startConversationsUsecase!, permanent: true);
        Get.put(usecaseConfig.paymentsChatUsecase!, permanent: true);
        Get.put(usecaseConfig.sendMessageUsecase!, permanent: true);
        Get.put(usecaseConfig.getLikeByUsersUsecase!, permanent: true);
        Get.put(usecaseConfig.getPendingLikedChatsUsecase!, permanent: true);
        Get.put(usecaseConfig.toggleLikeUsecase!, permanent: true);
        Get.put(usecaseConfig.followUserUsecase!, permanent: true);
        Get.put(usecaseConfig.unfollowUserUsecase!, permanent: true);
        Get.put(usecaseConfig.unlockChatUsecase!, permanent: true);
        Get.put(usecaseConfig.fetchBlockedUsersUsecase!, permanent: true);
        Get.put(usecaseConfig.blockUserUsecase!, permanent: true);
        Get.put(usecaseConfig.unblockUserUsecase!, permanent: true);
        Get.put(usecaseConfig.updateLocationUsecase!, permanent: true);
        Get.put(usecaseConfig.searchCityUsecase!, permanent: true);
        Get.put(usecaseConfig.deactivateTripUsecase!, permanent: true);
        Get.put(usecaseConfig.updateCityUsecase!, permanent: true);
        

        Get.put(usecaseConfig.getnotificationUsecase!, permanent: true);
        Get.put(usecaseConfig.markAllNotificationsAsReadUsecase!,permanent: true,);
        Get.put(usecaseConfig.saveTokenFcmUsecase!, permanent: true);
        Get.put(usecaseConfig.purchaseAppleUsecase!, permanent: true);
        Get.put(usecaseConfig.purchaseGoogleUsecase!, permanent: true);
        Get.put(usecaseConfig.purchaseAppleUsecase!, permanent: true);
        Get.put(usecaseConfig.getPurchasesUsecase!, permanent: true);

        Get.put(usecaseConfig.logViewProfileUsecase!, permanent: true);
        Get.put(usecaseConfig.logRegisterUsecase!, permanent: true);
        Get.put(usecaseConfig.logMatchUsecase!, permanent: true);
        Get.put(usecaseConfig.logLoginUsecase!, permanent: true);
        Get.put(usecaseConfig.verificationUsecase!, permanent: true);
        Get.put(usecaseConfig.verificationSelfieUsecase!, permanent: true);
        Get.put(usecaseConfig.getVerificationUsecase!, permanent: true);

        Get.lazyPut(  () => LoginController( loginUsecase: Get.find(),saveTokenFcmUsecase: Get.find(), logLoginUsecase: Get.find(),), fenix: true,);
        Get.put(SignalRService( connectSignalRUsecase: Get.find(),disconnectSignalRUsecase: Get.find(),joinChatUsecase: Get.find(),leaveChatUsecase: Get.find(), setupMessageListenerUsecase: Get.find(),setOnDisconnectedCallbackUsecase: Get.find(),  onMensajesLeidosUsecase: Get.find(),
            marcarMensajesLeidosUsecase: Get.find(), ), permanent: true, );
        Get.lazyPut(() => RegisterController(createUserUsecase: Get.find(), fetchQualitiesUsecase: Get.find(), fetchInterestsUsecase: Get.find(), logRegisterUsecase: Get.find(),), fenix: true,);
        Get.lazyPut(() => SplashController(getUserUsecase: Get.find(),updateLocationUsecase: Get.find(),),fenix: true, );
        Get.lazyPut(() => PreferencesController(preferencesUserUsecase: Get.find(),uploadMediaUsecase: Get.find(),fetchInterestsUsecase: Get.find(),fetchQualitiesUsecase: Get.find(),postInterestsUsecase: Get.find(),
            postQualitiesUsecase: Get.find(),uploadPicturePerfileUsecase: Get.find(),),fenix: true,);
        Get.lazyPut(() => ProfileController( getUserUsecase: Get.find(),uploadMediaUsecase: Get.find(),uploadPicturePerfileUsecase: Get.find(), deleteMediaUsecase: Get.find(),),fenix: true,);
        Get.lazyPut(() => StoryController(fetchStoriesUsecase: Get.find(), addLikeToStoryUsecase: Get.find(), fetchStoriesByIdUsecase: Get.find(), removeStoryUsecase: Get.find(),createStroryUsecase: Get.find(), setStoryAsSeenUsecase: Get.find(), ),fenix: true,);
        //  Get.lazyPut(() => ProfileDetailController( fetchNearbyUsersUsecase: Get.find()), fenix: true);
        Get.lazyPut(() => NearbyUsersController( fetchNearbyUsersUsecase: Get.find(),
            toggleLikeUsecase: Get.find(), updateLocationUsecase: Get.find(), createReportsUserUsecase:  Get.find(), deactivateTripUsecase:  Get.find(), updateCityUsecase:  Get.find(), searchCityUsecase: Get.find(), ),fenix: true,);
        Get.lazyPut(  () => MyMatchController(getMyChatsUsecase: Get.find()),  fenix: true,);

        Get.lazyPut( () => ChatController( getChatMensajeUsecase: Get.find(), sendMessageUsecase: Get.find(),
            authService: Get.find(),startConversationsUsecase: Get.find(), paymentsChatUsecase: Get.find(),), fenix: true, );
        Get.lazyPut(  () => LikedByUsersController(getPendingLikedChatsUsecase: Get.find(), unlockChatUsecase: Get.find(), logMatchUsecase:  Get.find(), getLikeByUsersUsecase: Get.find(),),  fenix: true,);
        //    Get.lazyPut(() => StartConversationsController(startConversationsUsecase: Get.find(), paymentsChatUsecase: Get.find()), fenix:true);
        Get.lazyPut(() => UserProfileController( getUserByIdUsecase: Get.find(), toggleLikeUsecase: Get.find(), blockUserUsecase: Get.find(), logViewProfileUsecase:  Get.find(), createReportsUserUsecase: Get.find(), followUserUsecase: Get.find(), unfollowUserUsecase: Get.find(),),fenix: true,);
        Get.lazyPut(() => BlockedUsersController( fetchBlockedUsersUsecase: Get.find(), unblockUserUsecase: Get.find(), ),fenix: true,);
        Get.lazyPut(  () => UpdateProfileController( deleteInterestsUsecase: Get.find(),deleteQualitiesUsecase: Get.find(),  updateUserUsecase: Get.find(),  fetchInterestsUsecase: Get.find(),fetchQualitiesUsecase: Get.find(),  postInterestsUsecase: Get.find(),  postQualitiesUsecase: Get.find(), putPreferencesUserUsecase: Get.find(),  deleteUserUsecase: Get.find(),),fenix: true,);
        Get.lazyPut( () => NotificationController(getNotificationUsecase: Get.find(),markAllNotificationsAsReadUsecase: Get.find(),), fenix: true, );
        Get.lazyPut(   () => BalanceController(getBalanceUsecase: Get.find()),  fenix: true, );
        Get.lazyPut(() => LanguageController(), fenix: true);
        Get.put(TranslationService());
        Get.lazyPut(() => TutorialController(), fenix: true);
        Get.lazyPut(() => ProfileTutorialController(), fenix: true);
        Get.lazyPut(() => StartTutorialController(), fenix: true);
        Get.lazyPut(() => UpdateProfileTutorialController(), fenix: true);
        Get.lazyPut(() =>StartController(updateLocationUsecase: Get.find()), fenix: true);
        
        Get.lazyPut(  () => PurchaseController(  getPurchasesUsecase: Get.find(),  purchaseAppleUsecase: Get.find(), purchaseGoogleUsecase: Get.find(), validateCouponsUsecase: Get.find(),  ), fenix: true,  );
        Get.lazyPut( () => VerificationController(  verificationUsecase: Get.find(), verificationSelfieUsecase: Get.find(), getVerificationUsecase: Get.find(), ),  fenix: true,  );
        Get.lazyPut(() =>StartControllerVip(updateLocationUsecase: Get.find()));
      }),

      getPages: AppPages.routes,
      unknownRoute: AppPages.unknownRoute,
    );
      });
  }
}
