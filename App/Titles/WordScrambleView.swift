import SwiftUI
import OffPlayCore

struct WordScrambleView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        if case let .wordScramble(game)? = store.library.session(.wordScramble)?.state {
            VStack(alignment: .leading, spacing: 20) {
                    Text("Susun satu kata · \(game.group.length) huruf").font(.headline)
                    Text("Jawaban").font(.subheadline).foregroundStyle(GameTheme.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
                        ForEach(0..<game.letters.count, id: \.self) { slot in
                            Button { remove(slot) } label: {
                                VStack(spacing: 4) {
                                    Text(slot < game.chosen.count ? game.letters[game.chosen[slot]].uppercased() : "_").font(.system(.title2, design: .rounded).bold())
                                    Text(String(slot + 1)).font(.caption2).foregroundStyle(GameTheme.secondary)
                                }.frame(maxWidth: .infinity, minHeight: 64)
                                    .background(GameTheme.accentFill).clipShape(RoundedRectangle(cornerRadius: 10))
                            }.buttonStyle(.plain).disabled(slot >= game.chosen.count)
                                .accessibilityLabel("Slot jawaban \(slot + 1)")
                                .accessibilityValue(slot < game.chosen.count ? game.letters[game.chosen[slot]] : "kosong")
                                .accessibilityIdentifier("word.answer.\(slot)")
                        }
                    }
                    Text("Huruf tersedia").font(.subheadline).foregroundStyle(GameTheme.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 8)], spacing: 8) {
                        ForEach(game.letters.indices, id: \.self) { index in
                            Button(game.letters[index].uppercased()) { add(index) }
                                .buttonStyle(ActionButtonStyle()).disabled(game.chosen.contains(index))
                                .accessibilityLabel("Huruf \(game.letters[index].uppercased()), keping \(index + 1)")
                                .accessibilityIdentifier("word.letter.\(index)")
                        }
                    }
                    Button("Kirim Jawaban") {
                        store.play(.wordScramble, submittingWord: true) { state in
                            guard case var .wordScramble(current) = state else { return false }
                            let changed = current.submit(); state = .wordScramble(current); return changed
                        }
                    }.buttonStyle(ActionButtonStyle(primary: true)).disabled(!game.canSubmit).accessibilityIdentifier("word.submit")
                    Text("\(game.guesses) tebakan · tap huruf jawaban untuk mengeditnya.").font(.footnote).foregroundStyle(GameTheme.secondary)
            }.padding(.vertical, 16)
        }
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
