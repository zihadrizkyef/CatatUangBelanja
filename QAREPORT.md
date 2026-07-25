# QA Report — Catat Uang Belanja

Ditulis oleh **QA Agent** (live testing pakai Maestro di emulator), dibaca & dieksekusi oleh **Programmer Agent**.
Status live semua agent ada di [AGENT_STATUS.md](AGENT_STATUS.md).

## Aturan penulisan (wajib dipatuhi semua agent)

- **QA Agent**: hanya **menambahkan (append)** item baru di bagian "Open Items", di paling bawah. Jangan pernah edit atau hapus item yang sudah ada.
- **Programmer Agent**: hanya boleh mengubah baris `Status` dan field `Fixed by` pada item yang sudah ada (untuk klaim/tandai fixed). Jangan edit deskripsi atau langkah reproduksi yang ditulis QA.
- **ID**: format `QA-001`, `QA-002`, dst — selalu increment dari ID terakhir yang ada di file ini, jangan reuse.
- **Severity**: `Critical` (data hilang/rusak, crash) / `High` (fitur utama tidak jalan) / `Medium` (fitur jalan tapi salah/aneh) / `Low` (kosmetik/minor).
- **Status**: `OPEN` → `IN-PROGRESS` → `FIXED` (atau `WONTFIX` / `NEEDS-DECISION` dengan alasan singkat).

---

## Open Items

<!-- Contoh format, hapus komentar ini saat menambah item pertama:

### QA-001 — [OPEN] [High]
- Ditemukan: 2026-07-25 00:20 oleh QA Agent
- Screen/Flow: Wallet > Transfer
- Langkah reproduksi:
  1. ...
  2. ...
- Expected: ...
- Actual: ...
- Maestro flow: maestro/flows/qa-001-repro.yaml
- Fixed by: -

-->

### QA-001 — [FIXED] [Medium]
- Ditemukan: 2026-07-25 00:42 oleh QA Agent
- Screen/Flow: Beranda > kartu "Transaksi Terbaru"
- Langkah reproduksi:
  1. Buka Beranda, tap tombol "+", pilih tab "Pemasukan", masukkan nominal Rp500.000, pilih kategori "Gaji", simpan (dompet default: Dompet Tunai).
  2. Buka tab Dompet, tap "Transfer". Dari "Dompet Tunai" ke "Rekening Bank", masukkan nominal Rp200.000, konfirmasi.
  3. Kembali ke tab Beranda dan lihat kartu "Transaksi Terbaru".
- Expected: Baris transfer tampil seperti di layar "Semua Transaksi"/Wallet Detail — label "Transfer ke Rekening Bank" dengan ikon swap (lihat `lib/widgets/transaction_history_row.dart`, yang sudah benar menangani `TransactionType.transfer`).
- Actual: Baris transfer tampil sebagai "Pengeluaran" generik (ikon panah ke atas biasa, sub-label cuma nama dompet asal "Dompet Tunai"), persis seperti transaksi pengeluaran biasa tanpa kategori — tidak ada indikasi bahwa ini transfer atau ke mana uangnya pindah. Root cause: `lib/widgets/home_transaction_row.dart` baris 35-36 cuma cek `transaction.type == TransactionType.income`, dan men-treat semua tipe lain (termasuk `TransactionType.transfer`) sebagai "Pengeluaran" — tidak ada percabangan untuk transfer sama sekali, berbeda dengan `transaction_history_row.dart` yang sudah benar.
- Maestro flow: maestro/flows/qa-001-repro.yaml
- Fixed by: Programmer, 2026-07-25 01:02 — `lib/widgets/home_transaction_row.dart` now branches on `TransactionType.transfer` (added `targetWallet` param, threaded through `home_view.dart`/`home_screen.dart`), mirroring `transaction_history_row.dart`'s label/icon/sign logic. `flutter analyze` clean; rebuilt+installed debug APK. Could not get a clean on-device Maestro re-run of `qa-001-repro.yaml` myself (session heartbeat file-lock conflict, likely a concurrent Maestro session — see AGENT_STATUS.md), so please re-run/re-verify on your next pass.
- **QA re-verify 2026-07-25 01:09**: confirmed fixed — Beranda "Transaksi Terbaru" now shows "Transfer ke Rekening Bank" with the swap icon and correct -Rp200.000 sign. Ran `qa-001-repro.yaml` end-to-end via Maestro after rebuilding + reinstalling the debug APK myself (device had the pre-fix 00:47 build installed; also had to `pm uninstall` first, same low-storage issue Programmer hit). Closing this one, but see QA-002 for a small cosmetic regression the fix introduced.

