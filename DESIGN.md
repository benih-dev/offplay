# OffPlay — Panduan Gaya Menu

OffPlay memakai gaya game kasual yang ceria: latar biru langit, huruf membulat yang tebal, dan pilihan game seperti kepingan papan. Ilustrasi permainan menjadi pusat perhatian dan membantu pemain mengenali enam game.

Dokumen ini mencatat desain menu koleksi OffPlay di SwiftUI, berdasarkan prototipe HTML. Nilai native mengacu pada `GameMenuTheme`, `GameMenuButtonStyle`, `GameBoxView`, dan `GameMenuPreview`. Untuk permainan aktif, lihat bagian [Layar gameplay](#layar-gameplay).

## Arah visual

- Gunakan warna hijau, koral, biru, dan kuning untuk membedakan permainan.
- Beri keenam pilihan ukuran dan prioritas yang setara.
- Bentuk kedalaman dengan garis kontras dan bayangan pendek tanpa blur. Terapkan bayangan pada bentuk dasar, bukan pada teks atau ikon.
- Gunakan sudut membulat serta ilustrasi papan yang besar dan mudah dikenali.
- Jaga deskripsi tetap singkat agar judul dan papan menjadi fokus.

Arah ini mengikuti permintaan untuk membuat OffPlay terasa lebih ceria. Palet dan bentuknya menggantikan default Neutral Modern untuk menu ini.

## Warna

### Warna dasar dan tema

| Token SwiftUI | Terang | Gelap | Penggunaan |
| --- | --- | --- | --- |
| `canvas` | `#DFF3FC` | `#172D36` | Latar menu |
| `text` | `#173C43` | `#DFF3FC` | Teks utama di atas latar menu |
| `secondary` | `#365B63` | `#B9DCE9` | Deskripsi pengantar dan catatan |
| `brand` | `#168458` | `#70D99B` | Wordmark OffPlay |
| `ink` | `#173C43` | `#173C43` | Teks dan garis pada kepingan serta tombol Acak |
| `paper` | `#FFFFFF` | `#FFFFFF` | Kartu dan sel papan ilustrasi |
| `utilitySurface` | `#FFFFFF` | `#284653` | Permukaan Statistik dan Pengaturan |
| `utilityOutline` | `#173C43` | `#82ADBC` | Garis tombol utilitas |
| `depth` | `#173C43` | `#091A21` | Bayangan keras tombol |
| `brandRim` | `#FFFFFF` | `#2F675B` | Lapisan tengah wordmark |
| `brandDepth` | `#0D5B3D` | `#091A21` | Lapisan belakang wordmark |

### Mode gelap

Menu mengikuti pilihan tampilan aplikasi: sistem, terang, atau gelap. Saat gelap, tombol utilitas memakai permukaan biru tua dengan ikon `text` terang dan garis `utilityOutline` agar tetap terlihat di atas latar. Bayangan keras tetap pendek dan gelap; siluet tombol tidak bergantung pada bayangan.

Kepingan dan tombol Acak tetap berwarna, tetapi dengan permukaan dan latar ilustrasi yang lebih redup daripada mode terang. Gunakan `ink` gelap untuk teks di atas warna tersebut, bukan `text` adaptif. Putih tetap dipakai pada detail ilustrasi seperti kartu remi dan sel yang terbuka.

### Warna permainan

| Keluarga | Permukaan kepingan (terang / gelap) | Latar ilustrasi (terang / gelap) | Detail (keduanya) |
| --- | --- | --- | --- |
| Hijau | `green` · `#70D99B` / `#76BE91` | `greenFill` · `#C8F2D3` / `#A2CFB1` | `greenTile` · `#168458`, `greenDeep` · `#0D5B3D` |
| Koral | `coral` · `#FF9486` / `#E88D84` | `coralFill` · `#FFDDD4` / `#EDB9AD` | `redInk` · `#A32E38` |
| Biru | `blue` · `#79C8EE` / `#74B4D7` | `blueFill` · `#B9E5FB` / `#9ECDE4` | `blueInk` · `#164F76` |
| Kuning | `yellow` · `#FFDA65` / `#E5C360` | `yellowFill` · `#FFF0B4` / `#DDCB8C` | Teks dan garis memakai `ink` |

| Game | Keluarga warna | Ilustrasi pengenal |
| --- | --- | --- |
| Block Grid | Hijau | Papan 8 × 8 dengan susunan blok hijau dan kuning |
| Klondike Solitaire | Koral | Tiga kartu dengan angka dan simbol jenis kartu |
| Sudoku | Biru | Papan 9 × 9, garis pembatas kelompok 3 × 3 |
| 2048 | Kuning | Papan 4 × 4 dengan kepingan angka |
| Minesweeper | Hijau | Papan 5 × 5 dengan angka terbuka dan bendera |
| Word Scramble | Koral | Dua baris kepingan huruf, jawaban berwarna kuning |

Warna selalu disertai judul dan bentuk papan. Pemain tidak perlu mengandalkan warna untuk mengenali game.

## Tipografi

Gunakan font sistem dengan desain `.rounded` pada SwiftUI. Pertahankan bobot tebal pada logo, judul, dan aksi; gunakan bobot reguler untuk deskripsi.

| Elemen | Implementasi SwiftUI |
| --- | --- |
| Wordmark OffPlay | Ukuran dasar 56 pt, `.black`, `.rounded`, tracking −2 pt |
| Judul pengantar | `.largeTitle`, `.black`, `.rounded` |
| Judul koleksi dan tombol Acak | `.headline`, `.heavy`, `.rounded` |
| Nama game | `.title3`, `.black`, `.rounded` |
| Deskripsi | `.body`, `.rounded` |
| Status permainan | `.body`, `.bold`, `.rounded` |
| Ikon utilitas | `.title3`, `.bold` |
| Angka kartu remi | 20 pt, `.bold`, `.serif` |

Ukuran logo mengikuti `@ScaledMetric(relativeTo: .largeTitle)`. Wordmark tetap satu baris dan dapat mengecil hingga faktor 0,4 agar tombol utilitas tetap tersedia.

Gunakan ukuran teks semantik untuk konten aplikasi agar mengikuti Dynamic Type. Ukuran kecil pada angka papan merupakan detail ilustrasi dekoratif, bukan ukuran untuk petunjuk atau status yang perlu dibaca.

## Ukuran dan tata letak

Nilai berikut memakai satuan pt untuk SwiftUI.

| Token | Nilai | Peran |
| --- | --- | --- |
| `unit` | 4 | Satuan dasar |
| `inset` | 16 | Padding luar dan jarak antarkolom |
| `sectionGap` | 24 | Jarak antarbagian dan antarbaris game |
| `radius` | 20 | Sudut kepingan game |
| `smallRadius` | 12 | Sudut tombol utilitas dan wadah ilustrasi |
| `edge` | 2 | Ketebalan garis utama |
| `lift` | 6 | Bayangan vertikal saat tombol diam |
| `target` | 48 | Ukuran tombol utilitas dan tinggi minimum aksi |
| `previewSize` | 120 | Area ilustrasi native 120 × 120 |
| `previewHeight` | 144 | Tinggi minimum wadah ilustrasi |

Susunan menu native:

1. Statistik, wordmark OffPlay, dan Pengaturan.
2. Judul pengantar dan satu kalimat pendukung.
3. Judul koleksi dan tombol Acak.
4. Grid keenam permainan.
5. Catatan penyimpanan progres.

Konten memakai `ScrollView` dengan lebar maksimum 640 pt dan padding luar 16 pt. Grid adaptif memakai lebar minimum kolom 152 pt. Saat Dynamic Type melebihi `.large`, minimum kolom menjadi 280 pt dan judul koleksi beserta tombol Acak tersusun vertikal.

Biarkan teks membungkus dan tinggi kepingan bertambah. Jangan memaksakan dua kolom saat ruang tidak mencukupi. Latar boleh meluas ke tepi layar, sementara konten mengikuti safe area sistem.

## Komponen

### Wordmark

Tampilkan teks “OffPlay” dalam hijau brand dengan font membulat yang berat. Tambahkan lapisan `brandRim` pada offset vertikal 2 pt dan `brandDepth` pada 4 pt, tanpa blur.

### Kepingan game

Seluruh kepingan merupakan satu tombol. Urutannya: ilustrasi papan, nama game, deskripsi singkat, lalu status sesi.

Gunakan warna keluarga game sebagai permukaan, radius 20 pt, garis `ink` 2 pt, dan bayangan `depth` ke bawah 6 pt tanpa blur. Padding dalam utama 8 pt. Wadah ilustrasi memakai warna isian yang lebih muda, radius 12 pt, dan garis 2 pt.

Status berasal dari sesi sebenarnya: siap dimainkan, lanjutkan beserta waktu, atau hasil sesi. Jangan menambahkan skor contoh ke status pengguna.

### Tombol Acak dan utilitas

Tombol Acak memakai permukaan `yellow`, label teks, dan simbol `shuffle`. Statistik dan Pengaturan memakai permukaan `utilitySurface` dengan simbol `chart.bar` serta `gearshape` berwarna `text`. Gunakan SF Symbols untuk ikon native dan beri nama aksesibel pada tombol tanpa teks.

Ketiganya memakai garis 2 pt, sudut 12 pt, dan perlakuan tekan yang sama dengan kepingan.

### Ilustrasi papan

Buat papan dari bentuk, teks, dan simbol native yang dapat diedit. Ilustrasi adalah contoh statis, bukan cuplikan progres pemain. Sembunyikan ilustrasi dari VoiceOver dan nonaktifkan hit testing; akses permainan tetap melalui tombol induknya.

## Interaksi dan gerak

| Keadaan | Perlakuan native |
| --- | --- |
| Diam | Bayangan bawah 6 pt |
| Ditekan | Konten turun 4 pt; bayangan berkurang menjadi 2 pt |
| Transisi tekan | `easeOut`, durasi 0,18 detik |
| Reduce Motion | Tanpa perpindahan atau animasi; opacity saat ditekan 0,8 |
| Nonaktif | Opacity 0,5 |

Gerak hanya menjelaskan respons sentuhan. Hindari animasi berulang pada logo atau papan saat menu diam.

Pilihan game dan tombol Acak di aplikasi native memakai `store.open(id)` agar tetap mengikuti alur sesi yang ada. Prototipe HTML membuka ringkasan aturan; perilaku ini bukan ketentuan navigasi untuk aplikasi native.

## Bahasa dan aksesibilitas

Gunakan bahasa yang singkat, ramah, dan langsung mengajak bermain. Contoh label: “Acak”, “Cara bermain”, dan “Kembali ke koleksi”. Teks sumber menggunakan bahasa Inggris; terjemahan Indonesia tersedia di `Localizable.xcstrings`.

- Pertahankan judul bagian sebagai heading aksesibilitas.
- Gabungkan nama game dan status sesi pada label aksesibel tombol.
- Beri petunjuk bahwa tombol membuka permainan.
- Sediakan ruang untuk pembesaran teks dan deskripsi yang lebih panjang akibat terjemahan.
- Pada HTML, pertahankan indikator fokus keyboard yang terlihat.
- Targetkan kontras minimal 4,5:1 untuk teks biasa dan 3:1 untuk teks besar serta grafis penting.

Target kontras merupakan persyaratan pemeliharaan; dokumen ini tidak menyatakan hasil audit kontras atau pengujian simulator.

## Layar gameplay

Gunakan keluarga warna kepingan menu sebagai aksen pada chrome bersama, bukan pada isi sel. `GamePlayView` memasang environment `gameplayGame` sesuai `GameID`; nilai awal `nil` mempertahankan tampilan netral untuk sheet, Pengaturan, dan Statistik.

Semua token warna berikut berasal dari `GameMenuTheme`, kecuali permukaan sel netral yang masih memakai `GameTheme`. Pemetaan `face(id)` dan `well(id)` mengikuti tabel warna permainan di atas, dalam mode terang maupun gelap.

| Elemen | Token terang / gelap | Penggunaan |
| --- | --- | --- |
| Kanvas dan footer | `canvas` / `canvas` | Latar biru langit / biru tua `#172D36` |
| Kartu header | `face(id)`, `ink`, `depth` / token yang sama | Hasil dan metrik termasuk label; padding vertikal 6 pt, radius 20 pt, garis 2 pt, bayangan keras 6 pt pada bentuk dasar |
| Bingkai papan | `boardWell(id)` terang / gelap: hijau `#C8F2D3` / `#274A3A`, koral `#FFDDD4` / `#4D3236`, biru `#B9E5FB` / `#22445A`, kuning `#FFF0B4` / `#4A4428`; `boardEdge(id)` terang `#173C43` / gelap: hijau `#76BE91`, koral `#E88D84`, biru `#74B4D7`, kuning `#E5C360` | Isian area luar sel, radius 20 pt dan garis 2 pt; ukuran sel serta ruang papan tetap |
| Tombol utama | `face(id)`, `ink`, `depth` / token yang sama | Label gelap, garis 2 pt, radius 12 pt; aksi destruktif memakai `redInk` dengan label `paper` |
| Tombol sekunder | `utilitySurface`, `text`, `utilityOutline`, `depth` / token yang sama | Permukaan putih / biru tua, label dan garis adaptif |
| Sel papan | `paper` atau permukaan netral, teks keluarga `ink` / permukaan netral gelap dengan teks kontras | Isi tenang, tanpa warna keluarga game di belakang angka |

Tombol mempertahankan tinggi minimum 48 pt dan interaksi menu: bayangan 6 pt, saat ditekan turun 4 pt dengan bayangan 2 pt. Reduce Motion meniadakan perpindahan dan animasi, memakai opacity 0,8 saat ditekan. Tombol nonaktif memakai opacity 0,5. Ikon Home dan aksi Pause memakai `text`.

Jaga kontras angka Sudoku dan Minesweeper minimal 4,5:1 pada sel netral. Kesalahan dan umpan balik memakai tinta merah. Umpan balik berada di ruang tetap di bawah kartu, memakai `GameTheme.danger` adaptif pada kanvas dengan kontras minimal 4,5:1; pesan tidak menggeser papan. Hasil menang tetap memakai `ink` agar terbaca. Seleksi dan keadaan tidak boleh disampaikan lewat warna saja: sertakan garis, simbol, atau label.

Footer tetap di bawah saat seluruh konten muat. Jika tinggi konten melebihi ruang aman, gulir konten dan footer bersama dalam urutan dokumen agar kontrol tidak tertutup footer. Jangan menambal tata letak dengan offset tetap. Numpad Sudoku memakai satu baris 1–9 bila sembilan tombol selebar minimal 36 pt muat; selain itu gunakan dua baris 1–5 dan 6–9 yang terpusat, dengan tinggi tombol 44 pt.

Interior papan tiap game mengikuti aturan sel tenang.
Sel 2048 memakai ramp monokrom `paper`–`ink`: 2, 4, 8, 16, 32, dan 64 semakin pekat dengan angka `ink` berkontras minimal 4,5:1; mode gelap meredupkan permukaan agar tidak menyilaukan. Nilai ≥128 memakai isian `ink` dan angka `paper`, dengan garis paling tebal pada ≥2048, tanpa hue keluarga game di belakang angka. Sel kosong memakai garis putus-putus dan isian transparan yang lebih gelap dari bingkai pada mode gelap. Instruksi memakai `secondary` dan pesan mencapai 2048 memakai `text` agar kontras pada kanvas.

## Pemeliharaan

Sumber implementasi native dalam repositori ini:

- `App/Design/GameMenuStyle.swift`: token warna, ukuran, dan gaya tombol.
- `App/Design/GameTheme.swift`: environment gameplay, metrik, bingkai papan, dan gaya tombol aksi bersama.
- `App/Views/GamePlayView.swift`: kartu header, kanvas, footer, dan aksen chrome gameplay.
- `App/Views/GameBoxView.swift`: susunan menu, tipografi, navigasi, dan status sesi.
- `App/Views/GameMenuPreview.swift`: ilustrasi keenam papan.
- `App/Localizable.xcstrings`: teks terjemahan.

Bingkai iPhone, Dynamic Island, dan latar panggung pada prototipe HTML merupakan perangkat presentasi, bukan komponen yang perlu dibuat ulang di SwiftUI.

Ubah token bersama sebelum menambah nilai lokal baru. Pertahankan pemetaan warna game, bentuk kepingan, dan hierarki teks saat menambah komponen. Hindari latar gradasi dominan, bayangan kabur besar, emoji sebagai ikon fungsi, atau dekorasi yang menutupi papan.
