import UserNotifications

/// Mostra le notifiche anche ad app aperta e, quando ne tocchi una, apre il volo (iPhone e Mac).
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let watchID = response.notification.request.content.userInfo["watch_id"] as? String
        Task { @MainActor in
            if let watchID {
                NotificationManager.shared.open(watchID: watchID)
            }
        }
        completionHandler()
    }
}
