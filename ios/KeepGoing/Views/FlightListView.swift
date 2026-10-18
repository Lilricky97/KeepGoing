import SwiftUI

/// Scheda "I miei voli": i voli monitorati con prezzo attuale e variazione.
struct FlightListView: View {
    var onSearch: () -> Void

    @EnvironmentObject private var store: MonitorStore
    @EnvironmentObject private var notifications: NotificationManager
    @State private var path: [String] = []

    init(onSearch: @escaping () -> Void = {}) {
        self.onSearch = onSearch
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if notifications.authorization == .notDetermined && !store.flights.isEmpty {
                    Section { NotificationPrompt() }
                }
                if notifications.authorization == .denied {
                    Section {
                        Label("Le notifiche sono disattivate: riattivale nelle Impostazioni di iOS per ricevere gli avvisi.", systemImage: "bell.slash.fill")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }
                if let error = store.lastError {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                }
                if !store.flights.isEmpty {
                    Section {
                        ForEach(store.flights) { flight in
                            NavigationLink(value: flight.id) {
                                FlightRow(flight: flight, isChecking: store.checking.contains(flight.id))
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.remove(id: flight.id)
                                } label: {
                                    Label("Non monitorare", systemImage: "bell.slash")
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    store.remove(id: flight.id)
                                } label: {
                                    Label("Non monitorare", systemImage: "bell.slash")
                                }
                            }
                        }
                    } footer: {
                        if Platform.isMac {
                            Text("Ricontrollo i prezzi circa ogni \(store.checkIntervalHours) ore finché KeepGoing è aperta (basta l'icona ✈︎ nella barra dei menu). Tasto destro su un volo per toglierlo.")
                        } else {
                            Text("Ricontrollo i prezzi circa ogni \(store.checkIntervalHours) ore, anche ad app chiusa (iOS decide il momento esatto). Trascina in giù per controllare subito; scorri un volo a sinistra per toglierlo.")
                        }
                    }
                }
            }
            .overlay {
                if store.flights.isEmpty {
                    ContentUnavailableView {
                        Label("Nessun volo monitorato", systemImage: "airplane.departure")
                    } description: {
                        Text("Cerca un volo e tocca \"Monitora\": ti avviso quando il prezzo scende.")
                    } actions: {
                        Button("Cerca un volo", action: onSearch)
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("I miei voli")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if Platform.isMac {
                        Button {
                            Task { await store.checkDue(force: true) }
                        } label: {
                            Label("Controlla adesso", systemImage: "arrow.clockwise")
                        }
                        .disabled(store.flights.isEmpty || !store.checking.isEmpty)
                    }
                }
            }
            .navigationDestination(for: String.self) { id in
                FlightDetailView(flightID: id)
            }
            .refreshable { await store.checkDue(force: true) }
        }
        .task { openPendingFlight() }  // app aperta toccando una notifica
        .onChange(of: notifications.pendingWatchID) { _, id in
            if id != nil { openPendingFlight() }
        }
    }

    private func openPendingFlight() {
        guard let id = notifications.pendingWatchID else { return }
        path = [id]
        notifications.pendingWatchID = nil
    }
}

struct FlightRow: View {
    let flight: MonitoredFlight
    var isChecking = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.name)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if flight.isExpired() {
                    Label("Partito: non lo controllo più", systemImage: "airplane.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let level = flight.insights?.levelText {
                    Text(level)
                        .font(.caption.bold())
                        .foregroundStyle(flight.insights?.level == "low" ? Color.green : flight.insights?.level == "high" ? Color.red : Color.orange)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if isChecking {
                    ProgressView()
                } else if let price = flight.currentPrice {
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

    private var subtitle: String {
        var text = "\(flight.route) · \(Format.period(flight.depart))"
        if let back = flight.returnDate {
            text += " – \(Format.period(back))"
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
        .environmentObject(MonitorStore(preview: MonitoredFlight.samples))
        .environmentObject(NotificationManager.shared)
}
