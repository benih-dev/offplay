import SwiftUI
import OffPlayCore

struct BlockGridView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var selected: Int?

    var body: some View {
        if let session = store.library.session(.blockGrid), case let .blockGrid(game) = session.state {
            let size: CGFloat = textSize.isAccessibilitySize ? 64 : 48
            VStack(spacing: 12) {
                if session.outcome == nil {
                    Text("Choose a piece, then tap where its top-left corner should go.")
                        .font(.footnote).foregroundStyle(GameMenuTheme.secondary)
                        .accessibilityIdentifier("block.instructions")
                }
                FittedBoard(columns: 8, preferredCellSize: size) { size in
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(size), spacing: 0), count: 8), spacing: 0) {
                        ForEach(0..<64, id: \.self) { index in
                            Button {
                                guard let slot = selected else { return }
                                if store.play(.blockGrid, { state in
                                    guard case var .blockGrid(current) = state else { return false }
                                    let changed = current.place(slot: slot, row: index / 8, column: index % 8)
                                    state = .blockGrid(current); return changed
                                }) { selected = nil }
                            } label: {
                                BoardCell(filled: game.board[index] != 0).frame(width: size, height: size)
                            }
                            .buttonStyle(BoardButtonStyle()).disabled(selected == nil)
                            .accessibilityLabel("Row \(index / 8 + 1), column \(index % 8 + 1), \(game.board[index] == 0 ? String(localized: "empty") : String(localized: "filled"))")
                            .accessibilityIdentifier("block.cell.\(index)")
                        }
                    }.frame(width: size * 8)
                }
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { slot in
                        Button { selected = selected == slot ? nil : slot } label: {
                            TraySlot(piece: game.tray[slot], selected: selected == slot)
                        }
                        .buttonStyle(.plain).disabled(game.tray[slot] == nil)
                        .accessibilityLabel("Piece \(slot + 1)")
                        .accessibilityValue(selected == slot ? LocalizedStringKey("selected") : (game.tray[slot] == nil ? "used" : "available"))
                        .accessibilityIdentifier("block.piece.\(slot)")
                    }
                }
                if session.outcome == nil {
                    Text("Pieces cannot be rotated.")
                        .font(.caption).foregroundStyle(GameMenuTheme.secondary)
                        .accessibilityIdentifier("block.rotationHint")
                }
            }
        }
    }
}

private struct BoardCell: View {
    let filled: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        shape.fill(filled ? GameMenuTheme.blockTile : GameMenuTheme.utilitySurface)
            .overlay(shape.strokeBorder(filled ? GameMenuTheme.blockTileEdge : GameMenuTheme.blockCellEdge, lineWidth: 1))
            .padding(1)
    }
}

private struct TraySlot: View {
    let piece: Int?
    let selected: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: GameMenuTheme.smallRadius, style: .continuous)
        Group {
            if let piece { PieceView(cells: BlockGridGame.pieces[piece], ink: selected ? GameMenuTheme.greenDeep : GameMenuTheme.blockTile) }
            else { Text("Used").font(.system(.caption, design: .rounded)).foregroundStyle(GameMenuTheme.secondary) }
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .background {
            if piece == nil {
                shape.strokeBorder(GameMenuTheme.utilityOutline, style: StrokeStyle(lineWidth: GameMenuTheme.edge, dash: [6, 4]))
            } else {
                shape.fill(selected ? GameMenuTheme.face(.blockGrid) : GameMenuTheme.utilitySurface)
                    .shadow(color: GameMenuTheme.depth, radius: 0, y: selected ? 2 : GameMenuTheme.lift)
                    .overlay(shape.strokeBorder(selected ? GameMenuTheme.ink : GameMenuTheme.utilityOutline, lineWidth: GameMenuTheme.edge))
            }
        }
        .overlay(alignment: .topTrailing) {
            if selected {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 17, weight: .bold))
                    .foregroundStyle(GameMenuTheme.ink).padding(6)
            }
        }
        .offset(y: selected ? 4 : 0)
        .contentShape(shape)
    }
}

private struct PieceView: View {
    let cells: [GridCell]
    let ink: Color
    var body: some View {
        Grid(horizontalSpacing: 2, verticalSpacing: 2) {
            ForEach(0...cells.map(\.row).max()!, id: \.self) { row in
                GridRow {
                    ForEach(0...cells.map(\.column).max()!, id: \.self) { column in
                        RoundedRectangle(cornerRadius: 2, style: .continuous).fill(cells.contains(GridCell(row, column)) ? ink : .clear).frame(width: 11, height: 11)
                    }
                }
            }
        }.accessibilityHidden(true)
    }
}
