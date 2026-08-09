import 'package:google_sign_in/google_sign_in.dart';

import 'api_client.dart';
import 'auth_service.dart';

/// Scope requested via incremental authorization — on top of the basic
/// sign-in [AuthService] already does for login/sync, one additional
/// permission on the *same* Google account to read Gmail for Bank Jago
/// notification emails.
const gmailReadonlyScope = 'https://www.googleapis.com/auth/gmail.readonly';

/// Mirrors backend routes/jago.ts's GET /jago/status shape. No wallet_id —
/// Bank Jago sync auto-creates and manages one wallet per Kantong (pocket)
/// instead of linking to a single pre-picked wallet.
class JagoStatus {
  const JagoStatus({required this.connected, this.connectedAt});

  final bool connected;
  final DateTime? connectedAt;

  static const disconnected = JagoStatus(connected: false);

  factory JagoStatus.fromJson(Map<String, Object?> json) => JagoStatus(
    connected: json['connected'] as bool,
    connectedAt: json['connected_at'] != null
        ? DateTime.parse(json['connected_at'] as String)
        : null,
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
  /// already granted) and exchanges the result on the backend, which runs
  /// the first sync — auto-creating a wallet per Kantong as it goes, no
  /// wallet to pick here. Returns how many transactions that first sync
  /// imported. Throws [StateError] if not logged in yet or the user
  /// declines the Gmail permission, [ApiException] if the backend rejects
  /// it.
  Future<int> connect() async {
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

    final response = await _apiClient.connectJago(token, serverAuthCode: authorization.serverAuthCode);
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
