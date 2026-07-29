import 'package:flutter_test/flutter_test.dart';

import 'package:catat_uang_belanja/services/secure_key_value_store.dart';
import 'package:catat_uang_belanja/services/security_service.dart';

/// In-memory [SecureKeyValueStore] so these tests exercise the real PIN
/// hash/verify round-trip without touching a platform channel (OS
/// Keystore/Keychain), which isn't available under `flutter test`.
class _InMemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

void main() {
  late SecurityService securityService;

  setUp(() {
    securityService = SecurityService(secureStorage: _InMemorySecureStore());
  });

  test('hasPinSet() is false until a PIN is set', () async {
    expect(await securityService.hasPinSet(), isFalse);
    await securityService.setPin('123456');
    expect(await securityService.hasPinSet(), isTrue);
  });

  test('verifyPin() accepts the correct PIN and rejects a wrong one', () async {
    await securityService.setPin('123456');

    expect(await securityService.verifyPin('123456'), isTrue);
    expect(await securityService.verifyPin('000000'), isFalse);
  });

  test('verifyPin() returns false when no PIN has been set', () async {
    expect(await securityService.verifyPin('123456'), isFalse);
  });

  test('clearPin() removes the stored PIN', () async {
    await securityService.setPin('123456');
    await securityService.clearPin();

    expect(await securityService.hasPinSet(), isFalse);
    expect(await securityService.verifyPin('123456'), isFalse);
  });

  test('isBiometricAvailable()/authenticateWithBiometric() fail closed with no platform channel', () async {
    expect(await securityService.isBiometricAvailable(), isFalse);
    expect(await securityService.authenticateWithBiometric(), isFalse);
  });
}