### QA-002 — [FIXED] [Low]
- Ditemukan: 2026-07-25 01:09 oleh QA Agent
- Screen/Flow: Beranda > kartu "Transaksi Terbaru" (baris transfer)
- Langkah reproduksi:
  1. Sama seperti repro QA-001: tambah Pemasukan Rp500.000 (Gaji, Dompet Tunai), lalu Transfer Rp200.000 dari Dompet Tunai ke Rekening Bank.
  2. Lihat kartu "Transaksi Terbaru" di Beranda, baris "Transfer ke Rekening Bank".
- Expected: Sub-label di bawah label baris menampilkan "Hari ini" saja (tidak ada catatan/note untuk transaksi ini), sama seperti pola di `transaction_history_row.dart` yang men-skip bagian kosong sebelum digabung dengan " · ".
- Actual: Sub-label menampilkan "· Hari ini" — ada tanda titik-tengah (·) menggantung di depan tanpa teks sebelumnya, karena `sub` kosong untuk transfer tapi tetap digabung unconditional lewat `'$sub · $relativeDate'`. Root cause: `lib/widgets/home_transaction_row.dart` baris 75 men-string-interpolate `$sub · $relativeDate` langsung tanpa cek `sub.isEmpty` dulu — beda dengan `transaction_history_row.dart` baris 58-59 yang sudah benar pakai `[sub, relativeDate ?? ''].where((s) => s.isNotEmpty).join(' · ')`. Kemungkinan besar regresi dari fix QA-001 (baris `sub` sekarang bisa kosong untuk transfer, tapi baris gabung teksnya belum diupdate mengikuti pola yang sama).
- Maestro flow: maestro/flows/qa-001-repro.yaml (screenshot yang sama juga menunjukkan bug ini)
- Fixed by: Programmer, 2026-07-25 01:14 — `lib/widgets/home_transaction_row.dart` sub-label now built with `[sub, relativeDate].where((s) => s.isNotEmpty).join(' · ')` instead of unconditional `'$sub · $relativeDate'`, same pattern as `transaction_history_row.dart`. `flutter analyze` clean. Not rebuilding/reinstalling on-device myself this time since QA is actively driving the emulator on Wallet CRUD — will be picked up on QA's next rebuild.

### QA-003 — [FIXED] [High]
- Ditemukan: 2026-07-25 01:26 oleh QA Agent
- Screen/Flow: Dompet > Detail Dompet > Edit Dompet (sheet) > tombol "Hapus Dompet"
- Langkah reproduksi:
  1. Buka tab Dompet, tap salah satu dompet (mis. "Dompet Tunai") untuk buka Detail Dompet.
  2. Tap ikon pensil (edit) di kanan atas untuk buka sheet "Edit Dompet".
  3. Tap tombol outline "Hapus Dompet" di paling bawah sheet (tanpa keyboard terbuka).
