import { describe, expect, it } from 'vitest';

import { CONNECTED_KANTONG_KEY, parseJagoEmail } from './jagoParser';

// Fixtures mirror the structure of a real export of 175 Bank Jago
// notification emails (16 distinct templates) — see jagoParser.ts's header
// comment. Names/account numbers are placeholders; merchant names are
// fabricated but realistic. Row-label casing/colons intentionally vary
// between fixtures to match what Jago's own templates actually do.

function transferTableEmail(rows: string, greeting = ''): string {
  return `<div class="transfer">${greeting}<div class="transfer-rectangle"><table><tbody><tr><td colspan="3"><p class="transfer-grey-font">Ringkasan transaksi</p></td></tr>${rows}</tbody></table></div></div>`;
}

function row(title: string, ...values: string[]): string {
  const contents = values.map((v) => `<p class="transfer-table-content">${v}</p>`).join('');
  return `<tr><td valign="top"><p class="transfer-table-title">${title}</p></td><td valign="top">${contents}</td></tr>`;
}

describe('parseJagoEmail — QRIS/merchant payment (debit)', () => {
  const html = transferTableEmail(
    row('Dari', '100000000001') +
      row('Ke', 'Toko Kelontong Bu Siti', '9360099999999999999') +
      row('Jumlah', 'Rp 10.000') +
      row('Tanggal Transaksi', '09 August 2026, 09:48 WIB') +
      row('Status Transaksi', 'Berhasil'),
    '<p class="transfer-title">Assalamu\'alaikum BUDI SANTOSO,</p><p class="transfer-paid">Kamu baru saja mengirimkan uang, berikut rinciannya:</p>',
  );

  it('parses amount, merchant, and WIB-adjusted UTC date', () => {
    expect(parseJagoEmail('Kamu telah membayar ke Toko Kelontong Bu Siti💸', html)).toEqual({
      kind: 'external',
      amount: 10000,
      direction: 'debit',
      merchant: 'Toko Kelontong Bu Siti',
      occurredAt: new Date(Date.UTC(2026, 7, 9, 2, 48)),
    });
  });

  it('returns null for a failed/pending transaction instead of recording it', () => {
    const failedHtml = transferTableEmail(
      row('Dari', '100000000001') +
        row('Ke', 'Toko Kelontong Bu Siti') +
        row('Jumlah', 'Rp 10.000') +
        row('Status Transaksi', 'Gagal'),
    );
    expect(parseJagoEmail('Kamu telah membayar ke Toko Kelontong Bu Siti', failedHtml)).toBeNull();
  });
});

describe('parseJagoEmail — transfer (debit), lowercase "Tanggal transaksi"', () => {
  it('parses despite the differently-cased date label', () => {
    const html = transferTableEmail(
      row('Dari', 'SDC • 100000000001') +
        row('Ke', 'BUDI SANTOSO', 'Jago • 200000000002') +
        row('Jumlah', 'Rp100.000') +
        row('Tanggal transaksi', '31 July 2026 06:03 WIB'),
    );
    expect(parseJagoEmail('Kamu telah melakukan transfer💸', html)).toEqual({
      kind: 'external',
      amount: 100000,
      direction: 'debit',
      merchant: 'BUDI SANTOSO',
      occurredAt: new Date(Date.UTC(2026, 6, 30, 23, 3)),
    });
  });
});

describe('parseJagoEmail — top-up e-Wallet (debit), colon-suffixed labels', () => {
  it('normalizes the trailing colons on every row label', () => {
    const html = transferTableEmail(
      row('Dari:', '100000000001') + row('Ke:', '081234567890') + row('Jumlah:', 'Rp375.000') + row('Tanggal transaksi:', '20 July 2026 09:30 WIB'),
    );
    expect(parseJagoEmail('Kamu telah melakukan top up e-Wallet💸', html)).toEqual({
      kind: 'external',
      amount: 375000,
      direction: 'debit',
      merchant: '081234567890',
      occurredAt: new Date(Date.UTC(2026, 6, 20, 2, 30)),
    });
  });
});

describe('parseJagoEmail — incoming money (credit)', () => {
  it('takes the sender ("Dari") as merchant, not the recipient', () => {
    const html = transferTableEmail(
      row('Dari', 'PT MAJU JAYA', 'Bank Contoh • 300000000003') + row('Ke', 'SDC • 100000000001') + row('Jumlah', 'Rp183.909') + row('Tanggal transaksi', '30 July 2026 20:25 WIB'),
      '<p class="transfer-paid">Kantong Jago-mu telah menerima sejumlah uang dan berikut rinciannya:</p>',
    );
    expect(parseJagoEmail('Asik, kamu telah menerima sejumlah uang💰', html)).toEqual({
      kind: 'external',
      amount: 183909,
      direction: 'credit',
      merchant: 'PT MAJU JAYA',
      occurredAt: new Date(Date.UTC(2026, 6, 30, 13, 25)),
    });
  });
});

describe('parseJagoEmail — cash withdrawal (debit), no Dari/Ke rows at all', () => {
  it('parses amount/date with only Jumlah and Tanggal transaksi present', () => {
    const html = transferTableEmail(row('Jumlah', 'Rp500.000') + row('Tanggal transaksi', '30 June 2026 16:48 WIB'));
    expect(parseJagoEmail('Kamu telah melakukan tarik tunai💵', html)).toEqual({
      kind: 'external',
      amount: 500000,
      direction: 'debit',
      merchant: null,
      occurredAt: new Date(Date.UTC(2026, 5, 30, 9, 48)),
    });
  });
});

