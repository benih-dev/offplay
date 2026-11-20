import SwiftUI
import OffPlayCore

struct GamePlayView: View {
    let id: GameID
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        if let session = store.library.session(id) {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        if let result = session.outcome {
                            Text(id == .game2048 ? String(localized: "Session ended") : result.localizedName)
                                .font(.system(.title, design: .rounded).bold())
                                .foregroundStyle(result == .won ? GameTheme.accent : GameTheme.ink)
                                .accessibilityIdentifier("session.result")
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: textSize.isAccessibilitySize ? 260 : 135), spacing: 16)], alignment: .leading, spacing: 12) {
                            if let score = session.state.score { MetricView(label: "Score", value: String(score)).frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("session.score") }
                            MetricView(label: "Active Time", value: GameTheme.time(session.elapsed)).frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("session.time")
                            if case let .klondike(game) = session.state { MetricView(label: "Moves", value: String(game.moves)).frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("session.moves") }
                        }
                        ZStack(alignment: .topLeading) {
                            ForEach(GameFeedback.allCases, id: \.self) { feedback in
                                Text(feedback.localizedMessage).hidden()
                            }
                            if let feedback = store.feedback {
                                Text(feedback.localizedMessage)
                                    .foregroundStyle(GameTheme.danger)
                                    .accessibilityIdentifier("session.feedback")
                            }
                        }
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    GameCatalog.board(id).id(session.id).disabled(session.outcome != nil)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("session.board")
                }
                .padding(.horizontal, 12).padding(.vertical, 12)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button { store.leaveGame() } label: {
                        Image(systemName: "house").frame(width: 48, height: 48)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(GameTheme.accent)
                    .accessibilityLabel("Game Box").accessibilityIdentifier("session.back")
                    if [.klondike, .sudoku, .game2048].contains(id) {
                        Button("Undo") { store.undo(id) }
                            .buttonStyle(ActionButtonStyle()).disabled(!session.state.canUndo || session.outcome != nil)
                            .accessibilityIdentifier("session.undo")
                    } else {
                        Button("Rules") { store.present(.rules) }.buttonStyle(ActionButtonStyle()).accessibilityIdentifier("session.rules")
                    }
                    Button("New Game") { store.requestNewGame(id) }
                        .buttonStyle(ActionButtonStyle(primary: true)).accessibilityIdentifier("session.new")
                }
                .padding(.horizontal, 12).padding(.vertical, 8).background(GameTheme.canvas)
            }
            .background(GameTheme.canvas)
            .onChange(of: store.feedback) { _, message in
                if let message { AccessibilityNotification.Announcement(message.localizedMessage).post() }
            }
            .navigationTitle(id.name).navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Pause") { store.present(.pause) }.frame(minWidth: 48, minHeight: 48).accessibilityIdentifier("session.pause")
                }
            }
            .toolbar(.visible, for: .navigationBar)
        }
    }
}
