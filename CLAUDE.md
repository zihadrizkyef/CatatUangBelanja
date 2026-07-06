# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository layout

This repo contains two independent projects for "Catat Uang Belanja" (a household budgeting app for Indonesian moms — see `Draft Aplikasi Pencatatan Keuangan.md` for the full product spec, written in Indonesian):

- `catat-uang-belanja-android/` — the Flutter app. This is where all current feature work happens; it's a fully offline-first, single-user app with a local SQLite database.
- `catat-uang-belanja-backend/` — an Express + Prisma/Postgres API skeleton for **Tahap 4** (online sync, per the draft doc). It's not wired up to the Flutter app yet — only a `/health` route exists. Don't assume backend endpoints exist for features the Flutter app needs; check the spec's development stages (doc section 10) before building sync-related backend features.

The product spec (`Draft Aplikasi Pencatatan Keuangan.md`) is the source of truth for feature scope, data model, and UX tone — read the relevant section before implementing a feature. Section headings: 1 Ringkasan, 2 Design Language, 3 Tujuan, 4 Fitur Utama, 5 Struktur Data, 6 Alur Pengguna, 7 Wireframe, 8 Non-Fungsional, 9 Asumsi & Batasan, 10 Tahapan Pengembangan.

## Flutter app (`catat-uang-belanja-android/`)

### Commands

Run all commands from inside `catat-uang-belanja-android/`.

```
flutter pub get                        # install dependencies
flutter run                            # run on connected device/emulator
flutter run -d windows|chrome|linux    # run on desktop/web (uses sqflite FFI, see below)
flutter test                           # run all tests
flutter test test/widget_test.dart     # run a single test file
flutter analyze                        # static analysis / lints
```

There is no CI config in this repo; `flutter analyze` and `flutter test` are the checks to run before considering a change done.

### Architecture

- **State management**: a single `FinanceRepository` (`lib/repositories/finance_repository.dart`), a `ChangeNotifier` provided at the app root via `provider` (see `lib/main.dart`). It holds in-memory lists of wallets/categories/transactions/budgets loaded from SQLite on startup (`load()`), and every mutation writes to SQLite then updates the in-memory list and calls `notifyListeners()`. Screens read it via `context.watch<FinanceRepository>()`. There is no other state layer (no BLoC/Riverpod) — new features should extend this repository rather than introducing a new pattern.
- **Storage**: `lib/db/app_database.dart` is a singleton (`AppDatabase.instance`) wrapping a raw `sqflite` `Database` (schema created by hand via `CREATE TABLE`, no migration framework — schema changes mean bumping the `version` and adding `onUpgrade` logic). Seeded on first run with a default cash wallet and the household categories from doc section 2.7.
  - Platform note: `sqflite` only works natively on Android/iOS. `lib/main.dart` wires up `sqflite_common_ffi` for Windows/Linux/macOS and `sqflite_common_ffi_web` for web before `runApp` — any code touching `databaseFactory` needs to preserve this branching or desktop/web builds will hang with no error.
