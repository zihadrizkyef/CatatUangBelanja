# PM Report — Catat Uang Belanja

Ditulis oleh **Product Manager** (review langsung di perangkat fisik), berdasarkan build debug terkini (working tree, belum di-commit — lihat [AGENT_STATUS.md](AGENT_STATUS.md), [QAREPORT.md](QAREPORT.md), [UXREPORT.md](UXREPORT.md) untuk histori sesi QA/UX/Programmer semalam).

## Status Update — Programmer, 2026-07-25

All 7 findings addressed (PM-01 through PM-06 fixed; PM-07 left as-is, see note):

- **PM-01** (no date/note input) — added a date chip (opens `showDatePicker`, capped at today) and a note `TextField` to `transaction_sheet_view.dart`/`transaction_sheet.dart`. `Transaction.copyWith` gained a `clearNote` flag since the existing `note ?? this.note` pattern couldn't express "clear the note" for edits. Verified end-to-end on-device (edited a transaction's date from "Hari ini" to "20 Jul 2026", confirmed it re-sorted to "5 hari lalu" on Beranda).
- **PM-02** (Top Spending computed from budgets, not transactions) — `summary_screen.dart` now aggregates `topSpending` directly from expense transactions in the active period (reusing the same per-category sum already computed for the donut chart), independent of `budgetStatuses`. Verified on-device: "Hiburan Keluarga" (no budget) now correctly appears ranked #3.
- **PM-03** (invisible transfer icon in dark mode) — same fix as UX-009 (`palette.chipNeutral` instead of hardcoded `AppColors.lightChipNeutral`). Verified on-device in dark mode.
- **PM-04** (no supportive copy on budget warning) — `warning_budget_banner.dart` now shows a category-specific line ("... udah lewat batas/mendekati batas nih, Bun — yuk cek/pantau ... ya 💛") depending on over/near-limit. Verified on-device.
- **PM-05** ("boros" wording) — replaced with "lebih banyak dari sebelumnya" in `summary_view.dart`; "lebih hemat" (positive framing) left unchanged. Verified on-device.
- **PM-06** (no scroll affordance on Tambah Anggaran) — added an explicit `Scrollbar(thumbVisibility: true)` around `budget_sheet_view.dart`'s `SingleChildScrollView`.
- **PM-07** (wallet icon picker has fewer choices than category picker) — not changed. PM's own writeup flags this as "kemungkinan besar bukan bug" (icon = proxy for `WalletType`, and full icon/color customization is explicitly Tahap 5 roadmap per doc section 10) — left for a deliberate roadmap decision rather than a reactive fix.

`flutter analyze` and `flutter test` (19 tests) clean throughout. See [UXREPORT.md](UXREPORT.md) for the overlapping UX-009 fix and QAREPORT.md's existing history.

## Info Sesi

- **Perangkat**: Samsung Galaxy Tab (model **SM-T225**), Android 14 (API 34), fisik via USB — bukan emulator.
- **Build**: `flutter build apk --debug`, versionName 1.0.0 (versionCode 1), commit dasar `7e9906e` + seluruh working-tree changes yang belum di-commit (wallet CRUD, transfer, all-transactions, 6 bug fix QA semalam, dll — lihat `git status`).
- **Metodologi**: instalasi bersih (`pm uninstall` lalu `adb install`, tanpa data lama), lalu dipakai langsung layar demi layar seperti pengguna baru — termasuk memakai fitur "Generate Data Dummy" untuk menguji tampilan dengan data yang lebih realistis. `flutter analyze` bersih sebelum build.
- Laporan ini fokus pada **kelengkapan fitur vs dokumen spesifikasi** (`Draft Aplikasi Pencatatan Keuangan.md`) dan **temuan baru** yang belum tercatat di QAREPORT/UXREPORT semalam (mereka sudah menemukan & memperbaiki 6 bug — QA-001 s/d QA-006 — sebelum sesi ini dimulai).

## Ringkasan Eksekutif

Alur inti (catat transaksi → saldo dompet ter-update → progres anggaran → rangkuman & grafik) **berjalan dan terasa solid** di perangkat fisik — bukan cuma di emulator. Bahasa & nuansa visual (warna pastel hangat, ikon OpenMoji bulat, sapaan "Bun", dark mode yang tetap hangat bukan abu-abu) sudah sangat sesuai dengan Design Language di dokumen spec bagian 2. Multi-wallet, transfer, dan anggaran dengan 3 mode reset (Bulanan/Mingguan/Event) — fitur inti Tahap 2 — semuanya berfungsi dan match dengan spec 4.2–4.4.

