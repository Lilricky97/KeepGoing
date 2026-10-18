import SwiftUI

/// Scheda "Cerca": scegli tratta e date, guarda i prezzi di Google Voli, monitora il volo.
struct SearchView: View {
    var onMonitored: () -> Void

    @State private var origin: Place?
    @State private var destination: Place?
    @State private var roundTrip = true
    @State private var departDay: Date
    @State private var returnDay: Date
    @State private var directOnly = false
    @State private var picking: PlaceField?
    @State private var activeQuery: SearchQuery?

    @AppStorage("search.origin") private var savedOrigin = ""
    @AppStorage("search.destination") private var savedDestination = ""

    init(initialQuery: SearchQuery? = nil, onMonitored: @escaping () -> Void) {
        self.onMonitored = onMonitored
        let inTwoWeeks = Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now
        _departDay = State(initialValue: inTwoWeeks)
        _returnDay = State(initialValue: Calendar.current.date(byAdding: .day, value: 7, to: inTwoWeeks) ?? inTwoWeeks)
        _origin = State(initialValue: initialQuery?.origin)
        _destination = State(initialValue: initialQuery?.destination)
        _activeQuery = State(initialValue: initialQuery)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    placeRow("Da", place: origin, icon: "airplane.departure") { picking = .origin }
                    placeRow("A", place: destination, icon: "airplane.arrival") { picking = .destination }
                    Button {
                        (origin, destination) = (destination, origin)
                    } label: {
                        Label("Inverti partenza e arrivo", systemImage: "arrow.up.arrow.down")
                    }
                    .disabled(origin == nil && destination == nil)
                }

                Section("Quando") {
                    Picker("Viaggio", selection: $roundTrip) {
                        Text("Andata e ritorno").tag(true)
                        Text("Solo andata").tag(false)
                    }
                    .pickerStyle(.segmented)
                    DatePicker("Andata", selection: $departDay, in: Date.now..., displayedComponents: .date)
                    if roundTrip {
                        DatePicker("Ritorno", selection: $returnDay, in: departDay..., displayedComponents: .date)
                    }
                    Toggle("Solo voli diretti", isOn: $directOnly)
                }

