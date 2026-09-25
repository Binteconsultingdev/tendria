import 'package:tendria/features/auth/data/datasource/auth_data_source_imp.dart';
import 'package:tendria/features/auth/data/repositories/auth_repository_imp.dart';
import 'package:tendria/features/auth/domain/usecase/create_user_usecase.dart';
import 'package:tendria/features/auth/domain/usecase/login_usecase.dart';
import 'package:tendria/features/catalog/data/datasources/catalog_data_sources_imp.dart';
import 'package:tendria/features/catalog/data/repositories/catalog_repository_imp.dart';
import 'package:tendria/features/catalog/domain/usecase/delete_interests_usecase.dart';
import 'package:tendria/features/catalog/domain/usecase/delete_qualities_usecase.dart';
import 'package:tendria/features/catalog/domain/usecase/fetch_interests_usecase.dart';
import 'package:tendria/features/catalog/domain/usecase/fetch_qualities_usecase.dart';
import 'package:tendria/features/catalog/domain/usecase/post_interests_usecase.dart';
import 'package:tendria/features/catalog/domain/usecase/post_qualities_usecase.dart';
import 'package:tendria/features/chat/data/datasources/chat_data_sources_imp.dart';
import 'package:tendria/features/chat/data/repositories/chat_repository_imp.dart';
import 'package:tendria/features/chat/domain/usecase/connect_signalr_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/disconnect_signalr_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/get_chat_mensaje_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/get_my_chats_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/join_chat_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/leave_chat_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/marcar_mensajes_leidos_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/on_mensajes_leidos_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/set_on_disconnected_callback_usecase.dart';
import 'package:tendria/features/facebookEvent/data/datasources/facebook_datasources_imp.dart';
import 'package:tendria/features/facebookEvent/data/repositories/facebook_repository_imp.dart';
import 'package:tendria/features/facebookEvent/domain/usecase/log_login_usecase.dart';
import 'package:tendria/features/facebookEvent/domain/usecase/log_match_usecase.dart';
import 'package:tendria/features/facebookEvent/domain/usecase/log_register_usecase.dart';
import 'package:tendria/features/facebookEvent/domain/usecase/log_view_profile_usecase.dart';
import 'package:tendria/features/like/domain/usecase/payments_chat_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/send_message_usecase.dart';
import 'package:tendria/features/chat/domain/usecase/setup_message_listener_usecase.dart';
import 'package:tendria/features/like/domain/usecase/start_conversations_usecase.dart';
import 'package:tendria/features/like/data/datasources/like_data_sources_imp.dart';
import 'package:tendria/features/follow/data/datasources/follow_data_sources_imp.dart';
import 'package:tendria/features/follow/data/repositories/follow_repository_imp.dart';
import 'package:tendria/features/follow/domain/usecase/follow_user_usecase.dart';
import 'package:tendria/features/follow/domain/usecase/unfollow_user_usecase.dart';
import 'package:tendria/features/like/data/repositories/like_repository_imp.dart';
import 'package:tendria/features/like/domain/usecase/get_like_by_users_usecase.dart';
import 'package:tendria/features/like/domain/usecase/get_pending_liked_chats_usecase.dart';
import 'package:tendria/features/like/domain/usecase/toggle_like_usecase.dart';
import 'package:tendria/features/like/domain/usecase/unlock_chat_usecase.dart';
import 'package:tendria/features/notification/data/datasources/notification_data_sources_imp.dart';
import 'package:tendria/features/notification/data/repositories/notification_repository_imp.dart';
import 'package:tendria/features/notification/domain/usecase/get_notification_usecase.dart';
import 'package:tendria/features/notification/domain/usecase/mark_all_notifications_as_read_usecase.dart';
import 'package:tendria/features/notification/domain/usecase/save_token_fcm_usecase.dart';
import 'package:tendria/features/purchase/data/datasources/purchase_data_sources_imp.dart';
import 'package:tendria/features/purchase/data/repositories/purchase_repository_imp.dart'; 
import 'package:tendria/features/purchase/domain/usecase/get_purchases_usecase.dart';
import 'package:tendria/features/purchase/domain/usecase/purchase_apple_usecase.dart';
import 'package:tendria/features/purchase/domain/usecase/purchase_google_usecase.dart';
import 'package:tendria/features/stories/data/datasources/stories_data_sources_imp.dart';
import 'package:tendria/features/stories/data/repository/stories_repository_imp.dart';
import 'package:tendria/features/stories/domain/usecase/add_like_to_story_usecase.dart';
import 'package:tendria/features/stories/domain/usecase/create_strory_usecase.dart';
import 'package:tendria/features/stories/domain/usecase/fetch_stories_by_id_usecase.dart';
import 'package:tendria/features/stories/domain/usecase/fetch_stories_usecase.dart';
import 'package:tendria/features/stories/domain/usecase/remove_story_usecase.dart';
import 'package:tendria/features/stories/domain/usecase/set_story_as_seen_usecase.dart';
import 'package:tendria/features/unlock/data/datasources/unlock_datasources_imp.dart';
import 'package:tendria/features/unlock/data/repositories/unlock_repository_imp.dart';
import 'package:tendria/features/unlock/domain/usecase/block_user_usecase.dart';
import 'package:tendria/features/unlock/domain/usecase/fetch_blocked_users_usecase.dart';
import 'package:tendria/features/unlock/domain/usecase/unblock_user_usecase.dart';
import 'package:tendria/features/user/data/datasources/user_data_sources_imp.dart';
import 'package:tendria/features/user/data/repositories/user_repository_imp.dart';
import 'package:tendria/features/user/domain/usecase/create_reports_user_usecase.dart';
import 'package:tendria/features/user/domain/usecase/deactivate_trip_usecase.dart';
import 'package:tendria/features/user/domain/usecase/delete_media_usecase.dart';
import 'package:tendria/features/user/domain/usecase/delete_user_usecase.dart';
import 'package:tendria/features/user/domain/usecase/fetch_nearby_users_usecase.dart';
import 'package:tendria/features/user/domain/usecase/get_balance_usecase.dart';
import 'package:tendria/features/user/domain/usecase/get_user_by_id_usecase.dart';
import 'package:tendria/features/user/domain/usecase/get_user_usecase.dart';
import 'package:tendria/features/user/domain/usecase/preferences_user_usecase.dart';
import 'package:tendria/features/user/domain/usecase/put_preferences_user_usecase.dart';
import 'package:tendria/features/user/domain/usecase/search_city_usecase.dart';
import 'package:tendria/features/user/domain/usecase/update_city_usecase.dart';
import 'package:tendria/features/user/domain/usecase/update_location_usecase.dart';
import 'package:tendria/features/user/domain/usecase/update_user_usecase.dart';
import 'package:tendria/features/user/domain/usecase/upload_media_usecase.dart';
import 'package:tendria/features/user/domain/usecase/upload_picture_perfile_usecase.dart';
import 'package:tendria/features/purchase/domain/usecase/validate_coupons_usecase.dart';
import 'package:tendria/features/verifications/data/datasources/verifications_data_sources_imp.dart';
import 'package:tendria/features/verifications/data/repositories/verifications_repository_imp.dart';
import 'package:tendria/features/verifications/domain/usecase/get_verification_usecase.dart';
import 'package:tendria/features/verifications/domain/usecase/verification_selfie_usecase.dart';
import 'package:tendria/features/verifications/domain/usecase/verification_usecase.dart';

