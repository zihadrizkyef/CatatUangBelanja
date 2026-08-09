import { decryptToken, refreshAccessToken } from './googleOAuth';
import { CONNECTED_KANTONG_KEY, parseJagoEmail } from './jagoParser';
import { prisma } from './prisma';

// Confirmed against a real Bank Jago notification: `From: "Jago" <noreply@jago.com>`.
// Overridable via JAGO_SENDER_EMAIL (no redeploy needed, read at call time)
// in case Jago sends other notification types from a different address.
function jagoSenderDomain(): string {
  return process.env.JAGO_SENDER_EMAIL || 'jago.com';
}

function jagoSenderQuery(): string {
  return `from:${jagoSenderDomain()}`;
}

const gmailApiBase = 'https://gmail.googleapis.com/gmail/v1/users/me';
// Defensive cap on pagination per sync run — a personal inbox's Jago
// notification volume is low; this just guards against an unbounded loop
// if Gmail ever returns nextPageToken forever.
const maxPages = 10;

interface GmailHeader {
  name: string;
  value: string;
}

interface GmailMessagePart {
  mimeType?: string;
  headers?: GmailHeader[];
  body?: { data?: string };
  parts?: GmailMessagePart[];
}

interface GmailMessage {
  id: string;
  internalDate?: string;
  payload?: {
    headers?: GmailHeader[];
  } & GmailMessagePart;
}

async function gmailFetch(accessToken: string, path: string, query: Record<string, string> = {}): Promise<any> {
  const url = new URL(`${gmailApiBase}${path}`);
  for (const [key, value] of Object.entries(query)) url.searchParams.set(key, value);
  const response = await fetch(url, { headers: { Authorization: `Bearer ${accessToken}` } });
  if (!response.ok) {
    throw new Error(`Gmail API ${path} failed: ${response.status} ${await response.text()}`);
  }
  return response.json();
}

function headerValue(headers: GmailHeader[] | undefined, name: string): string {
  return headers?.find((h) => h.name.toLowerCase() === name.toLowerCase())?.value ?? '';
}

function decodeBase64Url(data: string): Buffer {
  return Buffer.from(data.replace(/-/g, '+').replace(/_/g, '/'), 'base64');
}

/// Gmail API's `body.data` is base64url of the MIME part's bytes exactly as
/// they appeared in the original message — i.e. still whatever
/// Content-Transfer-Encoding that part declared (quoted-printable is
/// common for HTML emails, as Bank Jago's are). Decoding only the base64
/// layer and stopping there — the original bug here — left HTML bodies
/// full of `=3D`/soft-wrapped-`=` artifacts and broke every regex match.
function decodeQuotedPrintable(ascii: string): string {
  const withoutSoftBreaks = ascii.replace(/=\r?\n/g, '');
  const bytes: number[] = [];
  for (let i = 0; i < withoutSoftBreaks.length; i++) {
    const hex = withoutSoftBreaks.slice(i + 1, i + 3);
    if (withoutSoftBreaks[i] === '=' && /^[0-9A-Fa-f]{2}$/.test(hex)) {
      bytes.push(Number.parseInt(hex, 16));
      i += 2;
    } else {
      bytes.push(withoutSoftBreaks.charCodeAt(i));
    }
  }
  return Buffer.from(bytes).toString('utf8');
}

function decodePartBody(part: GmailMessagePart): string {
  if (!part.body?.data) return '';
  const raw = decodeBase64Url(part.body.data);
  const cte = headerValue(part.headers, 'Content-Transfer-Encoding').toLowerCase();
  if (cte === 'quoted-printable') return decodeQuotedPrintable(raw.toString('utf8'));
  if (cte === 'base64') return decodeBase64Url(raw.toString('utf8').replace(/\s+/g, '')).toString('utf8');
  return raw.toString('utf8');
}

