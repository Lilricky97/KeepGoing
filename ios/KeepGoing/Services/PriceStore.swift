import Foundation

/// Scarica lo storico prezzi da GitHub e lo tiene in cache per l'uso offline.
@MainActor
final class PriceStore: ObservableObject {
    @Published private(set) var data: PriceData?
    @Published private(set) var isLoading = false
    /// True finché non ci sono dati veri: si vedono i voli di esempio.
    @Published private(set) var isShowingSample = false
    @Published var errorMessage: String?

    private let cacheURL: URL

    init(cacheURL: URL = URL.applicationSupportDirectory.appending(path: "prices.json")) {
        self.cacheURL = cacheURL
        if let cached = try? Data(contentsOf: cacheURL) {
            data = try? PriceData.decode(cached)
        }
    }

    /// Per le anteprime di Xcode.
    init(preview: PriceData) {
        cacheURL = URL.temporaryDirectory.appending(path: "preview-prices.json")
        data = preview
    }

    var flights: [Flight] { data?.flights ?? [] }

    func flight(id: String) -> Flight? {
        flights.first { $0.id == id }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let raw = try await GitHubSource.current().fetchPrices()
            data = try PriceData.decode(raw)
            isShowingSample = false
            errorMessage = nil
            try? FileManager.default.createDirectory(
                at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try? raw.write(to: cacheURL, options: .atomic)
        } catch is DecodingError {
            errorMessage = "Lo storico prezzi ha un formato inatteso: aggiorna l'app."
        } catch is CancellationError {
            // L'utente ha chiuso la schermata durante l'aggiornamento: nessun errore da mostrare.
        } catch let error as URLError where error.code == .cancelled {
            // Come sopra, ma segnalato da URLSession.
        } catch let error as FetchError {
            if case .notFound = error, data == nil || isShowingSample {
                errorMessage = nil  // il motore non ha ancora fatto il primo controllo: normale
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        if data == nil {
            data = .sample
            isShowingSample = true
        }
    }
}
