import SwiftUI
import OffPlayCore

struct StatisticsView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        NavigationStack {
            List {
                ForEach(GameID.allCases) { id in
                    let stats = store.library.stats(id)
                    Section(id.name) {
                        if stats.total.started == 0 { Text("Belum ada Sesi dimainkan.").foregroundStyle(GameTheme.secondary).accessibilityIdentifier("stats.empty.\(id.rawValue)") }
                        stat("Sesi dimulai", String(stats.total.started))
                        stat("Sesi selesai", String(stats.total.completed))
                        stat("Ditinggalkan", String(stats.total.abandoned))
                        stat("Waktu aktif", GameTheme.time(stats.total.activeTime))
                        switch id {
                        case .blockGrid, .game2048:
                            stat("Skor tertinggi", stats.total.highScore.map(String.init) ?? "Belum ada rekor", id: "stats.\(id.rawValue).highScore")
                            if id == .game2048 {
                                stat("Ubin terminal tertinggi", stats.total.highestTile.map(String.init) ?? "Belum ada rekor", id: "stats.game2048.highestTile")
                                stat("Sesi mencapai 2048", String(stats.total.target2048Count))
                            }
                        case .klondike:
                            stat("Menang", String(stats.total.won))
                            bestTime(stats.total)
                            stat("Langkah Menang tersedikit", stats.total.fewestMoves.map(String.init) ?? "Belum ada rekor")
                        case .sudoku:
                            ForEach(SudokuDifficulty.allCases) { level in
                                group(level.name, stats.groups[level.rawValue] ?? GameStatistics(), mines: false)
                            }
                        case .minesweeper:
                            ForEach(MineDifficulty.allCases) { level in
                                group(level.name, stats.groups[level.rawValue] ?? GameStatistics(), mines: true)
                            }
                        case .wordScramble:
                            ForEach(4...8, id: \.self) { length in
                                group("\(length) huruf", stats.groups[String(length)] ?? GameStatistics(), mines: false)
                            }
                        }
                    }.listRowBackground(GameTheme.surface)
                }
            }
            .scrollContentBackground(.hidden).background(GameTheme.canvas).foregroundStyle(GameTheme.ink)
            .navigationTitle("Statistik Pemain").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Selesai") { store.modal = nil }.frame(minHeight: 48).keyboardShortcut(.cancelAction).accessibilityIdentifier("stats.done") }
        }
    }

    @ViewBuilder private func stat(_ name: String, _ value: String, id: String? = nil) -> some View {
        let row = HStack(alignment: .top) { Text(name); Spacer(minLength: 12); Text(value).monospacedDigit().foregroundStyle(GameTheme.secondary).multilineTextAlignment(.trailing) }
        if let id {
            row.accessibilityElement(children: .combine).accessibilityValue(value).accessibilityIdentifier(id)
        } else {
            row
        }
    }
    private func bestTime(_ stats: GameStatistics) -> some View {
        stat("Waktu Menang terbaik", stats.bestTime.map(GameTheme.time) ?? "Belum ada rekor")
    }
    private func group(_ name: String, _ stats: GameStatistics, mines: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name).font(.headline).foregroundStyle(GameTheme.accent)
            stat("Menang", String(stats.won))
            bestTime(stats)
            if mines {
                stat("Kalah", String(stats.lost))
                stat("Win rate", stats.winRate.map { String(format: "%.0f%%", $0 * 100) } ?? "Belum ada hasil")
                stat("Streak", String(stats.streak))
                stat("Streak terpanjang", String(stats.longestStreak))
            }
        }.padding(.vertical, 8)
    }
}
