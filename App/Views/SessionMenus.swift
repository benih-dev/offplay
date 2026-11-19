import SwiftUI
import OffPlayCore

struct PauseMenuView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sesi dijeda").font(.system(.title2, design: .rounded).bold())
                if let id = store.activeID {
                    Text("\(id.name) · \(GameTheme.time(store.library.session(id)?.elapsed ?? 0))").foregroundStyle(GameTheme.secondary).accessibilityIdentifier("pause.time")
                    Button("Lanjutkan") { store.modal = nil }.buttonStyle(ActionButtonStyle(primary: true)).keyboardShortcut(.cancelAction).accessibilityIdentifier("pause.resume")
                    Button("Mulai Baru") { store.requestNewGame(id) }.buttonStyle(ActionButtonStyle())
                    Button("Aturan Permainan") { store.present(.rules) }.buttonStyle(ActionButtonStyle()).accessibilityIdentifier("pause.rules")
                }
                Button("Ke Game Box") { store.leaveGame() }.buttonStyle(ActionButtonStyle()).accessibilityIdentifier("pause.catalog")
            }.padding(24)
        }
        .foregroundStyle(GameTheme.ink).background(GameTheme.canvas)
        .presentationDetents([.medium, .large])
    }
}

struct NewGameView: View {
    let id: GameID
    @State private var sudoku: SudokuDifficulty
    @State private var mines: MineDifficulty
    @Environment(AppStore.self) private var store

    init(id: GameID, sudoku: SudokuDifficulty, mines: MineDifficulty) {
        self.id = id; _sudoku = State(initialValue: sudoku); _mines = State(initialValue: mines)
    }

    var body: some View {
        let abandoning = store.library.session(id).map { $0.hasStarted && $0.outcome == nil } ?? false
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Mulai tantangan baru?").font(.system(.title2, design: .rounded).bold())
                if abandoning {
                    Text("Sesi ini akan dicatat sebagai Ditinggalkan. Progres papan saat ini tidak dipulihkan.").foregroundStyle(GameTheme.secondary)
                }
                if id == .sudoku {
                    ForEach(SudokuDifficulty.allCases) { level in
                        Button { sudoku = level } label: {
                            HStack { Text(level.name); Spacer(); if sudoku == level { Image(systemName: "checkmark") } }
                        }.buttonStyle(ActionButtonStyle()).accessibilityIdentifier("new.sudoku.\(level.rawValue)")
                    }
                } else if id == .minesweeper {
                    ForEach(MineDifficulty.allCases) { level in
                        Button { mines = level } label: {
                            HStack { Text("\(level.name) · \(level.side)×\(level.side)"); Spacer(); if mines == level { Image(systemName: "checkmark") } }
                        }.buttonStyle(ActionButtonStyle()).accessibilityIdentifier("new.mines.\(level.rawValue)")
                    }
                }
                Button(abandoning ? "Ya, Mulai Baru" : "Mulai Baru") { store.newGame(id, sudoku: sudoku, mines: mines) }
                    .buttonStyle(ActionButtonStyle(primary: true, destructive: abandoning)).accessibilityIdentifier("new.confirm")
                Button("Batal") { store.modal = nil }.buttonStyle(ActionButtonStyle()).keyboardShortcut(.cancelAction).accessibilityIdentifier("new.cancel")
            }.padding(24)
        }
        .foregroundStyle(GameTheme.ink).background(GameTheme.canvas)
        .presentationDetents([.medium, .large])
    }
}

struct RulesView: View {
    let id: GameID
    @Environment(AppStore.self) private var store
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(rules).font(.body).frame(maxWidth: .infinity, alignment: .leading).padding(24)
            }.background(GameTheme.canvas).foregroundStyle(GameTheme.ink)
                .navigationTitle("Aturan \(id.name)").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Selesai") { store.modal = nil }.frame(minHeight: 48).keyboardShortcut(.cancelAction).accessibilityIdentifier("rules.done") }
        }
    }
    private var rules: String {
        switch id {
        case .blockGrid: "Pilih keping dari baki, lalu tap petak untuk pojok kiri atas keping. Keping tidak dapat diputar. Baris dan kolom penuh dibersihkan bersamaan. Skor: satu poin per sel keping ditambah 10 per garis. Baki baru muncul sesudah ketiga keping terpakai. Sesi berakhir ketika tidak ada keping tersisa yang dapat diletakkan."
        case .klondike: "Tap kartu terbuka, lalu tap kolom atau fondasi tujuan. Tableau berurutan turun dengan warna bergantian; rangkaian terbuka dapat dipindah bersama. Hanya King mengisi kolom kosong. Fondasi per jenis dimulai dari Ace sampai King. Ambil satu kartu dari stock; putar ulang tanpa batas ketika habis. Undo mengembalikan satu tindakan lengkap. Selesaikan keempat fondasi untuk Menang."
        case .sudoku: "Isi angka 1 sampai 9 tanpa duplikasi pada baris, kolom, atau kotak 3×3. Angka bawaan tidak dapat diubah. Mode Catatan mengubah kandidat manual di sel kosong. Penanda kesalahan hanya menunjukkan duplikasi, bukan jawaban dari solusi. Undo mengembalikan angka beserta catatan. Pilih kesulitan melalui Mulai Baru."
        case .game2048: "Geser papan atau gunakan tombol arah. Angka yang sama bergabung sekali per langkah. Sesudah gerakan sah, muncul satu ubin baru. Skor berasal dari penggabungan. Undo mengembalikan satu geseran beserta undian ubin. Mencapai 2048 bukan akhir permainan: terus bermain sampai tidak ada gerakan sah."
        case .minesweeper: "Tap untuk membuka petak. Pembukaan pertama dan tetangganya aman. Angka menunjukkan jumlah ranjau di sekitarnya. Gunakan mode Bendera pada petak tertutup. Tap angka terbuka untuk membuka tetangga ketika jumlah benderanya cocok; bendera yang salah bisa membuka ranjau. Menang ketika semua petak aman terbuka. Papan dapat digeser untuk menjangkau seluruh petak."
        case .wordScramble: "Tap huruf untuk menyusun jawaban. Tap slot jawaban untuk mengeluarkan hurufnya. Kirim setelah semua slot terisi. Setiap kata dalam korpus yang memakai seluruh huruf diterima, termasuk anagram lain yang sah. Jawaban salah dapat diedit. Satu kata selesai berarti satu Sesi Menang."
        }
    }
}
