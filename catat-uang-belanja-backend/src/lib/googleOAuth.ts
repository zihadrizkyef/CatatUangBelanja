import crypto from 'crypto';

import { OAuth2Client } from 'google-auth-library';

// Same Web OAuth client `auth.ts` verifies Google ID tokens against
// (GOOGLE_CLIENT_ID doubles as the Android app's serverClientId — see that
// file's comment). Exchanging a serverAuthCode for tokens additionally
// needs the client secret, since this call is confidential-client-only
// (unlike ID-token verification, which needs no secret).
const googleClientId = process.env.GOOGLE_CLIENT_ID;
const googleClientSecret = process.env.GOOGLE_CLIENT_SECRET;

function oauthClient(): OAuth2Client {
  if (!googleClientId || !googleClientSecret) {
    throw new Error('Server not configured for Gmail sync (GOOGLE_CLIENT_ID/GOOGLE_CLIENT_SECRET missing)');
  }
  return new OAuth2Client(googleClientId, googleClientSecret);
}

export interface ExchangedTokens {
  refreshToken: string;
  accessToken: string;
  expiryDate: number;
}

/// Exchanges the one-time serverAuthCode the Flutter app obtains via
/// `GoogleSignIn.instance.authorizationClient.authorizeServer(scopes: [gmail.readonly])`
/// for a refresh token (long-lived, stored encrypted against the User row)
/// and an access token (short-lived, used immediately for the first sync).
export async function exchangeServerAuthCode(serverAuthCode: string): Promise<ExchangedTokens> {
  const client = oauthClient();
  const { tokens } = await client.getToken(serverAuthCode);
  if (!tokens.refresh_token || !tokens.access_token) {
    throw new Error('Google did not return a refresh token — the user may need to revoke prior access and reconnect');
  }
  return {
    refreshToken: tokens.refresh_token,
    accessToken: tokens.access_token,
    expiryDate: tokens.expiry_date ?? Date.now() + 55 * 60 * 1000,
  };
}

/// Mints a fresh access token from a stored (decrypted) refresh token —
/// used on every sync run after the initial connect.
export async function refreshAccessToken(refreshToken: string): Promise<string> {
  const client = oauthClient();
  client.setCredentials({ refresh_token: refreshToken });
  const { token } = await client.getAccessToken();
  if (!token) {
    throw new Error('Google did not return an access token for the stored refresh token');
  }
  return token;
}

// AES-256-GCM, key from TOKEN_ENCRYPTION_KEY (32 raw bytes, base64-encoded
// in the env var). Refresh tokens are long-lived Gmail-read credentials —
// same trust boundary as the JWT secret guards, so encrypted at rest rather
// than stored plaintext like the rest of the User row.
const ivLength = 12;

function encryptionKey(): Buffer {
  const value = process.env.TOKEN_ENCRYPTION_KEY;
  if (!value) {
    throw new Error('TOKEN_ENCRYPTION_KEY is not set');
  }
  const key = Buffer.from(value, 'base64');
  if (key.length !== 32) {
    throw new Error('TOKEN_ENCRYPTION_KEY must decode to exactly 32 bytes');
  }
  return key;
}

export function encryptToken(plaintext: string): string {
  const iv = crypto.randomBytes(ivLength);
  const cipher = crypto.createCipheriv('aes-256-gcm', encryptionKey(), iv);
  const ciphertext = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return Buffer.concat([iv, authTag, ciphertext]).toString('base64');
}

export function decryptToken(encoded: string): string {
  const raw = Buffer.from(encoded, 'base64');
  const iv = raw.subarray(0, ivLength);
  const authTag = raw.subarray(ivLength, ivLength + 16);
  const ciphertext = raw.subarray(ivLength + 16);
  const decipher = crypto.createDecipheriv('aes-256-gcm', encryptionKey(), iv);
  decipher.setAuthTag(authTag);
  return Buffer.concat([decipher.update(ciphertext), decipher.final()]).toString('utf8');
}