/// Walks the (possibly multipart) message tree for both an HTML and a
/// plain-text body. jagoParser.ts's real template is HTML (see its header
/// comment), so callers should prefer `html` and fall back to `text`.
function extractBodyParts(part: GmailMessagePart | undefined): { html: string; text: string } {
  if (!part) return { html: '', text: '' };
  if (part.body?.data) {
    if (part.mimeType === 'text/html') return { html: decodePartBody(part), text: '' };
    if (part.mimeType === 'text/plain') return { html: '', text: decodePartBody(part) };
  }
  let html = '';
  let text = '';
  for (const child of part.parts ?? []) {
    const found = extractBodyParts(child);
    html = html || found.html;
    text = text || found.text;
  }
  return { html, text };
}

async function fetchMessage(accessToken: string, id: string): Promise<GmailMessage> {
  return gmailFetch(accessToken, `/messages/${id}`, { format: 'full' });
}

/// Lists candidate message ids for the very first sync (no historyId cursor
/// yet), via a plain search — Gmail's History API needs a starting point we
/// don't have until after this first pass.
async function listInitialMessageIds(accessToken: string): Promise<string[]> {
  const ids: string[] = [];
  let pageToken: string | undefined;
  for (let page = 0; page < maxPages; page++) {
    const result = await gmailFetch(accessToken, '/messages', {
      q: jagoSenderQuery(),
      ...(pageToken ? { pageToken } : {}),
    });
    for (const m of result.messages ?? []) ids.push(m.id);
    pageToken = result.nextPageToken;
    if (!pageToken) break;
  }
  return ids;
}

/// Lists candidate message ids added since [historyId], via the History
/// API — the efficient path used on every sync after the first.
async function listMessageIdsSince(accessToken: string, historyId: string): Promise<{ ids: string[]; latestHistoryId: string }> {
  const ids: string[] = [];
  let latestHistoryId = historyId;
  let pageToken: string | undefined;
  for (let page = 0; page < maxPages; page++) {
    let result;
    try {
      result = await gmailFetch(accessToken, '/history', {
        startHistoryId: historyId,
        historyTypes: 'messageAdded',
        ...(pageToken ? { pageToken } : {}),
      });
    } catch {
      // startHistoryId too old / expired (Gmail only retains ~a week of
      // history) — fall back to a fresh full search rather than erroring
      // the whole sync out; duplicates are harmless (externalId dedupes).
      return { ids: await listInitialMessageIds(accessToken), latestHistoryId: historyId };
    }
    for (const h of result.history ?? []) {
      for (const added of h.messagesAdded ?? []) ids.push(added.message.id);
    }
    if (result.historyId) latestHistoryId = result.historyId;
    pageToken = result.nextPageToken;
    if (!pageToken) break;
  }
  return { ids, latestHistoryId };
}

async function currentHistoryId(accessToken: string): Promise<string> {
  const profile = await gmailFetch(accessToken, '/profile');
  return String(profile.historyId);
}

// Every Jago-auto-created wallet looks like this by default — same visual
// treatment as the app's own seeded "Rekening Bank" wallet. Zihad can
// rename/re-theme any of them afterward via the existing wallet-edit UI;
// this is just a starting point so newly-discovered Kantong don't show up
// unstyled.
const jagoWalletDefaults = {
  type: 'Bank' as const,
  color: '#DCD3F0',
  iconType: 'System' as const,
  iconValue: 'wallet_bank',
};

/// Named Kantong are identified only by display name (e.g. "Modal
/// Bisnis") — normalized to a case-insensitive key for JagoKantong lookup
/// while the original casing is preserved as the wallet's display name.
/// CONNECTED_KANTONG_KEY is already a fixed sentinel, left as-is.
function normalizeKantongKey(nameOrSentinel: string): string {
  return nameOrSentinel === CONNECTED_KANTONG_KEY ? CONNECTED_KANTONG_KEY : nameOrSentinel.trim().toLowerCase();
}

/// Finds the Wallet already linked to Kantong `key` for this user, or
/// creates one (and the JagoKantong row pointing to it) if this is the
/// first time this Kantong has been seen. Also recreates the wallet if
/// the user deleted it since — the mapping shouldn't get permanently
/// stuck pointing at a wallet that no longer exists.
async function resolveKantongWallet(userId: string, key: string, fallbackName: string) {
  const existing = await prisma.jagoKantong.findUnique({ where: { userId_key: { userId, key } } });
  if (existing) {
    const wallet = await prisma.wallet.findUnique({ where: { id: existing.walletId } });
    if (wallet) return wallet;
  }

  const wallet = await prisma.wallet.create({ data: { userId, name: fallbackName, ...jagoWalletDefaults } });
  await prisma.jagoKantong.upsert({
    where: { userId_key: { userId, key } },
    update: { walletId: wallet.id },
    create: { userId, key, walletId: wallet.id },
  });
  return wallet;
}

