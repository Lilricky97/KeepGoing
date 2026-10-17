import SwiftUI

/// Scheda "Cerca": scegli tratta e date, guarda i prezzi, monitora il volo.
struct SearchView: View {
    var onMonitored: () -> Void

    @State private var origin: Place?
    @State private var destination: Place?
    @State private var roundTrip = true
    @State private var wholeMonth = true
    @State private var departMonth: String
    @State private var returnMonth: String
    @State private var departDay: Date
    @State private var returnDay: Date
    @State private var directOnly = false
    @State private var picking: PlaceField?
    @State private var activeQuery: SearchQuery?

    @AppStorage("search.origin") private var savedOrigin = ""
    @AppStorage("search.destination") private var savedDestination = ""

    private let months = Format.upcomingMonths()

    init(initialQuery: SearchQuery? = nil, onMonitored: @escaping () -> Void) {
        self.onMonitored = onMonitored
        let nextMonth = Format.upcomingMonths(count: 2).last ?? Format.upcomingMonths(count: 1)[0]
        _departMonth = State(initialValue: nextMonth)
        _returnMonth = State(initialValue: nextMonth)
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
                    Picker("Date", selection: $wholeMonth) {
                        Text("Tutto il mese").tag(true)
                        Text("Giorno preciso").tag(false)
                    }
                    .pickerStyle(.segmented)
                    if wholeMonth {
                        Picker("Partenza", selection: $departMonth) {
                            ForEach(months, id: \.self) { Text(Format.period($0).capitalized).tag($0) }
                        }
                        if roundTrip {
                            Picker("Ritorno", selection: $returnMonth) {
                                ForEach(months.filter { $0 >= departMonth }, id: \.self) {
                                    Text(Format.period($0).capitalized).tag($0)
                                }
                            }
                        }
                    } else {
                        DatePicker("Partenza", selection: $departDay, in: Date.now..., displayedComponents: .date)
                        if roundTrip {
                            DatePicker("Ritorno", selection: $returnDay, in: departDay..., displayedComponents: .date)
                        }
                    }
                    Toggle("Solo voli diretti", isOn: $directOnly)
                }

