import SwiftUI
import OffPlayCore

struct WordScrambleView: View {
    @Environment(AppStore.self) private var store
    @ScaledMetric(relativeTo: .title2) private var minimumTileWidth: CGFloat = 36

    private struct TileButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label.opacity(configuration.isPressed ? 0.8 : 1)
        }
    }

    var body: some View {
        if case let .wordScramble(game)? = store.library.session(.wordScramble)?.state {
            VStack(alignment: .leading, spacing: 12) {
                if game.isWon {
                    solved(game)
                } else {
                    puzzle(game)
                }
            }
            .foregroundStyle(GameMenuTheme.text)
            .padding(12)
            .background {
                let frame = RoundedRectangle(cornerRadius: GameMenuTheme.radius)
                frame.fill(GameMenuTheme.boardWell(.wordScramble))
                    .overlay(frame.strokeBorder(GameMenuTheme.boardEdge(.wordScramble), lineWidth: GameMenuTheme.edge))
            }
        }
    }

    @ViewBuilder private func puzzle(_ game: WordScrambleGame) -> some View {
        Text("Build an Indonesian word · \(game.group.length) letters").font(.headline)
        VStack(alignment: .leading, spacing: 6) {
            Text("Answer").font(.subheadline)
            tileGrid(game.letters.indices) { slot in
                let filled = game.chosen.indices.contains(slot)
                Button { remove(slot) } label: {
                    tile(filled ? game.letters[game.chosen[slot]].uppercased() : "_", number: slot + 1, recessed: !filled)
                }
                .buttonStyle(TileButtonStyle())
                .disabled(!filled)
                .accessibilityLabel("Answer slot \(slot + 1)")
                .accessibilityValue(filled ? game.letters[game.chosen[slot]] : String(localized: "empty"))
                .accessibilityIdentifier("word.answer.\(slot)")
            }
        }
        VStack(alignment: .leading, spacing: 6) {
            Text("Available Letters").font(.subheadline)
            tileGrid(game.letters.indices) { index in
                let used = game.chosen.contains(index)
                Button { add(index) } label: {
                    tile(game.letters[index].uppercased(), recessed: used)
                }
                .buttonStyle(TileButtonStyle())
                .disabled(used)
                .accessibilityLabel("Letter \(game.letters[index].uppercased()), tile \(index + 1)")
                .accessibilityIdentifier("word.letter.\(index)")
            }
        }
        Button("Submit Answer") {
            store.play(.wordScramble, submittingWord: true) { state in
                guard case var .wordScramble(current) = state else { return false }
                let changed = current.submit(); state = .wordScramble(current); return changed
            }
        }.buttonStyle(ActionButtonStyle(primary: true)).disabled(!game.canSubmit).accessibilityIdentifier("word.submit")
        Text("Guesses: \(game.guesses) · Tap an answer letter to edit it.").font(.footnote)
            .accessibilityIdentifier("word.hint")
    }

    @ViewBuilder private func solved(_ game: WordScrambleGame) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Solved Word").font(.subheadline)
            tileGrid(game.chosen.indices) { slot in
                tile(game.letters[game.chosen[slot]].uppercased())
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Solved Word")
            .accessibilityValue(game.answer)
            .accessibilityIdentifier("word.solved")
        }
        Text("Guesses: \(game.guesses)").font(.footnote)
            .accessibilityIdentifier("word.guesses")
    }

    private func tileGrid<Tile: View>(_ indices: Range<Int>, @ViewBuilder tile: @escaping (Int) -> Tile) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
                ForEach(indices, id: \.self) { index in
                    tile(index).frame(minWidth: minimumTileWidth)
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumTileWidth), spacing: 4)], spacing: 4) {
                ForEach(indices, id: \.self, content: tile)
            }
        }
    }

    private func tile(_ letter: String, number: Int? = nil, recessed: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: 10)
        return VStack(spacing: 2) {
            Text(letter).font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(recessed ? GameTheme.secondary : GameTheme.ink)
            if let number {
                Text(String(number)).font(.caption2).foregroundStyle(GameTheme.secondary)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, minHeight: number == nil ? 48 : 56)
        .background(GameTheme.surface, in: shape)
        .overlay(shape.strokeBorder(GameTheme.line, style: StrokeStyle(lineWidth: 1, dash: recessed ? [3, 2] : [])))
        .contentShape(shape)
    }

    private func add(_ index: Int) {
        store.play(.wordScramble) { state in
            guard case var .wordScramble(game) = state else { return false }
            let changed = game.addLetter(at: index); state = .wordScramble(game); return changed
        }
    }
    private func remove(_ slot: Int) {
        store.play(.wordScramble) { state in
            guard case var .wordScramble(game) = state else { return false }
            let changed = game.removeLetter(at: slot); state = .wordScramble(game); return changed
        }
    }
}
