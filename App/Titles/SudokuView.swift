import SwiftUI
import OffPlayCore

struct SudokuView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var selected: Int?
    @State private var noteMode = false

    var body: some View {
        if case let .sudoku(game)? = store.library.session(.sudoku)?.state {
            let size: CGFloat = textSize.isAccessibilitySize ? 64 : 48
            let duplicates = game.duplicateCells
            VStack(spacing: 10) {
                Text("\(game.puzzle.difficulty.name) · tap sel kosong untuk mengisi").font(.footnote).foregroundStyle(GameTheme.secondary)
                BoardViewport(height: size * 9 + 16) {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(size), spacing: 0), count: 9), spacing: 0) {
                        ForEach(0..<81, id: \.self) { index in
                            SudokuCellView(index: index, size: size, value: game.values[index], notes: game.notes[index], given: game.puzzle.givens[index] > 0, selected: selected == index, duplicate: duplicates.contains(index)) { selected = index }
                        }
                    }.frame(width: size * 9)
                }
                if !duplicates.isEmpty {
                    Text("Angka duplikat pada \(duplicates.count) sel.").font(.footnote).foregroundStyle(GameTheme.danger)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 6)], spacing: 6) {
                    ForEach(1...9, id: \.self) { digit in
                        Button(String(digit)) { enter(digit) }.buttonStyle(ActionButtonStyle())
                            .disabled(selected == nil).accessibilityIdentifier("sudoku.digit.\(digit)")
                    }
                }
                HStack(spacing: 8) {
                    Button(noteMode ? "Catatan: aktif" : "Catatan") { noteMode.toggle() }
                        .buttonStyle(ActionButtonStyle(primary: noteMode)).accessibilityIdentifier("sudoku.notes")
                    Button("Hapus") { enter(0) }.buttonStyle(ActionButtonStyle()).disabled(selected == nil).accessibilityIdentifier("sudoku.erase")
                }
            }
        }
    }
    private func enter(_ digit: Int) {
        guard let selected else { return }
        store.play(.sudoku) { state in
            guard case var .sudoku(game) = state else { return false }
            let changed = game.enter(digit, at: selected, asNote: digit != 0 && noteMode)
            state = .sudoku(game); return changed
        }
    }
}

private struct SudokuCellView: View {
    let index: Int
    let size: CGFloat
    let value: Int
    let notes: Set<Int>
    let given: Bool
    let selected: Bool
    let duplicate: Bool
    let select: () -> Void

    var body: some View {
        Group {
            if given { surface.accessibilityElement(children: .ignore) }
            else { Button(action: select) { surface }.buttonStyle(BoardButtonStyle()) }
        }
        .accessibilityLabel("Baris \(index / 9 + 1), kolom \(index % 9 + 1)\(given ? ", angka bawaan" : "")")
        .accessibilityValue(value == 0 ? "kosong" : String(value))
        .accessibilityHint(duplicate ? "Angka duplikat" : notes.sorted().map(String.init).joined(separator: ", "))
        .accessibilityIdentifier("sudoku.cell.\(index)")
    }

    private var surface: some View {
        ZStack {
            Rectangle().fill(selected ? GameTheme.accentFill : (given ? GameTheme.canvas : GameTheme.surface))
            if value > 0 {
                Text(String(value)).font(.system(.title3, design: .rounded).weight(given ? .bold : .regular)).lineLimit(1).minimumScaleFactor(0.7)
            } else if !notes.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 0) {
                    ForEach(1...9, id: \.self) { digit in
                        Text(notes.contains(digit) ? String(digit) : " ").font(.caption2).lineLimit(1).minimumScaleFactor(0.5).frame(height: size / 3)
                    }
                }
            }
        }
        .frame(width: size, height: size).foregroundStyle(duplicate ? GameTheme.danger : GameTheme.ink)
        .overlay(Rectangle().stroke(duplicate ? GameTheme.danger : (selected ? GameTheme.accent : GameTheme.line), lineWidth: selected || duplicate ? 2 : 0.75))
        .overlay(alignment: .leading) { if index % 3 == 0 { Rectangle().fill(GameTheme.ink).frame(width: 1) } }
        .overlay(alignment: .top) { if index / 9 % 3 == 0 { Rectangle().fill(GameTheme.ink).frame(height: 1) } }
    }
}
