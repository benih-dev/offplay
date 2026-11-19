import SwiftUI
import UIKit

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

    func makeBody(configuration: Configuration) -> some View {
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
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(GameTheme.secondary)
            Text(value).font(.system(.headline, design: .rounded)).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
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
        .background(GameTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(GameTheme.line, lineWidth: 1))
    }
}
