import SwiftUI

struct FlightListView: View {
    @EnvironmentObject private var store: PriceStore
    @EnvironmentObject private var notifications: NotificationManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var path: [String] = []
    @State private var showSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if notifications.authorization == .notDetermined {
                    Section { NotificationPrompt() }
                }
                if let error = store.errorMessage {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                }
                let flights = store.flights
                let active = flights.filter(\.isActive)
                let archived = flights.filter { !$0.isActive }
                if !active.isEmpty {
                    Section {
                        ForEach(active) { flight in
                            NavigationLink(value: flight.id) { FlightRow(flight: flight) }
                        }
                    } footer: {
                        if let updated = store.data?.updatedAt {
                            Text("Ultimo controllo \(Format.relative(updated))")
                        }
                    }
                }
                if !archived.isEmpty {
                    Section("Non più monitorati") {
                        ForEach(archived) { flight in
                            NavigationLink(value: flight.id) { FlightRow(flight: flight) }
                        }
                    }
                }
            }
            .overlay {
                if store.flights.isEmpty && !store.isLoading {
                    ContentUnavailableView(
                        "Nessun volo ancora",
                        systemImage: "airplane.departure",
                        description: Text("Aggiungi i voli in config.toml su GitHub: appena il motore fa il primo controllo li vedrai qui.")
                    )
                }
            }
            .navigationTitle("KeepGoing")
            .navigationDestination(for: String.self) { id in
                FlightDetailView(watchID: id)
            }
            .refreshable { await store.refresh() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Impostazioni")
                }
            }
            .sheet(isPresented: $showSettings, onDismiss: {
                Task { await store.refresh() }
            }) {
                SettingsView()
            }
        }
        .task {
            openPendingFlight()  // app aperta da zero toccando una notifica
            await notifications.refreshStatus()
            await store.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await store.refresh() }
            }
        }
        .onChange(of: notifications.pendingWatchID) { _, id in
            guard id != nil else { return }
            openPendingFlight()
            Task { await store.refresh() }
        }
    }

    private func openPendingFlight() {
        guard let id = notifications.pendingWatchID else { return }
        path = [id]
        notifications.pendingWatchID = nil
    }
}

struct FlightRow: View {
    let flight: Flight

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.name)
                    .font(.headline)
                if let info = flight.info {
                    Text(subtitle(info))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let lowest = flight.state.lowest {
                    Text("Minimo: \(Format.price(lowest, currency: flight.currency))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let price = flight.currentPrice {
                    Text(Format.price(price, currency: flight.currency))
                        .font(.title3.bold())
                        .monospacedDigit()
                }
                if let change = flight.lastChange, change != 0 {
                    ChangeBadge(change: change, currency: flight.currency)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func subtitle(_ info: WatchInfo) -> String {
        var text = "\(info.origin) → \(info.destination) · \(Format.period(info.depart))"
        if let ret = info.returnDate {
            text += " – \(Format.period(ret))"
        }
        return text
    }
}

struct ChangeBadge: View {
    let change: Double
    let currency: String

    var body: some View {
        Label(Format.change(change, currency: currency), systemImage: change < 0 ? "arrow.down" : "arrow.up")
            .font(.caption.bold())
            .monospacedDigit()
            .foregroundStyle(change < 0 ? Color.green : Color.red)
    }
}

struct NotificationPrompt: View {
    @EnvironmentObject private var notifications: NotificationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Attiva le notifiche", systemImage: "bell.badge.fill")
                .font(.headline)
            Text("Così KeepGoing ti avvisa appena un prezzo scende, anche con l'app chiusa.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Attiva") {
                Task { await notifications.requestPermission() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FlightListView()
        .environmentObject(PriceStore(preview: .sample))
        .environmentObject(NotificationManager.shared)
}