                Section {
                    Button {
                        guard let query else { return }
                        save(query)
                        activeQuery = query
                    } label: {
                        Label("Cerca voli", systemImage: "magnifyingglass")
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
            .navigationTitle("Cerca voli")
            .navigationDestination(item: $activeQuery) { query in
                SearchResultsView(query: query, onMonitored: onMonitored)
            }
            .sheet(item: $picking) { field in
                PlacePickerView(title: field == .origin ? "Da dove parti?" : "Dove vuoi andare?") { place in
                    if field == .origin { origin = place } else { destination = place }
                }
            }
            .onChange(of: departMonth) { _, month in
                if returnMonth < month { returnMonth = month }
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
        let depart = wholeMonth ? departMonth : Format.isoDay(departDay)
        var returnDate: String?
        if roundTrip {
            returnDate = wholeMonth ? max(returnMonth, departMonth) : Format.isoDay(max(returnDay, departDay))
        }
        return SearchQuery(origin: origin, destination: destination, depart: depart, returnDate: returnDate, directOnly: directOnly)
    }

    private func save(_ query: SearchQuery) {
        savedOrigin = query.origin.encoded
        savedDestination = query.destination.encoded
    }

    private func placeRow(_ label: String, place: Place?, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.tint)
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
                    Text("Nessuna connessione: puoi scrivere direttamente il codice IATA (es. MIL, BCN).")
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
            .searchable(text: $text, placement: .navigationBarDrawer(displayMode: .always), prompt: "Città o aeroporto")
            .autocorrectionDisabled()
            .task(id: text) {
                try? await Task.sleep(for: .milliseconds(300))  // aspetta che finisca di scrivere
                guard !Task.isCancelled else { return }
                do {
                    results = try await TravelpayoutsClient.places(matching: text)
                    failed = false
                } catch {
                    if PriceStore.message(for: error) != nil { failed = true }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
    }

    /// Un codice IATA scritto a mano (es. "BCN"), se non è già tra i suggerimenti.
    private var manualPlace: Place? {
        let code = text.trimmingCharacters(in: .whitespaces).uppercased()
        guard code.count == 3, code.allSatisfy(\.isLetter), !results.contains(where: { $0.code == code }) else { return nil }
        return Place(code: code, name: code, type: "city", countryName: nil, cityName: nil)
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
            Text(place.code)
                .font(.subheadline.monospaced().bold())
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Risultati

struct SearchResultsView: View {
    let query: SearchQuery
    var onMonitored: () -> Void

    @State private var result: SearchResult?
    @State private var error: String?
    @State private var showMonitor = false

    var body: some View {
        List {
            if let result {
                if result.isSample {
                    Section {
                        Label(
                            "Prezzi di esempio: inserisci il token Travelpayouts nelle Impostazioni per vedere quelli veri.",
                            systemImage: "info.circle.fill"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                }
                Section {
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
                } footer: {
                    Text("Ti mando una notifica quando il prezzo più basso di questa ricerca scende (o sale).")
                }
                if !result.offers.isEmpty {
                    Section {
                        ForEach(result.offers) { offer in
                            OfferRow(offer: offer)
                        }
                    } header: {
                        Text("\(result.offers.count) voli, dal più economico")
                    } footer: {
                        Text("Tocca un volo per vederlo su Aviasales. I prezzi sono quelli trovati nelle ultime 48 ore.")
                    }
                }
            }
        }
        .overlay {
            if let error {
                ContentUnavailableView("Ricerca non riuscita", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if result == nil {
                ProgressView("Cerco i voli…")
            } else if result?.offers.isEmpty == true {
                ContentUnavailableView(
                    "Nessun volo trovato",
                    systemImage: "airplane",
                    description: Text("Prova altre date, un mese intero, oppure togli \"solo voli diretti\". Puoi comunque monitorarlo.")
                )
                .offset(y: 80)
            }
        }
        .navigationTitle(query.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $showMonitor) {
            MonitorSheet(query: query, cheapest: result?.offers.first?.price, onDone: onMonitored)
        }
    }

    private func load() async {
        do {
            result = try await TravelpayoutsClient.current().search(query)
            error = nil
        } catch {
            if let message = PriceStore.message(for: error) { self.error = message }
        }
    }
}

struct OfferRow: View {
    let offer: FlightOffer

    var body: some View {
        if let link = offer.link {
            Link(destination: link) { content }
                .tint(Color.primary)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            AirlineLogo(code: offer.airline)
            VStack(alignment: .leading, spacing: 3) {
                Text(Format.dayTime(offer.departureAt) ?? "Data da confermare")
                    .font(.subheadline.weight(.semibold))
                if let back = Format.dayTime(offer.returnAt) {
                    Text("Ritorno \(back)")
                        .font(.subheadline)
                }
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

    private var details: String {
        [Airlines.name(for: offer.airline), Format.stops(offer.transfers), Format.duration(offer.durationTo)]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

struct AirlineLogo: View {
    let code: String?

    var body: some View {
        AsyncImage(url: Airlines.logoURL(for: code)) { image in
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
    let cheapest: Double?
    var onDone: () -> Void

    @EnvironmentObject private var store: PriceStore
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var useTarget: Bool
    @State private var target: Double
    @State private var saving = false
    @State private var error: String?

    init(query: SearchQuery, cheapest: Double?, onDone: @escaping () -> Void) {
        self.query = query
        self.cheapest = cheapest
        self.onDone = onDone
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
                    LabeledContent("Partenza", value: Format.period(query.depart))
                    LabeledContent("Ritorno", value: query.returnDate.map(Format.period) ?? "Solo andata")
                    if query.directOnly {
                        LabeledContent("Voli", value: "Solo diretti")
                    }
                    if let cheapest {
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
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Monitora")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if saving {
                        ProgressView()
                    } else {
                        Button("Monitora") {
                            Task { await save() }
                        }
                        .bold()
                    }
                }
            }
            .interactiveDismissDisabled(saving)
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let watch = AppWatch(
            name: trimmed.isEmpty ? query.title : trimmed,
            origin: query.origin.code,
            destination: query.destination.code,
            depart: query.depart,
            returnDate: query.returnDate,
            directOnly: query.directOnly,
            targetPrice: useTarget ? target : nil
        )
        do {
            try await store.add(watch)
            dismiss()
            onDone()
        } catch {
            self.error = PriceStore.message(for: error)
        }
    }
}

#Preview("Ricerca") {
    SearchView(onMonitored: {})
        .environmentObject(PriceStore(preview: .sample))
}

#Preview("Risultati") {
    NavigationStack {
        SearchResultsView(query: .preview, onMonitored: {})
    }
    .environmentObject(PriceStore(preview: .sample))
}

extension SearchQuery {
    static let preview = SearchQuery(
        origin: Place(code: "MIL", name: "Milano", type: "city", countryName: "Italia", cityName: nil),
        destination: Place(code: "BCN", name: "Barcellona", type: "city", countryName: "Spagna", cityName: nil),
        depart: Format.upcomingMonths(count: 2).last ?? "2026-12",
        returnDate: Format.upcomingMonths(count: 2).last ?? "2026-12",
        directOnly: false
    )
}