describe('parseJagoEmail — plain-sentence templates (no table)', () => {
  // Jago wraps every dynamic value in its own <span class="param"> even in
  // these sentence-style templates (confirmed against the real export) —
  // fixtures below intentionally include that wrapping so a regression
  // that stops stripping it (see stripTags in jagoParser.ts) fails loudly.
  it('parses a debit card transaction with no merchant disclosed', () => {
    const result = parseJagoEmail(
      'Kamu melakukan transaksi menggunakan kartu debit Jago',
      "<p>Assalamu'alaikum BUDI SANTOSO,</p><p>Kamu telah melakukan transaksi sebesar <span class=\"param\">Rp372.118</span> menggunakan kartu debit Jago.</p>",
    );
    expect(result).toEqual({ kind: 'external', amount: 372118, direction: 'debit', merchant: null, occurredAt: null });
  });

  it('parses an insufficient-balance fee and its "di <merchant>" phrasing, stripping the span around the merchant', () => {
    const result = parseJagoEmail(
      'Kamu telah dikenakan biaya dari kekurangan saldo',
      '<p>Halo BUDI SANTOSO,</p><p>Kamu telah dikenakan biaya sebesar <span class="param">Rp5.000</span> karena saldo di Kantong terhubung tidak mencukupi untuk transaksi Visa di <span class="param">TOKO ONLINE CONTOH</span> .</p>',
    );
    expect(result).toEqual({ kind: 'external', amount: 5000, direction: 'debit', merchant: 'TOKO ONLINE CONTOH', occurredAt: null });
  });

  it('parses a refund as credit despite the body mentioning the original outgoing "pengiriman"', () => {
    const result = parseJagoEmail(
      'Uang telah dikembalikan',
      '<p>Halo BUDI SANTOSO,</p><p>Pengiriman uangmu sebesar Rp <span class="param">Rp18.816</span> ke <span class="param">TOKO CONTOH LAINNYA</span> .</p>',
    );
    expect(result).toEqual({ kind: 'external', amount: 18816, direction: 'credit', merchant: 'TOKO CONTOH LAINNYA', occurredAt: null });
  });
});

describe('parseJagoEmail — Kantong-to-Kantong transfer', () => {
  // Real Kantong names arrive wrapped in <span class="param"> too (this is
  // exactly the shape that shipped broken once — see stripTags in
  // jagoParser.ts — before real production data caught it).
  it('parses "dari Kantong X ke Kantong Y" as a transfer between two named pockets, stripping the spans around each name', () => {
    const result = parseJagoEmail(
      'Kamu telah memindahkan uang ke Kantong lain💸',
      '<p>Assalamu\'alaikum BUDI SANTOSO,</p><p>Kamu telah memindahkan uang sebesar <span class="param">Rp72.118</span> dari Kantong <span class="param">Modal Bisnis</span> ke Kantong <span class="param">Bayar ChatGPT</span>.</p>',
    );
    expect(result).toEqual({
      kind: 'kantong_transfer',
      amount: 72118,
      fromKantong: 'Modal Bisnis',
      toKantong: 'Bayar ChatGPT',
      occurredAt: null,
    });
  });

  it('parses a "penarikan ... dari Kantong X" (no destination named) as a transfer back to the connected Kantong', () => {
    const result = parseJagoEmail(
      'Kamu memindahkan uang dari salah satu Kantong kamu',
      '<p>Assalamu\'alaikum BUDI SANTOSO,</p><p>Kamu baru saja melakukan penarikan sebesar <span class="param">Rp500.000</span> dari Kantong <span class="param">Modal Bisnis</span>.</p>',
    );
    expect(result).toEqual({
      kind: 'kantong_transfer',
      amount: 500000,
      fromKantong: 'Modal Bisnis',
      toKantong: CONNECTED_KANTONG_KEY,
      occurredAt: null,
    });
  });

  it('skips a real Rp0 withdrawal (e.g. emptying a Kantong) as a no-op', () => {
    const result = parseJagoEmail(
      'Kamu memindahkan uang dari salah satu Kantong kamu',
      "<p>Kamu baru saja melakukan penarikan sebesar Rp0 dari Kantong Modal Bisnis.</p>",
    );
    expect(result).toBeNull();
  });
});

describe('parseJagoEmail — non-transactional subjects are skipped', () => {
  it.each([
    ['Kamu berhasil membuat Kantong baru', 'Kantong barumu sudah siap dipakai.'],
    ['Kontak baru ditambahkan ke daftar kontak', 'Kontak baru berhasil ditambahkan.'],
    ['Kamu menjadwalkan pembayaran otomatis', 'Pembayaran otomatis sebesar Rp50.000 dijadwalkan.'],
    ['Kamu telah membatalkan pembayaran otomatis', 'Pembayaran otomatis sebesar Rp50.000 dibatalkan.'],
  ])('skips "%s" even though the body mentions an amount', (subject, body) => {
    expect(parseJagoEmail(subject, body)).toBeNull();
  });
});

describe('parseJagoEmail — generic fallback', () => {
  it('returns null when neither an amount nor a recognizable direction is present', () => {
    expect(parseJagoEmail('Info Saldo', 'Saldo kamu saat ini Rp500.000')).toBeNull();
  });

  it('returns null when no amount is present', () => {
    expect(parseJagoEmail('Transaksi Berhasil', 'Debit ke SEBLAK BU YATI')).toBeNull();
  });
});
