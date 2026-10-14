import UIKit
import UserNotifications

/// Permesso per le notifiche, token del dispositivo e apertura del volo toccato in una notifica.
@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published private(set) var authorization: UNAuthorizationStatus = .notDetermined
    @Published private(set) var deviceToken: String?
    @Published private(set) var registrationError: String?
    /// Volo da aprire dopo il tocco su una notifica.
    @Published var pendingWatchID: String?

    private let tokenKey = "apns.deviceToken"

    init() {
        deviceToken = UserDefaults.standard.string(forKey: tokenKey)
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorization = settings.authorizationStatus
        if authorization == .authorized || authorization == .provisional {
            // Apple consiglia di registrarsi a ogni avvio: il token può cambiare.
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func requestPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            registrationError = error.localizedDescription
        }
        await refreshStatus()
    }

    func didRegister(deviceToken data: Data) {
        let token = data.map { String(format: "%02x", $0) }.joined()
        deviceToken = token
        registrationError = nil
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    func didFailToRegister(_ error: Error) {
        registrationError = error.localizedDescription
    }

    func open(watchID: String) {
        pendingWatchID = watchID
    }
}
