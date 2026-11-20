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
                        .font(.footnote).foregroundStyle(GameTheme.secondary)
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
                                Rectangle().fill(game.board[index] == 0 ? GameTheme.canvas : GameTheme.accent)
                                    .frame(width: size, height: size)
                                    .overlay(Rectangle().stroke(game.board[index] == 0 ? GameTheme.line : GameTheme.canvas, lineWidth: 1))
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
                            VStack(spacing: 8) {
                                if let piece = game.tray[slot] { PieceView(cells: BlockGridGame.pieces[piece]) }
                                else { Text("Used").font(.caption) }
                            }.frame(maxWidth: .infinity, minHeight: 80)
                                .background(selected == slot ? GameTheme.accentFill : GameTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected == slot ? GameTheme.accent : GameTheme.line, lineWidth: selected == slot ? 2 : 1))
                        }
                        .buttonStyle(.plain).disabled(game.tray[slot] == nil)
                        .accessibilityLabel("Piece \(slot + 1)")
                        .accessibilityValue(selected == slot ? LocalizedStringKey("selected") : (game.tray[slot] == nil ? "used" : "available"))
                        .accessibilityIdentifier("block.piece.\(slot)")
                    }
                }
                if session.outcome == nil {
                    Text("Pieces cannot be rotated.")
                        .font(.caption).foregroundStyle(GameTheme.secondary)
                        .accessibilityIdentifier("block.rotationHint")
                }
            }
        }
    }
}

private struct PieceView: View {
    let cells: [GridCell]
    var body: some View {
        Grid(horizontalSpacing: 2, verticalSpacing: 2) {
            ForEach(0...cells.map(\.row).max()!, id: \.self) { row in
                GridRow {
                    ForEach(0...cells.map(\.column).max()!, id: \.self) { column in
                        Rectangle().fill(cells.contains(GridCell(row, column)) ? GameTheme.accent : .clear).frame(width: 11, height: 11)
                    }
                }
            }
        }.accessibilityHidden(true)
    }
}