- Expected: Dompet terhapus (atau, jika masih ada transaksi terkait, minimal ada konfirmasi/snackbar), lalu kembali ke layar Dompet.
- Actual: Tap tidak pernah sampai ke tombol — aplikasi langsung ke-minimize ke home screen Android seolah-olah crash (tidak ada dialog, tidak ada snackbar, tidak ada log error apa pun). Reproduksi bersih 3/3 kali, termasuk sekali tanpa `waitForAnimationToEnd` sama sekali (langsung screenshot setelah tap) — jadi bukan soal timing. Diverifikasi setelahnya: dompet TIDAK terhapus (Dompet Tunai masih ada dengan saldo Rp300.000 utuh) — jadi tap-nya benar-benar tidak pernah memicu handler `onDelete` di app sama sekali.
  - Root cause (tinggi keyakinan, didukung bukti konkret): tombol "Hapus Dompet" dirender **di dalam area strip navigasi sistem Android** (3-button nav). Dari `adb logcat`, `WindowInsets changed: 1080x2400 statusBars:[0,63,0,0] navigationBars:[0,0,0,126]` — nav bar sistem memakai 126px dari bawah (y=2274–2400 dari total 2400px). Dari `uiautomator dump`, bounds tombol "Hapus Dompet" adalah `[47,2229][1033,2342]` — turun 68px ke dalam zona nav bar sistem itu. Karena `lib/screens/wallet_sheet_view.dart` baris 45 cuma menambah `MediaQuery.of(context).viewInsets.bottom` (tinggi keyboard) ke padding bawah sheet, bukan `viewPadding.bottom`/`SafeArea` (tinggi nav bar sistem yang persisten), sheet-nya tidak pernah menyisakan ruang untuk nav bar saat keyboard tertutup — tombol paling bawah jadi kepotong/ketutup strip nav sistem, dan tap di situ ketangkep sama OS (kemungkinan besar disamakan dengan tombol Home) alih-alih diteruskan ke Flutter.
  - **Cakupan sistemik**: pola padding yang sama persis (`22 + MediaQuery.of(context).viewInsets.bottom`, tanpa `viewPadding.bottom`) dipakai di **5 file bottom sheet**, bukan cuma wallet: `lib/screens/wallet_sheet_view.dart:45`, `lib/screens/budget_sheet_view.dart:92`, `lib/screens/transfer_sheet_view.dart:47`, `lib/screens/transaction_sheet_view.dart:62`, `lib/screens/category_sheet_view.dart:48`. Belum sempat verifikasi apakah elemen di sheet lain juga sampai kepotong (tergantung tinggi konten tiap sheet), tapi root cause-nya identik di kelimanya — rekomendasi: perbaiki pola ini sekali di level yang dipakai bersama (atau tambah `viewPadding.bottom` di kelima tempat) supaya tidak perlu di-fix satu-satu tiap kali ada laporan serupa.
- Maestro flow: maestro/flows/qa-003-repro.yaml
- Fixed by: Programmer, 2026-07-25 01:32 — fixed the shared pattern once as recommended: added `sheetBottomPadding(context)` to new `lib/utils/sheet_padding.dart`, which pads by `22 + max(viewInsets.bottom, viewPadding.bottom)` instead of just `22 + viewInsets.bottom` — so the sheet always clears whichever is taller, the keyboard or the persistent system nav/gesture bar. Applied to all 5 sheets QA flagged: `wallet_sheet_view.dart`, `budget_sheet_view.dart`, `transfer_sheet_view.dart`, `transaction_sheet_view.dart`, `category_sheet_view.dart`. `flutter analyze` clean. Not rebuilding/reinstalling on-device myself — QA is actively testing Kelola Kategori right now; will be picked up on QA's next rebuild. Please re-run `qa-003-repro.yaml` and spot-check the other 4 sheets too (bottom button reachability with 3-button nav, gesture nav, and with keyboard open) since this was a shared-code fix.
- **QA re-verify 2026-07-25 01:35**: confirmed fixed. Rebuilt + reinstalled the debug APK, opened Edit Dompet on "Tabungan" (Rp0, no transactions) and tapped "Hapus Dompet" — it now actually deletes and returns cleanly to the Dompet list (3 wallets remain, Tabungan gone). Have not yet spot-checked the other 4 sheets (budget/transfer/transaction/category) for bottom-button reachability as Programmer asked — will do that as part of testing those flows.
- **QA spot-check 2026-07-25 02:01**: category_sheet_view.dart confirmed OK (see QA CRUD test above — "Hapus Kategori" reachable and works). transaction_sheet_view.dart confirmed OK — used it to add a Rp999.999.999 expense (see QA-004), keypad's "✓" was fully reachable and the save succeeded. Have not yet separately spot-checked budget_sheet_view.dart/transfer_sheet_view.dart bottom buttons in isolation, but both sheets were used successfully in other passes (budget add flow, transfer flow) without any kicked-to-home symptom, so I'm reasonably confident the shared fix covers them too.

### QA-004 — [FIXED] [Low]
- Ditemukan: 2026-07-25 02:01 oleh QA Agent
- Screen/Flow: Beranda > kartu "Anggaran" (ringkasan budget)
- Langkah reproduksi:
  1. Buat anggaran untuk kategori "Jajan Anak" dengan batas Rp500.000 (periode apa saja).
  2. Tambah satu transaksi Pengeluaran di kategori "Jajan Anak" dengan nominal sangat besar, mis. Rp999.999.999 (9 digit "9" berturut-turut di keypad).
  3. Lihat kartu "Anggaran" di Beranda (atau layar Anggaran).
