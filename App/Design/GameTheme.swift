import SwiftUI
import UIKit
import OffPlayCore

private struct GameplayGameKey: EnvironmentKey {
    static let defaultValue: GameID? = nil
}

extension EnvironmentValues {
    var gameplayGame: GameID? {
        get { self[GameplayGameKey.self] }
        set { self[GameplayGameKey.self] = newValue }
    }
}

enum GameTheme {
    static let canvas = adaptive(0xf4f2ec, 0x1d211f)
    static let surface = adaptive(0xffffff, 0x282e2b)
    static let ink = adaptive(0x23211c, 0xf4f2ec)
    static let secondary = adaptive(0x6b675e, 0xb9c3bd)
    static let accent = adaptive(0x3a6e5d, 0x91c8ae)
    static let line = adaptive(0x7c7b73, 0x889b8f)
    static let danger = adaptive(0xa8402f, 0xf4a28d)
    static let accentFill = adaptive(0xe4eee8, 0x34483e)
    static let pressedAccent = adaptive(0x2b5548, 0xb1dbc4)
    static let pressedDanger = adaptive(0x883426, 0xffc0b0)

    // SwiftUI also resolves dynamic colors on its background renderer.
    nonisolated private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }

    static func time(_ seconds: TimeInterval) -> String {
        let value = max(0, Int(seconds))
        return value >= 3600 ? String(format: "%d:%02d:%02d", value / 3600, value / 60 % 60, value % 60) : String(format: "%d:%02d", value / 60, value % 60)
    }
}

struct ActionButtonStyle: ButtonStyle {
    var primary = false
    var destructive = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.gameplayGame) private var game
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        if let game {
            let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
            let pressed = configuration.isPressed
            configuration.label
                .font(.system(.headline, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 12)
                .foregroundStyle(primary ? (destructive ? GameMenuTheme.paper : GameMenuTheme.ink) : GameMenuTheme.text)
                .background {
                    shape.fill(primary ? (destructive ? GameMenuTheme.redInk : GameMenuTheme.face(game)) : GameMenuTheme.utilitySurface)
                        .shadow(color: GameMenuTheme.depth, radius: 0, y: pressed && !reduceMotion ? 2 : 6)
                        .overlay(shape.strokeBorder(primary ? GameMenuTheme.ink : GameMenuTheme.utilityOutline, lineWidth: 2))
                }
                .offset(y: pressed && !reduceMotion ? 4 : 0)
                .opacity(enabled ? (pressed && reduceMotion ? 0.8 : 1) : 0.5)
                .animation(reduceMotion ? nil : .easeOut(duration: GameMenuTheme.pressDuration), value: pressed)
                .contentShape(shape)
        } else {
            configuration.label
                .font(.system(.headline, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 12)
                .background(background(pressed: configuration.isPressed))
                .foregroundStyle(primary ? GameTheme.canvas : GameTheme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(primary ? .clear : GameTheme.line, lineWidth: 1))
                .opacity(enabled ? 1 : 0.4)
        }
    }

    private func background(pressed: Bool) -> Color {
        if primary {
            return destructive ? (pressed ? GameTheme.pressedDanger : GameTheme.danger) : (pressed ? GameTheme.pressedAccent : GameTheme.accent)
        }
        return pressed ? GameTheme.accentFill : GameTheme.surface
    }
}

struct BoardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.overlay {
            if configuration.isPressed { Rectangle().stroke(GameTheme.accent, lineWidth: 2) }
        }
    }
}

struct MetricView: View {
    @Environment(\.gameplayGame) private var game
    let label: LocalizedStringKey
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(game == nil ? GameTheme.secondary : GameMenuTheme.ink)
            Text(value).font(.system(.headline, design: .rounded)).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct GameplayBoardFrame: ViewModifier {
    @Environment(\.gameplayGame) private var game

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: game == nil ? 16 : 20, style: game == nil ? .circular : .continuous)
        content
            .background(game.map { GameMenuTheme.well($0) } ?? GameTheme.surface)
            .clipShape(shape)
            .overlay(shape.strokeBorder(game == nil ? GameTheme.line : GameMenuTheme.ink, lineWidth: game == nil ? 1 : 2))
    }
}

struct FittedBoard<Content: View>: View {
    let columns: Int
    let preferredCellSize: CGFloat
    var onOverflowChange: (Bool) -> Void = { _ in }
    @ViewBuilder let content: (CGFloat) -> Content
    @State private var availableWidth: CGFloat = 0

    private var cellSize: CGFloat {
        floor(min(preferredCellSize, max(36, (availableWidth - 16) / CGFloat(columns))))
    }

    private var isOverflowing: Bool {
        cellSize * CGFloat(columns) + 16 > availableWidth
    }

    var body: some View {
        ScrollView(.horizontal) {
            content(cellSize)
                .frame(minWidth: max(0, availableWidth - 16))
                .padding(8)
        }
            .scrollDisabled(!isOverflowing)
            .accessibilityIdentifier("board.viewport")
            .frame(height: cellSize * CGFloat(columns) + 16)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
            .onChange(of: isOverflowing, initial: true) { onOverflowChange(isOverflowing) }
            .modifier(GameplayBoardFrame())
    }
}

struct BoardViewport<Content: View>: View {
    let height: CGFloat
    @ViewBuilder let content: () -> Content
    var body: some View {
        ScrollView(.horizontal) {
            content().padding(8)
        }
        .frame(maxWidth: .infinity).frame(height: height)
        .modifier(GameplayBoardFrame())
    }
}
