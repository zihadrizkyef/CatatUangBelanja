// Parses a Bank Jago transaction-notification email into a transaction
// jagoSync.ts can write to Postgres.
//
// Calibrated against a real export of 175 Bank Jago notification emails
// (16 distinct subject/template types). Two structural families produce
// an "external" event (money entering/leaving Bank Jago entirely):
//
// 1. Table-based (QRIS/merchant payment, transfer, top-up e-Wallet,
//    incoming money, cash withdrawal) — an HTML "Ringkasan transaksi"
//    table:
//      <p class="transfer-table-title">Dari</p> ... <p class="transfer-table-content">505871494756</p>
//      <p class="transfer-table-title">Ke</p> ... <p class="transfer-table-content">CILOK KEJU MR YAN</p><p class="transfer-table-content">9360...</p>
//      <p class="transfer-table-title">Jumlah</p> ... <p class="transfer-table-content">Rp 10.000</p>
//      <p class="transfer-table-title">Tanggal Transaksi</p> ... <p class="transfer-table-content">09 August 2026, 09:48 WIB</p>
//    Row labels are inconsistently capitalized/colon-suffixed across
//    templates ("Tanggal Transaksi" / "Tanggal transaksi" / "Tanggal
//    transaksi:") — extractTransferTableRows normalizes them (lowercase,
//    trailing ":" stripped) before lookup.
//
// 2. Plain-sentence (debit card transaction, insufficient-balance fee,
//    refund) — no table, just a sentence embedding the amount and
//    sometimes a merchant, e.g. "Kamu telah dikenakan biaya sebesar
//    Rp5.000 karena saldo ... tidak mencukupi untuk transaksi Visa di
//    <merchant>." Debit-card transactions never disclose a merchant at
//    all — merchant stays null for those, which is expected, not a
//    parse failure.
//
// A third group of subjects isn't an "external" transaction at all, but
// still affects wallet balances: moving money between the user's own
// Kantong (pockets) is a real transfer between two of the app's wallets
// (see jagoSync.ts's resolveKantongWallet), not an expense/income —
// parseKantongTransfer handles those. A fourth group — creating a
// Kantong, contact-list changes, scheduling/cancelling an autopay (the
// autopay's *execution* would arrive as its own payment-type email later
// — this is just the schedule itself) — isn't a transaction of any kind;
// skippedSubjectPattern short-circuits parseJagoEmail to null for these.

/** Sentinel Kantong identifier for Bank Jago's single "Kantong Terhubung"
 *  (connected pocket) — the only Kantong ever identified by an account
 *  number rather than a name (see this file's header comment). Never a
 *  real Kantong name, so it can't collide with one. */
export const CONNECTED_KANTONG_KEY = '__connected__';

export type ParsedJagoEvent =
  | {
      kind: 'external';
      /** Whole Rupiah, always positive — direction says which way it moved. */
      amount: number;
      direction: 'debit' | 'credit';
      merchant: string | null;
      occurredAt: Date | null;
    }
  | {
      kind: 'kantong_transfer';
      amount: number;
      /** Either a Kantong display name (e.g. "Modal Bisnis") or CONNECTED_KANTONG_KEY. */
      fromKantong: string;
      toKantong: string;
      occurredAt: Date | null;
    };

const skippedSubjectPattern = /kantong baru|kontak|pembayaran otomatis/i;

// --- HTML table template (family 1 above) ---

// Non-greedy up to the first </div> — safe here since the table itself
// contains no nested <div>s to confuse the match.
const transferRectanglePattern = /<div class="transfer-rectangle">([\s\S]*?)<\/div>/;
const rowTitlePattern = /<p class="transfer-table-title">([^<]+)<\/p>/;
const rowContentPattern = /<p class="transfer-table-content">([^<]*)<\/p>/g;

function normalizeLabel(label: string): string {
  return label.trim().replace(/:$/, '').toLowerCase();
}

/** Normalized label -> one or more values (the "Ke" row carries both a
 *  merchant/recipient name and an account number as two separate
 *  `transfer-table-content` cells). */
function extractTransferTableRows(html: string): Map<string, string[]> {
  const rows = new Map<string, string[]>();
  const scoped = transferRectanglePattern.exec(html)?.[1] ?? html;
  for (const rowHtml of scoped.split(/<tr>/i).slice(1)) {
    const title = rowTitlePattern.exec(rowHtml)?.[1];
    if (!title) continue;
    const values = [...rowHtml.matchAll(rowContentPattern)].map((m) => m[1].trim()).filter(Boolean);
    if (values.length) rows.set(normalizeLabel(title), values);
  }
  return rows;
}

