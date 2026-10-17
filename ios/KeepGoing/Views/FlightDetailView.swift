import Charts
import SwiftUI

struct FlightDetailView: View {
    let flightID: String

    @EnvironmentObject private var store: MonitorStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmRemove = false

    var body: some View {
        Group {
            if let flight = store.flight(id: flightID) {
                content(flight)
            } else {
                ContentUnavailableView("Volo non trovato", systemImage: "airplane.circle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
            if PriceChart.hasData(flight) {
                Section("Andamento del prezzo") {
                    PriceChart(flight: flight)
                        .frame(height: 230)
                        .padding(.vertical, 8)
                }
            }
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
                    Task { await store.checkDue(force: true) }
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
        .refreshable { await store.checkDue(force: true) }
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

/// L'andamento secondo Google Voli (grigio) e i prezzi dei tuoi controlli (blu).
private struct PriceChart: View {
    let flight: MonitoredFlight

    static func hasData(_ flight: MonitoredFlight) -> Bool {
        (flight.insights?.history.count ?? 0) >= 2 || flight.history.count >= 2
    }

    var body: some View {
        Chart {
            ForEach(flight.insights?.history ?? []) { point in
                LineMark(x: .value("Data", point.at), y: .value("Prezzo", point.price), series: .value("Serie", "Google"))
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(by: .value("Fonte", "Google Voli"))
            }
            ForEach(flight.history) { point in
                LineMark(x: .value("Data", point.at), y: .value("Prezzo", point.price), series: .value("Serie", "Controlli"))
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(by: .value("Fonte", "I tuoi controlli"))
                PointMark(x: .value("Data", point.at), y: .value("Prezzo", point.price))
                    .foregroundStyle(by: .value("Fonte", "I tuoi controlli"))
            }
            if let target = flight.targetPrice {
                RuleMark(y: .value("Obiettivo", target))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.orange)
                    .annotation(position: .top, alignment: .leading) {
                        Text("Obiettivo")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
            }
        }
        .chartForegroundStyleScale(["Google Voli": Color.gray.opacity(0.6), "I tuoi controlli": Color.accentColor])
        .chartYScale(domain: .automatic(includesZero: false))
        .chartLegend(position: .bottom)
    }
}

#Preview {
    NavigationStack {
        FlightDetailView(flightID: MonitoredFlight.samples[0].id)
    }
    .environmentObject(MonitorStore(preview: MonitoredFlight.samples))
}
