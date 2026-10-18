import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Piccole differenze tra iPhone e Mac, in un posto solo.
extension View {
    /// Titolo piccolo in alto (iPhone); sul Mac non esiste.
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Campo di ricerca sempre visibile sotto il titolo (iPhone) o nella barra della finestra (Mac).
    @ViewBuilder
    func alwaysVisibleSearch(text: Binding<String>, prompt: String) -> some View {
        #if os(iOS)
        searchable(text: text, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(prompt))
        #else
        searchable(text: text, prompt: Text(prompt))
        #endif
    }

    /// Le finestre "sheet" sul Mac non hanno una dimensione propria.
    @ViewBuilder
    func sheetSize() -> some View {
        #if os(macOS)
        frame(minWidth: 460, minHeight: 560)
        #else
        self
        #endif
    }

    /// Niente maiuscola automatica nei campi (codici e chiavi). Sul Mac non serve.
    @ViewBuilder
    func noAutoCapitalization() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
}

enum Platform {
    static var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }

    /// Le impostazioni delle notifiche del sistema.
    static var notificationSettingsURL: URL? {
        #if os(iOS)
        return URL(string: "app-settings:")
        #else
        return URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
        #endif
    }
}

#if os(macOS)
/// Il menu dell'icona nella barra dei menu del Mac.
struct MenuBarView: View {
    @EnvironmentObject private var store: MonitorStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if store.flights.isEmpty {
            Text("Nessun volo monitorato")
        }
        ForEach(store.flights) { flight in
            Button {
                NotificationManager.shared.open(watchID: flight.id)
                showWindow()
            } label: {
                Text("\(flight.name): \(flight.currentPrice.map { Format.price($0, currency: flight.currency) } ?? "—")")
            }
        }
        Divider()
        Button("Controlla adesso") {
            Task { await store.checkDue(force: true) }
        }
        .disabled(store.flights.isEmpty)
        Button("Apri KeepGoing") { showWindow() }
        Divider()
        Button("Esci da KeepGoing") { NSApplication.shared.terminate(nil) }
    }

    private func showWindow() {
        openWindow(id: "main")
        NSApplication.shared.activate()
    }
}
#endif
