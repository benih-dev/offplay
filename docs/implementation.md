# Implementasi inti OffPlay

App iPhone SwiftUI, minimum iOS 17. Entry point berada di `App/OffPlayApp.swift`; buka `OffPlay.xcodeproj` dengan scheme **OffPlay**.

## Menjalankan

Pilih simulator iPhone di Xcode lalu Run. Dari terminal, ganti `<simulator-id>` dengan ID dari `xcrun simctl list devices available`:

```sh
xcodebuild -project OffPlay.xcodeproj -scheme OffPlay -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=<simulator-id>' \
  -derivedDataPath /tmp/OffPlayDerivedData CODE_SIGNING_ALLOWED=NO build
```

## Pengujian

```sh
swift test -c release
swift run -c release OffPlayContentBuilder --validate
xcodebuild -project OffPlay.xcodeproj -scheme OffPlay -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,id=<simulator-id>' \
  -derivedDataPath /tmp/OffPlayDerivedData -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO test
```

## Susunan scaffold pada baseline `b9ab538`

[Kontrak inti OffPlay](architecture.md) menetapkan perilaku yang dinilai. Tabel ini menjelaskan cara kode baseline disusun, bukan hasil pengujian.

| Bagian | Implementasi |
|---|---|
| Toolchain | Mode bahasa Swift 6; deployment target iOS 17. Catat versi Xcode, Swift dan runtime simulator pada setiap verifikasi. |
| UI dan navigasi | SwiftUI `NavigationStack`, `AppStore.path`, dan `AppModal`; `App/Titles/` memisahkan tampilan setiap Judul |
| Aturan permainan | Swift package `OffPlayCore`, terpisah dari SwiftUI/UIKit; tiap Judul memiliki model data serta validasi langkah sendiri |
| Pembaruan HUD | Observation pada `AppStore.library`; perubahan papan berasal dari tindakan pemain |
| Waktu | Timer satu detik dan `systemUptime`; `scenePhase`, navigasi dan modal mengatur penghitungan waktu aktif |
| Persistensi | JSON version 1 melalui `LibraryFileStore`; penulisan atomik, cadangan terakhir, validasi struktur dan penolakan versi yang lebih baru |
| Konten | `Sources/OffPlayCore/Resources/`; bank Sudoku dibangun sebelum distribusi, korpus kata dikurasi di `words.txt` |
| Tes | XCTest untuk aturan/persistensi/konten; XCUITest untuk alur layar dan interaksi app |

## Permainan dan Sesi

Enam Judul adalah Block Grid, Klondike Solitaire, Sudoku, 2048, Minesweeper, dan Word Scramble. Semua papan dan konten tersedia dalam app.

`GameLibrary` menyimpan satu Sesi per Judul, Statistik Pemain, pilihan kesulitan, riwayat Undo dan kumpulan tantangan. Membuka Judul melanjutkan keadaan yang ada; tindakan bermain pertama memulai penghitungan Sesi. Hasil terminal dicatat sekali. Penggantian Sesi yang sudah dimainkan mencatat Ditinggalkan setelah konfirmasi.

Simpanan berada di Application Support app pada perangkat. Board, statistik, Undo dan urutan undian dapat dilanjutkan setelah proses app ditutup. Target pemulihan lintas instalasi tetap memiliki keputusan desain sendiri pada peta produk.

## Konten offline

Bank Sudoku berisi 150 papan, 50 per kesulitan. `Tools/ContentBuilder/` membentuk varian dari satu papan dasar per kesulitan, memeriksa solusi tunggal dan menilai teknik penyelesaian. Jumlah entri bukan ukuran keragaman struktur teka-teki. Runtime memilih dari bank tersimpan tanpa pengulangan sampai kumpulan habis.

Korpus bahasa Indonesia disimpan di repo. `GameContent` memvalidasi huruf a-z, panjang 4–8, dan mengelompokkan anagram berdasarkan multiset huruf. Inventaris baseline menghitung 586 kelompok; minimum 300 diperiksa saat pemuatan dan pada tes konten. Hitungan itu bukan bukti kurasi bahasa atau hak pakai.

## Arah tampilan

Keputusan produk: **Hangat & Tenang**, teks mengikuti ukuran sistem, target sentuh minimal 48 pt, status tidak bergantung pada warna, dan kontrol berlabel VoiceOver. Getaran untuk langkah berhasil, kesalahan dan akhir Sesi dapat dimatikan; navigasi biasa tanpa getaran. Pilihan tema sistem/terang/gelap dan detail tampilan berikut adalah keputusan scaffold, bukan syarat tambahan.

- Krem, permukaan putih dan aksen hijau mengikuti prototipe yang dipilih pemilik; tema gelap memakai pasangan warna yang terukur.
- Tipografi sistem dan bentuk rounded pada label permainan menjaga keterbacaan serta dukungan Dynamic Type.
- Grid Game Box seragam karena enam pilihan permainan mempunyai prioritas yang setara; status Sesi menjadi pembeda yang relevan.
- SF Symbols dipilih menurut permainan/fungsi: grid, suit kartu, angka, bendera, huruf, statistik dan Pengaturan.
- Radius 16 pada wadah, 12 pada tombol, dan 8 pada kartu membedakan kelompok konten dari kontrol serta keping permainan.
- Motion mengikuti transisi navigasi/sheet bawaan iOS dan feedback penekanan; perubahan warna ditekan mempertahankan kontras teks.
- Petak input minimal 48 pt; papan besar dipan dalam wadah terbatas. Konten permainan dapat mengalir vertikal ketika layar atau ukuran teks memerlukannya.
- Tombol Game Box berada di bar tindakan bawah agar keluar dari permainan tetap terjangkau setelah papan digulir.

Audit After dan bukti simulator berada di `anti-slop/`.

## Riwayat sebelum baseline

Butir berikut adalah laporan sesi terdahulu, bukan hasil uji ulang commit `b9ab538`. Untuk menilai baseline, jalankan perintah pengujian dan catat revisi, perangkat, runtime, hasil serta skenario yang belum tercakup. Periksa bermain tanpa jaringan dan simpan lintas peluncuran secara eksplisit. Lulus di simulator yang lebih baru bukan bukti lulus di runtime iOS 17.

- Build Debug simulator dan Release iPhone berhasil.
- 18 tes XCTest inti lulus: aturan enam permainan, Undo/undian, Sesi, penghitungan hasil, simpan/muat, pemulihan cadangan dan konten.
- Enam tes XCUITest utama lulus di iPhone 17 / iOS Simulator 26.5. Tes kontrol tambahan memeriksa aturan permainan, semua tombol arah dan geseran 2048.
- Tes layout di iPhone SE generasi ketiga lulus pada teks standar dan `accessibility-extra-large`. Screenshot diperiksa untuk reflow dan ukuran kartu; kondisi teks besar setelah perbaikan berada pada laporan audit tindak lanjut.
- `OffPlayContentBuilder --validate` memverifikasi 150 papan dan 586 kelompok huruf.
- Target deployment adalah iOS 17; runtime yang tersedia dan digunakan dalam sesi ini adalah iOS Simulator 26.5.

## Sumber keputusan produk

- [Menetapkan siklus Sesi dan perilaku langsung bermain](https://github.com/benih-dev/offplay/issues/22)
- [Menetapkan arah visual dan aksesibilitas alur Sesi](https://github.com/benih-dev/offplay/issues/25)
- [Menetapkan batas aturan dan Statistik Pemain per Judul](https://github.com/benih-dev/offplay/issues/26)
- [Menetapkan penanganan celah bukti privasi SDK](https://github.com/benih-dev/offplay/issues/36)
