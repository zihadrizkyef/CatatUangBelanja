/// Backend base URL (doc 4.10 — Tahap 4 online sync). Defaults to the
/// deployed Render backend. Override at build/run time for local dev
/// against `npm run dev` in `catat-uang-belanja-backend/` — e.g.
/// `--dart-define=API_BASE_URL=http://10.0.2.2:3000` on an emulator, or
/// `http://<your-laptop-LAN-IP>:3000` on a physical device.
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://catatuangbelanja.onrender.com');

/// Web OAuth Client ID from Google Cloud Console, passed to `google_sign_in`
/// as `serverClientId` so the ID token's audience matches what the backend
/// verifies (`GOOGLE_CLIENT_ID` in `catat-uang-belanja-backend/.env`). This
/// is a public client identifier, not a secret, so it's safe to default
/// here. Override with `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` only if
/// testing against a different OAuth client.
const googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: '139168280853-scjhanf259r02afp5k8gi6mk9i4sgeq2.apps.googleusercontent.com',
);
