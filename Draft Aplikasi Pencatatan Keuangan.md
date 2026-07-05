# Draft Aplikasi Pencatatan Keuangan

Dokumen Rancangan Fitur & Struktur — Versi 0.4
Disusun untuk: Zihad
Tanggal: 4 Juli 2026

## 1. Ringkasan

Dokumen ini merupakan draft rancangan untuk aplikasi pencatatan keuangan pribadi yang dirancang khusus untuk ibu-ibu pengelola keuangan keluarga. Aplikasi memungkinkan pengguna mencatat transaksi masuk dan keluar, mengelola beberapa dompet sekaligus, memindahkan dana antar dompet, mengatur anggaran per kategori, menjadwalkan transaksi berulang (seperti tagihan bulanan), melihat rangkuman dan grafik keuangan, serta melakukan backup dan restore data. Aplikasi mendukung tampilan light dan dark mode, menggunakan mata uang Rupiah (IDR) secara tetap, mendukung pencatatan online dengan sinkronisasi antar perangkat serta tetap dapat digunakan saat offline, dan dilengkapi kunci aplikasi (PIN/biometric) untuk menjaga privasi data keuangan keluarga.

Selain fitur, tampilan dan nuansa aplikasi (warna, ikon, ilustrasi, bahasa) dirancang hangat dan bersahabat agar terasa cocok dan nyaman digunakan sehari-hari oleh ibu-ibu, bukan terasa seperti aplikasi akuntansi kantor.

Dokumen ini mencakup profil pengguna & gaya desain, daftar fitur, struktur data, alur pengguna, gambaran layar, kebutuhan non-fungsional, asumsi & batasan, serta tahapan pengembangan yang disarankan. Nama entitas dan field pada struktur data ditulis dalam bahasa Inggris agar konsisten dengan penamaan pada kode program.

## 2. Target Pengguna & Gaya Desain (Design Language)

### 2.1 Profil Pengguna

Target utama aplikasi adalah ibu-ibu, baik ibu rumah tangga maupun ibu bekerja, yang menjadi pengelola utama keuangan sehari-hari di keluarga. Rentang usia utama sekitar 25-55 tahun, dengan kebutuhan mencatat belanja dapur, kebutuhan anak, arisan, tagihan rumah tangga, dan tabungan keluarga secara cepat, tanpa istilah teknis yang membingungkan.

### 2.2 Prinsip Desain

- Hangat dan bersahabat, bukan kaku/corporate. Nuansa visual terasa seperti buku catatan pribadi, bukan aplikasi akuntansi kantor.
- Suportif, bukan menghakimi. Saat pengeluaran membengkak atau anggaran terlampaui, nada pesan tetap ramah dan memotivasi, bukan terkesan menegur.
- Sederhana dan ringkas, cocok untuk pengguna yang tidak selalu terbiasa dengan aplikasi rumit; alur inti (catat transaksi, login) bisa selesai dalam beberapa ketukan saja, tanpa perlu mengingat password.

### 2.3 Palet Warna

Palet warna pastel hangat menjadi identitas utama, misalnya kombinasi pink lembut, peach, krem, mint, dan lavender, dipakai pada aksen tombol, kartu ringkasan, dan grafik. Mode gelap tetap menggunakan turunan warna hangat (bukan abu-abu/hitam pekat khas aplikasi teknis) agar suasana tetap ramah, bukan terkesan dingin.

### 2.4 Ikon & Ilustrasi

- Gaya ikon bulat, lembut, dan sedikit playful — bukan ikon garis tajam ala aplikasi fintech/korporat.
- Paket ikon bawaan sistem (system icon) berisi ilustrasi bertema rumah tangga: keranjang belanja, dapur, anak sekolah, arisan, kesehatan keluarga, kado, dan sejenisnya.
- Pengguna tetap bisa memilih emoji atau mengunggah foto sendiri sebagai ikon dompet/kategori bila ingin personalisasi lebih jauh (lihat field icon_type pada struktur data di bagian 5). Fitur upload foto disediakan pada tahap pengembangan lanjutan (lihat bagian 10) karena membutuhkan penanganan kompresi dan penyimpanan gambar.
- Ilustrasi pendukung pada layar kosong (empty state), layar onboarding, backup sukses, atau pencapaian target tabungan menggunakan karakter/ilustrasi lucu bertema keluarga, bukan ikon generik.

