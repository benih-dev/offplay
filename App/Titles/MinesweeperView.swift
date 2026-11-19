import SwiftUI
import OffPlayCore

struct MinesweeperView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var flagMode = false

    var body: some View {
        if case let .minesweeper(game)? = store.library.session(.minesweeper)?.state {
            let size: CGFloat = textSize.isAccessibilitySize ? 64 : 48
            VStack(spacing: 10) {
                HStack {
                    Text(game.difficulty.name).font(.subheadline)
                    Spacer()
                    Text("Bendera \(game.flags.count)/\(game.mineCount)").font(.subheadline).monospacedDigit()
                }
                Button { flagMode.toggle() } label: { Label(flagMode ? "Bendera: aktif" : "Mode Bendera", systemImage: "flag") }
                    .buttonStyle(ActionButtonStyle(primary: flagMode)).accessibilityIdentifier("mines.flagMode")
                    .accessibilityValue(flagMode ? "aktif" : "nonaktif")
                FittedBoard(columns: game.side, preferredCellSize: size) { size in
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(size), spacing: 0), count: game.side), spacing: 0) {
                        ForEach(0..<(game.side * game.side), id: \.self) { index in
                            Button { open(index) } label: {
                                Text(symbol(game, index)).font(.system(.title3, design: .rounded).bold())
                                    .frame(width: size, height: size)
                                    .foregroundStyle(game.isFinished && game.mines.contains(index) ? GameTheme.danger : GameTheme.ink)
                                    .background(game.revealed.contains(index) ? GameTheme.canvas : GameTheme.accentFill)
                                    .overlay(Rectangle().stroke(GameTheme.line, lineWidth: 1))
                            }
                            .buttonStyle(BoardButtonStyle())
                            .accessibilityLabel("Baris \(index / game.side + 1), kolom \(index % game.side + 1), \(description(game, index))")
                            .accessibilityIdentifier("mines.cell.\(index)")
                        }
                    }.frame(width: size * CGFloat(game.side))
                }
                Text("Tap angka terbuka untuk buka-serentak.").font(.caption).foregroundStyle(GameTheme.secondary)
            }
        }
    }

    private func open(_ index: Int) {
        store.play(.minesweeper) { state in
            guard case var .minesweeper(game) = state else { return false }
            let changed = flagMode ? game.toggleFlag(at: index) : (game.revealed.contains(index) ? game.chord(at: index) : game.reveal(at: index))
            state = .minesweeper(game); return changed
        }
    }
    private func symbol(_ game: MinesweeperGame, _ index: Int) -> String {
        if game.isFinished && game.mines.contains(index) { return "●" }
        if game.flags.contains(index) { return "⚑" }
        if game.revealed.contains(index) { let count = game.adjacentMines(at: index); return count == 0 ? "" : String(count) }
        return "·"
    }
    private func description(_ game: MinesweeperGame, _ index: Int) -> String {
        if game.isFinished && game.mines.contains(index) { return "ranjau" }
        if game.flags.contains(index) { return "bendera" }
        if game.revealed.contains(index) { return "terbuka, \(game.adjacentMines(at: index)) ranjau di sekitar" }
        return "tertutup"
    }
}
