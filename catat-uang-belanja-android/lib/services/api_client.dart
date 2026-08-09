import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Thrown when the backend rejects the request outright (bad input, or an
/// expired/invalid session token) — distinct from a plain network failure
/// (no connectivity, DNS, timeout), which callers should treat as "try
/// again later" rather than "something is wrong".
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Talks to `catat-uang-belanja-backend` (Tahap 4 — online sync, doc 4.10).
/// [baseUrl] defaults to a local dev server; override via constructor for a
/// deployed backend once one exists (see README for how to point this at a
/// real host).
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ?? apiBaseUrl,
        _client = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Exchanges a Google ID token (from `google_sign_in`) for our own session
  /// token. Returns `{token, user: {id, email, name, avatar_url}}`.
  Future<Map<String, Object?>> exchangeGoogleIdToken(String idToken) async {
    final response = await _client.post(
      _uri('/auth/google'),
      headers: _headers(),
      body: jsonEncode({'id_token': idToken}),
    );
    return _decode(response);
  }

  Future<Map<String, Object?>> fetchMe(String token) async {
    final response = await _client.get(_uri('/me'), headers: _headers(token: token));
    return _decode(response);
  }

  Future<Map<String, Object?>> push(String token, Map<String, Object?> body) async {
    final response = await _client.post(_uri('/sync/push'), headers: _headers(token: token), body: jsonEncode(body));
    return _decode(response);
  }

  Future<Map<String, Object?>> pull(String token, {DateTime? since}) async {
    final uri = _uri('/sync/pull').replace(
      queryParameters: since != null ? {'since': since.toUtc().toIso8601String()} : null,
    );
    final response = await _client.get(uri, headers: _headers(token: token));
    return _decode(response);
  }

  /// Bank Jago email sync (integrasi-jago) — see backend routes/jago.ts.

  Future<Map<String, Object?>> fetchJagoStatus(String token) async {
    final response = await _client.get(_uri('/jago/status'), headers: _headers(token: token));
    return _decode(response);
  }

  Future<Map<String, Object?>> connectJago(String token, {required String serverAuthCode}) async {
    final response = await _client.post(
      _uri('/jago/connect'),
      headers: _headers(token: token),
      body: jsonEncode({'server_auth_code': serverAuthCode}),
    );
    return _decode(response);
  }

  Future<void> disconnectJago(String token) async {
    _decode(await _client.delete(_uri('/jago/connect'), headers: _headers(token: token)));
  }

  Future<Map<String, Object?>> syncJago(String token) async {
    final response = await _client.post(_uri('/jago/sync'), headers: _headers(token: token));
    return _decode(response);
  }

  Map<String, Object?> _decode(http.Response response) {
    final body = response.body.isEmpty ? <String, Object?>{} : jsonDecode(response.body) as Map<String, Object?>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, body['error'] as String? ?? 'Request failed');
    }
    return body;
  }
}
