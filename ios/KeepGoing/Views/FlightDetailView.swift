import Charts
import SwiftUI

struct FlightDetailView: View {
    let watchID: String
    @EnvironmentObject private var store: PriceStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmRemove = false
    @State private var removing = false
    @State private var removeError: String?

    var body: some View {
        Group {
            if let flight = store.flight(id: watchID) {
                content(flight)
            } else {
                ContentUnavailableView("Volo non trovato", systemImage: "airplane.circle")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func content(_ flight: Flight) -> some View {
        List {
            Section {
                PriceHeader(flight: flight)
            }
            if flight.isPending {
                Section {
                    Label(
                        "Il motore su GitHub lo controlla entro pochi minuti: poi qui vedrai il prezzo e riceverai la prima notifica.",
                        systemImage: "clock"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            if flight.history.count >= 2 {
                Section("Andamento del prezzo") {
                    PriceChart(flight: flight)
                        .frame(height: 220)
                        .padding(.vertical, 8)
                }
            }
            if let offer = flight.last {
                Section("Offerta migliore") {
                    if let date = Format.tripDate(offer.departureAt) {
                        LabeledContent("Andata", value: date)
                    }
                    if let date = Format.tripDate(offer.returnAt) {
                        LabeledContent("Ritorno", value: date)
                    }
                    if let stops = Format.stops(offer.transfers) {
                        LabeledContent("Scali", value: stops)
                    }
                    if let number = offer.flightNumber ?? offer.airline {
                        LabeledContent("Volo", value: number)
                    }
                    if let provider = offer.provider {
                        LabeledContent("Fonte", value: provider)
                    }
                    if let checked = offer.checkedAt {
                        LabeledContent("Controllato", value: Format.relative(checked))
                    }
                    if let link = offer.link, let url = URL(string: link) {
                        Link(destination: url) {
                            Label("Apri l'offerta", systemImage: "safari")
                        }
                    }
                }
            }
            if let info = flight.info {
                Section("Cosa stai monitorando") {
                    LabeledContent("Tratta", value: "\(info.origin) → \(info.destination)")
                    LabeledContent("Partenza", value: Format.period(info.depart))
                    if let ret = info.returnDate {
                        LabeledContent("Ritorno", value: Format.period(ret))
                    } else {
                        LabeledContent("Tipo", value: "Solo andata")
                    }
                    if info.directOnly == true {
                        LabeledContent("Voli", value: "Solo diretti")
                    }
                    if let target = info.targetPrice {
                        LabeledContent("Obiettivo", value: Format.price(target, currency: flight.currency))
                    }
                }
            }
            if flight.isFromApp && flight.isActive {
                Section {
                    Button(role: .destructive) {
                        confirmRemove = true
                    } label: {
                        if removing {
                            ProgressView()
                        } else {
                            Label("Smetti di monitorare", systemImage: "bell.slash")
                        }
                    }
                    .disabled(removing)
                } footer: {
                    if let removeError {
                        Text(removeError).foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle(flight.name)
        .refreshable { await store.refresh() }
        .confirmationDialog("Smettere di monitorare \(flight.name)?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Smetti di monitorare", role: .destructive) {
                Task { await remove(flight) }
            }
        } message: {
            Text("Non riceverai più notifiche per questo volo.")
        }
    }

    private func remove(_ flight: Flight) async {
        removing = true
        defer { removing = false }
        do {
            try await store.remove(id: flight.id)
            dismiss()
        } catch {
            removeError = PriceStore.message(for: error)
        }
    }
}

private struct PriceHeader: View {
    let flight: Flight

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(flight.route)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let price = flight.currentPrice {
                Text(Format.price(price, currency: flight.currency))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
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
            if let target = flight.info?.targetPrice, let price = flight.currentPrice, price <= target {
                Label("Sotto il tuo obiettivo!", systemImage: "target")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct PriceChart: View {
    let flight: Flight

    var body: some View {
        let points = flight.history
        let lowest = points.min { $0.price < $1.price }
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("Data", point.at), y: .value("Prezzo", point.price))
                    .interpolationMethod(.stepEnd)
                AreaMark(x: .value("Data", point.at), y: .value("Prezzo", point.price))
                    .interpolationMethod(.stepEnd)
                    .foregroundStyle(.linearGradient(
                        colors: [Color.accentColor.opacity(0.25), .clear],
                        startPoint: .top, endPoint: .bottom
                    ))
            }
            if let lowest {
                PointMark(x: .value("Data", lowest.at), y: .value("Prezzo", lowest.price))
                    .foregroundStyle(.green)
                    .annotation(position: .bottom) {
                        Text(Format.price(lowest.price, currency: flight.currency))
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
            }
            if let target = flight.info?.targetPrice {
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
        .chartYScale(domain: .automatic(includesZero: false))
    }
}

#Preview {
    NavigationStack {
        FlightDetailView(watchID: "mil-bcn-2026-12-2026-12")
    }
    .environmentObject(PriceStore(preview: .sample))
}
