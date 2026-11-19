import SwiftUI
import Combine
import UIKit

@main struct OffPlayApp: App {
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            ThemedRootView()
                .environment(store)
                .preferredColorScheme(store.colorScheme)
                .onChange(of: phase) { _, phase in store.setSceneActive(phase == .active) }
        }
    }
}

private struct ThemedRootView: View {
    @Environment(AppStore.self) private var store
    @State private var systemColorScheme: ColorScheme = .light

    var body: some View {
        AppRootView()
            .environment(\.colorScheme, store.colorScheme ?? systemColorScheme)
            .background(SystemAppearanceReader { systemColorScheme = $0 })
    }
}

private struct SystemAppearanceReader: UIViewRepresentable {
    let onChange: (ColorScheme) -> Void

    func makeUIView(context: Context) -> AppearanceView { AppearanceView(onChange: onChange) }
    func updateUIView(_ uiView: AppearanceView, context: Context) {}

    final class AppearanceView: UIView {
        private let onChange: (ColorScheme) -> Void
        private weak var observedScene: UIWindowScene?
        private var registration: (any UITraitChangeRegistration)?

        init(onChange: @escaping (ColorScheme) -> Void) {
            self.onChange = onChange
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let registration, let observedScene { observedScene.unregisterForTraitChanges(registration) }
            observedScene = window?.windowScene
            guard let scene = observedScene else { return }
            publish(scene)
            registration = scene.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (scene: UIWindowScene, _: UITraitCollection) in
                self?.publish(scene)
            }
        }

        private func publish(_ scene: UIWindowScene) {
            let scheme: ColorScheme = scene.traitCollection.userInterfaceStyle == .dark ? .dark : .light
            DispatchQueue.main.async { [weak self] in self?.onChange(scheme) }
        }
    }
}

struct AppRootView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        @Bindable var state = store
        Group {
            if store.loading {
                ProgressView("Opening OffPlay…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.loadError {
                ContentUnavailableView {
                    Label("Couldn’t open saved data", systemImage: "externaldrive")
                } description: { Text(error) } actions: {
                    Button("Try Again") { store.load() }.buttonStyle(ActionButtonStyle(primary: true))
                }.padding()
            } else {
                GameBoxView()
            }
        }
        .foregroundStyle(GameTheme.ink)
        .background(GameTheme.canvas.ignoresSafeArea())
        .task { if store.loading { store.load() } }
        .onReceive(timer) { _ in store.tick() }
        .onChange(of: store.path) { _, _ in store.navigationChanged() }
        .safeAreaInset(edge: .bottom) {
            if let error = store.saveError {
                VStack(spacing: 8) {
                    Text(error).font(.caption).foregroundStyle(GameTheme.danger)
                    Button("Try Saving Again") { store.save() }.buttonStyle(ActionButtonStyle())
                }.padding().background(GameTheme.surface)
            }
        }
        .sheet(item: $state.modal, onDismiss: store.sheetDismissed) { modal in
            Group {
                switch modal {
                case .statistics: StatisticsView()
                case .settings: SettingsView()
                case .pause: PauseMenuView()
                case .newGame:
                    if let id = store.activeID {
                        NewGameView(id: id, sudoku: store.library.lastSudokuDifficulty, mines: store.library.lastMineDifficulty)
                    }
                case .rules:
                    if let id = store.activeID { RulesView(id: id) }
                }
            }
            .environment(\.colorScheme, colorScheme)
        }
    }
}
