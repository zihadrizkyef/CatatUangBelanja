import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';
import 'api_client.dart';
import 'secure_key_value_store.dart';

class AuthUser {
  const AuthUser({required this.id, required this.email, required this.name, this.avatarUrl});

  final String id;
  final String email;
  final String name;
  final String? avatarUrl;

  Map<String, Object?> toJson() => {'id': id, 'email': email, 'name': name, 'avatar_url': avatarUrl};

  factory AuthUser.fromJson(Map<String, Object?> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
      );
}

/// Login is Google Sign-In only (doc 4.10/6.1 — updated from the original
/// phone+OTP plan, see PRODUCT_DECISIONS note in the spec doc). The session
/// token issued by the backend is kept in [SecureKeyValueStore] alongside
/// the PIN hash ([SecurityService]) — never in the plaintext sqlite
/// `settings` table.
class AuthService {
  AuthService({SecureKeyValueStore? secureStorage, ApiClient? apiClient, GoogleSignIn? googleSignIn})
      : _secureStorage = secureStorage ?? FlutterSecureKeyValueStore(),
        _apiClient = apiClient ?? ApiClient(),
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final SecureKeyValueStore _secureStorage;
  final ApiClient _apiClient;
  final GoogleSignIn _googleSignIn;

  static const _sessionTokenKey = 'session_token';
  static const _sessionUserKey = 'session_user';

  // Fails closed (treated as "not logged in") rather than throwing when the
  // secure-storage platform channel is unavailable — same defensive pattern
  // as SecurityService.isBiometricAvailable, and what lets FinanceRepository
  // call this unconditionally on every app load without crashing widget
  // tests that don't mock flutter_secure_storage.
  Future<String?> get sessionToken async {
    try {
      return await _secureStorage.read(_sessionTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<AuthUser?> get currentUser async {
    try {
      final raw = await _secureStorage.read(_sessionUserKey);
      if (raw == null) return null;
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> get isLoggedIn async => await sessionToken != null;

  /// Runs the Google account picker, exchanges the resulting ID token for a
  /// backend session, and persists both. Throws [ApiException] if the
  /// backend rejects the token, or the underlying `google_sign_in` exception
  /// if the user cancels or the platform call fails.
  Future<AuthUser> signIn() async {
    await _googleSignIn.initialize(
      serverClientId: googleServerClientId.isEmpty ? null : googleServerClientId,
    );
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw ApiException(401, 'Google tidak mengembalikan token — coba lagi, Bun.');
    }

    final result = await _apiClient.exchangeGoogleIdToken(idToken);
    final user = AuthUser.fromJson(result['user'] as Map<String, Object?>);
    await _secureStorage.write(_sessionTokenKey, result['token'] as String);
    await _secureStorage.write(_sessionUserKey, jsonEncode(user.toJson()));
    return user;
  }

  Future<void> signOut() async {
    await _secureStorage.delete(_sessionTokenKey);
    await _secureStorage.delete(_sessionUserKey);
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Best-effort — the local session is already cleared either way.
    }
  }
}
