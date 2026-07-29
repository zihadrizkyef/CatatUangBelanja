import 'dart:convert';
import 'dart:typed_data';

import 'package:local_auth/local_auth.dart';

import 'pin_hasher.dart';
import 'secure_key_value_store.dart';

/// App-lock PIN storage + biometric prompt (doc 4.11). The PIN is hashed
/// ([PinHasher], salted) and kept in [SecureKeyValueStore]
/// (OS Keystore/Keychain), never in the plaintext sqlite `settings` table.
class SecurityService {
  SecurityService({SecureKeyValueStore? secureStorage, LocalAuthentication? localAuth})
      : _secureStorage = secureStorage ?? FlutterSecureKeyValueStore(),
        _localAuth = localAuth ?? LocalAuthentication();

  final SecureKeyValueStore _secureStorage;
  final LocalAuthentication _localAuth;

  static const _pinHashKey = 'pin_hash';
  static const _pinSaltKey = 'pin_salt';

  Future<bool> hasPinSet() async {
    final hash = await _secureStorage.read(_pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final salt = PinHasher.generateSalt();
    final hash = await PinHasher.hash(pin, salt);
    await _secureStorage.write(_pinSaltKey, base64Encode(salt));
    await _secureStorage.write(_pinHashKey, base64Encode(hash));
  }

  Future<bool> verifyPin(String pin) async {
    final results = await Future.wait([_secureStorage.read(_pinSaltKey), _secureStorage.read(_pinHashKey)]);
    final saltEncoded = results[0];
    final expectedEncoded = results[1];
    if (saltEncoded == null || expectedEncoded == null) return false;

    final salt = Uint8List.fromList(base64Decode(saltEncoded));
    final expected = base64Decode(expectedEncoded);
    final actual = await PinHasher.hash(pin, salt);
    return PinHasher.constantTimeEquals(actual, expected);
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(_pinHashKey);
    await _secureStorage.delete(_pinSaltKey);
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Verifikasi untuk membuka Catat Uang Belanja',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
