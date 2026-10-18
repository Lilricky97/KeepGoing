import Foundation

/// I voli monitorati, salvati sul telefono, e i controlli dei prezzi.
@MainActor
final class MonitorStore: ObservableObject {
    static let shared = MonitorStore()

    @Published private(set) var flights: [MonitoredFlight] = []
    @Published private(set) var checking: Set<String> = []
    @Published var lastError: String?
    /// Nessuna chiave di Google Voli: l'app usa prezzi di esempio.
    @Published private(set) var usesSamplePrices = GoogleFlightsClient.current().isDemo

    /// Ogni quante ore ricontrollare un volo (ogni controllo usa una ricerca di Google Voli).
    @Published var checkIntervalHours: Int {
        didSet { defaults.set(checkIntervalHours, forKey: "check.intervalHours") }
    }

    /// Avvisare anche quando il prezzo sale (non solo quando scende).
    @Published var notifyRises: Bool {
        didSet { defaults.set(notifyRises, forKey: "check.notifyRises") }
    }

    private let fileURL: URL?
    private let defaults: UserDefaults

    init(
        fileURL: URL? = URL.applicationSupportDirectory.appending(path: "monitored-flights.json"),
        defaults: UserDefaults = .standard
    ) {
        self.fileURL = fileURL
        self.defaults = defaults
        checkIntervalHours = defaults.object(forKey: "check.intervalHours") as? Int ?? 12
        notifyRises = defaults.object(forKey: "check.notifyRises") as? Bool ?? true
        if let fileURL, let data = try? Data(contentsOf: fileURL) {
            flights = (try? JSONDecoder().decode([MonitoredFlight].self, from: data)) ?? []
        }
    }

    /// Per le anteprime di Xcode e gli screenshot automatici: non salva niente.
    convenience init(preview flights: [MonitoredFlight]) {
        self.init(fileURL: nil)
        self.flights = flights
    }

    #if DEBUG
    func loadSamplesForScreenshots() {
        flights = MonitoredFlight.samples
    }
    #endif

    var trackerSettings: PriceTracker.Settings {
        var settings = PriceTracker.Settings()
        settings.notifyRises = notifyRises
        return settings
    }

    /// Ricerche di Google Voli al mese con i voli e la frequenza attuali.
    var estimatedSearchesPerMonth: Int {
        flights.filter { !$0.isExpired() }.count * (30 * 24 / max(1, checkIntervalHours))
    }

    func flight(id: String) -> MonitoredFlight? {
        flights.first { $0.id == id }
    }

    func isMonitoring(_ query: SearchQuery) -> Bool {
        flights.contains { $0.id == MonitoredFlight.makeID(query) }
    }

    // MARK: - Aggiungere e togliere

    /// Aggiunge il volo usando come primo controllo la ricerca appena fatta (niente ricerche in più).
    func add(_ query: SearchQuery, name: String, targetPrice: Double?, firstResult: SearchResult?, bestMarket: BestMarket? = nil) {
        var flight = MonitoredFlight(query: query, name: name, targetPrice: targetPrice)
        flight.bestMarket = bestMarket
        flight.samplePrices = firstResult?.isSample
        guard !flights.contains(where: { $0.id == flight.id }) else { return }
        if let firstResult {
            // Evento "primo prezzo" non notificato: lo stai già guardando nell'app.
            _ = PriceTracker.update(&flight, with: firstResult, settings: trackerSettings)
        }
        flights.append(flight)
        save()
        BackgroundRefresh.schedule()
    }

    /// Salva il paese più conveniente trovato con il confronto (VPN).
    func setBestMarket(_ best: BestMarket?, for id: String) {
        guard let best, let index = flights.firstIndex(where: { $0.id == id }) else { return }
        flights[index].bestMarket = best
        save()
    }

    func remove(id: String) {
        flights.removeAll { $0.id == id }
        save()
    }

    // MARK: - Controlli