### 2.5 Background & Tema Visual

- Pengguna dapat memilih tema latar (wallpaper) pada layar Beranda, misalnya motif bunga lembut, polkadot, atau pola pastel lain, sebagai alternatif dari warna solid biasa.
- Pilihan background tersedia untuk mode light maupun dark, dengan kontras yang tetap menjaga keterbacaan teks dan grafik di atasnya.
- Pilihan tema (light/dark/system) dan background disimpan sebagai preferensi lokal (lihat entitas Settings di bagian 5) dan diterapkan ke seluruh layar aplikasi tanpa perlu restart.

### 2.6 Tipografi & Bahasa

- Font rounded sans-serif yang mudah dibaca, dengan ukuran teks cukup besar secara default.
- Sapaan dan microcopy menggunakan bahasa akrab sehari-hari (contoh: "Yuk catat belanja hari ini, Bun!"), bukan istilah teknis seperti "input transaksi".
- Pesan pencapaian maupun pengingat anggaran (misalnya berhasil menabung, konsisten mencatat, atau anggaran belanja dapur mendekati batas) disampaikan dengan nada apresiatif dan suportif, dilengkapi stiker/ilustrasi kecil — bukan nada menegur.

### 2.7 Kategori Bawaan yang Relevan

Kategori sistem (system-provided, lihat field is_system pada entitas Category di bagian 5) disiapkan agar relevan dengan kebutuhan rumah tangga, misalnya:

- Pengeluaran: Belanja Dapur, Jajan Anak, Sekolah Anak, Arisan, Tagihan Rumah, Kesehatan Keluarga, Transportasi, Hiburan Keluarga.
- Pemasukan: Gaji, Uang Belanja dari Suami, Hasil Jualan/Usaha Sampingan, Bonus, Lainnya.

Pengguna tetap bebas menambah kategori baru, mengganti ikon, atau menyembunyikan kategori bawaan sesuai kebutuhan masing-masing.

## 3. Tujuan Aplikasi

- Membantu ibu-ibu mencatat pemasukan dan pengeluaran harian secara sederhana, cepat, dan tanpa istilah teknis.
- Memberikan gambaran kondisi keuangan keluarga melalui rangkuman, anggaran, dan visualisasi grafik yang mudah dipahami.
- Mendukung pengelolaan dana di beberapa dompet/akun (tunai, bank, e-wallet, dll).
- Mengurangi beban mencatat pengeluaran rutin (tagihan, cicilan) melalui transaksi berulang otomatis.
- Menjaga keamanan dan privasi data pengguna melalui kunci aplikasi, serta backup dan restore mandiri.
- Memberikan pengalaman visual yang hangat dan menyenangkan melalui pilihan tema, warna, ikon, dan background yang ramah untuk ibu-ibu.
- Memungkinkan data transaksi tetap dapat diakses dan dicatat dari beberapa perangkat melalui sinkronisasi online, tanpa mengganggu penggunaan saat offline.

## 4. Fitur Utama

### 4.1 Pencatatan Transaksi (Masuk / Keluar)

Fitur inti untuk mencatat setiap transaksi keuangan.

- Tambah transaksi baru dengan jenis: Pemasukan atau Pengeluaran.
- Input: nominal, tanggal & waktu, dompet terkait, kategori, catatan/deskripsi, (opsional) foto struk.
- Kategori dapat disesuaikan pengguna, contoh pengeluaran: Belanja Dapur, Jajan Anak, Sekolah Anak, Arisan, Tagihan Rumah; contoh pemasukan: Gaji, Uang Belanja dari Suami, Hasil Jualan, Bonus.
- Edit dan hapus transaksi yang sudah tercatat. Transaksi yang dihapus ditandai terhapus (soft delete) terlebih dahulu, bukan langsung dibuang, agar aman terhadap proses sinkronisasi (lihat 4.10).
- Daftar transaksi dapat difilter berdasarkan dompet, kategori, jenis, dan rentang tanggal. Pada versi awal (MVP), filter cukup satu kriteria dalam satu waktu agar UI tetap sederhana; kombinasi banyak filter sekaligus ditambahkan pada tahap lanjutan.
- Pencarian transaksi berdasarkan kata kunci pada catatan.

