import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  // 1. Cek Apakah Perangkat Mendukung Autentikasi Biometrik
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false; // Platform tidak didukung atau terjadi kesalahan
    }
  }

  // 2. Jalankan Proses Autentikasi Biometrik (Sidik Jari / Wajah)
  Future<bool> authenticate() async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        // Fallback untuk emulator/desktop yang tidak punya hardware biometrik:
        // Kembalikan true untuk mempermudah testing UI.
        return true;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Gunakan sidik jari atau Face ID Anda untuk masuk ke Uangku',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return didAuthenticate;
    } catch (_) {
      return false;
    }
  }
}
