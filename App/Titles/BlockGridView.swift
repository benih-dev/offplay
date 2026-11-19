import SwiftUI
import OffPlayCore

struct BlockGridView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var selected: Int?

    var body: some View {
        if case let .blockGrid(game)? = store.library.session(.blockGrid)?.state {
            let size: CGFloat = textSize.isAccessibilitySize ? 64 : 48
            VStack(spacing: 12) {
                Text("Pilih keping, lalu tap pojok kiri atas tempatnya.").font(.footnote).foregroundStyle(GameTheme.secondary)
                BoardViewport(height: size * 8 + 16) {
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
                            .accessibilityLabel("Baris \(index / 8 + 1), kolom \(index % 8 + 1), \(game.board[index] == 0 ? "kosong" : "terisi")")
                            .accessibilityIdentifier("block.cell.\(index)")
                        }
                    }.frame(width: size * 8)
                }
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { slot in
                        Button { selected = selected == slot ? nil : slot } label: {
                            VStack(spacing: 8) {
                                if let piece = game.tray[slot] { PieceView(cells: BlockGridGame.pieces[piece]) }
                                else { Text("Terpakai").font(.caption) }
                            }.frame(maxWidth: .infinity, minHeight: 80)
                                .background(selected == slot ? GameTheme.accentFill : GameTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected == slot ? GameTheme.accent : GameTheme.line, lineWidth: selected == slot ? 2 : 1))
                        }
                        .buttonStyle(.plain).disabled(game.tray[slot] == nil)
                        .accessibilityLabel("Keping \(slot + 1)")
                        .accessibilityValue(selected == slot ? "dipilih" : (game.tray[slot] == nil ? "terpakai" : "tersedia"))
                        .accessibilityIdentifier("block.piece.\(slot)")
                    }
                }
                Text("Papan dapat digeser. Keping tidak dapat diputar.").font(.caption).foregroundStyle(GameTheme.secondary)
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
