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
    @ScaledMetric(relativeTo: .largeTitle) private var logoSize = 56.0

    private var columns: [GridItem] {
        [GridItem(
            .adaptive(minimum: textSize > .large ? 280 : 152),
            spacing: GameMenuTheme.inset,
            alignment: .top
        )]
    }

    var body: some View {
        @Bindable var state = store
        NavigationStack(path: $state.path) {
            ScrollView {
                VStack(spacing: GameMenuTheme.sectionGap) {
                    masthead
                    VStack(spacing: GameMenuTheme.unit * 2) {
                        Text("What shall we play?")
                            .font(.system(.largeTitle, design: .rounded, weight: .black))
                            .accessibilityAddTraits(.isHeader)
                        Text("Six games for your downtime.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(GameMenuTheme.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                    collectionHeading
                    LazyVGrid(columns: columns, alignment: .center, spacing: GameMenuTheme.sectionGap) {
                        ForEach(GameID.allCases) { id in
                            gameTile(id)
                        }
                    }
                    Label("Progress is saved as you play.", systemImage: "externaldrive")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(GameMenuTheme.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, GameMenuTheme.unit * 2)
                }
                .padding(GameMenuTheme.inset)
                .padding(.bottom, GameMenuTheme.sectionGap)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .foregroundStyle(GameMenuTheme.text)
            .background(GameMenuTheme.canvas.ignoresSafeArea())
            .navigationTitle("OffPlay")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GameID.self) { GamePlayView(id: $0) }
        }
        .tint(GameTheme.accent)
    }

    private var masthead: some View {
        HStack(spacing: GameMenuTheme.unit * 2) {
            Button { store.present(.statistics) } label: {
                Image(systemName: "chart.bar")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .frame(width: GameMenuTheme.target, height: GameMenuTheme.target)
            }
            .buttonStyle(GameMenuButtonStyle())
            .accessibilityLabel("Player Statistics")
            .accessibilityIdentifier("catalog.statistics")

            Text("OffPlay")
                .font(.system(size: logoSize, weight: .black, design: .rounded))
                .tracking(-2)
                .foregroundStyle(GameMenuTheme.brand)
                .shadow(color: GameMenuTheme.paper, radius: 0, y: GameMenuTheme.edge)
                .shadow(color: GameMenuTheme.greenDeep, radius: 0, y: GameMenuTheme.unit)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)

            Button { store.present(.settings) } label: {
                Image(systemName: "gearshape")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .frame(width: GameMenuTheme.target, height: GameMenuTheme.target)
            }
            .buttonStyle(GameMenuButtonStyle())
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("catalog.settings")
        }
        .padding(.bottom, GameMenuTheme.unit)
    }

    private var collectionHeading: some View {
        let layout = textSize > .large
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: GameMenuTheme.inset))
            : AnyLayout(HStackLayout(spacing: GameMenuTheme.inset))
        return layout {
            Text("Six games, take your pick!")
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Button {
                if let id = GameID.allCases.randomElement() { store.open(id) }
            } label: {
                Label("Shuffle", systemImage: "shuffle")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .padding(.horizontal, GameMenuTheme.inset)
                    .padding(.vertical, GameMenuTheme.unit * 2)
                    .frame(minHeight: GameMenuTheme.target)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(GameMenuButtonStyle(fill: GameMenuTheme.yellow))
            .accessibilityLabel("Open a random game")
            .accessibilityIdentifier("catalog.random")
        }
    }

    private func gameTile(_ id: GameID) -> some View {
        Button { store.open(id) } label: {
            VStack(spacing: GameMenuTheme.unit * 2) {
                GameMenuPreview(id: id)
                VStack(spacing: GameMenuTheme.unit * 2) {
                    Text(id.name)
                        .font(.system(.title3, design: .rounded, weight: .black))
                        .frame(minHeight: GameMenuTheme.target)
                    Text(id.localizedDescription)
                        .font(.system(.body, design: .rounded))
                    Text(status(id))
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .padding(.top, GameMenuTheme.unit)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, GameMenuTheme.unit)
                .padding(.bottom, GameMenuTheme.unit * 2)
            }
            .padding(GameMenuTheme.unit * 2)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .buttonStyle(GameMenuButtonStyle(fill: GameMenuTheme.face(id), radius: GameMenuTheme.radius))
        .accessibilityIdentifier("catalog.\(id.rawValue)")
        .accessibilityLabel("\(id.name), \(status(id))")
        .accessibilityHint("Opens the game")
    }

    private func status(_ id: GameID) -> String {
        guard let session = store.library.session(id) else { return String(localized: "Ready to play") }
        if let result = session.outcome { return id == .game2048 ? String(localized: "Session ended") : result.localizedName }
        return session.hasStarted ? String(localized: "Resume Game · \(GameTheme.time(session.elapsed))") : String(localized: "Ready to play")
    }
}