### 4.2 Manajemen Dompet (Multi-Wallet)

Pengguna dapat membuat dan mengelola beberapa dompet sebagai representasi sumber dana.

- Tambah, edit, hapus dompet (contoh: Dompet Tunai, Rekening Bank, E-Wallet, Tabungan).
- Setiap dompet memiliki nama, warna, dan ikon sebagai identitas visual (warna dan ikon disimpan sebagai dua atribut terpisah).
- Ikon dapat dipilih dari tiga sumber: ikon bawaan sistem yang lucu dan bertema rumah tangga, emoji, atau foto yang diunggah pengguna (upload foto tersedia pada tahap lanjutan, lihat 2.4).
- Saldo dompet tidak disimpan sebagai data tersendiri, melainkan selalu dihitung (turunan) dari seluruh transaksi aktif (tidak terhapus) yang terkait dengan dompet tersebut.
- Saldo total seluruh dompet ditampilkan di halaman utama/beranda.
- Dompet yang tidak lagi dipakai dapat diarsipkan tanpa menghapus riwayat transaksinya.

### 4.3 Pindah Uang Antar Dompet (Transfer)

Fitur untuk memindahkan dana antar dompet tanpa memengaruhi total rangkuman pemasukan/pengeluaran.

- Pilih dompet asal dan dompet tujuan, nominal, tanggal, serta catatan opsional.
- Transfer dicatat sebagai satu transaksi berpasangan (keluar dari dompet asal, masuk ke dompet tujuan).
- Transfer ditandai dengan jenis tersendiri agar tidak terhitung ganda dalam rangkuman pemasukan/pengeluaran.
- Riwayat transfer dapat dilihat terpisah dari transaksi pemasukan/pengeluaran biasa.

### 4.4 Anggaran per Kategori (Budget)

- Pengguna dapat mengatur batas anggaran bulanan untuk kategori pengeluaran tertentu, misalnya Belanja Dapur atau Jajan Anak.
- Aplikasi menampilkan progres pemakaian terhadap batas anggaran (contoh: "Rp650rb terpakai dari Rp1.000.000").
- Pesan ramah dan suportif muncul saat anggaran mendekati atau melewati batas (bukan nada menegur), sejalan dengan prinsip desain di 2.2/2.6.
- Anggaran bersifat opsional per kategori; kategori tanpa anggaran tidak menampilkan progres.

### 4.5 Transaksi Berulang (Recurring)

- Pengguna dapat menjadwalkan transaksi yang berulang otomatis, misalnya tagihan listrik, SPP anak, atau cicilan bulanan.
- Pengaturan meliputi: nominal, dompet, kategori, frekuensi (harian/mingguan/bulanan), dan tanggal mulai.
- Aplikasi otomatis membuat transaksi baru sesuai jadwal, dan mengirim pengingat sebelum tanggal jatuh tempo.
- Transaksi hasil jadwal berulang dapat diedit atau dihapus seperti transaksi biasa setelah dibuat, tanpa memengaruhi jadwal berikutnya.
- Jadwal berulang dapat dijeda atau dinonaktifkan kapan saja oleh pengguna.

### 4.6 Mode Tampilan & Tema Visual (Light / Dark Mode)

- Pengguna dapat memilih tema Terang, Gelap, atau Mengikuti Sistem (lihat 2.3 untuk palet warna dan 2.5 untuk pilihan background/wallpaper).
- Preferensi tema dan background disimpan secara lokal dan diterapkan ke seluruh layar tanpa perlu restart aplikasi.
- Dark mode diprioritaskan setelah kebutuhan inti (pencatatan, anggaran, keamanan) selesai, karena bukan kebutuhan utama target pengguna (lihat bagian 10).

### 4.7 Backup & Restore

- Selama pengguna login dan sinkronisasi aktif, data secara otomatis tersimpan aman di server (lihat 4.10) — ini menjadi cara utama menjaga data tidak hilang.
- Sebagai cadangan tambahan, tersedia opsi satu tombol "Cadangkan ke Google Drive" tanpa perlu pengguna memilih folder atau format file secara manual.
- Restore dilakukan dengan memilih cadangan yang tersedia di akun Google Drive terhubung, disertai konfirmasi sebelum data lama ditimpa.
- Validasi cadangan sebelum proses restore untuk mencegah data korup.