Namun ditemukan **2 gap fungsional yang cukup signifikan** untuk alur harian (lihat PM-01 dan PM-02 di bawah), plus beberapa bug/UX kecil baru yang belum tercatat QA/UX semalam. Fitur-fitur yang memang belum ada (login/OTP, sync, PIN/biometric, backup, recurring) sudah sesuai roadmap (Tahap 3+) dan **tidak saya hitung sebagai gap** — itu memang belum waktunya.

## Temuan Baru (belum ada di QAREPORT.md / UXREPORT.md)

### PM-01 — [High] Tidak ada cara mengisi tanggal atau catatan transaksi
**Screen/Flow**: Tambah/Edit Pengeluaran & Pemasukan (`lib/screens/transaction_sheet_view.dart`)

Sheet tambah/edit transaksi cuma punya 3 input: nominal (keypad), kategori, dan dompet. **Tidak ada date/time picker sama sekali** (transaksi selalu tercatat "Hari ini", tidak bisa mencatat belanja kemarin/minggu lalu) dan **tidak ada field catatan/deskripsi**, padahal:

- Spec 4.1 eksplisit menyebut "nominal, tanggal & waktu, dompet terkait, kategori, catatan/deskripsi" sebagai input transaksi.
- Model data (`Transaction.note`), widget tampilan (`home_transaction_row.dart`, `transaction_history_row.dart` — keduanya sudah punya logika menampilkan `note` sebagai sub-label), dan bahkan search bar di layar "Semua Transaksi" ("Cari transaksi...") **sudah dibangun mengasumsikan field note terisi** — tapi satu-satunya cara field itu terisi adalah lewat "Generate Data Dummy" (lihat screenshot: transaksi dummy punya catatan "Token listrik", "Vitamin anak", dll). Pengguna nyata tidak pernah diberi kesempatan mengetik catatan sendiri, jadi fitur pencarian transaksi berdasarkan catatan (spec 4.1) juga jadi mati fungsi buat data asli.
- Untuk target pengguna (ibu-ibu yang sering baru sempat mencatat belanja di malam hari atau beberapa hari kemudian), tidak bisa mengisi tanggal transaksi adalah gap yang cukup terasa di alur harian, bukan cuma kosmetik.

**Rekomendasi**: tambahkan date/time picker dan text field catatan (opsional) di `transaction_sheet_view.dart`, sebelum tombol simpan.

### PM-02 — [High] "Pengeluaran Terbesar" di Rangkuman tidak menghitung dari transaksi, tapi dari ada/tidaknya anggaran
**Screen/Flow**: Rangkuman > "Pengeluaran Terbesar"

**Reproduksi**:
1. Install bersih, tambah satu transaksi Pengeluaran (mis. Belanja Dapur, berapapun nominalnya, tanpa anggaran apapun dibuat).
2. Buka Rangkuman — kartu "Ringkasan Pengeluaran" (donut chart) sudah benar menunjukkan 100% Belanja Dapur.
3. Scroll ke "Pengeluaran Terbesar" — tetap menampilkan empty state "Belum ada pengeluaran untuk dirangking, Bun." meskipun jelas-jelas ada pengeluaran.
4. Buat anggaran untuk kategori "Belanja Dapur" (anggaran manapun, nominal berapapun) → kembali ke Rangkuman → "Belanja Dapur" langsung muncul di "Pengeluaran Terbesar" dengan medali 🥇.

**Root cause**: `lib/screens/summary_view.dart` baris 394–407 memakai `budgetStatuses.isEmpty` sebagai kondisi empty state, dan me-render list dari `budgetStatuses` (pasangan Budget+kategori+usage) — bukan menghitung top kategori langsung dari transaksi pengeluaran seperti seharusnya. Akibatnya: **kategori pengeluaran mana pun yang belum diberi anggaran tidak akan pernah muncul di "Pengeluaran Terbesar"**, walau pengeluarannya besar sekalipun. Ini bug pada fitur yang eksplisit disebut di spec 4.8 ("Daftar kategori dengan pengeluaran terbesar") dan 7.4, dan seharusnya independen dari fitur anggaran.

**Rekomendasi**: hitung top spending dari agregasi transaksi Pengeluaran per kategori pada periode aktif (mirip logika `Ringkasan Pengeluaran`/donut chart di atasnya, yang sudah benar), lepas dari apakah kategori itu punya budget atau tidak.

