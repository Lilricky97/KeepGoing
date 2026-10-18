import SwiftUI

/// Lo stesso volo cercato su Google Voli da più paesi: dove conviene collegarsi con la VPN.
struct MarketCompareView: View {
    let query: SearchQuery

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = Markets.defaultSelection
    @State private var results: [MarketPrice]?
    @State private var running = false
    @State private var isSample = false

    var body: some View {
        NavigationStack {
            List {
                if let results {
                    resultSections(results)
                } else {
                    Section {
                        Text("Google Voli mostra prezzi diversi a seconda del paese da cui cerchi. Scegli i paesi da confrontare: ognuno usa una ricerca di Google Voli.")
                            .font(.subheadline)
                    }
                    Section("Paesi") {
                        ForEach(Markets.all) { market in
                            Toggle(isOn: binding(for: market)) {
                                Text("\(market.flag)  \(market.name)")
                            }
                        }
                    }
                }
            }
            .overlay {
                if running {
                    ProgressView("Cerco da \(selected.count) paesi…")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("Confronta paesi")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if results == nil {
                        Button("Confronta (\(selected.count))") {
                            Task { await run() }
                        }
                        .bold()
                        .disabled(selected.isEmpty || running)
                    } else {
                        Button("Altri paesi") { results = nil }
                    }
                }
            }
        }
        .sheetSize()
    }

    @ViewBuilder
    private func resultSections(_ results: [MarketPrice]) -> some View {
        if isSample {
            Section {
                Label("Prezzi di esempio: con la chiave di Google Voli vedi quelli veri.", systemImage: "info.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
        if let best = MarketComparison.best(results) {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(best.market.market.flag) \(best.market.market.name): \(Format.price(best.market.price ?? 0))")
                        .font(.title3.bold())
                    if let saving = best.saving, saving >= 1 {
                        Text("\(Format.price(saving.rounded())) in meno che cercando dall'Italia. Collega la VPN a \(best.market.market.name), poi apri Google Voli e cerca lo stesso volo.")
                            .font(.subheadline)
                    } else if best.market.market.code == Markets.home.code {
                        Text("L'Italia è già il paese più conveniente per questo volo.")
                            .font(.subheadline)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Il paese più conveniente")
            }
        }
        Section("Prezzo più basso per paese") {
            let home = results.first { $0.market.code == Markets.home.code }?.price
            ForEach(results) { result in
                MarketRow(result: result, homePrice: home)
            }
        }
        Section {
            Text("Google converte i prezzi in euro: al pagamento la banca può applicare il cambio e una commissione. Alcune compagnie chiedono una carta o un indirizzo del paese, e i termini di certi siti vietano l'uso della VPN. Controlla sempre il prezzo finale prima di pagare.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func binding(for market: Market) -> Binding<Bool> {
        Binding(
            get: { selected.contains(market.code) },
            set: { isOn in
                if isOn { selected.insert(market.code) } else { selected.remove(market.code) }
            }
        )
    }

    private func run() async {
        running = true
        defer { running = false }
        let client = GoogleFlightsClient.current()
        isSample = client.isDemo
        results = await client.compare(query, markets: Markets.all.filter { selected.contains($0.code) })
    }
}

private struct MarketRow: View {
    let result: MarketPrice
    let homePrice: Double?

    var body: some View {
        HStack(spacing: 12) {
            Text(result.market.flag)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(result.market.name)
                if let error = result.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if let airline = result.cheapest?.airline {
                    Text(airline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let price = result.price {
                    Text(Format.price(price))
                        .font(.headline)
                        .monospacedDigit()
                    if let homePrice, result.market.code != Markets.home.code, abs(price - homePrice) >= 1 {
                        Text(Format.change(price - homePrice))
                            .font(.caption.bold())
                            .foregroundStyle(price < homePrice ? Color.green : Color.red)
                    }
                } else if result.error == nil {
                    Text("—")
                }
            }
            if let url = result.googleURL {
                Link(destination: url) {
                    Image(systemName: "safari")
                }
                .accessibilityLabel("Apri su Google Voli")
            }
        }
    }
}