### 4.8 Rangkuman Keuangan

- Ringkasan total pemasukan, pengeluaran, dan selisih (net) per periode: harian, mingguan, bulanan, tahunan, atau rentang kustom.
- Ringkasan per dompet dan per kategori, termasuk progres anggaran kategori yang sudah diatur.
- Perbandingan pengeluaran/pemasukan antar periode (contoh: bulan ini vs bulan lalu).
- Daftar kategori dengan pengeluaran terbesar (top spending).
- Pesan apresiatif dan ilustrasi kecil saat pengguna berhasil hemat atau konsisten mencatat.

### 4.9 Grafik (Chart)

- Versi awal (MVP): grafik lingkaran (pie/donut) untuk komposisi pengeluaran per kategori, dan grafik garis sederhana untuk tren pemasukan vs pengeluaran.
- Tahap lanjutan: grafik batang untuk perbandingan saldo antar dompet, serta filter periode dan dompet pada tampilan grafik.
- Seluruh tampilan grafik menyesuaikan light/dark mode dan palet warna pastel aplikasi.

### 4.10 Online & Sinkronisasi Multi-Perangkat

Aplikasi bersifat offline-first: seluruh pencatatan tetap bisa dilakukan tanpa koneksi internet, dan data disinkronkan ke server begitu koneksi tersedia.

- Pengguna login menggunakan nomor HP dan kode OTP (tanpa perlu membuat atau mengingat password), mengikuti pola yang sudah familiar seperti WhatsApp atau aplikasi e-wallet.
- Transaksi yang dicatat saat offline tetap tersimpan di penyimpanan lokal perangkat.
- Saat koneksi internet kembali tersedia, data yang tertunda (pending) otomatis diunggah ke server di background tanpa perlu aksi manual.
- Setiap transaksi memiliki status sinkronisasi: Tersinkron, Menunggu, atau Gagal, yang ditampilkan pada UI.
- Jika sebuah transaksi diubah dari dua perangkat berbeda sebelum sempat sinkron, sistem menggunakan aturan perubahan terakhir yang menang (last write wins) berdasarkan waktu edit terbaru.
- Transaksi yang dihapus ditandai terhapus (soft delete), bukan langsung dibuang di server, sehingga tidak berisiko "muncul kembali" secara tidak sengaja akibat sinkronisasi dari perangkat lain yang belum menerima info penghapusan.
- Pengguna dapat memicu sinkronisasi manual (pull-to-refresh) selain proses sinkronisasi otomatis di background.

### 4.11 Keamanan Aplikasi (PIN / Biometric)

- Pengguna dapat mengaktifkan kunci aplikasi berupa PIN 6 digit atau sidik jari/Face ID, agar data keuangan keluarga tidak mudah dilihat orang lain saat HP dipegang bergantian dengan anak atau anggota keluarga lain.
- Kunci aplikasi bersifat opsional dan terpisah dari kunci layar HP itu sendiri.
- Jika lupa PIN, pengguna dapat mengatur ulang melalui verifikasi akun (nomor HP + OTP).

## 5. Struktur Data

Gambaran entitas data utama sebagai acuan pengembangan database aplikasi. Nama entitas dan field ditulis dalam bahasa Inggris. Seluruh nominal uang (amount, limit_amount) disimpan sebagai bilangan bulat (integer) dalam satuan Rupiah penuh untuk menghindari masalah pembulatan angka desimal.

### 5.1 Entity: Wallet

| Field | Type | Description |
|---|---|---|
| id | string/UUID | Unique wallet identifier |
| name | string | Wallet name, e.g. "Cash Wallet" |
| type | enum | Cash, Bank, EWallet, Savings, Other |
| color | string | Hex color code for UI identity |
| icon_type | enum | System, Emoji, Photo |
| icon_value | string | Value depends on icon_type: system icon key, emoji character, or uploaded photo URL |
| is_archived | boolean | Archive status |
| created_at | datetime | Creation timestamp |

