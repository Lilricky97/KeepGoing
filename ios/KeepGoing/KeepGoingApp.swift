import SwiftUI

@main
struct KeepGoingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = MonitorStore.shared
    @StateObject private var notifications = NotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notifications)
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.identifier)) {
            await BackgroundRefresh.run()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: Task { await store.checkDue() }  // riapri l'app: ricontrolla i voli "scaduti"
            case .background: BackgroundRefresh.schedule()
            default: break
            }
        }
    }
}