class UsecaseConfig {
  AuthDataSourceImp? authDataSourceImp;
  CatalogDataSourcesImp? catalogDataSourcesImp;
  UserDataSourcesImp? userDataSourcesImp;
  StoriesDataSourcesImp? storiesDataSourcesImp;
  ChatDataSourcesImp?chatDataSourcesImp;
  LikeDataSourcesImp? likeDataSourcesImp;
  FollowDataSourcesImp? followDataSourcesImp;
  UnlockDatasourcesImp? unlockDataSourcesImp;
  PurchaseDataSourcesImp? purchaseDataSourcesImp;
  FacebookDatasourcesImp? facebookDatasourcesImp;
  VerificationsDataSourcesImp? verificationsDataSourcesImp;
  
  NotificationDataSourcesImp? notificationDataSourcesImp;

  AuthRepositoryImp? authRepositoryImp;
  CatalogRepositoryImp? catalogRepositoryImp;
  UserRepositoryImp? userRepositoryImp;
  StoriesRepositoryImp? storiesRepositoryImp;
  ChatRepositoryImp?chatRepositoryImp;
  LikeRepositoryImp? likeRepositoryImp;
  FollowRepositoryImp? followRepositoryImp;
  UnlockRepositoryImp? unlockRepositoryImp;
  PurchaseRepositoryImp? purchaseRepositoryImp;
   NotificationRepositoryImp? notificationRepositoryImp;
   FacebookRepositoryImpl? facebookRepositoryImp;
   VerificationsRepositoryImp? verificationsRepositoryImp;

  LoginUsecase? loginUsecase;
  CreateUserUsecase? createUserUsecase;

