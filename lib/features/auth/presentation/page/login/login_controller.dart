import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tendria/common/errors/convert_message.dart';
import 'package:tendria/common/services/auth_service.dart';
import 'package:tendria/common/services/biometric_service.dart';
import 'package:tendria/common/services/notification_service.dart';
import 'package:tendria/common/settings/language_controller.dart';
import 'package:tendria/common/settings/routes_names.dart';
import 'package:tendria/common/widgets/alert/custom_alert_type.dart';
import 'package:tendria/features/auth/domain/usecase/login_usecase.dart';
import 'package:tendria/features/facebookEvent/domain/usecase/log_login_usecase.dart'; 
import 'package:tendria/features/notification/domain/usecase/save_token_fcm_usecase.dart';

class LoginController extends GetxController {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final FocusNode emailFocusNode;
  late final FocusNode passwordFocusNode;

  final RxBool isLoading = false.obs;
  final RxBool showPassword = false.obs;
  final RxBool biometricReady = false.obs;

  final AuthService _authService = Get.find<AuthService>();
  final LoginUsecase loginUsecase;
  final SaveTokenFcmUsecase saveTokenFcmUsecase;
  final LogLoginUsecase logLoginUsecase;
 
  LanguageController get _l => Get.find<LanguageController>();

  LoginController({
    required this.loginUsecase,
    required this.saveTokenFcmUsecase,
    required this.logLoginUsecase,
  });

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
  }

  @override
  void onReady() {
    super.onReady();
    _prepareBiometric();
  }

  /// Si el usuario ya activó huella/rostro, se muestra el botón y se pide la verificación al abrir.
  Future<void> _prepareBiometric() async {
    final bio = BiometricService.instance;
    biometricReady.value = await bio.isAvailable() && await bio.isEnabled();
    if (biometricReady.value) onBiometricTap();
  }

  Future<void> onBiometricTap() async {
    if (isLoading.value) return;
    final creds = await BiometricService.instance.authenticate(_l.t('bio_reason'));
    if (creds == null) return;
    await _login(creds.email, creds.password, fromBiometric: true);
  }

  void _initializeControllers() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    emailFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
  }

  void onemailSubmitted() {
    passwordFocusNode.requestFocus();
  }

  void onPasswordSubmitted() {
    passwordFocusNode.unfocus();
    onLoginTap();
  }

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  void onLoginTap() async {
    if (!_validateFields()) return;
    await _login(emailController.text.trim(), passwordController.text.trim());
  }

  Future<void> _offerBiometric(String email, String password) async {
    final bio = BiometricService.instance;
    if (!await bio.isAvailable()) return;
    if (await bio.isEnabled()) {
      await bio.enable(email, password); // mantiene al día la contraseña guardada
      return;
    }
    final accept = await Get.dialog<bool>(
      AlertDialog(
        title: Text(_l.t('bio_offer_title')),
        content: Text(_l.t('bio_offer_body')),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(_l.t('bio_offer_no'))),
          FilledButton(onPressed: () => Get.back(result: true), child: Text(_l.t('bio_offer_yes'))),
        ],
      ),
    );
    if (accept == true) await bio.enable(email, password);
  }

  Future<void> _login(String email, String password, {bool fromBiometric = false}) async {
    try {
      isLoading.value = true;

      final loginResponse = await loginUsecase.execute(
        email: email,
        password: password,
      );

      await _authService.saveLoginResponse(loginResponse);
      await _saveDeviceToken();
      await logLoginUsecase.call(method: fromBiometric ? 'biometric' : 'email');
      if (!fromBiometric) await _offerBiometric(email, password);
      _clearFields();
      await _resetControllersForNewSession();

          Get.offAllNamed(RoutesNames.preferencesPage);

    } catch (e) {
      if (fromBiometric) {
        // La contraseña guardada ya no sirve (por ejemplo, la cambió): se pide iniciar sesión de nuevo
        await BiometricService.instance.disable();
        biometricReady.value = false;
      }
      _showErrorAlert(
        _l.t('login_error_title'),
        cleanExceptionMessage(e),
      );
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveDeviceToken() async {
    try {
      if (!GetPlatform.isMobile) {
        print('ℹ️ Dispositivo no móvil - omitiendo guardado de token FCM');
        return;
      }

      final fcmToken = await NotificationService().getToken();

      if (fcmToken == null) {
        print('⚠️ No se pudo obtener el token FCM');
        return;
      }

      String deviceType = _getDeviceType();

      print('📤 Guardando token FCM en el servidor...');
      print('   - Token: ${fcmToken.substring(0, 20)}...');
      print('   - Dispositivo: $deviceType');

      await saveTokenFcmUsecase.execute(fcmToken, deviceType);

      print('✅ Token FCM guardado exitosamente');
    } catch (e) {
      print('❌ Error al guardar token FCM: $e');
    }
  }

  String _getDeviceType() {
    if (GetPlatform.isAndroid) return 'Android';
    if (GetPlatform.isIOS) return 'iOS';
    if (GetPlatform.isMacOS) return 'macOS';
    if (GetPlatform.isWindows) return 'Windows';
    if (GetPlatform.isLinux) return 'Linux';
    if (GetPlatform.isWeb) return 'Web';
    return 'Unknown';
  }

  Future<void> _resetControllersForNewSession() async {
    print('🔄 Reseteando controllers para nueva sesión...');
    try {
      final controllersToDelete = [];
      for (final controllerType in controllersToDelete) {
        if (Get.isRegistered(tag: controllerType.toString())) {
          Get.delete(tag: controllerType.toString());
          print('🗑️ ${controllerType.toString()} eliminado');
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
      print('✅ Controllers reseteados para nueva sesión');
    } catch (e) {
      print('❌ Error reseteando controllers: $e');
    }
  }

  void _showErrorAlert(String title, String message, {VoidCallback? onDismiss}) {
    if (Get.context != null) {
      showCustomAlert(
        context: Get.context!,
        title: title,
        message: message,
        confirmText: _l.t('accept'),   
        type: CustomAlertType.error,
        onConfirm: onDismiss,
      );
    }
  }

  bool _validateFields() {
    if (emailController.text.isEmpty) {
      _showErrorAlert(
        _l.t('login_warning'),       
        _l.t('login_val_email'),     
      );
      return false;
    }

    if (passwordController.text.isEmpty) {
      _showErrorAlert(
        _l.t('login_warning'),
        _l.t('login_val_password'),   
      );
      return false;
    }

    return true;
  }

  void _clearFields() {
    if (emailController.hasListeners) emailController.clear();
    if (passwordController.hasListeners) passwordController.clear();
  }

  void onRegisterTap() {
    Get.toNamed(RoutesNames.registerPage);
  }

  @override
  void onClose() {
    if (!emailController.hasListeners) emailController.dispose();
    if (!passwordController.hasListeners) passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.onClose();
  }
}