                Section {
                    Button {
                        guard let query else { return }
                        savedOrigin = query.origin.encoded
                        savedDestination = query.destination.encoded
                        activeQuery = query
                    } label: {
                        Label("Cerca su Google Voli", systemImage: "magnifyingglass")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(query == nil)
                } footer: {
                    if origin != nil, origin?.code == destination?.code {
                        Text("Partenza e arrivo sono uguali.")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Cerca voli")
            .navigationDestination(item: $activeQuery) { query in
                SearchResultsView(query: query, onMonitored: onMonitored)
            }
            .sheet(item: $picking) { field in
                PlacePickerView(title: field == .origin ? "Da dove parti?" : "Dove vuoi andare?") { place in
                    if field == .origin { origin = place } else { destination = place }
                }
            }
            .onChange(of: departDay) { _, day in
                if returnDay < day { returnDay = Calendar.current.date(byAdding: .day, value: 7, to: day) ?? day }
            }
            .onAppear {
                if origin == nil { origin = Place.decoded(savedOrigin) }
                if destination == nil { destination = Place.decoded(savedDestination) }
            }
        }
    }

    private var query: SearchQuery? {
        guard let origin, let destination, origin.code != destination.code else { return nil }
        return SearchQuery(
            origin: origin,
            destination: destination,
            depart: Format.isoDay(departDay),
            returnDate: roundTrip ? Format.isoDay(max(returnDay, departDay)) : nil,
            directOnly: directOnly
        )
    }

    private func placeRow(_ label: String, place: Place?, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let place {
                        Text("\(place.name) (\(place.code))")
                            .foregroundStyle(.primary)
                    } else {
                        Text("Scegli città o aeroporto")
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .tint(Color.primary)  // testi neri/grigi invece del colore dei pulsanti
    }
}

private enum PlaceField: String, Identifiable {
    case origin, destination
    var id: String { rawValue }
}

private extension Place {
    var encoded: String {
        (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    static func decoded(_ text: String) -> Place? {
        try? JSONDecoder().decode(Place.self, from: Data(text.utf8))
    }
}

// MARK: - Scelta di città e aeroporti

struct PlacePickerView: View {
    let title: String
    let onPick: (Place) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var results: [Place] = []
    @State private var failed = false

    var body: some View {
        NavigationStack {
            List {
                if failed {
                    Text("Nessuna connessione: puoi scrivere direttamente il codice dell'aeroporto (es. MXP, BCN).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ForEach(results) { place in
                    Button {
                        onPick(place)
                        dismiss()
                    } label: {
                        PlaceRow(place: place)
                    }
                }
                if let manual = manualPlace {
                    Button {
                        onPick(manual)
                        dismiss()
                    } label: {
                        Label("Usa il codice \(manual.code)", systemImage: "character.cursor.ibeam")
                    }
                }
            }
            .overlay {
                if results.isEmpty && manualPlace == nil && !failed {
                    ContentUnavailableView(
                        "Scrivi una città o un aeroporto",
                        systemImage: "magnifyingglass",
                        description: Text("Per esempio Milano, Malpensa, Barcellona o BCN.")
                    )
                }
            }
            .alwaysVisibleSearch(text: $text, prompt: "Città o aeroporto")
            .autocorrectionDisabled()
            .task(id: text) {
                try? await Task.sleep(for: .milliseconds(300))  // aspetta che finisca di scrivere
                guard !Task.isCancelled else { return }
                do {
                    results = try await PlaceSearch.places(matching: text)
                    failed = false
                } catch {
                    if MonitorStore.message(for: error) != nil { failed = true }
                }
            }
            .navigationTitle(title)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
        .sheetSize()
    }

    /// Un codice scritto a mano (es. "BCN"), se non è già tra i suggerimenti.
    private var manualPlace: Place? {
        let code = text.trimmingCharacters(in: .whitespaces).uppercased()
        guard code.count == 3, code.allSatisfy(\.isLetter), !results.contains(where: { $0.code == code }) else { return nil }
        return Place(code: code, name: code, type: "airport")
    }
}

private struct PlaceRow: View {
    let place: Place

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: place.isAirport ? "airplane" : "building.2")
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .foregroundStyle(.primary)
                if !place.subtitle.isEmpty {
                    Text(place.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(place.isAirport ? place.code : "\(place.code) · tutti")
                .font(.subheadline.monospaced().bold())
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Risultati

struct SearchResultsView: View {
    let query: SearchQuery
    var onMonitored: () -> Void

    @EnvironmentObject private var store: MonitorStore
    @State private var result: SearchResult?
    @State private var error: String?
    @State private var showMonitor = false
    @State private var showCompare = false

    var body: some View {
        List {
            if let result {
                if result.isSample {
                    Section {
                        Label(
                            "Prezzi di esempio: inserisci la chiave di Google Voli nelle Impostazioni per vedere quelli veri.",
                            systemImage: "info.circle.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                }
                if let insights = result.insights, insights.levelText != nil {
                    Section {
                        InsightsRow(insights: insights)
                    }
                }
                if let history = result.insights?.history, HistoryChart.hasData(google: history) {
                    Section("Andamento del prezzo (Google Voli)") {
                        HistoryChart(google: history)
                            .padding(.vertical, 6)
                    }
                }
                Section {
                    if store.isMonitoring(query) {
                        Label("Stai già monitorando questo volo", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            showMonitor = true
                        } label: {
                            Label("Monitora questo volo", systemImage: "bell.badge.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                } footer: {
                    Text("Ti mando una notifica quando il prezzo più basso di questa ricerca scende (o sale).")
                }
                if !result.offers.isEmpty {
                    Section {
                        ForEach(result.offers) { offer in
                            OfferRow(offer: offer, link: result.googleURL)
                        }
                    } header: {
                        Text("\(result.offers.count) voli, dal più economico")
                    } footer: {
                        Text(query.returnDate == nil ? "Prezzi a persona, solo andata." : "Prezzi a persona, andata e ritorno; gli orari sono dell'andata.")
                    }
                }
                DepartureTimesSection(offers: result.offers)
                Section {
                    Button {
                        showCompare = true
                    } label: {
                        Label("Confronta i prezzi da altri paesi (VPN)", systemImage: "globe.europe.africa")
                    }
                    if let url = result.googleURL {
                        Link(destination: url) {
                            Label("Apri la ricerca su Google Voli", systemImage: "safari")
                        }
                    }
                } footer: {
                    Text("Lo stesso volo può costare meno cercandolo da un altro paese: l'app ti dice dove conviene collegarsi con la VPN.")
                }
            }
        }
        .overlay {
            if let error {
                ContentUnavailableView("Ricerca non riuscita", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if result == nil {
                ProgressView("Cerco su Google Voli…")
            } else if result?.offers.isEmpty == true {
                ContentUnavailableView(
                    "Nessun volo trovato",
                    systemImage: "airplane",
                    description: Text("Prova altre date oppure togli \"solo voli diretti\". Puoi comunque monitorarlo.")
                )
                .offset(y: 80)
            }
        }
        .navigationTitle(query.title)
        .inlineNavigationTitle()
        .task {
            if result == nil { await load() }
            #if DEBUG
            if DebugScreen.current == "compare" { showCompare = true }
            #endif
        }
        .refreshable { await load() }
        .sheet(isPresented: $showMonitor) {
            MonitorSheet(query: query, result: result, onDone: onMonitored)
        }
        .sheet(isPresented: $showCompare) {
            MarketCompareView(query: query)
        }
    }

    private func load() async {
        do {
            result = try await GoogleFlightsClient.current().search(query)
            error = nil
        } catch {
            if let message = MonitorStore.message(for: error) { self.error = message }
        }
    }
}

/// "Prezzo basso secondo Google · di solito 95–140 €"
struct InsightsRow: View {
    let insights: PriceInsights

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(insights.levelText ?? "") secondo Google")
                    .font(.headline)
                if let low = insights.typicalLow, let high = insights.typicalHigh {
                    Text("Di solito costa tra \(Format.price(low)) e \(Format.price(high)).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var icon: String {
        switch insights.level {
        case "low": return "arrow.down.circle.fill"
        case "high": return "arrow.up.circle.fill"
        default: return "equal.circle.fill"
        }
    }

    private var color: Color {
        switch insights.level {
        case "low": return .green
        case "high": return .red
        default: return .orange
        }
    }
}

struct OfferRow: View {
    let offer: FlightOffer
    var link: URL?

    @Environment(\.openURL) private var openURL

    var body: some View {
        if let link {
            // Pulsante "semplice" invece di Link: i testi restano neri/grigi anche sul Mac.
            Button {
                openURL(link)
            } label: {
                content.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            AirlineLogo(url: offer.airlineLogo)
            VStack(alignment: .leading, spacing: 3) {
                Text(times)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(Format.price(offer.price, currency: offer.currency))
                .font(.headline)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }

    /// "09:30 MXP → 11:15 BCN"
    private var times: String {
        func time(_ raw: String?) -> String? {
            guard let raw, raw.count >= 16 else { return nil }
            return String(raw.suffix(5))
        }
        let from = [time(offer.departureAt), offer.departureAirport].compactMap { $0 }.joined(separator: " ")
        let to = [time(offer.arrivalAt), offer.arrivalAirport].compactMap { $0 }.joined(separator: " ")
        return "\(from) → \(to)"
    }

    private var details: String {
        [offer.airline, Format.stops(offer.stops), Format.duration(offer.durationMinutes)]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

struct AirlineLogo: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFit()
        } placeholder: {
            Image(systemName: "airplane")
                .foregroundStyle(.secondary)
        }
        .frame(width: 36, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Monitora

struct MonitorSheet: View {
    let query: SearchQuery
    let result: SearchResult?
    var onDone: () -> Void

    @EnvironmentObject private var store: MonitorStore
    @EnvironmentObject private var notifications: NotificationManager
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var useTarget: Bool
    @State private var target: Double

    init(query: SearchQuery, result: SearchResult?, onDone: @escaping () -> Void) {
        self.query = query
        self.result = result
        self.onDone = onDone
        let cheapest = result?.cheapest?.price
        _name = State(initialValue: query.title)
        _useTarget = State(initialValue: cheapest != nil)
        _target = State(initialValue: cheapest.map { max(5, ($0 * 0.9 / 5).rounded() * 5) } ?? 100)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nome") {
                    TextField("Nome", text: $name)
                }
                Section {
                    LabeledContent("Tratta", value: "\(query.origin.code) → \(query.destination.code)")
                    LabeledContent("Andata", value: Format.period(query.depart))
                    LabeledContent("Ritorno", value: query.returnDate.map { Format.period($0) } ?? "Solo andata")
                    if query.directOnly {
                        LabeledContent("Voli", value: "Solo diretti")
                    }
                    if let cheapest = result?.cheapest?.price {
                        LabeledContent("Prezzo più basso ora", value: Format.price(cheapest))
                    }
                }
                Section {
                    Toggle("Avvisami sotto un prezzo", isOn: $useTarget)
                    if useTarget {
                        Stepper(value: $target, in: 5...10_000, step: 5) {
                            LabeledContent("Prezzo obiettivo", value: Format.price(target))
                        }
                    }
                } footer: {
                    Text("Ti avviso comunque a ogni ribasso. L'obiettivo aggiunge un avviso speciale quando il prezzo ci scende sotto.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Monitora")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Monitora") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.add(
                            query,
                            name: trimmed.isEmpty ? query.title : trimmed,
                            targetPrice: useTarget ? target : nil,
                            firstResult: result
                        )
                        Task {
                            // Senza permesso le notifiche non arrivano: chiederlo qui ha senso per l'utente.
                            if notifications.authorization == .notDetermined { await notifications.requestPermission() }
                        }
                        dismiss()
                        onDone()
                    }
                    .bold()
                }
            }
        }
        .sheetSize()
    }
}

#Preview("Ricerca") {
    SearchView(onMonitored: {})
        .environmentObject(MonitorStore(preview: []))
}

#Preview("Risultati") {
    NavigationStack {
        SearchResultsView(query: .preview, onMonitored: {})
    }
    .environmentObject(MonitorStore(preview: []))
    .environmentObject(NotificationManager.shared)
}

extension SearchQuery {
    static var preview: SearchQuery {
        let depart = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
        return SearchQuery(
            origin: Place(code: "MIL", name: "Milano", type: "city", countryName: "Italia"),
            destination: Place(code: "BCN", name: "Barcellona", type: "city", countryName: "Spagna"),
            depart: Format.isoDay(depart),
            returnDate: Format.isoDay(Calendar.current.date(byAdding: .day, value: 7, to: depart) ?? depart),
            directOnly: false
        )
    }
}
