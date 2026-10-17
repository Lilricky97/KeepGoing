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
        // Solo per gli screenshot automatici (.github/workflows/ios.yml): -kgScreen results|flights|detail|settings
        let screen = UserDefaults.standard.string(forKey: "kgScreen")
        if ["flights", "detail", "settings"].contains(screen) {
            MonitorStore.shared.loadSamplesForScreenshots()
        }
        switch screen {
        case "results": query = .preview
        case "flights": tab = .flights
        case "detail":
            tab = .flights
            NotificationManager.shared.open(watchID: MonitoredFlight.samples[0].id)
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
