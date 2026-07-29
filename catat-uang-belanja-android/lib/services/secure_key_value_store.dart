import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin abstraction over [FlutterSecureStorage] so [SecurityService] can be
/// unit tested with an in-memory fake instead of a real platform channel
/// (OS Keystore/Keychain), which isn't available under `flutter test`.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              // Without this, every read/write on Android goes through a
              // raw Keystore RSA encrypt/decrypt round-trip per key, which
              // is known to take seconds on real devices/emulators.
              // EncryptedSharedPreferences (Jetpack Security) caches the
              // AES key instead, making it fast — see
              // https://pub.dev/packages/flutter_secure_storage#configure-android-version.
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
