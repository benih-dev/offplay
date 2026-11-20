# Modular structure with each Judul as an independent module

> Status: draf desain. Arah modular disetujui; rincian protokol dan batas modul menunggu spesifikasi pada [Kesiapan desain OffPlay v1.0](https://github.com/benih-dev/offplay/issues/14).

Each Judul (Block Grid, Klondike Solitaire, etc.) lives as its own module behind a shared `GameModule` protocol (name, icon, `makeGameView()`, `makeStatsView()`). The shell app discovers and renders whichever modules are present.

Reason: six games will be developed and maintained at different times, and a monolith would produce merge conflicts and one fat target. If App Review rejects one Judul, we remove that module without touching the rest of the app.