// --- Amount ("Rp 10.000" / "Rp10.000" / the odd double "Rp Rp18.816" seen
// in the refund template — the regex naturally skips the first, bare "Rp"
// and matches the second, digit-bearing one). ---

function parseRupiah(text: string): number | null {
  const match = /Rp\s?([\d.,]+)/i.exec(text);
  if (!match) return null;
  const amount = Number.parseInt(match[1].replace(/[.,]/g, ''), 10);
  return Number.isFinite(amount) && amount > 0 ? amount : null;
}

// --- Direction — keyword-based, works against either the subject or the
// HTML/text body (Indonesian only; no English-language sample seen yet).
// Credit is checked before debit so a specific phrase like "dikembalikan"
// can't lose to a coincidental generic debit match. ---

const creditKeywords = /\b(menerima|diterima|pemasukan|dana masuk|transfer masuk|kredit|dikembalikan)\b/i;
const debitKeywords =
  /\b(membayar|mengirim(?:kan)?|terkirim|pembayaran|pengeluaran|debit|melakukan transfer|tarik tunai|penarikan|top up|dikenakan biaya)\b/i;

function parseDirection(text: string): 'debit' | 'credit' | null {
  if (creditKeywords.test(text)) return 'credit';
  if (debitKeywords.test(text)) return 'debit';
  return null;
}

// --- Date/time — "09 August 2026, 09:48 WIB" / "31 July 2026 06:03 WIB"
// (comma before the time is inconsistent too): day, month name (English
// or Indonesian, abbreviated or full — real samples use English "August"
// despite the rest of the email being Indonesian), year, 24h time, always
// WIB (UTC+7) per Jago's own emails. ---

const monthNames: Record<string, number> = {
  jan: 0, january: 0, januari: 0,
  feb: 1, february: 1, februari: 1,
  mar: 2, march: 2, maret: 2,
  apr: 3, april: 3,
  mei: 4, may: 4,
  jun: 5, june: 5, juni: 5,
  jul: 6, july: 6, juli: 6,
  aug: 7, august: 7, agu: 7, agustus: 7,
  sep: 8, september: 8, sept: 8,
  oct: 9, october: 9, okt: 9, oktober: 9,
  nov: 10, november: 10,
  dec: 11, december: 11, des: 11, desember: 11,
};

const dateTimePattern = /(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})[, ]+(\d{1,2}):(\d{2})(?:\s*WIB)?/;

function parseOccurredAt(text: string): Date | null {
  const match = dateTimePattern.exec(text);
  if (!match) return null;
  const [, day, monthName, year, hour, minute] = match;
  const month = monthNames[monthName.toLowerCase()];
  if (month === undefined) return null;
  // WIB is UTC+7, fixed (no DST) — subtract it to store the correct instant
  // regardless of what timezone the server process itself runs in.
  const date = new Date(Date.UTC(Number(year), month, Number(day), Number(hour) - 7, Number(minute)));
  return Number.isNaN(date.getTime()) ? null : date;
}

function parseFromTransferTable(subject: string, html: string, rows: Map<string, string[]>): ParsedJagoEvent | null {
  const status = rows.get('status transaksi')?.[0];
  if (status && !/berhasil/i.test(status)) {
    return null; // failed/pending transaction — don't record it as a real one
  }

  const amount = rows.get('jumlah')?.[0] ? parseRupiah(rows.get('jumlah')![0]) : null;
  if (amount === null) return null;

  const direction = parseDirection(`${subject} ${html}`);
  if (direction === null) return null;

  // Best-effort counterparty: "Ke" (recipient) for an outgoing
  // payment/transfer/top-up, "Dari" (sender) for an incoming one.
  const counterpartyRow = direction === 'debit' ? rows.get('ke') : rows.get('dari');
  const merchant = counterpartyRow?.[0] || null;

  const occurredAt = rows.get('tanggal transaksi')?.[0] ? parseOccurredAt(rows.get('tanggal transaksi')![0]) : null;

  return { kind: 'external', amount, direction, merchant, occurredAt };
}