  FetchInterestsUsecase? fetchInterestsUsecase;
  FetchQualitiesUsecase? fetchQualitiesUsecase;
  PostInterestsUsecase? postInterestsUsecase;
  PostQualitiesUsecase? postQualitiesUsecase;
  DeleteInterestsUsecase? deleteInterestsUsecase;
  DeleteQualitiesUsecase? deleteQualitiesUsecase;
  
  GetUserUsecase? getUserUsecase;
  UpdateLocationUsecase? updateLocationUsecase;
  SearchCityUsecase? searchCityUsecase;
  DeactivateTripUsecase? deactivateTripUsecase;
  UpdateCityUsecase? updateCityUsecase;
  DeleteUserUsecase?deleteUserUsecase;
  GetUserByIdUsecase? getUserByIdUsecase;
  FetchNearbyUsersUsecase? fetchNearbyUsersUsecase;
  PreferencesUserUsecase? preferencesUserUsecase;
  PutPreferencesUserUsecase? putPreferencesUserUsecase;
  UploadMediaUsecase? uploadMediaUsecase;
  DeleteMediaUsecase? deleteMediaUsecase;
  CreateReportsUserUsecase? createReportsUserUsecase;
  UploadPicturePerfileUsecase? uploadPicturePerfileUsecase;
  UpdateUserUsecase? updateUserUsecase;
  GetBalanceUsecase? getBalanceUsecase;
  ValidateCouponsUsecase? validateCouponsUsecase;
  

 
  GetChatMensajeUsecase?getChatMensajeUsecase;
  GetMyChatsUsecase? getMyChatsUsecase;
  SendMessageUsecase?sendMessageUsecase;
  ConnectSignalRUsecase? connectSignalRUsecase;
  DisconnectSignalRUsecase? disconnectSignalRUsecase;
  JoinChatUsecase? joinChatUsecase;
  LeaveChatUsecase? leaveChatUsecase;
  SetOnDisconnectedCallbackUsecase?setOnDisconnectedCallbackUsecase;
  SetupMessageListenerUsecase? setMessageCallbackUsecase;
  StartConversationsUsecase? startConversationsUsecase;
  MarcarMensajesLeidosUsecase? marcarMensajesLeidosUsecase;
  OnMensajesLeidosUsecase? onMensajesLeidosUsecase;
  PaymentsChatUsecase? paymentsChatUsecase;
  UnlockChatUsecase? unlockChatUsecase;
   AddLikeToStoryUsecase? addLikeToStoryUsecase;
   CreateStroryUsecase? createStroryUsecase;
   FetchStoriesByIdUsecase? fetchStoriesByIdUsecase;
   FetchStoriesUsecase? fetchStoriesUsecase;
   RemoveStoryUsecase? removeStoryUsecase;
   SetStoryAsSeenUsecase? setStoryAsSeenUsecase;

   GetLikeByUsersUsecase? getLikeByUsersUsecase;
   GetPendingLikedChatsUsecase? getPendingLikedChatsUsecase;
   ToggleLikeUsecase? toggleLikeUsecase;
   FollowUserUsecase? followUserUsecase;
   UnfollowUserUsecase? unfollowUserUsecase;


   UnblockUserUsecase? unblockUserUsecase;
   BlockUserUsecase? blockUserUsecase;
  FetchBlockedUsersUsecase? fetchBlockedUsersUsecase;

  

   GetNotificationUsecase? getnotificationUsecase;
   MarkAllNotificationsAsReadUsecase? markAllNotificationsAsReadUsecase;

   SaveTokenFcmUsecase? saveTokenFcmUsecase;

   GetPurchasesUsecase? getPurchasesUsecase;
   PurchaseAppleUsecase? purchaseAppleUsecase;
   PurchaseGoogleUsecase?purchaseGoogleUsecase;

   LogViewProfileUsecase? logViewProfileUsecase;
   LogRegisterUsecase? logRegisterUsecase;
   LogMatchUsecase? logMatchUsecase;
   LogLoginUsecase? logLoginUsecase;

   VerificationUsecase? verificationUsecase;
   VerificationSelfieUsecase? verificationSelfieUsecase;
    GetVerificationUsecase? getVerificationUsecase;