### PM-03 — [Medium] Ikon baris "Transfer" tak terlihat (invisible) di Mode Gelap
**Screen/Flow**: Beranda > "Transaksi Terbaru", baris transfer

Setelah mengaktifkan Mode Gelap dan melakukan transfer antar dompet, baris "Transfer ke Rekening Bank" di kartu Beranda menampilkan **lingkaran ikon kosong/putih polos** — bukan ikon swap seperti mestinya (dibandingkan `wallet detail`/`Semua Transaksi` yang tidak punya masalah ini karena tidak memakai lingkaran background untuk ikon).

**Root cause**: `lib/widgets/home_transaction_row.dart` baris 44 — untuk transaksi tanpa kategori (saat ini hanya transfer, karena income/expense selalu punya kategori), warna latar lingkaran ikon jatuh ke `AppColors.lightChipNeutral` yang didefinisikan hardcode `Color(0xFFF3ECE6)` (krem hampir putih) di `lib/theme/app_colors.dart:34` — warna ini **tidak mengikuti tema gelap/terang** (namanya sendiri "light..."), sementara warna ikon fallback-nya (`palette.textPrimary`) otomatis jadi terang di dark mode. Hasilnya: ikon terang di atas latar hampir-putih → nyaris tak terlihat kontrasnya, khususnya di dark mode.

**Rekomendasi**: latar ikon untuk baris tanpa kategori (transfer) sebaiknya memakai token warna yang mengikuti tema (`palette.chipNeutral` atau sejenis), bukan konstanta `AppColors.lightChipNeutral` yang selalu terang.

### PM-04 — [Medium] Pesan ramah/suportif belum ada saat anggaran mendekati/melewati batas
**Screen/Flow**: Beranda > banner peringatan anggaran (`lib/widgets/warning_budget_banner.dart`)

Saat anggaran sebuah kategori mencapai ≥80% (dan sudah diverifikasi hingga 100%+ dengan data dummy), banner yang muncul di Beranda hanya menampilkan: nama kategori, "Rp terpakai dari Rp limit", persentase, dan progress bar — **tidak ada satu pun kalimat pesan** di dalamnya. Spec 2.2 ("nada pesan tetap ramah dan memotivasi, bukan terkesan menegur"), 2.6 ("Pesan pencapaian maupun pengingat anggaran... disampaikan dengan nada apresiatif dan suportif"), 4.4, dan 6.4 poin 4 semuanya secara eksplisit meminta *pesan* ramah pada momen ini — bukan cuma angka. Sebagai perbandingan, empty-state anggaran ("Belum ada anggaran, Bun. Yuk mulai atur...") dan status aman ("Semua anggaran masih aman, Bun. Mantap!") sudah punya copy yang pas — tapi justru momen paling penting (mendekati/lewat batas) yang belum ada copy-nya sama sekali.

**Rekomendasi**: tambahkan satu baris copy suportif di `WarningBudgetBanner` (mis. "Belanja Hiburan Keluarga udah lewat batas nih, Bun — yuk cek lagi ya 💛"), bukan cuma nama kategori dan angka.

### PM-05 — [Low] Kata "boros" di perbandingan Rangkuman terasa sedikit menghakimi
**Screen/Flow**: Rangkuman > kartu "Bulanan ini vs sebelumnya"

Ketika pengeluaran bulan ini lebih besar dari bulan lalu, badge menampilkan "▲ 100% **lebih boros**". Kata "boros" dalam Bahasa Indonesia punya konotasi menghakimi (berarti "pemboros/menghambur-hamburkan uang"), berlawanan dengan prinsip desain 2.2 yang eksplisit: "Suportif, bukan menghakimi... nada pesan tetap ramah dan memotivasi, bukan terkesan menegur" — dan bagian ini secara spesifik mencontohkan skenario persis seperti ini ("Saat pengeluaran membengkak..."). Severity rendah karena bukan blocker, tapi tone-nya tidak konsisten dengan bagian lain aplikasi yang sudah rapi menghindari nada menegur.

**Rekomendasi**: ganti dengan frasa netral seperti "lebih banyak dari bulan lalu" atau "naik dari bulan lalu".

### PM-06 — [Low] Sheet "Tambah Anggaran" perlu di-scroll untuk mencapai tombol simpan, tanpa petunjuk visual
**Screen/Flow**: Anggaran > Tambah Anggaran