// Jago wraps dynamic values (amounts, Kantong names, ...) in their own
// inline tags even in the plain-sentence templates — e.g. "dari Kantong
// <span class="param">Modal Bisnis</span> ke Kantong ...". Harmless for
// parseRupiah/parseDirection (keyword/digit matching doesn't care about
// surrounding tags), but the loose name-capturing regexes below
// (merchantAfterKeDariPattern, twoNamedKantongPattern, ...) would
// otherwise capture the tags themselves — strip them first.
function stripTags(html: string): string {
  return html.replace(/<[^>]+>/g, ' ');
}

// --- Plain-sentence template (family 2 above) — also the fallback for
// anything else unrecognized (e.g. if Jago ever sends a genuinely
// plain-text notification instead of HTML). ---

const merchantAfterKeDariPattern = /\b(?:ke|dari)\s+([A-Z0-9][A-Za-z0-9 .'&-]{1,60})/i;
// The insufficient-balance-fee sentence has its own earlier "di Kantong
// terhubung ..." phrase that isn't a merchant — anchoring on "untuk
// transaksi ... di <merchant>" specifically (rather than a bare "di X")
// avoids matching that unrelated phrase.
const merchantAfterTransactionDiPattern = /untuk transaksi[^.]*?\bdi\s+([A-Z0-9][A-Za-z0-9 .'&-]{1,60})/i;

function extractMerchant(text: string): string | null {
  const match = merchantAfterTransactionDiPattern.exec(text)?.[1] ?? merchantAfterKeDariPattern.exec(text)?.[1];
  if (!match) return null;
  // The allowed character class includes "." for names like "RENDER.COM",
  // but that also happily swallows a sentence-ending period — strip a
  // trailing one (with any preceding whitespace) after trimming.
  return match.trim().replace(/\s*\.$/, '') || null;
}

function parseFromSentence(subject: string, bodyText: string): ParsedJagoEvent | null {
  const strippedBody = stripTags(bodyText);
  const combined = `${subject}\n${strippedBody}`;
  const amount = parseRupiah(combined);
  const direction = parseDirection(combined);
  if (amount === null || direction === null) return null;

  // Merchant is extracted from the body only, not the subject — several
  // subjects (e.g. "...biaya dari kekurangan saldo") contain their own
  // "dari <something>" phrasing that isn't a merchant at all.
  return {
    kind: 'external',
    amount,
    direction,
    merchant: extractMerchant(strippedBody),
    occurredAt: parseOccurredAt(combined),
  };
}

// --- Kantong-to-Kantong transfer (family 3 above) — "Kamu telah
// memindahkan uang ke Kantong lain" (both sides named) and "Kamu
// memindahkan uang dari salah satu Kantong kamu" (only the source named —
// a "penarikan" back out of a savings pocket, with no destination
// mentioned; the money implicitly returns to the Kantong Terhubung). ---

const twoNamedKantongPattern = /dari Kantong\s+(.+?)\s+ke Kantong\s+(.+?)\s*\./i;
const oneNamedKantongPattern = /penarikan sebesar\s+Rp[\d.,]+\s+dari Kantong\s+(.+?)\s*\./i;

function parseKantongTransfer(subject: string, body: string): ParsedJagoEvent | null {
  const combined = `${subject}\n${stripTags(body)}`;

  const twoNamed = twoNamedKantongPattern.exec(combined);
  if (twoNamed) {
    const amount = parseRupiah(combined);
    if (amount === null) return null; // includes the real Rp0 case seen in the export — a no-op, nothing to record
    return {
      kind: 'kantong_transfer',
      amount,
      fromKantong: twoNamed[1].trim(),
      toKantong: twoNamed[2].trim(),
      occurredAt: parseOccurredAt(combined),
    };
  }

  const oneNamed = oneNamedKantongPattern.exec(combined);
  if (oneNamed) {
    const amount = parseRupiah(combined);
    if (amount === null) return null;
    return {
      kind: 'kantong_transfer',
      amount,
      fromKantong: oneNamed[1].trim(),
      toKantong: CONNECTED_KANTONG_KEY,
      occurredAt: parseOccurredAt(combined),
    };
  }

  return null;
}

export function parseJagoEmail(subject: string, body: string): ParsedJagoEvent | null {
  if (skippedSubjectPattern.test(subject)) return null;

  const kantongTransfer = parseKantongTransfer(subject, body);
  if (kantongTransfer) return kantongTransfer;

  const rows = extractTransferTableRows(body);
  if (rows.size > 0) {
    return parseFromTransferTable(subject, body, rows);
  }
  return parseFromSentence(subject, body);
}