Catatan: saldo dompet (balance) sengaja tidak disimpan sebagai field. Nilainya selalu dihitung on-the-fly dengan menjumlahkan seluruh transaksi aktif (income, expense, transfer_in, transfer_out; is_deleted = false) yang memiliki wallet_id sesuai dompet tersebut.

### 5.2 Entity: Transaction

| Field | Type | Description |
|---|---|---|
| id | string/UUID | Unique transaction identifier |
| type | enum | Income, Expense, Transfer |
| amount | integer | Transaction amount, in whole Rupiah |
| wallet_id | ref | Related wallet (source wallet for Transfer) |
| target_wallet_id | ref | Filled only when type = Transfer |
| category_id | ref | Transaction category (empty for Transfer) |
| date_time | datetime | Transaction date and time |
| note | string | Optional description |
| attachment_url | string/uri | Optional receipt photo |
| recurring_id | ref | Filled if generated from a RecurringTransaction schedule, otherwise empty |
| is_deleted | boolean | Soft-delete flag; true means hidden from the UI but retained for safe sync |
| sync_status | enum | Synced, Pending, Failed |
| created_at | datetime | Record creation timestamp |
| updated_at | datetime | Last edit timestamp, used for sync conflict resolution |

### 5.3 Entity: Category

| Field | Type | Description |
|---|---|---|
| id | string/UUID | Unique category identifier |
| name | string | e.g. "Belanja Dapur", "Gaji", "Arisan" |
| type | enum | Income or Expense |
| color | string | Hex color code for UI identity |
| icon_type | enum | System, Emoji, Photo |
| icon_value | string | Value depends on icon_type: system icon key, emoji character, or uploaded photo URL |
| is_system | boolean | Default category vs. user-created |

### 5.4 Entity: Budget

| Field | Type | Description |
|---|---|---|
| id | string/UUID | Unique budget identifier |
| category_id | ref | Category this budget applies to |
| period | enum | Monthly (only period supported in the initial version) |
| limit_amount | integer | Budget limit for the period, in whole Rupiah |
| created_at | datetime | Creation timestamp |
| updated_at | datetime | Last edit timestamp |

### 5.5 Entity: RecurringTransaction

| Field | Type | Description |
|---|---|---|
| id | string/UUID | Unique identifier |
| type | enum | Income, Expense |
| amount | integer | Amount generated on each cycle, in whole Rupiah |
| wallet_id | ref | Target wallet |
| category_id | ref | Target category |
| frequency | enum | Daily, Weekly, Monthly |
| start_date | date | First occurrence date |
| next_run_at | datetime | Next scheduled generation time |
| is_active | boolean | Whether the schedule is still active |
| note | string | Optional description |

### 5.6 Entity: Settings

| Field | Type | Description |
|---|---|---|
| theme | enum | Light, Dark, System |
| background_theme | string | Selected wallpaper/background theme identifier for the home screen |
| app_lock_enabled | boolean | Whether app lock (PIN/biometric) is active |
| app_lock_type | enum | PIN, Biometric, None |
| last_synced_at | datetime | Timestamp of the last successful sync |

Catatan: mata uang tidak menjadi bagian dari pengaturan karena aplikasi selalu menggunakan Rupiah (IDR) dan tidak menyediakan pilihan mata uang lain.

## 6. Alur Pengguna Utama

### 6.1 Alur Onboarding & Login

1. Pengguna membuka aplikasi pertama kali dan disambut 2-3 layar perkenalan singkat dengan ilustrasi hangat bertema keluarga.
2. Pengguna login/daftar dengan memasukkan nomor HP, lalu memverifikasi kode OTP yang dikirim lewat SMS.
3. Aplikasi memandu membuat dompet pertama (contoh: "Dompet Tunai") dan menampilkan kategori bawaan yang bisa langsung dipakai atau disesuaikan.
4. Pengguna ditawarkan mengaktifkan kunci aplikasi (PIN/biometric); langkah ini dapat dilewati dan diaktifkan belakangan lewat Pengaturan.
5. Pengguna diarahkan ke Beranda dan dapat langsung mencatat transaksi pertama.

### 6.2 Alur Tambah Transaksi

