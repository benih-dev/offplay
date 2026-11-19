import SwiftUI
import OffPlayCore

struct Game2048View: View {
    @Environment(AppStore.self) private var store
    @FocusState private var keyboardFocus: Bool

    var body: some View {
        if case let .game2048(game)? = store.library.session(.game2048)?.state {
            VStack(spacing: 12) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(0..<16, id: \.self) { index in
                            let tile = game.board[index]
                            Text(tile == 0 ? "" : String(tile))
                                .font(.system(.title2, design: .rounded).bold()).minimumScaleFactor(0.4).lineLimit(1)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .background(tile >= 8 ? GameTheme.accent : GameTheme.accentFill)
                                .foregroundStyle(tile >= 8 ? GameTheme.canvas : GameTheme.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .accessibilityLabel("Baris \(index / 4 + 1), kolom \(index % 4 + 1), \(tile == 0 ? "kosong" : String(tile))")
                        }
                }
                    .frame(maxWidth: 480)
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
                if game.reached2048 { Text("2048 tercapai. Kamu bisa terus bermain.").font(.footnote).foregroundStyle(GameTheme.accent) }
                HStack(spacing: 8) {
                    ForEach([SlideDirection.left, .up, .down, .right], id: \.rawValue) { direction in
                        Button { move(direction) } label: { Image(systemName: "arrow.\(direction.rawValue)") }
                            .buttonStyle(ActionButtonStyle()).accessibilityLabel("Geser \(label(direction))")
                            .accessibilityIdentifier("slide.\(direction.rawValue)")
                    }
                }
                Text("Geser papan, tombol arah, atau tombol panah keyboard.").font(.caption).foregroundStyle(GameTheme.secondary)
            }.onAppear { keyboardFocus = true }
        }
    }

    private func move(_ direction: SlideDirection) {
        store.play(.game2048) { state in
            guard case var .game2048(game) = state else { return false }
            let changed = game.slide(direction); state = .game2048(game); return changed
        }
    }
    private func label(_ direction: SlideDirection) -> String {
        switch direction { case .left: "kiri"; case .right: "kanan"; case .up: "atas"; case .down: "bawah" }
    }
}
