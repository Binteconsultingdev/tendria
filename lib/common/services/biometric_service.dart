import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Entrar con huella o rostro. Las credenciales se guardan cifradas en el llavero del dispositivo
/// (Keystore en Android, Keychain en iOS) y solo se leen después de una verificación biométrica exitosa.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  static const _kEmail = 'bio_email';
  static const _kPassword = 'bio_password';

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// El dispositivo tiene huella/rostro configurados.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    try {
      return (await _storage.read(key: _kEmail)) != null && (await _storage.read(key: _kPassword)) != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> enable(String email, String password) async {
    await _storage.write(key: _kEmail, value: email);
    await _storage.write(key: _kPassword, value: password);
  }

  Future<void> disable() async {
    try {
      await _storage.delete(key: _kEmail);
      await _storage.delete(key: _kPassword);
    } catch (_) {}
  }

  /// Pide huella/rostro y, si la verificación es correcta, devuelve (correo, contraseña) guardados.
  Future<({String email, String password})?> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!ok) return null;

      final email = await _storage.read(key: _kEmail);
      final password = await _storage.read(key: _kPassword);
      if (email == null || password == null) return null;
      return (email: email, password: password);
    } catch (_) {
      return null;
    }
  }
}