Berbeda dari kasus QA-003 (yang sudah di-fix — tombol benar-benar tak terjangkau karena tertutup nav bar sistem), di sini kontennya memang lebih panjang dari layar (grid kategori + pemilih periode + pemilih tanggal reset + keypad) sehingga wajar perlu di-scroll, dan scroll-nya berfungsi baik. Yang saya catat: **tidak ada indikasi visual** (fade di tepi bawah, chevron, dsb) bahwa sheet ini bisa di-scroll — pengguna baru berpotensi mengira sheet-nya "kepotong" atau tombol simpannya hilang, terutama di perangkat dengan layar lebih pendek seperti tablet ini (800×1340).

**Rekomendasi**: pertimbangkan indikator scroll tipis di tepi bawah sheet, atau pindahkan tombol simpan ke luar area yang di-scroll (persistent footer) khusus untuk sheet ini.

### PM-07 — [Low] Wallet icon picker jauh lebih terbatas dibanding Kategori (4 vs 13 pilihan), tanpa pilihan warna di keduanya
**Screen/Flow**: Dompet > Tambah/Edit Dompet vs Pengaturan > Kelola Kategori > Tambah/Edit Kategori

Sheet Tambah Dompet hanya menawarkan 4 pilihan ikon (tampaknya 1 per `WalletType`), sementara sheet kategori punya 13 pilihan ikon lucu bertema rumah tangga. Spec 5.1 memisahkan field `type` (5 enum: Cash/Bank/EWallet/Savings/Other) dari `icon_value`, tapi UI Tambah Dompet tampaknya menyatukan keduanya (icon = proxy untuk type) sehingga pilihan visualnya jauh lebih sempit untuk dompet dibanding kategori. Ini kemungkinan besar **bukan bug** — kustomisasi warna & ikon emoji/foto memang dijadwalkan Tahap 5 di roadmap (bagian 10) — tapi kesenjangan jumlah pilihan ikon antara dompet vs kategori terasa tidak konsisten dan sayang secara polish, mengingat dompet ("Dompet Tunai", "Tabungan", dll) sama-sama butuh personalisasi visual seperti kategori.

## Konfirmasi Hal yang Sudah Bekerja Baik (sanity check di perangkat fisik)

- **Alur inti**: tambah pengeluaran/pemasukan → saldo dompet & Total Saldo ter-update instan, transaksi langsung muncul di Beranda & Semua Transaksi. Cepat, terasa di bawah 1 detik sesuai NFR 8.
- **Multi-wallet & Transfer** (spec 4.2/4.3): 4 dompet default sesuai contoh di spec, transfer antar dompet menghitung saldo kedua sisi dengan benar dan tidak memengaruhi Total Saldo — sesuai spec.
- **Anggaran 3 mode** (spec 4.4): Bulanan (dengan pemilih tanggal reset 1–31), Mingguan, dan Event semuanya tersedia di sheet Tambah Anggaran; tombol "Reset Sekarang" ada; progress bar berubah warna (hijau→oranye→merah) sesuai ambang batas.
- **Rangkuman & Grafik** (spec 4.8/4.9): pemilih periode Harian/Mingguan/Bulanan/Tahunan, donut chart komposisi pengeluaran, line chart tren pemasukan vs pengeluaran, perbandingan periode — semua tampil dan menyesuaikan data dengan benar.
- **Dark Mode** (spec 4.6): toggle instan tanpa restart, palet tetap hangat (coklat tua/maroon, bukan abu-abu/hitam pekat) sesuai spec 2.3, kontras teks tetap terjaga di semua layar yang saya cek (Beranda, Rangkuman, Pengaturan, Kategori) — kecuali PM-03 di atas.
- **Kategori bawaan** (spec 2.7): 8 kategori pengeluaran default persis sesuai daftar di spec, muncul lengkap dengan ikon OpenMoji bertema rumah tangga.
- **Delete confirmations**: "Hapus Semua Data" di Pengaturan sudah pakai dialog konfirmasi yang jelas ("...tidak bisa dikembalikan. Yakin mau lanjut, Bun?") dengan tombol Batal/Ya, Hapus — friction yang tepat untuk aksi destruktif.
- **Scoping roadmap**: fitur Login/OTP, sinkronisasi, PIN/biometric, backup/restore, dan recurring transaction semuanya **konsisten belum ada** atau berupa stub "Segera hadir ✨" (Keamanan, Notifikasi, Profil, Bahasa) — sesuai roadmap Tahap 3+ di dokumen spec bagian 10, bukan gap untuk versi saat ini.
- **6 bug dari sesi QA semalam** (QA-001 s/d QA-006) sudah tervalidasi fixed dalam build yang sama yang saya uji di tablet — termasuk fix reachability tombol di 5 bottom sheet (QA-003) yang saya konfirmasi ulang di perangkat fisik berbeda (tablet, bukan emulator) tanpa masalah serupa.