    /// La chiave di Google Voli è stata cambiata (o tolta).
    func keyChanged() {
        usesSamplePrices = GoogleFlightsClient.current().isDemo
    }

    /// Chiave appena verificata: i voli che hanno ancora i prezzi di esempio passano subito a quelli veri.
    func switchToRealPrices() async {
        keyChanged()
        guard !usesSamplePrices else { return }
        await check(flights.filter { $0.samplePrices != false }.map(\.id), now: .now)
    }

    /// Controlla i voli non ancora partiti il cui ultimo controllo è più vecchio della frequenza scelta.
    /// `force` = tutti, subito (es. "trascina per aggiornare").
    @discardableResult
    func checkDue(force: Bool = false, now: Date = .now) async -> Int {
        let interval = TimeInterval(checkIntervalHours) * 3600 * 0.9  // un po' di margine: i controlli non sono puntuali
        let due = flights.filter { flight in
            guard !force, let last = flight.lastCheck else { return true }
            return now.timeIntervalSince(last) >= interval
        }
        return await check(due.map(\.id), now: now)
    }

    /// Aggiorna un volo se l'ultimo controllo è più vecchio di `maxAge` (es. quando lo apri).
    func refresh(id: String, ifOlderThan maxAge: TimeInterval = 3600, now: Date = .now) async {
        guard let flight = flight(id: id) else { return }
        if let last = flight.lastCheck, now.timeIntervalSince(last) < maxAge { return }
        await check([id], now: now)
    }

    #if os(macOS)
    private var autoCheckTask: Task<Void, Never>?

    /// Sul Mac l'app resta aperta (anche solo nella barra dei menu): ogni 15 minuti
    /// guarda se qualche volo va ricontrollato.
    func startAutoChecks() {
        guard autoCheckTask == nil else { return }
        autoCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.checkDue()
                try? await Task.sleep(for: .seconds(15 * 60))
            }
        }
    }
    #endif

    @discardableResult
    private func check(_ ids: [String], now: Date) async -> Int {
        let due = flights.filter { ids.contains($0.id) && !$0.isExpired(today: now) && !checking.contains($0.id) }
        guard !due.isEmpty else { return 0 }

        let client = GoogleFlightsClient.current()
        checking.formUnion(due.map(\.id))
        defer { checking.subtract(due.map(\.id)) }
        var events = 0
        lastError = nil

        await withTaskGroup(of: (String, Result<SearchResult, Error>).self) { group in
            for flight in due {
                let query = flight.query
                group.addTask {
                    do {
                        return (flight.id, .success(try await client.search(query, now: now)))
                    } catch {
                        return (flight.id, .failure(error))
                    }
                }
            }
            for await (id, outcome) in group {
                guard let index = flights.firstIndex(where: { $0.id == id }) else { continue }  // tolto nel frattempo
                switch outcome {
                case let .success(result):
                    if (flights[index].samplePrices ?? true) != result.isSample {
                        flights[index].clearPrices()  // da prezzi di esempio a veri (o viceversa)
                    }
                    flights[index].samplePrices = result.isSample
                    if let event = PriceTracker.update(&flights[index], with: result, at: now, settings: trackerSettings) {
                        events += 1
                        await NotificationManager.shared.post(event)
                    }
                case let .failure(error):
                    flights[index].lastCheck = now  // non riprovare a raffica
                    flights[index].lastError = Self.message(for: error)
                    lastError = flights[index].lastError
                }
                save()
            }
        }
        return events
    }

    nonisolated static func message(for error: Error) -> String? {
        switch error {
        case is CancellationError:
            return nil
        case let urlError as URLError where urlError.code == .cancelled:
            return nil
        case let urlError as URLError where urlError.code == .notConnectedToInternet:
            return "Nessuna connessione a internet."
        default:
            return error.localizedDescription
        }
    }

    private func save() {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(flights).write(to: fileURL, options: .atomic)
        } catch {
            lastError = "Non riesco a salvare i voli: \(error.localizedDescription)"
        }
    }
}
