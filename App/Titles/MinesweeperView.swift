import SwiftUI
import OffPlayCore

struct MinesweeperView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var flagMode = false
    @State private var boardOverflows = false

    var body: some View {
        if case let .minesweeper(game)? = store.library.session(.minesweeper)?.state {
            let size: CGFloat = textSize.isAccessibilitySize ? 64 : 48
            VStack(spacing: 10) {
                HStack {
                    Text(game.difficulty.localizedName)
                    Spacer()
                    Text("Flags \(game.flags.count)/\(game.mineCount)").monospacedDigit()
                }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(GameMenuTheme.text)
                Button { flagMode.toggle() } label: { Label(flagMode ? LocalizedStringKey("Flag Mode: On") : "Flag Mode", systemImage: "flag") }
                    .buttonStyle(ActionButtonStyle(primary: flagMode)).accessibilityIdentifier("mines.flagMode")
                    .accessibilityValue(flagMode ? LocalizedStringKey("On") : "Off")
                FittedBoard(columns: game.side, preferredCellSize: size, onOverflowChange: { boardOverflows = $0 }) { size in
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(size), spacing: 0), count: game.side), spacing: 0) {
                        ForEach(0..<(game.side * game.side), id: \.self) { index in
                            Button { open(index) } label: {
                                Text(symbol(game, index)).font(.system(.title3, design: .rounded).bold())
                                    .frame(width: size, height: size)
                                    .foregroundStyle(foreground(game, index))
                                    .background(background(game, index))
                                    .overlay(Rectangle().stroke(GameMenuTheme.mineGrid, lineWidth: 1))
                            }
                            .buttonStyle(BoardButtonStyle())
                            .accessibilityLabel("Row \(index / game.side + 1), column \(index % game.side + 1), \(description(game, index))")
                            .accessibilityIdentifier("mines.cell.\(index)")
                        }
                    }.frame(width: size * CGFloat(game.side))
                }
                Text(boardOverflows ? LocalizedStringKey("Scroll to reach more cells. Tap a revealed number to open its neighbors.") : "Tap a revealed number to open its neighbors.").font(.caption).foregroundStyle(GameTheme.secondary)
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
        if game.exploded == index { return String(localized: "exploded mine") }
        if game.isFinished && game.mines.contains(index) { return String(localized: "mine") }
        if game.flags.contains(index) { return String(localized: "flagged") }
        if game.revealed.contains(index) { return String(localized: "revealed, nearby mines: \(game.adjacentMines(at: index))") }
        return String(localized: "covered")
    }
    private func foreground(_ game: MinesweeperGame, _ index: Int) -> Color {
        if game.exploded == index { return GameMenuTheme.paper }
        if game.isFinished && game.mines.contains(index) { return GameMenuTheme.mineSymbol }
        if game.flags.contains(index) { return GameMenuTheme.mineSymbol }
        if game.revealed.contains(index) { return GameMenuTheme.mineNumber(game.adjacentMines(at: index)) }
        return GameMenuTheme.mineSymbol
    }
    private func background(_ game: MinesweeperGame, _ index: Int) -> Color {
        if game.exploded == index { return GameMenuTheme.mineExplosion }
        return game.revealed.contains(index) ? GameMenuTheme.mineSurface : GameMenuTheme.mineCovered
    }
}
