import SwiftUI
import OffPlayCore

struct Game2048View: View {
    @Environment(AppStore.self) private var store
    @FocusState private var keyboardFocus: Bool

    var body: some View {
        if let session = store.library.session(.game2048), case let .game2048(game) = session.state {
            VStack(spacing: 12) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(0..<16, id: \.self) { index in
                            let tile = game.board[index]
                            Text(tile == 0 ? "" : String(tile))
                                .font(.system(.title2, design: .rounded).bold()).minimumScaleFactor(0.4).lineLimit(1)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background(GameMenuTheme.paper.opacity(tile == 0 ? 0.12 : 1))
                                .foregroundStyle(GameMenuTheme.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(tile == 0 ? GameMenuTheme.boardEdge(.game2048).opacity(0.35) : GameMenuTheme.ink.opacity(tile >= 128 ? 0.8 : 0.2), style: StrokeStyle(lineWidth: tile >= 128 ? 2 : 1, dash: tile == 0 ? [3, 3] : []))
                                }
                                .accessibilityLabel("Row \(index / 4 + 1), column \(index % 4 + 1), \(tile == 0 ? String(localized: "empty") : String(tile))")
                        }
                }
                    .padding(8)
                    .modifier(GameplayBoardFrame())
                    .frame(maxWidth: 480)
                    .containerRelativeFrame(.horizontal) { width, _ in
                        min(width - 24, width < 390 ? 300 : 480)
                    }
                    .accessibilityElement(children: .contain).accessibilityIdentifier("slide.board")
                    .highPriorityGesture(DragGesture(minimumDistance: 0).onEnded { gesture in
                        let x = gesture.translation.width, y = gesture.translation.height
                        guard max(abs(x), abs(y)) >= 24 else { return }
                        move(abs(x) > abs(y) ? (x < 0 ? .left : .right) : (y < 0 ? .up : .down))
                    })
                    .focusable().focused($keyboardFocus)
                    .onKeyPress(.leftArrow) { move(.left); return .handled }
                    .onKeyPress(.rightArrow) { move(.right); return .handled }
                    .onKeyPress(.upArrow) { move(.up); return .handled }
                    .onKeyPress(.downArrow) { move(.down); return .handled }
                if game.reached2048 { Text("You reached 2048. Keep playing!").font(.footnote).foregroundStyle(GameMenuTheme.text) }
                HStack(spacing: 8) {
                    ForEach([SlideDirection.left, .up, .down, .right], id: \.rawValue) { direction in
                        Button { move(direction) } label: { Image(systemName: "arrow.\(direction.rawValue)") }
                            .buttonStyle(ActionButtonStyle()).accessibilityLabel(label(direction))
                            .accessibilityIdentifier("slide.\(direction.rawValue)")
                    }
                }
                if session.outcome == nil {
                    Text("Swipe the board, tap the direction buttons, or use the arrow keys.")
                        .font(.caption).foregroundStyle(GameMenuTheme.secondary)
                        .accessibilityIdentifier("slide.instructions")
                }
            }.onAppear { keyboardFocus = true }
        }
    }

    private func move(_ direction: SlideDirection) {
        store.play(.game2048) { state in
            guard case var .game2048(game) = state else { return false }
            let changed = game.slide(direction); state = .game2048(game); return changed
        }
    }
    private func label(_ direction: SlideDirection) -> LocalizedStringKey {
        switch direction { case .left: "Slide left"; case .right: "Slide right"; case .up: "Slide up"; case .down: "Slide down" }
    }
}
