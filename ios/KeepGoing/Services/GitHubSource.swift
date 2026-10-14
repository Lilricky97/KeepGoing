import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Da dove leggere data/prices.json: il repository GitHub su cui gira il motore.
struct GitHubSource {
    static let defaultOwner = "Lilricky97"
    static let defaultRepo = "KeepGoing"

    var owner: String
    var repo: String
    var branch: String  // vuoto = branch predefinito del repository
    var token: String?  // serve solo se il repository è privato

    enum Keys {
        static let owner = "github.owner"
        static let repo = "github.repo"
        static let branch = "github.branch"
        static let token = "github-token"
    }

    static func current(defaults: UserDefaults = .standard) -> GitHubSource {
        GitHubSource(
            owner: defaults.string(forKey: Keys.owner).nonEmpty ?? defaultOwner,
            repo: defaults.string(forKey: Keys.repo).nonEmpty ?? defaultRepo,
            branch: defaults.string(forKey: Keys.branch) ?? "",
            token: Keychain.read(Keys.token)
        )
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/repos/\(owner)/\(repo)/contents/data/prices.json"
        let ref = branch.trimmingCharacters(in: .whitespaces)
        if !ref.isEmpty {
            components.queryItems = [URLQueryItem(name: "ref", value: ref)]
        }
        return components.url
    }

    func fetchPrices(session: URLSession = .shared) async throws -> Data {
        guard let url else { throw FetchError.badRepository }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/vnd.github.raw+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let token = token.nonEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200: return data
        case 401: throw FetchError.badToken
        case 403, 429: throw FetchError.rateLimited
        case 404: throw FetchError.notFound(owner: owner, repo: repo)
        default: throw FetchError.http(status)
        }
    }
}

enum FetchError: LocalizedError {
    case badRepository
    case badToken
    case rateLimited
    case notFound(owner: String, repo: String)
    case http(Int)

    var errorDescription: String? {
        switch self {
        case .badRepository:
            return "Nome del repository non valido: controllalo nelle Impostazioni."
        case .badToken:
            return "Il token GitHub non è valido o è scaduto."
        case .rateLimited:
            return "Troppe richieste a GitHub: riprova tra qualche minuto (oppure aggiungi un token nelle Impostazioni)."
        case let .notFound(owner, repo):
            return "Nessuno storico in \(owner)/\(repo). Il primo controllo non è ancora stato fatto, "
                + "oppure il repository è privato: in quel caso aggiungi un token nelle Impostazioni."
        case let .http(status):
            return "GitHub ha risposto con un errore (\(status))."
        }
    }
}

extension Optional where Wrapped == String {
    /// nil se la stringa è vuota o fatta solo di spazi.
    var nonEmpty: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}
