# Kontrak inti OffPlay v1.0

Pemain iPhone dapat memilih salah satu dari enam Judul di Game Box dan langsung bermain, tanpa login, jaringan, atau unduhan konten tambahan. Target minimum iOS 17. V1.0 tanpa iklan, SDK iklan, Remove Ads, atau monetisasi lain. Kontrak ini menilai inti di simulator, bukan kesiapan rilis.

## Sesi dan Statistik Pemain

Membuka Judul melanjutkan papan atau hasil terakhir, tanpa dialog pembuka. Hitungan Sesi dimulai pada tindakan bermain pertama yang sah. Waktu aktif berhenti selama jeda, ketika pemain meninggalkan papan, atau ketika app tidak aktif. Kembali ke Game Box tidak berarti Kalah.

Setelah proses app ditutup, papan, riwayat Undo yang berlaku, Statistik Pemain dan urutan tantangan harus dapat dilanjutkan dari simpanan lokal. Mulai Baru pada Sesi yang sudah dimainkan tetapi belum selesai memerlukan konfirmasi; membatalkannya tidak mengubah progres. Jika diteruskan, hasilnya Ditinggalkan. Hasil akhir dicatat tepat sekali, tetap terlihat saat Judul dibuka lagi, dan tidak dapat dibatalkan dengan Undo.

| Judul | Perilaku pembeda untuk diperiksa |
|---|---|
| Block Grid | Baki tiga keping terisi kembali setelah habis. Baris dan kolom penuh dibersihkan bersamaan; tanpa Undo. |
| Klondike Solitaire | Ambil satu kartu; putar ulang stock tanpa mengocok. Undo maksimal 100 tindakan. Buntu bukan Kalah. |
| Sudoku | Bank offline tiga tingkat, solusi tunggal, catatan manual dan Undo maksimal 100 perubahan. Penanda duplikat bukan petunjuk jawaban. |
| 2048 | Satu Undo mengembalikan undian yang sama. Mencapai 2048 bukan akhir Sesi; pencapaian bertahan setelah Undo. |
| Minesweeper | Dua kesulitan; pembukaan pertama beserta tetangga aman. Buka-serentak dengan bendera salah bisa Kalah. Win rate tidak memasukkan Ditinggalkan. |
| Word Scramble | Kata bahasa Indonesia dari kelompok anagram offline. Jawaban sah dengan susunan huruf yang sama diterima; kelompok diundi tanpa pengulangan sampai habis. |

Rincian aturan, bantuan, skor dan rekor tetap mengikuti **Menetapkan batas aturan dan Statistik Pemain per Judul**; tabel ini bukan daftar lengkap kasus uji.

## Batas arsitektur

SwiftUI dan `AppStore` menangani navigasi, modal, serta status aktif app. `OffPlayCore` menjalankan aturan tanpa UI. `GameLibrary` menghubungkan tindakan sah dengan Sesi dan statistik; `LibraryFileStore` menyimpan satu arsip lokal untuk seluruh Judul. [Implementasi inti OffPlay](implementation.md) mencatat struktur baseline dan cara mengujinya.

ADR awal adalah konteks historis. Protokol `GameModule` bukan kontrak antar-Judul yang wajib. ADR iklan dan StoreKit tidak berlaku untuk v1.0. Simpan lokal antarproses tidak menjamin pemulihan setelah pemasangan ulang, tetapi juga tidak membatalkan target pemulihan pada peta desain. iCloud, ukuran unduhan rilis dan App Review tidak dinilai pada peta inti.
