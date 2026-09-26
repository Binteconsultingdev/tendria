import 'package:flutter/material.dart';
import 'package:get/get.dart'; 
import 'package:tendria/framework/preferences_service.dart';  

enum AppThemeMode { light, dark, vip }

class ThemeController extends GetxController {
  final _prefs = PreferencesUser();
  // El tema dorado (vip) ya no se usa: la app tiene solo claro y oscuro
  final Rx<AppThemeMode> themeMode = AppThemeMode.light.obs;
 
  bool get isDarkMode => themeMode.value == AppThemeMode.dark;
  bool get isVipMode => themeMode.value == AppThemeMode.vip;

  static const String _key = 'appThemeMode';

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final saved = await _prefs.loadPrefs(type: int, key: _key);
    // Quien tenía guardado el tema dorado pasa al claro
    themeMode.value = (saved != null && saved >= 0 && saved <= AppThemeMode.dark.index)
        ? AppThemeMode.values[saved]
        : AppThemeMode.light;
    _applyFlutterThemeMode();
  }

  void setThemeMode(AppThemeMode mode) {
    themeMode.value = mode;
    _prefs.savePrefs(type: int, key: _key, value: mode.index);
    _applyFlutterThemeMode();
  }

  void toggleTheme() {
    setThemeMode(isDarkMode ? AppThemeMode.light : AppThemeMode.dark);
  }

 
  /// Antes activaba el tema dorado; ahora solo alterna claro/oscuro (se conserva por si alguna pantalla antigua lo llama)
  void toggleVip() => toggleTheme();

  void _applyFlutterThemeMode() {
    Get.changeThemeMode(
      themeMode.value == AppThemeMode.light ? ThemeMode.light : ThemeMode.dark,
    );
  }
}