## Risiko yang Perlu Diperhatikan (bukan bug, tapi relevan untuk keputusan produk)

- **Tidak ada proteksi akses sama sekali saat ini** (Keamanan masih stub) — untuk aplikasi yang menyimpan data keuangan keluarga dan secara eksplisit ditujukan untuk dipakai bergantian dengan anak/anggota keluarga lain (spec 4.11), ini wajar untuk tahap sekarang tapi sebaiknya tetap diprioritaskan tinggi begitu masuk Tahap 3, bukan ditunda-tunda.
- **"DEBUG" ribbon** di pojok kanan atas setiap layar adalah artefak normal Flutter debug build (akan hilang di build release/profile) — bukan bug aplikasi, tapi pastikan tidak lupa build mode `--release` sebelum demo ke pengguna asli atau stakeholder non-teknis.

## Prioritas yang Disarankan

1. **PM-02** (Top Spending salah hitung) — fix logika-nya kecil (satu fungsi agregasi), tapi ini fitur yang eksplisit ada di spec dan saat ini selalu salah/kosong untuk kategori tanpa anggaran.
2. **PM-01** (tidak ada input tanggal/catatan) — dampak terbesar ke pengalaman harian pengguna nyata; perlu effort UI lebih besar (date picker + text field) tapi field & tampilannya sudah separuh jalan (model data & widget list sudah siap, tinggal input-nya).
3. **PM-03** (ikon transfer tak terlihat di dark mode) — quick fix satu baris warna.
4. **PM-04** (pesan suportif anggaran) — quick fix copy, tapi selaras langsung dengan salah satu prinsip desain inti aplikasi (2.2).
5. PM-05, PM-06, PM-07 — polish, bisa disatukan dengan pekerjaan UI lain yang relevan.

## Riset Pasar: Fitur Unggulan Aplikasi Kompetitor vs Status di App Ini

Untuk melengkapi review internal di atas, saya riset fitur-fitur yang jadi andalan aplikasi pencatatan keuangan populer (Money Lover, Wallet by BudgetBakers, Spendee, YNAB, PocketGuard, Monarch Money, dkk — lihat sumber di bawah), lalu cek satu per satu apakah sudah ada, sudah direncanakan (sesuai roadmap Tahap di spec), atau memang di luar cakupan produk ini.

