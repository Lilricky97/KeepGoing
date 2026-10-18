import SwiftUI

/// Lo stesso volo cercato su Google Voli da più paesi: parte subito e dice da dove conviene
/// collegarsi con la VPN. La scelta dei paesi è facoltativa (per usare meno ricerche).
struct MarketCompareView: View {
    let query: SearchQuery
    var onResult: (BestMarket?) -> Void = { _ in }

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = Markets.selection()
    @State private var results: [MarketPrice]?
    @State private var running = false
    @State private var isSample = false
    @State private var showChoice = false

    var body: some View {
        NavigationStack {
            List {
                if let results {
                    resultSections(results)
                }
                choiceSection
                Section {
                    Text("Google converte i prezzi in euro: al pagamento la banca può applicare il cambio e una commissione. Alcune compagnie chiedono una carta o un indirizzo del paese, e i termini di certi siti vietano l'uso della VPN. Controlla sempre il prezzo finale prima di pagare.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .overlay {
                if running {
                    ProgressView("Cerco lo stesso volo da \(selected.count) paesi…")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("Dove conviene")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
            .task {
                if results == nil { await run() }  // parte subito: niente da scegliere prima
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
        if let best = MarketComparison.summary(results) {
            Section {
                BestMarketCard(best: best)
            } header: {
                Text("Collegati da qui")
            }
        } else {
            Section {
                Text("Nessun paese ha restituito un prezzo per questo volo. Riprova più tardi.")
                    .foregroundStyle(.secondary)
            }
        }
        Section("Prezzo più basso per paese") {
            let home = results.first { $0.market.code == Markets.home.code }?.price
            ForEach(results) { result in
                MarketRow(result: result, homePrice: home)
            }
        }
    }

    private var choiceSection: some View {
        Section {
            DisclosureGroup(isExpanded: $showChoice) {
                ForEach(Markets.all) { market in
                    Toggle(isOn: binding(for: market)) {
                        Text("\(market.flag)  \(market.name)")
                    }
                }
                Button("Consigliati (\(Markets.recommended.count))") { setSelection(Markets.recommended) }
                    .disabled(selected == Markets.recommended)
                Button("Tutti (\(Markets.all.count))") { setSelection(Set(Markets.all.map(\.code))) }
                    .disabled(selected.count == Markets.all.count)
            } label: {
                Text("Paesi da confrontare: \(selected.count) di \(Markets.all.count)")
            }
            Button {
                Task { await run() }
            } label: {
                Label("Confronta di nuovo (\(selected.count) ricerche)", systemImage: "arrow.clockwise")
            }
            .disabled(selected.isEmpty || running)
        } footer: {
            Text("Di base confronto l'Italia con i paesi dove di solito i voli costano meno. Ogni paese usa una ricerca di Google Voli (250 gratuite al mese): aggiungine altri se vuoi un confronto più ampio.")
        }
    }

    private func setSelection(_ codes: Set<String>) {
        selected = codes
        Markets.saveSelection(codes)
    }

    private func binding(for market: Market) -> Binding<Bool> {
        Binding(
            get: { selected.contains(market.code) },
            set: { isOn in
                if isOn { selected.insert(market.code) } else { selected.remove(market.code) }
                Markets.saveSelection(selected)
            }
        )
    }

    private func run() async {
        guard !selected.isEmpty else { return }
        running = true
        defer { running = false }
        let client = GoogleFlightsClient.current()
        isSample = client.isDemo
        let prices = await client.compare(query, markets: Markets.all.filter { selected.contains($0.code) })
        results = prices
        onResult(MarketComparison.summary(prices))
    }
}

/// Il paese più conveniente in grande: bandiera, prezzo, risparmio e link a Google Voli.
struct BestMarketCard: View {
    let best: BestMarket

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(best.market.flag) \(best.market.name)")
                    .font(.title2.bold())
                Spacer()
                Text(Format.price(best.price))
                    .font(.title2.bold())
                    .monospacedDigit()
                    .foregroundStyle(.green)
            }
            Text(explanation)
                .font(.subheadline)
            if let url = best.googleURL {
                Link(destination: url) {
                    Label("Apri Google Voli come da \(best.market.name)", systemImage: "safari")
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var explanation: String {
        if best.isHome {
            return "L'Italia è già il paese più conveniente per questo volo: non serve la VPN."
        }
        if let saving = best.saving, saving >= 1 {
            return "\(Format.price(saving.rounded())) in meno che cercando dall'Italia. Collega la VPN a \(best.market.name), poi apri Google Voli e cerca lo stesso volo."
        }
        return "Il prezzo più basso tra i \(best.countries) paesi confrontati. Collega la VPN a \(best.market.name) e cerca lo stesso volo."
    }
}

/// Riga compatta con il paese migliore (risultati e dettaglio), con il pulsante per (ri)fare il confronto.
struct BestMarketSection: View {
    let best: BestMarket?
    let onCompare: () -> Void

    var body: some View {
        Section {
            if let best {
                BestMarketCard(best: best)
                Button(action: onCompare) {
                    Label("Confronta di nuovo (\(Format.relative(best.comparedAt)))", systemImage: "globe.europe.africa")
                }
            } else {
                Button(action: onCompare) {
                    Label("Trova il paese più conveniente (VPN)", systemImage: "globe.europe.africa")
                        .font(.headline)
                }
            }
        } header: {
            Text("Dove conviene collegarsi")
        } footer: {
            if best == nil {
                Text("Lo stesso volo può costare meno cercandolo da un altro paese: l'app lo cerca da \(Markets.selection().count) paesi e ti dice dove collegarti con la VPN.")
            }
        }
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
