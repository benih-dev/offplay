import SwiftUI
import OffPlayCore

enum GameCatalog {
    static func symbol(_ id: GameID) -> String {
        switch id {
        case .blockGrid: "square.grid.3x3.fill"
        case .klondike: "suit.spade.fill"
        case .sudoku: "number.square"
        case .game2048: "square.grid.2x2.fill"
        case .minesweeper: "flag.fill"
        case .wordScramble: "textformat.abc"
        }
    }

    @ViewBuilder static func board(_ id: GameID) -> some View {
        switch id {
        case .blockGrid: BlockGridView()
        case .klondike: KlondikeView()
        case .sudoku: SudokuView()
        case .game2048: Game2048View()
        case .minesweeper: MinesweeperView()
        case .wordScramble: WordScrambleView()
        }
    }
}

struct GameBoxView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        @Bindable var state = store
        NavigationStack(path: $state.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Enam permainan untuk waktu luangmu.")
                        .font(.subheadline).foregroundStyle(GameTheme.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: textSize.isAccessibilitySize ? 260 : 155), spacing: 12)], spacing: 12) {
                        ForEach(GameID.allCases) { id in
                            Button { store.open(id) } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    Image(systemName: GameCatalog.symbol(id)).font(.system(size: 29)).foregroundStyle(GameTheme.accent).accessibilityHidden(true)
                                    Text(id.name).font(.system(.headline, design: .rounded)).multilineTextAlignment(.leading)
                                    Text(id.description).font(.caption).foregroundStyle(GameTheme.secondary).multilineTextAlignment(.leading)
                                    Text(status(id)).font(.caption.weight(.semibold)).foregroundStyle(GameTheme.accent)
                                }
                                .frame(maxWidth: .infinity, minHeight: 158, alignment: .leading)
                                .padding(16)
                                .background(GameTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(GameTheme.line, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("catalog.\(id.rawValue)")
                            .accessibilityLabel("\(id.name), \(status(id))")
                            .accessibilityHint("Membuka permainan langsung")
                        }
                    }
                    Label("Progres tersimpan saat kamu bermain.", systemImage: "externaldrive")
                        .font(.footnote).foregroundStyle(GameTheme.secondary)
                }.padding(16)
            }
            .background(GameTheme.canvas)
            .navigationTitle("OffPlay")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { store.present(.statistics) } label: { Image(systemName: "chart.bar").frame(minWidth: 48, minHeight: 48) }
                        .accessibilityLabel("Statistik Pemain").accessibilityIdentifier("catalog.statistics")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { store.present(.settings) } label: { Image(systemName: "gearshape").frame(minWidth: 48, minHeight: 48) }
                        .accessibilityLabel("Pengaturan").accessibilityIdentifier("catalog.settings")
                }
            }
            .navigationDestination(for: GameID.self) { GamePlayView(id: $0) }
        }
        .tint(GameTheme.accent)
    }

    private func status(_ id: GameID) -> String {
        guard let session = store.library.session(id) else { return "Siap dimainkan" }
        if let result = session.outcome { return id == .game2048 ? "Sesi selesai" : result.name }
        return session.hasStarted ? "Lanjutkan Sesi · \(GameTheme.time(session.elapsed))" : "Siap dimainkan"
    }
}