| Fitur andalan di aplikasi kompetitor | Ada di spec produk ini? | Status di app (hasil cek langsung) |
|---|---|---|
| Multi-wallet (tunai/bank/e-wallet/tabungan) | Ya — 4.2 | ✅ Ada & jalan baik |
| Transfer antar dompet tanpa ganggu rangkuman | Ya — 4.3 | ✅ Ada & jalan baik |
| Anggaran per kategori + alert mendekati/lewat batas | Ya — 4.4 | ✅ Ada, tapi alert-nya cuma angka tanpa pesan suportif (**PM-04**) |
| Kategori custom dengan ikon bertema | Ya — 2.4/2.7 | ✅ Ada, 13 pilihan ikon per kategori |
| **Scan struk otomatis (OCR isi nominal/kategori)** | Tidak — spec cuma sebut "opsional foto struk" sebagai lampiran biasa (4.1), bukan OCR | ❌ Belum ada sama sekali. Field `attachment_url` sudah disiapkan di database (`transaction.dart`) tapi **tidak dipakai di satupun layar** — bahkan upload foto polos (tanpa OCR) belum ada. Upload foto memang dijadwalkan Tahap 5 di roadmap; OCR sendiri tidak pernah masuk cakupan dokumen spec — kalau mau bersaing dengan Money Lover/Spendee/Wallet, ini layak dipertimbangkan sebagai penambahan scope, bukan cuma upload foto polos. |
| Transaksi berulang (tagihan/cicilan) + reminder jatuh tempo | Ya — 4.5 | ❌ Belum ada, sesuai roadmap Tahap 6 — belum waktunya |
| Notifikasi push (pengingat mencatat / tagihan) | Tersirat — 4.5 | ❌ Belum ada; dicek `pubspec.yaml` — tidak ada package notifikasi lokal terpasang sama sekali, konsisten dengan Tahap 6 |
| **Savings goal bertarget dengan progress bar** (mis. "Nabung buat Lebaran, 60% tercapai") | Cuma disebut sekilas sbg konteks ilustrasi (2.4: "pencapaian target tabungan"), **tidak** jadi item fitur utuh di bagian 4 manapun | ❌ Tidak ada di spec sebagai fitur, dan tidak ada di app. Ini salah satu fitur paling sering jadi favorit di Money Lover (dompet khusus goal) dan BudgetBakers — worth diusulkan utk versi mendatang karena relevan banget buat target ibu-ibu (dana sekolah anak, lebaran, dst), tapi ini rekomendasi fitur baru di luar dokumen spec saat ini, bukan gap implementasi. |
| Shared/family access antar anggota keluarga | Eksplisit di luar cakupan v1 — bagian 9 | ❌ Belum ada, sesuai spec (dipertimbangkan "pengembangan lanjutan") |
| Sinkronisasi otomatis ke rekening bank | Di luar cakupan produk (by design — manual entry, offline-first) | N/A — bukan tujuan produk ini, beda filosofi dari Wallet/Money Lover yang bank-sync |
| PIN / biometric lock | Ya — 4.11 | ❌ Stub "Segera hadir ✨", sesuai Tahap 3 |
| Backup & restore ke cloud | Ya — 4.7 | ❌ Menunya belum ada sama sekali di Pengaturan, sesuai Tahap 3 |
| Pencarian transaksi | Ya — 4.1 | ⚠️ UI search bar sudah ada di "Semua Transaksi", tapi nyaris tak berguna karena field catatan tidak pernah bisa diisi pengguna (**PM-01**) |
| Grafik pie/donut + tren garis pemasukan-pengeluaran | Ya — 4.9 | ✅ Ada & bagus, custom-painted tanpa dependency chart pihak ketiga |
| Filter transaksi (dompet/kategori/jenis) | Ya — 4.1 | ✅ Ada (tab Semua/Pengeluaran/Pemasukan + 2 dropdown filter) |

**Kesimpulan riset**: sebagian besar fitur "wow" yang jadi pembeda aplikasi kompetitor (scan struk OCR, transaksi berulang, notifikasi, PIN, backup, sync) memang **sudah dipikirkan dan dijadwalkan** di roadmap Tahap 3–6 dokumen spec — bukan terlewat, cuma belum waktunya. Satu-satunya fitur populer di kompetitor yang **belum tercatat sama sekali di dokumen spec** adalah **savings goal / target tabungan dengan progress visual** — worth didiskusikan apakah mau ditambahkan ke roadmap, mengingat ini relevan dengan use case ibu-ibu (nabung buat sekolah anak, lebaran, dst.) dan cukup murah untuk diimplementasi karena bisa dibangun di atas struktur Budget yang sudah ada (tinggal ubah maknanya dari "batas pengeluaran" jadi "target terkumpul").

**Sumber riset**:
- [Best Personal Finance Tracker Apps for Every Goal in 2026 — Mindful Suite](https://www.mindfulsuite.com/reviews/best-personal-finance-tracker-apps)
- [Best Budgeting Apps of 2026 — Forbes Advisor](https://www.forbes.com/advisor/banking/best-budgeting-apps/)
- [The Best Budget Apps for 2026 — NerdWallet](https://www.nerdwallet.com/finance/learn/best-budget-apps)
- [Money Lover — Google Play](https://play.google.com/store/apps/details?id=com.bookmark.money&hl=en_US)
- [Wallet by BudgetBakers](https://budgetbakers.com/en/products/wallet/)
- [Wallet by BudgetBakers Review 2026 — Finny Blog](https://getfinny.app/blog/wallet-budgetbakers-review-2026)
- [Best App That Scans Receipts for Your Budget in 2026 — Finny Blog](https://getfinny.app/blog/app-that-scans-receipts-for-budget)
- [15 Aplikasi Pengatur Keuangan Terbaik untuk Android & iOS — RuangMom](https://www.ruangmom.com/aplikasi-pengatur-keuangan.html)
- [5 Rekomendasi Aplikasi Pencatatan Keuangan Rumah Tangga Gratis — PINA](https://pina.id/artikel/detail/5-rekomendasi-aplikasi-pencatatan-keuangan-rumah-tangga-gratis-0ua90k3x5eb)
