import Foundation
import UserNotifications

/// Permesso per le notifiche, invio delle notifiche e apertura del volo toccato in una notifica.
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var authorization: UNAuthorizationStatus = .notDetermined
    /// Volo da aprire dopo il tocco su una notifica.
    @Published var pendingWatchID: String?

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorization = settings.authorizationStatus
    }

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        await refreshStatus()
    }

    /// Notifica generata dall'app stessa: niente server e niente chiavi Apple.
    func post(_ event: PriceEvent) async {
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.body
        content.sound = .default
        content.threadIdentifier = event.flight.id  // raggruppa le notifiche dello stesso volo
        content.userInfo = ["watch_id": event.flight.id]
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }

    func open(watchID: String) {
        pendingWatchID = watchID
    }
}
