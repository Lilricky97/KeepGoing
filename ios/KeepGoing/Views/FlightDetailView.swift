import SwiftUI

struct FlightDetailView: View {
    let flightID: String

    @EnvironmentObject private var store: MonitorStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmRemove = false
    @State private var showCompare = false

    var body: some View {
        Group {
            if let flight = store.flight(id: flightID) {
                content(flight)
            } else {
                ContentUnavailableView("Volo non trovato", systemImage: "airplane.circle")
            }
        }
        .inlineNavigationTitle()
        .task {
            // Grafico aggiornato appena apri il volo (se l'ultimo controllo ha più di un'ora).
            await store.refresh(id: flightID, ifOlderThan: 3600)
        }
    }

    private func content(_ flight: MonitoredFlight) -> some View {
        List {
            Section {
                PriceHeader(flight: flight, isChecking: store.checking.contains(flight.id))
            }
            if let insights = flight.insights, insights.levelText != nil {
                Section {
                    InsightsRow(insights: insights)
                }
            }
            if !flight.isExpired() || flight.bestMarket != nil {
                BestMarketSection(best: flight.bestMarket) { showCompare = true }
            }
            if HistoryChart.hasData(google: flight.insights?.history ?? [], checks: flight.history) {
                Section("Andamento del prezzo") {
                    HistoryChart(google: flight.insights?.history ?? [], checks: flight.history, target: flight.targetPrice)
                        .padding(.vertical, 8)
                }
            }
            WhenCheaperSection(flight: flight)
            if let offer = flight.best {
                Section("Volo più economico") {
                    OfferRow(offer: offer, link: flight.googleURL)
                    if let back = flight.returnDate {
                        LabeledContent("Ritorno", value: Format.period(back))
                    }
                    if let url = flight.googleURL ?? GoogleFlightsClient.googleFlightsURL(for: flight.query) {
                        Link(destination: url) {
                            Label("Apri su Google Voli", systemImage: "safari")
                        }
                    }
                }
            }
            Section("Cosa stai monitorando") {
                LabeledContent("Tratta", value: "\(flight.origin.name) → \(flight.destination.name)")
                LabeledContent("Andata", value: Format.period(flight.depart))
                LabeledContent("Ritorno", value: flight.returnDate.map { Format.period($0) } ?? "Solo andata")
                if flight.directOnly {
                    LabeledContent("Voli", value: "Solo diretti")
                }
                if let target = flight.targetPrice {
                    LabeledContent("Obiettivo", value: Format.price(target, currency: flight.currency))
                }
                if let lastCheck = flight.lastCheck {
                    LabeledContent("Ultimo controllo", value: Format.relative(lastCheck))
                }
                if let error = flight.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            Section {
                Button {
                    Task { await store.refresh(id: flight.id, ifOlderThan: 0) }
                } label: {
                    Label("Controlla adesso", systemImage: "arrow.clockwise")
                }
                .disabled(store.checking.contains(flight.id) || flight.isExpired())
                Button(role: .destructive) {
                    confirmRemove = true
                } label: {
                    Label("Smetti di monitorare", systemImage: "bell.slash")
                }
            }
        }
        .navigationTitle(flight.name)
        .refreshable { await store.refresh(id: flight.id, ifOlderThan: 0) }
        .sheet(isPresented: $showCompare) {
            MarketCompareView(query: flight.query) { best in
                store.setBestMarket(best, for: flight.id)
            }
        }
        .confirmationDialog("Smettere di monitorare \(flight.name)?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Smetti di monitorare", role: .destructive) {
                store.remove(id: flight.id)
                dismiss()
            }
        } message: {
            Text("Non riceverai più notifiche per questo volo.")
        }
    }
}

private struct PriceHeader: View {
    let flight: MonitoredFlight
    var isChecking: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(flight.route) · \(Format.period(flight.depart))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline) {
                Text(flight.currentPrice.map { Format.price($0, currency: flight.currency) } ?? "—")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                if isChecking {
                    ProgressView()
                }
            }
            HStack(spacing: 12) {
                if let change = flight.lastChange, change != 0 {
                    ChangeBadge(change: change, currency: flight.currency)
                }
                if let lowest = flight.lowest {
                    Label("Minimo \(Format.price(lowest, currency: flight.currency))", systemImage: "trophy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let target = flight.targetPrice, let price = flight.currentPrice, price <= target {
                Label("Sotto il tuo obiettivo!", systemImage: "target")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        FlightDetailView(flightID: MonitoredFlight.samples[0].id)
    }
    .environmentObject(MonitorStore(preview: MonitoredFlight.samples))
}
