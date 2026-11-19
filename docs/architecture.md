# Arsitektur OffPlay v1.0

> Implementasi inti app dan perintah build/test yang sudah dijalankan berada pada [Implementasi inti OffPlay](implementation.md). Dokumen di bawah menyimpan draf awal untuk konteks keputusan produk.

> Status: draf lama, belum siap untuk implementasi. Peta aktif: [Kesiapan desain OffPlay v1.0](../.scratch/offplay-v1-design/map.md). Pernyataan di bawah tentang data boleh hilang dan tanpa sync tidak berlaku. Statistik Pemain dan Sesi yang belum selesai harus dapat dipulihkan setelah pemasangan ulang; syarat pemulihan masih akan diputuskan. Aturan Sesi, iklan, dan pilihan API lain masih usulan kecuali dikonfirmasi dalam peta.

Desain teknis untuk peluncuran awal: 6 Judul, SwiftUI, AdMob, StoreKit 2.
Lihat `GLOSSARY.md` untuk definisi istilah dan `docs/adr/` untuk keputusan.

## Struktur modul

```
OffPlay/
├── OffPlayApp                # shell: navigasi, tema, ATT prompt
├── Core/
│   ├── GameModule            # protokol yang dipenuhi tiap Judul
│   ├── StatsStore            # persistensi Statistik Pemain + Lanjutkan Sesi
│   ├── AdsCoordinator        # AdMob wrapper, Kadens Iklan, fail-silent
│   └── Entitlements          # StoreKit 2, status Remove Ads + restore
└── Titles/
    ├── BlockGrid/
    ├── KlondikeSolitaire/
    ├── Sudoku/
    ├── Game2048/
    ├── Minesweeper/
    └── WordScramble/
```

## Protokol `GameModule`

```swift
protocol GameModule {
    var name: String { get }
    var icon: Image { get }
    func makeGameView() -> AnyView
    func makeStatsView() -> AnyView          // dipakai di UI Game Box, bukan halaman detail
}
```

Alur tampilan: Game Box menampilkan daftar Judul sebagai grid ikon; tap ikon langsung membuka `makeGameView()`. Tidak ada halaman detail per Judul. `makeStatsView()` disajikan sebagai overlay/section kecil, bukan halaman tersendiri.

## Kadens Iklan

Aturan interstitial, semua deterministik dan diuji unit:

1. Interstitial hanya muncul pada akhir Sesi (Game Over / menang / keluar ke Game Box).
2. Maksimal 1 interstitial per 90 detik, dihitung sejak tayangan terakhir.
3. Tidak pernah muncul pada 2 Sesi pertama pengguna baru.
4. Saat offline atau iklan gagal muat: dilewati diam-diam, tidak ada retry loop, tidak ada UI error.
5. Tidak ada iklan banner dalam v1.0.

## Persistensi

- `StatsStore` (protokol) dengan implementasi JSON file via `UserDefaults`. Satu file per Judul. Tanpa sync.
- `Lanjutkan Sesi`: tiap Judul menyimpan state Sesi yang belum berakhir sendiri, juga via `StatsStore`. Saat Judul dibuka, jika ada Sesi tersimpan, tawarkan "Lanjutkan" atau "Mulai Baru".
- Penghapusan aplikasi menghapus semua data. Ini disengaja (ADR-0004).

## Momen iklan per Judul

| Judul | Akhir Sesi alami |
|---|---|
| Block Grid | Layar Game Over |
| Klondike Solitaire | Menang atau quit di tengah permainan |
| Sudoku | Puzzle selesai atau quit |
| 2048 | Game Over |
| Minesweeper | Menang, kalah, atau quit |
| Word Scramble | Ronde selesai |

## Platform & API

- SwiftUI untuk semua UI dan board/grid sederhana; SpriteKit hanya jika sebuah Judul butuh partikel/fisika ringan (keputusan per modul).
- Minimum iOS 17 (SwiftData tidak dipakai, tapi iOS 17 memperkecil rentang pengujian dan API StoreKit 2 terbaru stabil).
- Apple Core Haptics: feedback light/medium pada momen pasang balok, taruh kartu, gabung angka.
- Dark Mode dan Safe Area wajib di semua layar; tidak ada UI yang tertutup Dynamic Island atau gestur bawah.
- Target ukuran binary di bawah 60 MB.

## Urutan pengerjaan

1. Shell + `GameModule` + `StatsStore` + `AdsCoordinator` + `Entitlements` (tulang punggung, dengan 1 Judul main-main untuk integrasi)
2. Block Grid
3. Klondike Solitaire
4. 2048
5. Sudoku, Minesweeper, Word Scramble

Setiap langkah berakhir dengan build + pengujian E2E sebelum lanjut.
