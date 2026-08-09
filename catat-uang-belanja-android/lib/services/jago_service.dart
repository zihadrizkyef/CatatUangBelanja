import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';
import 'auth_service.dart';

/// Scope requested via incremental authorization — on top of the basic
/// sign-in [AuthService] already does for login/sync, one additional
/// permission on the *same* Google account to read Gmail for Bank Jago
/// notification emails.
const gmailReadonlyScope = 'https://www.googleapis.com/auth/gmail.readonly';

/// Mirrors backend routes/jago.ts's GET /jago/status shape. Named Kantong
/// (Tabungan, Modal Bisnis, dst.) auto-match by name and need no picker —
/// only the nameless "Kantong Terhubung" is explicitly picked at connect
/// time, hence [connectedWalletId].
class JagoStatus {
  const JagoStatus({required this.connected, this.connectedAt, this.connectedWalletId});

  final bool connected;
  final DateTime? connectedAt;
  final String? connectedWalletId;

  static const disconnected = JagoStatus(connected: false);

  factory JagoStatus.fromJson(Map<String, Object?> json) => JagoStatus(
    connected: json['connected'] as bool,
    connectedAt: json['connected_at'] != null
        ? DateTime.parse(json['connected_at'] as String)
        : null,
    connectedWalletId: json['connected_wallet_id'] as String?,
  );
}

/// Wraps the backend's `/jago/*` endpoints plus the Google
/// incremental-authorization step needed to obtain a one-time
/// serverAuthCode for Gmail access. Deliberately separate from
/// [SyncService]: connecting is a one-off Pengaturan action, but
/// [sync] is also called from [SyncService.syncNow] on every regular cycle
/// (best-effort — see that call site) so Jago transactions ride along on
/// the app's normal sync without a separate polling path.
class JagoService {
  JagoService({required AuthService authService, ApiClient? apiClient})
    : _authService = authService,
      _apiClient = apiClient ?? ApiClient();

  final AuthService _authService;
  final ApiClient _apiClient;

  Future<JagoStatus> fetchStatus() async {
    final token = await _authService.sessionToken;
    if (token == null) return JagoStatus.disconnected;
    return JagoStatus.fromJson(await _apiClient.fetchJagoStatus(token));
  }

  /// Prompts the Google account picker for [gmailReadonlyScope] (skipped if
  /// already granted) and exchanges the result on the backend along with
  /// [connectedWalletId] — the wallet that handles Kantong Terhubung's
  /// QRIS/card/transfer/top-up/withdrawal activity, since that Kantong has
  /// no name in any Jago email to auto-match against. Returns how many
  /// transactions the sync imported. Throws [StateError] if not logged in
  /// yet or the user declines the Gmail permission, [ApiException] if the
  /// backend rejects it.
  Future<int> connect(String connectedWalletId) async {
    final token = await _authService.sessionToken;
    if (token == null) {
      throw StateError(
        'Masuk dengan Google dulu sebelum menghubungkan Bank Jago, Bun.',
      );
    }

    await _authService.ensureInitialized();
    final authorization = await GoogleSignIn.instance.authorizationClient
        .authorizeServer([gmailReadonlyScope]);
    if (authorization == null) {
      throw StateError(
        'Google tidak memberikan izin akses Gmail — coba lagi, Bun.',
      );
    }

    final response = await _apiClient.connectJago(
      token,
      serverAuthCode: authorization.serverAuthCode,
      connectedWalletId: connectedWalletId,
    );
    return response['imported'] as int;
  }

  Future<void> disconnect() async {
    final token = await _authService.sessionToken;
    if (token == null) return;
    await _apiClient.disconnectJago(token);
  }

  /// No-ops (returns 0) rather than throwing when not logged in or the
  /// backend call fails, so callers — including [SyncService]'s regular
  /// cycle — can invoke this unconditionally without extra guards.
  Future<int> sync() async {
    final token = await _authService.sessionToken;
    if (token == null) return 0;
    try {
      final response = await _apiClient.syncJago(token);
      return response['imported'] as int? ?? 0;
    } on ApiException {
      return 0;
    }
  }
}
