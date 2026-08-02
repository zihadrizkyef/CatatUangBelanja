# Maestro regression suite

Every file in `flows/` is a standalone, independent flow — each one starts
with `launchApp: clearState: true`, so they don't depend on each other or
leftover state, and can be run individually or all together in any order.

## Run everything

With an emulator/device connected and the app already built+installed:

```
maestro test maestro/flows
```

This runs every `.yaml` in the folder and prints one aggregated pass/fail
report — this is the "run all after a change" command.

## Run a single flow

```
maestro test maestro/flows/wallet-add-edit-delete.yaml
```

## Run only the regression-tagged flows

All flows currently carry `tags: [regression]`, so this is equivalent to
running everything above — but once flows with other tags exist, this lets
you filter:

```
maestro test maestro/flows --include-tags regression
```

## Coverage

| Flow | Covers |
| --- | --- |
| `smoke.yaml` | App launch + all 4 bottom-nav tabs |
| `add-expense-transaction.yaml` | Add Pengeluaran |
| `add-income-transaction.yaml` | Add Pemasukan |
| `edit-and-delete-transaction.yaml` | Edit + delete a transaction (confirm dialog) |
| `wallet-add-edit-delete.yaml` | Wallet CRUD (confirm dialog) |
| `wallet-delete-in-use-guard.yaml` | Deleting a wallet with transactions is blocked (QA-005 regression guard) |
| `wallet-search.yaml` | Dompet search filter |
| `transfer-between-wallets.yaml` | Transfer + Beranda row label/sub-label (QA-001/QA-002 regression guard) |
| `category-add-edit-delete.yaml` | Kelola Kategori CRUD (confirm dialog) |
| `budget-add-edit-reset-delete.yaml` | Anggaran CRUD + manual reset |
| `all-transactions-filter.yaml` | Semua Transaksi + type filter chips |
| `summary-periods.yaml` | Rangkuman period selector, empty + populated |
| `dark-mode-toggle.yaml` | Dark mode toggle across tabs |
| `generate-dummy-data.yaml` | Generate Data Dummy (QA-006 regression guard) |
| `clear-all-data.yaml` | Hapus Semua Data |
| `settings-profile-and-about.yaml` | Edit Profil, Keamanan nav, Tentang Aplikasi |

Not covered yet: Google Sign-In / login flow, PIN/biometric app lock setup,
sync (backend isn't wired up to the app yet per the root `CLAUDE.md`).

## Known-fragile taps

A handful of icon-only buttons have no visible text or semantics label, so
they're tapped by screen-percentage point instead of `tapOn: "<text>"`.
Most are corroborated by several past live QA runs; two (the Dompet "add
wallet" icon at `90%,26%`, and the back chevron on pushed screens like
Keamanan at `5%,7%`) are best-effort estimates that weren't verified
against a running emulator. If a flow fails right after one of these taps,
that point is the first thing to check/adjust — search for `point:` in the
affected `.yaml` file.
