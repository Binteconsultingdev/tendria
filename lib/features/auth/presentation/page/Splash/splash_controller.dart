import 'package:camera/camera.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart'; 
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/widgets/alert/snackbar_helper.dart';
import 'package:tendria/features/user/domain/entities/update_location_entity.dart';
import 'package:tendria/features/user/domain/usecase/get_user_usecase.dart';
import 'package:tendria/features/user/domain/usecase/update_location_usecase.dart';

class SplashController extends GetxController {
  final UpdateLocationUsecase updateLocationUsecase;
  final RxBool isLoading = true.obs;

  final GetUserUsecase getUserUsecase;

  SplashController({
    required this.getUserUsecase,
    required this.updateLocationUsecase,
  });

  @override
  void onInit() async {
    super.onInit();
    await checkUserSession();
    await requestLocationPermission();
    await _requestNotificationPermission();
    await _requestCameraPermission();
   
  }

  Future<void> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Servicios de ubicación deshabilitados');
      showErrorSnackbar(
        'Por favor activa los servicios de ubicación para usar la aplicación',
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print(  'Permiso de ubicación denegado');
        showErrorSnackbar(
          'Se requieren permisos de ubicación para usar la aplicación',
        );
        return;
      }
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
          print('Permiso de ubicación concedido');
      await _updateUserCity();
    }
  }

  Future<void> _updateUserCity() async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: const Duration(seconds: 10),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final place = placemarks.first; 
      final city = _resolveCity(place);

      if (city.isNotEmpty) {
  final country = place.country?.trim() ?? '';
  
  print('city: $city | country: $country');
  await updateLocationUsecase.execute(
    UpdateLocationEntity(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      country: country,
    ),
  );
}
    }
  } catch (e) {
    print('Error obteniendo ubicación: $e');
  }
}

String _resolveCity(Placemark place) { 

  final subAdmin = place.subAdministrativeArea?.trim() ?? '';
  final locality = place.locality?.trim() ?? '';
 
  if (subAdmin.isNotEmpty && (subAdmin.contains(' ') || subAdmin.length > 6)) {
    return subAdmin;
  }
 
  if (locality.isNotEmpty && (locality.contains(' ') || locality.length > 6)) {
    return locality;
  }
 
  return subAdmin.isNotEmpty ? subAdmin : locality;
}
  

  Future<void> checkUserSession() async {
    try {
      await getUserUsecase.execute();
      AuthService().renewToken(); // sesión deslizante, sin esperar
      Get.offAllNamed(RoutesNames.preferencesPage);
    } catch (e) {
      Get.offAllNamed(RoutesNames.loginPage);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _requestNotificationPermission() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Estado de permisos: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permisos de notificaciones concedidos');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('Permisos provisionales concedidos');
    } else {
      print('Permisos de notificaciones denegados');
    }
  }

  
Future<void> _requestCameraPermission() async {
  try {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      print('❌ No hay cámaras disponibles');
      return;
    }

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: true, 
    );

    await controller.initialize();
    print('✅ Permiso de cámara concedido');
    print('✅ Permiso de micrófono concedido');
    await controller.dispose();

  } on CameraException catch (e) {
    if (e.code == 'CameraAccessDenied') {
      print('🚫 Permiso de cámara denegado');
    } else if (e.code == 'AudioAccessDenied') {
      print('🚫 Permiso de micrófono denegado');
    } else {
      print('❌ Error: ${e.description}');
    }
  }
}
}
