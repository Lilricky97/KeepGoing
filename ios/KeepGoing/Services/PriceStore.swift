import Foundation

/// Storico prezzi (data/prices.json) e voli aggiunti dall'app (watches.json), letti da GitHub.
@MainActor
final class PriceStore: ObservableObject {
    @Published private(set) var prices: PriceData?
    @Published private(set) var appWatches: [AppWatch]?  // nil = watches.json non ancora letto
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let cacheURL: URL
    private var lastRefresh: Date?

    init(cacheURL: URL = URL.applicationSupportDirectory.appending(path: "prices.json")) {
        self.cacheURL = cacheURL
        if let cached = try? Data(contentsOf: cacheURL) {
            prices = try? PriceData.decode(cached)
        }
    }

    /// Per le anteprime di Xcode.
    init(preview: PriceData) {
        cacheURL = URL.temporaryDirectory.appending(path: "preview-prices.json")
        prices = preview
        appWatches = []
    }

    /// Ancora niente di vero (nessun controllo, nessun volo aggiunto): si vedono i voli di esempio.
    var isShowingSample: Bool { prices == nil && (appWatches ?? []).isEmpty }

    var flights: [Flight] {
        isShowingSample
            ? Flight.combine(prices: .sample, appWatches: nil)
            : Flight.combine(prices: prices, appWatches: appWatches)
    }

    var updatedAt: Date? { isShowingSample ? PriceData.sample.updatedAt : prices?.updatedAt }

    func flight(id: String) -> Flight? {
        flights.first { $0.id == id }
    }

    func refreshIfStale() async {
        if let lastRefresh, Date.now.timeIntervalSince(lastRefresh) < 60 { return }
        await refresh()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer {
            isLoading = false
            lastRefresh = .now
        }
        let source = GitHubSource.current()
        var problem: Error?
        do {
            let raw = try await source.fetchPrices()
            prices = try PriceData.decode(raw)
            try? FileManager.default.createDirectory(
                at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try? raw.write(to: cacheURL, options: .atomic)
        } catch FetchError.notFound(_, _) {
            // Il motore non ha ancora fatto il primo controllo: normale.
        } catch {
            problem = error
        }
        do {
            appWatches = try await source.fetchWatches().0.watches
        } catch {
            problem = problem ?? error
        }
        errorMessage = problem.flatMap(Self.message(for:))
    }

    // MARK: - Aggiungere e togliere voli

    func add(_ watch: AppWatch) async throws {
        try await updateWatches(message: "Monitora \(watch.name) (dall'app)") { watches in
            guard !watches.contains(where: { $0.id == watch.id }) else { throw StoreError.alreadyMonitored }
            watches.append(watch)
        }
    }

    func remove(id: String) async throws {
        let name = flight(id: id)?.name ?? id
        try await updateWatches(message: "Smetti di monitorare \(name) (dall'app)") { watches in
            watches.removeAll { $0.id == id }
        }
    }

    /// Rilegge sempre l'ultima versione di watches.json prima di modificarla,
    /// così non si perdono voli aggiunti da un altro dispositivo.
    private func updateWatches(message: String, change: (inout [AppWatch]) throws -> Void) async throws {
        let source = GitHubSource.current()
        guard source.hasToken else { throw FetchError.missingToken }
        for attempt in 1...2 {
            let (current, sha) = try await source.fetchWatches()
            var list = current
            try change(&list.watches)
            do {
                try await source.saveWatches(list, sha: sha, message: message)
                appWatches = list.watches
                return
            } catch FetchError.conflict where attempt == 1 {
                continue
            }
        }
    }

    nonisolated static func message(for error: Error) -> String? {
        switch error {
        case is CancellationError:
            return nil
        case let urlError as URLError where urlError.code == .cancelled:
            return nil
        case is DecodingError:
            return "I dati su GitHub hanno un formato inatteso: aggiorna l'app."
        default:
            return error.localizedDescription
        }
    }
}

enum StoreError: LocalizedError {
    case alreadyMonitored

    var errorDescription: String? {
        switch self {
        case .alreadyMonitored: return "Stai già monitorando questo volo."
        }
    }
}