function kantongDisplayName(nameOrSentinel: string): string {
  return nameOrSentinel === CONNECTED_KANTONG_KEY ? 'Kantong Terhubung' : nameOrSentinel;
}

export interface JagoSyncResult {
  connected: boolean;
  imported: number;
}

export async function syncJagoForUser(userId: string): Promise<JagoSyncResult> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user?.jagoRefreshToken) {
    return { connected: false, imported: 0 };
  }

  const accessToken = await refreshAccessToken(decryptToken(user.jagoRefreshToken));

  let messageIds: string[];
  let nextHistoryId: string;
  if (user.jagoHistoryId) {
    const result = await listMessageIdsSince(accessToken, user.jagoHistoryId);
    messageIds = result.ids;
    nextHistoryId = result.latestHistoryId;
  } else {
    // First connect: capture the cursor *before* the initial search so no
    // message that arrives mid-scan gets missed on the next run (a
    // resulting duplicate on this run's own results is harmless —
    // externalId dedupes below).
    nextHistoryId = await currentHistoryId(accessToken);
    messageIds = await listInitialMessageIds(accessToken);
  }

  let imported = 0;
  for (const id of messageIds) {
    try {
      const existing = await prisma.transaction.findUnique({ where: { externalId: id } });
      if (existing) continue;

      const message = await fetchMessage(accessToken, id);

      // listMessageIdsSince (History API) has no sender filter — it
      // returns every new message in the mailbox, not just Jago's — so
      // this check is the only thing actually scoping Gmail access to
      // Jago's own emails on that path (listInitialMessageIds's `q:
      // from:...` search already filters, but re-checking here is cheap
      // and keeps both paths honest).
      const from = headerValue(message.payload?.headers, 'From');
      if (!from.toLowerCase().includes(jagoSenderDomain().toLowerCase())) continue;

      const subject = headerValue(message.payload?.headers, 'Subject');
      const { html, text } = extractBodyParts(message.payload);
      const parsed = parseJagoEmail(subject, html || text);
      if (!parsed) continue;

      const fallbackDate = new Date(Number(message.internalDate ?? Date.now()));

      if (parsed.kind === 'external') {
        const wallet = await resolveKantongWallet(userId, CONNECTED_KANTONG_KEY, 'Kantong Terhubung');
        await prisma.transaction.create({
          data: {
            userId,
            type: parsed.direction === 'debit' ? 'Expense' : 'Income',
            amount: parsed.amount,
            walletId: wallet.id,
            dateTime: parsed.occurredAt ?? fallbackDate,
            note: parsed.merchant,
            source: 'EmailSync',
            externalId: id,
          },
        });
      } else {
        const fromWallet = await resolveKantongWallet(userId, normalizeKantongKey(parsed.fromKantong), kantongDisplayName(parsed.fromKantong));
        const toWallet = await resolveKantongWallet(userId, normalizeKantongKey(parsed.toKantong), kantongDisplayName(parsed.toKantong));
        await prisma.transaction.create({
          data: {
            userId,
            type: 'Transfer',
            amount: parsed.amount,
            walletId: fromWallet.id,
            targetWalletId: toWallet.id,
            dateTime: parsed.occurredAt ?? fallbackDate,
            source: 'EmailSync',
            externalId: id,
          },
        });
      }
      imported++;
    } catch {
      // One bad/unparseable message shouldn't fail the whole sync run —
      // it's simply skipped and will be retried (harmlessly, dedupe via
      // externalId) on the next sync if it turns out fetchable later.
      continue;
    }
  }

  await prisma.user.update({ where: { id: userId }, data: { jagoHistoryId: nextHistoryId } });
  return { connected: true, imported };
}
