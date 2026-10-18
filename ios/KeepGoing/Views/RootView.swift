import SwiftUI

enum AppTab: Hashable {
    case search, flights, settings
}

struct RootView: View {
    @EnvironmentObject private var notifications: NotificationManager
    @State private var tab: AppTab
    private let initialQuery: SearchQuery?

    init() {
        var tab = AppTab.search
        var query: SearchQuery?
        #if DEBUG
        // Solo lettura: i dati di esempio li prepara DebugScreen.prepare() una volta sola all'avvio.
        // (RootView viene ricreata a ogni cambiamento: qui non si deve modificare niente.)
        switch DebugScreen.current {
        case "results", "compare", "key": query = .preview
        case "flights", "detail": tab = .flights
        case "settings": tab = .settings
        default: break
        }
        #endif
        _tab = State(initialValue: tab)
        initialQuery = query
    }

    var body: some View {
        TabView(selection: $tab) {
            SearchView(initialQuery: initialQuery) { tab = .flights }
                .tabItem { Label("Cerca", systemImage: "magnifyingglass") }
                .tag(AppTab.search)
            FlightListView { tab = .search }
                .tabItem { Label("I miei voli", systemImage: "airplane") }
                .tag(AppTab.flights)
            SettingsView()
                .tabItem { Label("Impostazioni", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .task {
            if notifications.pendingWatchID != nil { tab = .flights }
            await notifications.refreshStatus()
        }
        .onChange(of: notifications.pendingWatchID) { _, id in
            if id != nil { tab = .flights }  // tocco su una notifica: apre il volo
        }
    }
}

#Preview {
    RootView()
        .environmentObject(MonitorStore(preview: MonitoredFlight.samples))
        .environmentObject(NotificationManager.shared)
}

#if DEBUG
/// Solo per gli screenshot automatici (.github/workflows/ios.yml):
/// `-kgScreen search|results|compare|key|flights|detail|settings` apre una schermata precisa.
enum DebugScreen {
    static let current = UserDefaults.standard.string(forKey: "kgScreen")

    /// Da chiamare una volta sola, all'avvio dell'app.
    @MainActor
    static func prepare() {
        if ["flights", "detail", "settings"].contains(current) {
            MonitorStore.shared.loadSamplesForScreenshots()
        }
        if current == "detail" {
            NotificationManager.shared.open(watchID: MonitoredFlight.samples[0].id)
        }
    }
}
#endif
