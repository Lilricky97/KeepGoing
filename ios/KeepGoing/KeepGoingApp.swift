import SwiftUI
import UserNotifications

@main
struct KeepGoingApp: App {
    @StateObject private var store = MonitorStore.shared
    @StateObject private var notifications = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        #if os(macOS)
        MonitorStore.shared.startAutoChecks()  // sul Mac l'app resta aperta e controlla da sola
        #endif
    }

    var body: some Scene {
        #if os(macOS)
        Window("KeepGoing", id: "main") {
            content
                .frame(minWidth: 480, minHeight: 640)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.checkDue() } }
        }

        // Icona nella barra dei menu: prezzi sempre a portata e controlli attivi anche a finestra chiusa.
        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
        } label: {
            Label("KeepGoing", systemImage: "airplane")
        }
        #else
        WindowGroup {
            content
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
            await BackgroundRefresh.run()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: Task { await store.checkDue() }  // riapri l'app: ricontrolla i voli da aggiornare
            case .background: BackgroundRefresh.schedule()
            default: break
            }
        }
        #endif
    }

    private var content: some View {
        RootView()
            .environmentObject(store)
            .environmentObject(notifications)
    }
}