1. Pengguna menekan tombol tambah (+) dari Beranda.
2. Memilih jenis: Pemasukan atau Pengeluaran.
3. Mengisi nominal, memilih dompet, kategori, tanggal & waktu, dan catatan opsional.
4. Menekan Simpan; saldo dompet terkait ter-update otomatis (hasil hitung ulang dari transaksi).
5. Transaksi muncul di daftar riwayat dan mempengaruhi rangkuman, grafik, serta progres anggaran terkait.

### 6.3 Alur Pindah Uang Antar Dompet

1. Pengguna membuka menu Transfer.
2. Memilih dompet asal dan dompet tujuan (harus berbeda).
3. Mengisi nominal dan catatan opsional.
4. Konfirmasi transfer; saldo dompet asal berkurang, saldo dompet tujuan bertambah.
5. Riwayat transfer tercatat terpisah dari transaksi pemasukan/pengeluaran.

### 6.4 Alur Atur Anggaran Kategori

1. Pengguna membuka menu Anggaran dari Rangkuman atau Pengaturan.
2. Memilih kategori pengeluaran dan mengisi batas anggaran bulanan.
3. Aplikasi menampilkan progres pemakaian anggaran secara berkala di Beranda dan Rangkuman.
4. Pengguna menerima pesan ramah saat anggaran mendekati atau melewati batas.

### 6.5 Alur Backup & Restore

1. Pengguna membuka menu Pengaturan > Backup & Restore.
2. Jika sudah login, data tersimpan otomatis lewat sinkronisasi; pengguna dapat menekan "Cadangkan Sekarang" sebagai cadangan tambahan satu-tombol ke Google Drive.
3. Untuk restore, pengguna memilih cadangan yang tersedia di akun Google Drive terhubung dan mengonfirmasi sebelum data lama ditimpa.

### 6.6 Alur Pencatatan Offline & Sinkronisasi

1. Pengguna mencatat transaksi seperti biasa meskipun perangkat sedang tanpa koneksi internet.
2. Transaksi tersimpan lokal dengan status sinkronisasi "Menunggu".
3. Ketika perangkat kembali terhubung ke internet, aplikasi otomatis mengunggah transaksi berstatus "Menunggu" ke server di background.
4. Status transaksi berubah menjadi "Tersinkron" setelah berhasil diunggah; jika gagal, status menjadi "Gagal" dan akan dicoba ulang otomatis.
5. Perangkat lain yang login dengan akun yang sama menerima transaksi terbaru melalui sinkronisasi.

## 7. Gambaran Layar (Wireframe Deskriptif)

### 7.1 Onboarding & Login

- Slide perkenalan singkat dengan ilustrasi hangat bertema keluarga/rumah tangga.
- Form login: input nomor HP, tombol kirim OTP, input kode OTP.
- Wizard singkat membuat dompet pertama dan memilih kategori awal.

### 7.2 Beranda

- Sapaan hangat di bagian atas (contoh: "Selamat pagi, Bun! Yuk catat belanja hari ini.").
- Kartu total saldo seluruh dompet, dengan aksen warna pastel dan opsi background/wallpaper lucu.
- Ringkasan pemasukan vs pengeluaran bulan berjalan, serta kartu progres anggaran kategori yang mendekati/melewati batas (jika anggaran diatur).
- Grafik ringkas tren transaksi 7/30 hari terakhir.
- Daftar transaksi terbaru dan tombol tambah transaksi (+) yang mudah dijangkau.
- Indikator status sinkronisasi (tersinkron / menunggu / offline) di bagian header.

### 7.3 Dompet

- Daftar kartu dompet beserta saldo masing-masing, dengan warna dan ikon lucu sesuai pilihan pengguna.
- Tombol tambah dompet baru dan tombol transfer antar dompet.
- Tap salah satu dompet untuk melihat riwayat transaksi dompet tersebut.

### 7.4 Rangkuman

- Pemilih periode (harian/mingguan/bulanan/tahunan/kustom).
- Daftar progres anggaran per kategori.
- Grafik komposisi pengeluaran per kategori (pie/donut) dengan palet warna pastel.
- Grafik tren pemasukan vs pengeluaran (garis sederhana untuk MVP; grafik batang perbandingan dompet pada tahap lanjutan).
- Daftar kategori dengan pengeluaran terbesar.
- Ilustrasi/stiker apresiasi ketika tren pengeluaran membaik.

