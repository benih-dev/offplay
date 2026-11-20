import SwiftUI
import OffPlayCore

struct SudokuView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var selected: Int?
    @State private var noteMode = false
    @State private var availableWidth: CGFloat = 0

    private var digitRows: [[Int]] {
        availableWidth >= 9 * 36 + 8 * 3 && !textSize.isAccessibilitySize
            ? [Array(1...9)] : [Array(1...5), Array(6...9)]
    }

    private var keyWidth: CGFloat {
        let columns = CGFloat(digitRows[0].count)
        return max(0, (availableWidth - (columns - 1) * 3) / columns)
    }

    var body: some View {
        if case let .sudoku(game)? = store.library.session(.sudoku)?.state {
            let size: CGFloat = textSize.isAccessibilitySize ? 64 : 48
            let duplicates = game.duplicateCells
            VStack(spacing: 3) {
                Text("\(game.puzzle.difficulty.localizedName) · Tap an empty cell to fill it").font(.footnote).foregroundStyle(GameTheme.secondary)
                FittedBoard(columns: 9, preferredCellSize: size) { size in
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(size), spacing: 0), count: 9), spacing: 0) {
                        ForEach(0..<81, id: \.self) { index in
                            SudokuCellView(index: index, size: size, value: game.values[index], notes: game.notes[index], given: game.puzzle.givens[index] > 0, selected: selected == index, duplicate: duplicates.contains(index)) { selected = index }
                        }
                    }.frame(width: size * 9)
                }
                ZStack {
                    ForEach(0...game.values.count, id: \.self) { count in
                        Text("Cells with duplicate numbers: \(count).")
                            .hidden()
                            .accessibilityHidden(true)
                    }
                    if !duplicates.isEmpty {
                        Text("Cells with duplicate numbers: \(duplicates.count).")
                            .foregroundStyle(GameTheme.danger)
                            .accessibilityIdentifier("sudoku.duplicates")
                    }
                }
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 6) {
                    ForEach(digitRows, id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(row, id: \.self) { digit in
                                Button(String(digit)) { enter(digit) }
                                    .buttonStyle(ActionButtonStyle(minimumHeight: 44, horizontalPadding: 0))
                                    .frame(width: keyWidth)
                                    .disabled(selected == nil).accessibilityIdentifier("sudoku.digit.\(digit)")
                            }
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("sudoku.keypad")
                HStack(spacing: 8) {
                    Button(noteMode ? LocalizedStringKey("Notes: On") : "Notes") { noteMode.toggle() }
                        .buttonStyle(ActionButtonStyle(primary: noteMode)).accessibilityIdentifier("sudoku.notes")
                    Button("Erase") { enter(0) }.buttonStyle(ActionButtonStyle()).disabled(selected == nil).accessibilityIdentifier("sudoku.erase")
                }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
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
    @Environment(\.colorScheme) private var colorScheme
    let index: Int
    let size: CGFloat
    let value: Int
    let notes: Set<Int>
    let given: Bool
    let selected: Bool
    let duplicate: Bool
    let select: () -> Void

    private var familyInk: Color {
        colorScheme == .dark ? GameMenuTheme.blue : GameMenuTheme.blueInk
    }

    var body: some View {
        Group {
            if given { surface.accessibilityElement(children: .ignore) }
            else { Button(action: select) { surface }.buttonStyle(BoardButtonStyle()) }
        }
        .accessibilityLabel(given ? LocalizedStringKey("Row \(index / 9 + 1), column \(index % 9 + 1), given number") : "Row \(index / 9 + 1), column \(index % 9 + 1)")
        .accessibilityValue(value == 0 ? String(localized: "empty") : String(value))
        .accessibilityHint(duplicate ? String(localized: "Duplicate number") : notes.sorted().map(String.init).joined(separator: ", "))
        .accessibilityIdentifier("sudoku.cell.\(index)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var surface: some View {
        ZStack {
            Rectangle().fill(given ? GameTheme.canvas : GameTheme.surface)
            if value > 0 {
                Text(String(value)).font(.system(.title3, design: .rounded).weight(given ? .bold : (duplicate ? .semibold : .regular))).lineLimit(1).minimumScaleFactor(0.7)
            } else if !notes.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 0) {
                    ForEach(1...9, id: \.self) { digit in
                        Text(notes.contains(digit) ? String(digit) : " ").font(.caption2).lineLimit(1).minimumScaleFactor(0.5).frame(height: (size - 12) / 3)
                    }
                }
                .padding(6)
            }
        }
        .frame(width: size, height: size).foregroundStyle(duplicate ? GameTheme.danger : (given ? GameTheme.ink : familyInk))
        .overlay(Rectangle().strokeBorder(duplicate ? GameTheme.danger : GameTheme.line, lineWidth: duplicate ? 2 : 0.75))
        .overlay(alignment: .leading) { if index % 3 == 0 { Rectangle().fill(familyInk).frame(width: 1) } }
        .overlay(alignment: .top) { if index / 9 % 3 == 0 { Rectangle().fill(familyInk).frame(height: 1) } }
        .overlay { if selected { Rectangle().inset(by: 3).strokeBorder(familyInk, lineWidth: 2) } }
    }
}