- **Derived data, not stored fields**: wallet balances are always computed from active (non-deleted) transactions (`FinanceRepository.balanceOf`/`totalBalance`), never stored — this matches doc section 4.2. Similarly budget usage (`budgetUsageThisMonth`) is computed on demand from transactions in the current calendar month.
- **Soft delete**: `deleteTransaction` sets `isDeleted` rather than removing the row, to stay safe for the future sync feature (doc 4.1/4.10). The `transactions` getter filters these out; raw `_transactions` still contains them.
- **Transfers**: modeled as a single `Transaction` row with `type = transfer`, using both `walletId` (source) and `targetWalletId` (destination), rather than two paired transactions — see `balanceOf` for how both sides are applied.
- **Models** (`lib/models/`): plain Dart classes with `toMap`/`fromMap` for SQLite (de)serialization — no code generation. `IconType` (system/emoji/photo) is shared across wallets and categories per doc 2.4; every seeded row uses `IconType.system` with a descriptive `iconValue` key (e.g. `category_kitchen`) resolved to a bundled icon via `AppIcons.byIconValue`, not a literal glyph. `BudgetStatus` (`lib/models/budget_status.dart`) pairs a `Budget` with its category and this month's usage — computed by `FinanceRepository.budgetStatuses`, shared by every screen that ranks/displays budget progress.
- **Screens** (`lib/screens/`): one file per bottom-nav tab — `home_screen.dart` (Beranda), `wallet_screen.dart` (Dompet), `summary_screen.dart` (Rangkuman), `settings_screen.dart` (Pengaturan) — plus `budget_screen.dart` (Anggaran, pushed via `Navigator` from the "Kelola"/"Kategori & Anggaran" entry points, not a bottom-nav tab). All hosted by `app_shell.dart`, which owns the `IndexedStack` + custom bottom nav + the "+" FAB that opens `TransactionSheet`. File/class names are English (naming the screen's function, not its Indonesian tab label); **UI strings stay Indonesian**, matching the target audience — keep new UI copy in the same warm, informal tone described in doc section 2.6 (e.g. "Yuk catat belanja hari ini, Bun!"), not technical/corporate phrasing.
- **Theming**: `lib/theme/app_colors.dart` and `app_theme.dart` centralize the palette and text styles — screens read resolved colors via `AppPalette.of(context)` (light/dark tokens) rather than branching on `Theme.of(context).brightness` themselves, and use `AppTheme.body(...)`/`heading(...)` instead of ad-hoc `TextStyle`s. Dark mode is a tri-state (`FinanceRepository.themeMode`, defaulting to `ThemeMode.system`) toggled via `toggleDarkMode()` from Pengaturan.
- **Icons**: `lib/theme/app_icons.dart` maps category/wallet `iconValue` keys and one-off UI icons (nav bar, sync status, medals, etc.) to bundled Twemoji SVGs (`assets/icons/twemoji/`, rendered via `TwemojiIcon`/`flutter_svg`) — chosen over raw emoji glyphs so icons render identically (and in full color) across every device/OS instead of depending on the platform's emoji font. Twemoji is CC-BY 4.0; attribution lives in `assets/icons/twemoji/NOTICE.md` and is surfaced in-app under Pengaturan → Tentang Aplikasi.
- **Fonts**: Baloo2 (headings) and Nunito (body) are bundled as local assets (see `pubspec.yaml`), not fetched via `google_fonts`, so the UI renders correctly offline on first launch.

### Testing notes

- Widget tests need the FFI `sqflite` factory set up manually in `setUpAll` (`sqfliteFfiInit()` + `databaseFactory = databaseFactoryFfi`) since tests run on desktop, not a real device.
- The app's real SQLite I/O during first load does not resolve under `pump()`/`pumpAndSettle()`'s fake clock — tests must call the pump inside `tester.runAsync()` with a real `Future.delayed`, then `pumpAndSettle()` afterward (see existing tests for the pattern).
- Tests that depend on empty-state UI (e.g. "Belum ada transaksi") delete the on-disk database file first to avoid leftover state from previous runs.

## Backend (`catat-uang-belanja-backend/`)

### Commands

Run all commands from inside `catat-uang-belanja-backend/`.

```
npm run dev              # tsx watch src/index.ts — dev server with reload
npm run build             # tsc -> dist/
npm start                 # node dist/index.js (run build first)
npm run prisma:generate   # regenerate Prisma client after schema.prisma changes
npm run prisma:migrate    # create/apply a dev migration
```

Requires a `DATABASE_URL` (Postgres) and `PORT` in `.env` — see `.env.example`. There are no tests or lint scripts configured yet in this project.

### Architecture

- Minimal Express 5 app (`src/app.ts`) exported separately from the listener (`src/index.ts`) — currently only mounts a `/health` router (`src/routes/health.ts`).
- Prisma client in `src/lib/prisma.ts` uses the `@prisma/adapter-pg` driver adapter (not the default Prisma engine binary).
- `prisma/schema.prisma` mirrors the entity list in doc section 5 (User, Wallet, Category, Transaction, Budget, RecurringTransaction, Settings) — this schema is ahead of the actual API implementation, which is still just a health check. When implementing new endpoints, cross-check field names/enums against `schema.prisma` since it's the more precise reference for the data model.
- Auth model (per schema comment and doc 4.10/6.1): phone number + OTP, no password field on `User`.