### 7.5 Pengaturan

- Pilihan tema: Light / Dark / Mengikuti Sistem, dan pilihan background/wallpaper Beranda.
- Kunci aplikasi (aktifkan/nonaktifkan PIN atau biometric).
- Menu Backup & Restore.
- Pengaturan kategori dan anggaran, termasuk pemilihan ikon (sistem/emoji/foto).
- Pengaturan transaksi berulang (recurring).
- Info akun (nomor HP) dan status login untuk sinkronisasi antar perangkat.

## 8. Kebutuhan Non-Fungsional

- Aplikasi bersifat offline-first: seluruh pencatatan harian tetap berfungsi penuh tanpa koneksi internet.
- Waktu buka aplikasi dan simpan transaksi harus terasa instan (di bawah 1 detik), tidak menunggu proses sinkronisasi.
- Perpindahan tema light/dark maupun background tidak memerlukan restart aplikasi.
- Data yang dikirim ke server terenkripsi dalam perjalanan (HTTPS/TLS), dan data sensitif (termasuk kredensial OTP) tidak disimpan dalam bentuk teks biasa di server.
- Sinkronisasi data ke server tidak boleh menyebabkan duplikasi maupun kehilangan transaksi, termasuk saat koneksi terputus di tengah proses.
- Perhitungan saldo, anggaran, dan rangkuman harus konsisten walau ada edit/hapus transaksi lama, baik secara lokal maupun setelah sinkronisasi.
- Tampilan tetap ramah dan mudah dibaca untuk pengguna dengan beragam tingkat kemahiran teknologi: ukuran teks cukup besar, kontras warna tetap terjaga meski memakai palet pastel.
- Aplikasi berjalan lancar pada perangkat Android kelas menengah-bawah yang umum dipakai target pengguna, tidak hanya perangkat kelas atas.

## 9. Asumsi & Batasan

- Versi awal aplikasi menyasar platform Android terlebih dahulu; dukungan iOS dipertimbangkan sebagai pengembangan lanjutan.
- Satu akun digunakan oleh satu pengguna utama. Fitur berbagi akses dompet antar anggota keluarga (family sharing, misalnya suami-istri mengakses data yang sama) belum termasuk dalam versi ini dan dapat dipertimbangkan pada pengembangan lanjutan.
- Login menggunakan nomor HP dan kode OTP; belum menyediakan login via email/password atau akun pihak ketiga (Google/Facebook) pada versi awal.
- Aplikasi tidak mencakup fitur investasi, utang-piutang, atau perencanaan keuangan lanjutan (financial planning); fokus versi ini adalah pencatatan, anggaran sederhana, dan rangkuman transaksi harian.
- Backup manual mengandalkan akun Google Drive pengguna; penyediaan penyimpanan cloud sendiri di luar itu berada di luar cakupan versi ini.

## 10. Tahapan Pengembangan yang Disarankan

**Tahap 1 — MVP**
Catat transaksi masuk/keluar, dompet tunggal, kategori bawaan rumah tangga, rangkuman dasar, gaya visual pastel dasar (warna, ikon sistem).

**Tahap 2 — Multi-Wallet, Transfer & Anggaran**
Dukungan banyak dompet, fitur pindah uang antar dompet, anggaran per kategori beserta progres dan pesan pengingat.

**Tahap 3 — Backup, Keamanan & Onboarding**
Backup manual satu-tombol ke Google Drive, kunci aplikasi (PIN/biometric), alur onboarding lengkap.

**Tahap 4 — Online & Sinkronisasi Multi-Perangkat**
Login nomor HP + OTP, penyimpanan offline-first, sinkronisasi otomatis saat online, indikator status sinkronisasi, soft delete untuk keamanan sinkronisasi.

**Tahap 5 — Visualisasi & Personalisasi Lanjutan**
Grafik tambahan (perbandingan saldo antar dompet), filter transaksi lanjutan, dark mode, pilihan background/wallpaper, ikon emoji & upload foto.

**Tahap 6 — Penyempurnaan**
Transaksi berulang (recurring) untuk tagihan/cicilan rutin, pengingat pencatatan harian, penanganan konflik sinkronisasi lanjutan.