  UsecaseConfig(){
    authDataSourceImp = AuthDataSourceImp();
    userDataSourcesImp = UserDataSourcesImp();
    catalogDataSourcesImp = CatalogDataSourcesImp();
    storiesDataSourcesImp = StoriesDataSourcesImp();
    chatDataSourcesImp = ChatDataSourcesImp();
    likeDataSourcesImp = LikeDataSourcesImp();
    followDataSourcesImp = FollowDataSourcesImp();
    unlockDataSourcesImp = UnlockDatasourcesImp();
    notificationDataSourcesImp = NotificationDataSourcesImp();
    purchaseDataSourcesImp = PurchaseDataSourcesImp();
    facebookDatasourcesImp = FacebookDatasourcesImp();
    verificationsDataSourcesImp = VerificationsDataSourcesImp();
    notificationRepositoryImp = NotificationRepositoryImp(notificationDataSourcesImp: notificationDataSourcesImp!);
    authRepositoryImp = AuthRepositoryImp(authDataSourceImp: authDataSourceImp!);
    catalogRepositoryImp = CatalogRepositoryImp(catalogDataSourcesImp: catalogDataSourcesImp!);
    userRepositoryImp = UserRepositoryImp(userDataSourcesImp: userDataSourcesImp!);
    storiesRepositoryImp = StoriesRepositoryImp(storiesDataSourcesImp: storiesDataSourcesImp!);
    chatRepositoryImp = ChatRepositoryImp(chatDataSourcesImp: chatDataSourcesImp!,);
    likeRepositoryImp = LikeRepositoryImp(likeDataSourcesImp: likeDataSourcesImp!);
    followRepositoryImp = FollowRepositoryImp(followDataSourcesImp: followDataSourcesImp!);
    unlockRepositoryImp = UnlockRepositoryImp(unlockDatasourcesImp: unlockDataSourcesImp!);
    purchaseRepositoryImp = PurchaseRepositoryImp(purchaseDataSourcesImp: purchaseDataSourcesImp!);
    facebookRepositoryImp = FacebookRepositoryImpl(facebookDatasourcesImp: facebookDatasourcesImp!);
    verificationsRepositoryImp = VerificationsRepositoryImp(verificationsDataSourcesImp: verificationsDataSourcesImp!);
    loginUsecase = LoginUsecase(authRepository: authRepositoryImp!);
    verificationUsecase = VerificationUsecase(verificationsRepository: verificationsRepositoryImp!);
    verificationSelfieUsecase = VerificationSelfieUsecase(verificationsRepository: verificationsRepositoryImp!);
    getVerificationUsecase = GetVerificationUsecase(verificationsRepository: verificationsRepositoryImp!);
    createUserUsecase = CreateUserUsecase(authRepository: authRepositoryImp!);
    fetchInterestsUsecase = FetchInterestsUsecase(catalogRepository: catalogRepositoryImp!);
    fetchQualitiesUsecase = FetchQualitiesUsecase(catalogRepository: catalogRepositoryImp!);
    deleteInterestsUsecase = DeleteInterestsUsecase(catalogRepository: catalogRepositoryImp!);
    deleteQualitiesUsecase = DeleteQualitiesUsecase(catalogRepository: catalogRepositoryImp!);
    getBalanceUsecase = GetBalanceUsecase(userRepository: userRepositoryImp!);
    getUserUsecase = GetUserUsecase(userRepository: userRepositoryImp!);
    updateUserUsecase = UpdateUserUsecase(userRepository: userRepositoryImp!);
    getUserByIdUsecase = GetUserByIdUsecase(userRepository: userRepositoryImp!);
    updateLocationUsecase = UpdateLocationUsecase(userRepository: userRepositoryImp!);
    searchCityUsecase = SearchCityUsecase(userRepository: userRepositoryImp!);
    deactivateTripUsecase = DeactivateTripUsecase(userRepository: userRepositoryImp!);
      updateCityUsecase = UpdateCityUsecase(userRepository: userRepositoryImp!);
    deleteUserUsecase = DeleteUserUsecase(userRepository: userRepositoryImp!);
    fetchNearbyUsersUsecase = FetchNearbyUsersUsecase(userRepository: userRepositoryImp!);
    postInterestsUsecase = PostInterestsUsecase(catalogRepository: catalogRepositoryImp!);
    postQualitiesUsecase = PostQualitiesUsecase(catalogRepository: catalogRepositoryImp!);
    preferencesUserUsecase = PreferencesUserUsecase(userRepository: userRepositoryImp!);
    putPreferencesUserUsecase = PutPreferencesUserUsecase(userRepository: userRepositoryImp!);
    uploadMediaUsecase = UploadMediaUsecase(userRepository: userRepositoryImp!);
    deleteMediaUsecase = DeleteMediaUsecase(userRepository: userRepositoryImp!);
    createReportsUserUsecase = CreateReportsUserUsecase(userRepository: userRepositoryImp!);
    uploadPicturePerfileUsecase = UploadPicturePerfileUsecase(userRepository: userRepositoryImp!);
    addLikeToStoryUsecase = AddLikeToStoryUsecase(storiesRepository: storiesRepositoryImp!);
    createStroryUsecase = CreateStroryUsecase(storiesRepository: storiesRepositoryImp!);
    fetchStoriesByIdUsecase = FetchStoriesByIdUsecase(storiesRepository: storiesRepositoryImp!);
    fetchStoriesUsecase = FetchStoriesUsecase(storiesRepository: storiesRepositoryImp!);
    removeStoryUsecase = RemoveStoryUsecase(storiesRepository: storiesRepositoryImp!);
    setStoryAsSeenUsecase = SetStoryAsSeenUsecase(storiesRepository: storiesRepositoryImp!);
    getChatMensajeUsecase = GetChatMensajeUsecase(chatRepository: chatRepositoryImp!);
    sendMessageUsecase = SendMessageUsecase(chatRepository: chatRepositoryImp!);
    getMyChatsUsecase = GetMyChatsUsecase(chatRepository: chatRepositoryImp!);
    startConversationsUsecase = StartConversationsUsecase(likeRepository: likeRepositoryImp!);
    paymentsChatUsecase = PaymentsChatUsecase(likeRepository: likeRepositoryImp!);
    unlockChatUsecase = UnlockChatUsecase(likeRepository: likeRepositoryImp!);
    connectSignalRUsecase = ConnectSignalRUsecase(chatRepository: chatRepositoryImp!);

    disconnectSignalRUsecase = DisconnectSignalRUsecase(chatRepository: chatRepositoryImp!);
    setOnDisconnectedCallbackUsecase =SetOnDisconnectedCallbackUsecase(chatRepository: chatRepositoryImp!);
    joinChatUsecase = JoinChatUsecase(chatRepository: chatRepositoryImp!);
    leaveChatUsecase = LeaveChatUsecase(chatRepository: chatRepositoryImp!);
    setMessageCallbackUsecase = SetupMessageListenerUsecase(chatRepository: chatRepositoryImp!);
    getLikeByUsersUsecase = GetLikeByUsersUsecase(likeRepository: likeRepositoryImp!);
    getPendingLikedChatsUsecase = GetPendingLikedChatsUsecase(likeRepository: likeRepositoryImp!);
    toggleLikeUsecase = ToggleLikeUsecase(likeRepository: likeRepositoryImp!);
    followUserUsecase = FollowUserUsecase(followRepository: followRepositoryImp!);
    unfollowUserUsecase = UnfollowUserUsecase(followRepository: followRepositoryImp!);
    marcarMensajesLeidosUsecase = MarcarMensajesLeidosUsecase(chatRepository: chatRepositoryImp!);
    onMensajesLeidosUsecase = OnMensajesLeidosUsecase(chatRepository: chatRepositoryImp!);


    unblockUserUsecase = UnblockUserUsecase(unlockRepository: unlockRepositoryImp!);
    blockUserUsecase = BlockUserUsecase(unlockRepository: unlockRepositoryImp!);
    fetchBlockedUsersUsecase = FetchBlockedUsersUsecase(unlockRepository: unlockRepositoryImp!);


      getnotificationUsecase = GetNotificationUsecase(notificationRepository: notificationRepositoryImp!);
      markAllNotificationsAsReadUsecase = MarkAllNotificationsAsReadUsecase(notificationRepository: notificationRepositoryImp!);
      saveTokenFcmUsecase = SaveTokenFcmUsecase(notificationRepository: notificationRepositoryImp!);  


      getPurchasesUsecase = GetPurchasesUsecase(purchaseRepository: purchaseRepositoryImp!);
      purchaseAppleUsecase = PurchaseAppleUsecase(purchaseRepository: purchaseRepositoryImp!);
      purchaseGoogleUsecase = PurchaseGoogleUsecase(purchaseRepository: purchaseRepositoryImp!);
      validateCouponsUsecase = ValidateCouponsUsecase(purchaseRepository: purchaseRepositoryImp!);

      logViewProfileUsecase = LogViewProfileUsecase(facebookRepository: facebookRepositoryImp!);
      logRegisterUsecase = LogRegisterUsecase(facebookRepository: facebookRepositoryImp!);
      logMatchUsecase = LogMatchUsecase(facebookRepository: facebookRepositoryImp!);
      logLoginUsecase = LogLoginUsecase(facebookRepository: facebookRepositoryImp!);


  }
}