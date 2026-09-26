import 'package:tendria/features/profile_social/presentation/page/follow_list_page.dart';
import 'package:tendria/features/communities/presentation/page/create_community_page.dart';
import 'package:tendria/features/communities/presentation/page/community_detail_page.dart';

import 'package:tendria/features/plans/presentation/page/create_plan_page.dart';
import 'package:tendria/features/plans/presentation/page/plan_detail_page.dart';
import 'package:tendria/features/plans/presentation/page/plans_page.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:tendria/common/settings/routes_names.dart'; 
import 'package:tendria/features/auth/presentation/page/Splash/splash_page.dart';
import 'package:tendria/features/auth/presentation/page/home/start_page.dart';
import 'package:tendria/features/auth/presentation/page/login/login_page.dart';
import 'package:tendria/features/moderation/moderation_page.dart';
import 'package:tendria/features/auth/presentation/page/login/forgot_password_page.dart';
import 'package:tendria/features/auth/presentation/page/register/register_page.dart';
import 'package:tendria/features/chat/presentation/page/chat_page.dart'; 
import 'package:tendria/features/feed/presentation/page/create_post_page.dart';
import 'package:tendria/features/feed/presentation/page/feed_page.dart';
import 'package:tendria/features/notification/presentation/page/notificasiones/notification_page.dart';
import 'package:tendria/features/page/achievementsCenterVip/achievements_center_vip.dart';
import 'package:tendria/features/page/chatPremium/chat_premium.dart';
import 'package:tendria/features/page/contentUnlocked/content_unlocked.dart';
import 'package:tendria/features/page/creatorProfilePremium/creator_profile_premium.dart';
import 'package:tendria/features/page/dashboardHomeVip/dashboard_home_vip.dart';
import 'package:tendria/features/page/earningsPanelVip/earnings_panel_vip.dart';
import 'package:tendria/features/page/eliteAchievements/elite_achievements.dart';
import 'package:tendria/features/page/finishOnboardingVip/finish_onboarding_vip.dart'; 
import 'package:tendria/features/page/parami/for_you_page.dart';
import 'package:tendria/features/page/sendGiftPage/send_gift_page.dart';
import 'package:tendria/features/page/startPage/start_page_vip.dart';
import 'package:tendria/features/page/statusAndLevels/status_and_levels.dart';
import 'package:tendria/features/page/valueOfContent/value_of_content.dart';
import 'package:tendria/features/purchase/presentation/page/purchase_page.dart';
import 'package:tendria/features/unlock/presentation/page/blocked_users_page.dart';
import 'package:tendria/features/user/presentation/page/profile/update_profile_page.dart';
import 'package:tendria/features/user/presentation/page/radarscanner/radar_scanner_page.dart';
import 'package:tendria/features/user/presentation/profiledetail/nearby_users_page.dart';
import 'package:tendria/features/user/presentation/page/preferences/preferences_page.dart';
import 'package:tendria/features/user/presentation/profiledetail/user_profile_detail_page.dart';
import 'package:tendria/features/verifications/presentation/page/verification_page.dart';
class AppPages {
  static final routes = [
   
   
        GetPage(name: RoutesNames.welcomePage, page: () =>SplashPage()),//SplashPage
        GetPage(name: RoutesNames.chatPage, page: () => ChatPage()),
        GetPage(name: RoutesNames.radarScannerPage, page: () => RadarScannerScreen()),
        GetPage(name: RoutesNames.preferencesPage, page: () => PreferencesPage()),
        GetPage(name: RoutesNames.foryoupage, page: () => ForYouPage()),
        GetPage(name: RoutesNames.loginPage, page: () => LoginPage()),
        GetPage(name: RoutesNames.registerPage, page: () => RegisterPage()),
        GetPage(name: RoutesNames.moderationPage, page: () => const ModerationPage()),
        GetPage(name: RoutesNames.forgotPasswordPage, page: () => const ForgotPasswordPage()),
        GetPage(name: RoutesNames.homePage, page: () => StartPage()),
        GetPage(name: RoutesNames.nearbyProfilesPage, page: () => NearbyUsersPage()),
        GetPage(name: RoutesNames.profileDetailPage, page: () => NearbyUsersPage()),
        GetPage(name: RoutesNames.userProfileDetailPage, page: () => UserProfileDetailPage()),
        GetPage(name: RoutesNames.blockedUsersPage, page: () => BlockedUsersPage()),
        GetPage(name: RoutesNames.updateProfilePage, page: () => UpdateProfilePage()), 
        GetPage (name: RoutesNames.notificationPage, page: () => NotificationPage()),
        GetPage(name: RoutesNames.purchasePage, page: () =>PurchasePage()),
        GetPage(name: RoutesNames.verificationPage, page: () => VerificationPage()),

        GetPage(name: RoutesNames.valueOfContentPage, page: () => valueOfContent()),
        GetPage(name: RoutesNames.statusAndLevelsPage, page: () => StatusAndLevels()),
        GetPage(name: RoutesNames.finishOnboardingVipPage, page: () => FinishOnboardingVip()),
        GetPage(name: RoutesNames.dashboardHomeVipPage, page: () => DashboardHomeVip()),
        GetPage(name: RoutesNames.contentUnlockedPage, page: () => ContentUnlocked()),
        GetPage(name: RoutesNames.earningsPanelVipPage, page: () => EarningsPanelVip()),
        GetPage(name: RoutesNames.creatorProfilePremiumPage, page: () => CreatorProfilePremium()),
        GetPage(name: RoutesNames.chatPremiumPage, page: () => ChatPremium()),
        GetPage(name: RoutesNames.eliteAchievementsPage, page: () => EliteAchievements()),
        GetPage(name: RoutesNames.achievementsCenterVipPage, page: () => AchievementsCenterVip()),
        GetPage(name: RoutesNames.sendGiftPage, page: () => SendGiftPage()),
        GetPage(name: RoutesNames.createPostPage, page: () => const CreatePostPage()),
        GetPage(name: RoutesNames.userPostsPage, page: () => const UserPostsPage()),
        GetPage(name: RoutesNames.plansPage, page: () => const PlansPage()),
        GetPage(name: RoutesNames.planDetailPage, page: () => const PlanDetailPage()),
        GetPage(name: RoutesNames.createPlanPage, page: () => const CreatePlanPage()),
        GetPage(name: RoutesNames.communityDetailPage, page: () => const CommunityDetailPage()),
        GetPage(name: RoutesNames.createCommunityPage, page: () => const CreateCommunityPage()),
        GetPage(name: RoutesNames.followListPage, page: () => const FollowListPage()),
  ];

  static final unknownRoute = GetPage(
    name: '/not-found',
    page: () => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada'),
      ),
    ),
  );
}