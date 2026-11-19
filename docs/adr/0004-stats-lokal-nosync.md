# Statistik Pemain stored locally only, no sync, plain persistence for v1.0

> Status: ditarik karena salah membaca jawaban pengguna. Isi historis di bawah tidak berlaku. Kebutuhan yang benar: Statistik Pemain dan Sesi yang belum selesai harus dapat dipulihkan setelah pemasangan ulang. Pilihan penyimpanan menunggu [Menetapkan janji dan batas pemulihan progres](../../.scratch/offplay-v1-design/issues/05-kebijakan-pemulihan.md).

Statistik Pemain is stored only on-device behind a `StatsStore` protocol with a UserDefaults/JSON file implementation for v1.0. There is no iCloud or server sync, and the data may be lost if the app is deleted. Lanjutkan Sesi state is persisted the same way.

Reason: six games with simple per-Judul stats do not justify Core Data or SwiftData for v1.0. The `StatsStore` protocol keeps the implementation swappable later, so replacing it with SwiftData is cheap and non-breaking.
