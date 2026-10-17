import SwiftUI

/// Scheda "I miei voli": i voli monitorati con prezzo attuale e variazione.
struct FlightListView: View {
    var onSearch: () -> Void = {}

    @EnvironmentObject private var store: PriceStore
    @EnvironmentObject private var notifications: NotificationManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var path: [String] = []
    @State private var actionError: String?

    init(onSearch: @escaping () -> Void = {}) {
        self.onSearch = onSearch
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if notifications.authorization == .notDetermined {
                    Section { NotificationPrompt() }
                }
                if store.isShowingSample {
                    Section {
                        Label(
                            "Questi sono voli di esempio: cerca un volo nella scheda Cerca e tocca \"Monitora\" per aggiungere i tuoi.",
                            systemImage: "info.circle.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
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
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if flight.isFromApp {
                                        Button(role: .destructive) {
                                            Task { await remove(flight) }
                                        } label: {
                                            Label("Non monitorare", systemImage: "bell.slash")
                                        }
                                    }
                                }
                        }
                    } footer: {
                        if let updated = store.updatedAt {
                            Text("Ultimo controllo \(Format.relative(updated)). Scorri un volo verso sinistra per smettere di monitorarlo.")
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
            .navigationDestination(for: String.self) { id in
                FlightDetailView(watchID: id)
            }
            .refreshable { await store.refresh() }
            .alert(
                "Operazione non riuscita",
                isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(actionError ?? "")
            }
        }
        .task {
            openPendingFlight()  // app aperta toccando una notifica
            await store.refreshIfStale()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await store.refreshIfStale() }
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

    private func remove(_ flight: Flight) async {
        do {
            try await store.remove(id: flight.id)
        } catch {
            actionError = PriceStore.message(for: error)
        }
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
                if flight.isPending {
                    Label("In attesa del primo controllo", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let lowest = flight.lowest {
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
                } else if flight.isPending {
                    ProgressView()
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
            text += ret == info.depart ? " · andata e ritorno" : " – \(Format.period(ret))"
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
