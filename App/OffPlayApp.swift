import SwiftUI
import Combine

@main struct OffPlayApp: App {
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            ThemedRootView()
                .environment(store)
                .onChange(of: phase) { _, phase in store.setSceneActive(phase == .active) }
        }
    }
}

private struct ThemedRootView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        AppRootView()
            .environment(\.colorScheme, store.colorScheme ?? systemColorScheme)
    }
}

struct AppRootView: View {
    @Environment(AppStore.self) private var store
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        @Bindable var state = store
        Group {
            if store.loading {
                ProgressView("Membuka OffPlay…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.loadError {
                ContentUnavailableView {
                    Label("Simpanan belum dapat dibuka", systemImage: "externaldrive")
                } description: { Text(error) } actions: {
                    Button("Coba Lagi") { store.load() }.buttonStyle(ActionButtonStyle(primary: true))
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
                    Button("Coba Simpan Lagi") { store.save() }.buttonStyle(ActionButtonStyle())
                }.padding().background(GameTheme.surface)
            }
        }
        .sheet(item: $state.modal, onDismiss: store.sheetDismissed) { modal in
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
    }
}