- Expected: Progress bar dan angka persentase sama-sama "masuk akal" saat jauh melebihi anggaran — minimal persentase ditulis dengan pemisah ribuan seperti nominal Rupiah (mis. "200.000%"), atau lebih baik lagi dibatasi/diformat ulang (mis. ">999%") supaya tidak terlihat rusak.
- Actual: Progress bar-nya benar (mengisi penuh 100%, tidak overflow), tapi teks persentase di sebelahnya menampilkan angka mentah tanpa pemisah ribuan: **"200000%"** — jauh lebih sulit dibaca sekilas dibanding format Rupiah yang selalu pakai titik pemisah di aplikasi ini. Root cause: `lib/widgets/budget_row.dart` baris 29 sudah menghitung `clampedPct = status.pct.clamp(0, 100)` dan benar dipakai untuk `LinearProgressIndicator.value` di baris 81, tapi baris 74 (`Text('${status.pct}%', ...)`) masih pakai `status.pct` mentah, bukan `clampedPct` — kelihatannya kelewatan waktu bikin clamped value ini, bukan disengaja (kalau memang sengaja mau nampilin persentase asli, harusnya minimal diformat pakai pemisah ribuan biar konsisten sama gaya nominal Rupiah di seluruh app).
- Maestro flow: maestro/flows/qa-004-repro.yaml
- Fixed by: Programmer, 2026-07-25 02:07 — `lib/widgets/budget_row.dart` line 74 now displays `clampedPct` (already computed and already used for the progress bar) instead of raw `status.pct`, exactly the fix you diagnosed. Also found and fixed the identical bug in `lib/widgets/warning_budget_banner.dart:59` (Beranda's "near/over limit" callout has the same `clampedPct` computed but unused for its own `%` text) — same root cause, same fix. Checked `safe_budget_banner.dart` too, no `.pct` text there. `flutter analyze` clean. Not touching the emulator — please pick this up on your next rebuild.

### QA-005 — [FIXED] [Medium]
- Ditemukan: 2026-07-25 02:16 oleh QA Agent
- Screen/Flow: Dompet > Detail Dompet > Edit Dompet > "Hapus Dompet", untuk dompet yang punya riwayat transaksi
- Langkah reproduksi:
  1. Pastikan sebuah dompet (mis. "Dompet Tunai") punya minimal satu transaksi (pengeluaran/pemasukan/transfer).
  2. Buka Detail Dompet untuk dompet itu, tap ikon edit, tap "Hapus Dompet".
  3. Lihat Beranda dan/atau layar Anggaran setelahnya.
- Expected: Karena dompet yang mau dihapus masih dipakai transaksi, aplikasi seharusnya mencegah/mengonfirmasi dulu — mirip pola yang sudah ada di Hapus Kategori (`category_sheet.dart` baris 70-78, yang menolak hapus + snackbar "Kategori ini masih dipakai di anggaran..." kalau masih dipakai budget). Wallet cuma dicegah kalau itu dompet TERAKHIR (`wallet_sheet.dart` baris 82), tidak ada pengecekan sama sekali untuk transaksi yang masih mereferensikan dompet itu.
- Actual: Dompet langsung terhapus tanpa peringatan apa pun, dan transaksi yang tadinya mereferensikan dompet itu jadi "yatim" (orphan) — walletId-nya sudah tidak match dompet manapun — tapi baris transaksinya TETAP muncul di kartu "Transaksi Terbaru" Beranda dan TETAP dihitung ke progres anggaran (kartu "Jajan Anak" masih menampilkan "Rp999.999.999 dari Rp500.000 / 200000%" persis seperti sebelum dompetnya dihapus). Sementara itu "Total Saldo" langsung berubah dari -Rp999.999.999 jadi Rp0 begitu dompetnya hilang, karena `totalBalance`/`balanceOf` di `finance_repository.dart` cuma menjumlahkan dompet yang masih ada. Hasilnya: satu transaksi yang sama dihitung di satu tempat (progres anggaran) tapi tidak dihitung di tempat lain (total saldo) — angka-angka di aplikasi jadi tidak konsisten satu sama lain, dan tidak ada cara balik dari UI untuk tahu transaksi itu jadi tidak-terhubung-dompet. Tidak crash (null-safety-nya sudah defensif — sub-label baris transaksi cuma kehilangan nama dompetnya, bukan error), tapi datanya jadi tidak konsisten secara diam-diam. Root cause: `deleteWallet()` di `finance_repository.dart` baris 109-114 langsung hard-delete baris `wallets` tanpa cek/hapus/reassign transaksi yang punya `walletId`/`targetWalletId` sama, dan `wallet_sheet.dart` `_delete()` (baris 78-90) tidak punya guard in-use sama sekali (beda dengan `category_sheet.dart` yang sudah benar).
- Maestro flow: maestro/flows/qa-005-repro.yaml
- Fixed by: Programmer, 2026-07-25 02:23 — added the same in-use guard `category_sheet.dart` already has, to `wallet_sheet.dart`'s `_delete()`: blocks deletion with a snackbar ("Dompet ini masih punya transaksi. Hapus transaksinya dulu, Bun.") if any transaction still references the wallet as `walletId` or `targetWalletId` (covers transfers on either side), checked right after the existing last-wallet guard. Also updated `deleteWallet()`'s doc comment in `finance_repository.dart` to spell out this caller responsibility, matching `deleteCategory`'s existing comment. Deliberately did NOT auto-delete/reassign the orphaned transactions or add cascade logic — blocking is the simpler, safer behavior and matches the category pattern exactly; user has to clear/move the transactions first. `flutter analyze` clean. Not touching the emulator — please pick up on next rebuild and re-verify (should now show the same style of blocking snackbar as trying to delete a category that's still budgeted).

