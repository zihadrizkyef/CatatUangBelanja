/// Backend base URL (doc 4.10 — Tahap 4 online sync). Override at
/// build/run time with `--dart-define=API_BASE_URL=https://your-deployed-backend`.
/// Defaults to the Android emulator's alias for the host machine's
/// localhost, for local development against `npm run dev` in
/// `catat-uang-belanja-backend/`.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');

/// Web OAuth Client ID from Google Cloud Console, passed to `google_sign_in`
/// as `serverClientId` so the ID token's audience matches what the backend
/// verifies (`GOOGLE_CLIENT_ID` in `catat-uang-belanja-backend/.env`).
/// Override with `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` — see the
/// backend README for how to create one.
const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
