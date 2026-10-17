import SwiftUI

@main
struct KeepGoingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PriceStore()
    @StateObject private var notifications = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(notifications)
        }
    }
}