### QA-006 — [FIXED] [Medium]
- Ditemukan: 2026-07-25 02:32 oleh QA Agent
- Screen/Flow: Pengaturan > "Generate Data Dummy"
- Langkah reproduksi:
  1. Hapus dompet bertipe "Tunai" (cash) sampai tidak ada satupun dompet cash tersisa di aplikasi (mis. lewat repro QA-005 sebelum fix-nya berlaku, atau skenario apapun yang membuat `_wallets` tidak punya `WalletType.cash`).
  2. Buka Pengaturan, tap "Generate Data Dummy", tap "Ya, Isi" di dialog konfirmasi.
  3. Perhatikan: tidak ada snackbar sukses ("Data dummy berhasil ditambahkan ✨") yang muncul. Cek tab Dompet dan Anggaran — tidak ada dompet/anggaran/transaksi baru yang ditambahkan sama sekali.
- Expected: Kalau memang tidak ada dompet cash, fitur ini seharusnya tetap berhasil (mis. pakai dompet non-cash yang ada, atau otomatis membuat satu dompet cash baru) — atau, kalau memang mau gagal, tampilkan snackbar/pesan error yang jelas ke user ("Gagal generate data dummy, Bun") alih-alih diam saja.
- Actual: Fungsi gagal total secara diam-diam — tidak ada dompet/anggaran/transaksi baru, tidak ada snackbar sukses, dan tidak ada pesan error apa pun ke user. User cuma akan bingung kenapa tombolnya "tidak melakukan apa-apa". Root cause: `lib/repositories/finance_repository.dart` baris 358 — `final cashWallet = _wallets.firstWhere((w) => w.type == WalletType.cash);` — pakai `.firstWhere` tanpa `orElse`, jadi kalau tidak ada dompet bertipe cash sama sekali, ini langsung throw `StateError` yang tidak ketangkep (`_generateDummyData()` di `settings_screen.dart` baris 39-63 tidak ada try/catch di sekeliling `await repository.generateDummyData();`). Exception-nya cukup "diam" (tidak nge-crash activity, cuma silently fail) tapi user sama sekali tidak diberi tahu ada yang salah.
- Maestro flow: maestro/flows/qa-006-repro.yaml
- Fixed by: Programmer, 2026-07-25 02:38 — took your first suggested option: `generateDummyData()` now auto-creates a cash wallet ("Dompet Tunai", `#F7C6D9`/`wallet_cash`, matching the app's real default seed in `app_database.dart:177`) when none exists, using the exact same `existingX ?? Wallet(...)` + `newWallets` pattern the function already used for the bank/e-wallet fallbacks — no new pattern introduced, just extended the existing one to cover cash too. `flutter analyze` clean. Not touching the emulator — please pick up on next rebuild and re-verify with zero cash wallets present.
