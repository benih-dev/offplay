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
                        if stats.total.started == 0 {
                            Text("No sessions played yet.")
                                .foregroundStyle(GameTheme.secondary)
                                .accessibilityIdentifier("stats.empty.\(id.rawValue)")
                        } else {
                            stat("Sessions Started", String(stats.total.started), id: "stats.\(id.rawValue).started")
                            stat("Sessions Completed", String(stats.total.completed))
                            stat("Abandoned", String(stats.total.abandoned))
                            stat("Active Time", GameTheme.time(stats.total.activeTime))
                            switch id {
                            case .blockGrid, .game2048:
                                stat("High Score", stats.total.highScore.map(String.init) ?? String(localized: "No record yet"), id: "stats.\(id.rawValue).highScore")
                                if id == .game2048 {
                                    stat("Highest Final Tile", stats.total.highestTile.map(String.init) ?? String(localized: "No record yet"), id: "stats.game2048.highestTile")
                                    stat("Sessions Reaching 2048", String(stats.total.target2048Count))
                                }
                            case .klondike:
                                stat("Wins", String(stats.total.won))
                                bestTime(stats.total)
                                stat("Fewest Moves to Win", stats.total.fewestMoves.map(String.init) ?? String(localized: "No record yet"))
                            case .sudoku:
                                ForEach(SudokuDifficulty.allCases) { level in
                                    group(Text(level.localizedName), stats.groups[level.rawValue] ?? GameStatistics(), mines: false)
                                }
                            case .minesweeper:
                                ForEach(MineDifficulty.allCases) { level in
                                    group(Text(level.localizedName), stats.groups[level.rawValue] ?? GameStatistics(), mines: true)
                                }
                            case .wordScramble:
                                ForEach(4...8, id: \.self) { length in
                                    group(Text("\(length) letters"), stats.groups[String(length)] ?? GameStatistics(), mines: false)
                                }
                            }
                        }
                    }.listRowBackground(GameTheme.surface)
                }
            }
            .scrollContentBackground(.hidden).background(GameTheme.canvas).foregroundStyle(GameTheme.ink)
            .navigationTitle("Player Statistics").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { store.modal = nil }.frame(minHeight: 48).keyboardShortcut(.cancelAction).accessibilityIdentifier("stats.done") }
        }
    }

    private func stat(_ name: LocalizedStringKey, _ value: String, id: String? = nil) -> some View {
        HStack(alignment: .top) { Text(name); Spacer(minLength: 12); Text(value).monospacedDigit().foregroundStyle(GameTheme.secondary).multilineTextAlignment(.trailing).accessibilityIdentifier(id ?? "") }
    }
    private func bestTime(_ stats: GameStatistics) -> some View {
        stat("Best Winning Time", stats.bestTime.map(GameTheme.time) ?? String(localized: "No record yet"))
    }
    private func group(_ name: Text, _ stats: GameStatistics, mines: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            name.font(.headline).foregroundStyle(GameTheme.accent)
            stat("Wins", String(stats.won))
            bestTime(stats)
            if mines {
                stat("Losses", String(stats.lost))
                stat("Win rate", stats.winRate.map { String(format: "%.0f%%", $0 * 100) } ?? String(localized: "No results yet"))
                stat("Streak", String(stats.streak))
                stat("Longest Streak", String(stats.longestStreak))
            }
        }.padding(.vertical, 8)
    }
}
