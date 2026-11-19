import SwiftUI
import OffPlayCore

struct PauseMenuView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Game Paused").font(.system(.title2, design: .rounded).bold())
                if let id = store.activeID {
                    Text("\(id.name) · \(GameTheme.time(store.library.session(id)?.elapsed ?? 0))").foregroundStyle(GameTheme.secondary).accessibilityIdentifier("pause.time")
                    Button("Resume") { store.modal = nil }.buttonStyle(ActionButtonStyle(primary: true)).keyboardShortcut(.cancelAction).accessibilityIdentifier("pause.resume")
                    Button("New Game") { store.requestNewGame(id) }.buttonStyle(ActionButtonStyle())
                    Button("Game Rules") { store.present(.rules) }.buttonStyle(ActionButtonStyle()).accessibilityIdentifier("pause.rules")
                }
                Button("Back to Game Box") { store.leaveGame() }.buttonStyle(ActionButtonStyle()).accessibilityIdentifier("pause.catalog")
            }.padding(24)
        }
        .foregroundStyle(GameTheme.ink).background(GameTheme.canvas)
        .presentationDetents([.medium, .large])
    }
}

struct NewGameView: View {
    let id: GameID
    @State private var sudoku: SudokuDifficulty
    @State private var mines: MineDifficulty
    @Environment(AppStore.self) private var store

    init(id: GameID, sudoku: SudokuDifficulty, mines: MineDifficulty) {
        self.id = id; _sudoku = State(initialValue: sudoku); _mines = State(initialValue: mines)
    }

    var body: some View {
        let abandoning = store.library.session(id).map { $0.hasStarted && $0.outcome == nil } ?? false
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Start a new game?").font(.system(.title2, design: .rounded).bold())
                if abandoning {
                    Text("This session will be marked as abandoned. Your current board progress will be lost.").foregroundStyle(GameTheme.secondary)
                }
                if id == .sudoku {
                    ForEach(SudokuDifficulty.allCases) { level in
                        Button { sudoku = level } label: {
                            HStack { Text(level.localizedName); Spacer(); if sudoku == level { Image(systemName: "checkmark") } }
                        }.buttonStyle(ActionButtonStyle()).accessibilityIdentifier("new.sudoku.\(level.rawValue)")
                    }
                } else if id == .minesweeper {
                    ForEach(MineDifficulty.allCases) { level in
                        Button { mines = level } label: {
                            HStack { Text("\(level.localizedName) · \(level.side)×\(level.side)"); Spacer(); if mines == level { Image(systemName: "checkmark") } }
                        }.buttonStyle(ActionButtonStyle()).accessibilityIdentifier("new.mines.\(level.rawValue)")
                    }
                }
                Button(abandoning ? LocalizedStringKey("Yes, Start New Game") : "New Game") { store.newGame(id, sudoku: sudoku, mines: mines) }
                    .buttonStyle(ActionButtonStyle(primary: true, destructive: abandoning)).accessibilityIdentifier("new.confirm")
                Button("Cancel") { store.modal = nil }.buttonStyle(ActionButtonStyle()).keyboardShortcut(.cancelAction).accessibilityIdentifier("new.cancel")
            }.padding(24)
        }
        .foregroundStyle(GameTheme.ink).background(GameTheme.canvas)
        .presentationDetents([.medium, .large])
    }
}

struct RulesView: View {
    let id: GameID
    @Environment(AppStore.self) private var store
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(rules).font(.body).frame(maxWidth: .infinity, alignment: .leading).padding(24)
            }.background(GameTheme.canvas).foregroundStyle(GameTheme.ink)
                .navigationTitle("\(id.name) Rules").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Done") { store.modal = nil }.frame(minHeight: 48).keyboardShortcut(.cancelAction).accessibilityIdentifier("rules.done") }
        }
    }
    private var rules: LocalizedStringKey {
        switch id {
        case .blockGrid: "Choose a piece from the tray, then tap the cell where its top-left corner should go. Pieces cannot be rotated. Full rows and columns clear together. You get one point per cell placed and 10 per line cleared. A new tray appears after you use all three pieces. The game ends when none of the remaining pieces fit."
        case .klondike: "Tap a face-up card, then its destination column or foundation. Build tableau columns in descending order, alternating colors. You can move a face-up sequence together. Only a king can fill an empty column. Build each suit’s foundation from ace to king. Draw one card at a time from the stock and recycle it as often as needed. Undo reverses one complete action. Complete all four foundations to win."
        case .sudoku: "Fill in the digits 1 through 9 without repeats in any row, column, or 3×3 box. You can’t change the given numbers. Use Notes to mark possible digits in empty cells. Errors flag duplicates without revealing the solution. Undo restores numbers and notes. Choose a difficulty under New Game."
        case .game2048: "Swipe the board or use the direction buttons. Matching tiles merge once per move. After each valid move, a new tile appears. Earn points by merging tiles. Undo reverses a swipe and the new tile it spawned. Reaching 2048 doesn’t end the game: keep playing until no valid moves remain."
        case .minesweeper: "Tap to reveal a cell. Your first cell and its neighbors are safe. Numbers show how many mines are nearby. Use Flag Mode on covered cells. Tap a revealed number to open adjacent cells when it has the same number of neighboring flags. Incorrect flags can expose a mine. Reveal all safe cells to win. Scroll to reach cells that don’t fit on screen."
        case .wordScramble: "Tap letters to build an Indonesian word. Tap an answer slot to remove its letter. Submit when all slots are full. Any word in the game’s dictionary that uses every letter counts, including other valid anagrams. Edit your answer if it isn’t accepted. Solve one word to win."
        }
    }
}
