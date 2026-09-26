import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tendria/app.dart';
import 'package:tendria/common/services/notification_service.dart';
import 'package:tendria/common/settings/enviroment.dart';
import 'package:tendria/firebase_options.dart';
import 'package:tendria/framework/preferences_service.dart';

String enviromentSelect = Enviroment.production.value;
final facebookAppEvents = FacebookAppEvents();
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PreferencesUser().initiPrefs();
  await NotificationService().initialize();
  print('=========ENVIROMENT SELECTED: $enviromentSelect');
  await dotenv.load(fileName: enviromentSelect);
  await facebookAppEvents.setAdvertiserTracking(enabled: true); 

  runApp(const App());
}   