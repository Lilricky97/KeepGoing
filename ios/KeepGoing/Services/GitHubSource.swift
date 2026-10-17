import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Il repository GitHub su cui gira il motore: da qui l'app legge lo storico
/// (data/prices.json) e legge/scrive i voli da monitorare (watches.json).
struct GitHubSource {
    static let defaultOwner = "Lilricky97"
    static let defaultRepo = "KeepGoing"

    var owner: String
    var repo: String
    var branch: String  // vuoto = branch predefinito del repository
    var token: String?  // serve per aggiungere o togliere voli (Contents: Read and write)

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

    var hasToken: Bool { token.nonEmpty != nil }

    var url: URL? { contentsURL("data/prices.json", withRef: true) }

    // MARK: - Storico prezzi

    func fetchPrices(session: URLSession = .shared) async throws -> Data {
        let (data, status) = try await send(path: "data/prices.json", accept: "application/vnd.github.raw+json", session: session)
        guard status == 200 else { throw FetchError(status: status, owner: owner, repo: repo) }
        return data
    }

    // MARK: - Voli aggiunti dall'app

    /// Il contenuto di watches.json e il suo "sha" (serve per salvarlo). Se il file non c'è: elenco vuoto.
    func fetchWatches(session: URLSession = .shared) async throws -> (WatchList, String?) {
        let (data, status) = try await send(path: "watches.json", accept: "application/vnd.github+json", session: session)
        if status == 404 { return (WatchList(), nil) }
        guard status == 200 else { throw FetchError(status: status, owner: owner, repo: repo) }
        let file = try JSONDecoder().decode(ContentFile.self, from: data)
        guard let raw = Data(base64Encoded: file.content, options: .ignoreUnknownCharacters) else {
            throw FetchError.http(status)
        }
        return (try JSONDecoder().decode(WatchList.self, from: raw), file.sha)
    }

    /// Salva watches.json con un commit; il push fa partire subito un controllo dei prezzi.
    @discardableResult
    func saveWatches(_ list: WatchList, sha: String?, message: String, session: URLSession = .shared) async throws -> String? {
        guard let token = token.nonEmpty else { throw FetchError.missingToken }
        guard let url = contentsURL("watches.json", withRef: false) else { throw FetchError.badRepository }
        var body = ["message": message, "content": try list.encoded().base64EncodedString()]
        if let sha { body["sha"] = sha }
        let ref = branch.trimmingCharacters(in: .whitespaces)
        if !ref.isEmpty { body["branch"] = ref }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200, 201:
            return (try? JSONDecoder().decode(SavedFile.self, from: data))?.content.sha
        case 409, 422: throw FetchError.conflict
        case 403, 404: throw FetchError.noWritePermission
        default: throw FetchError(status: status, owner: owner, repo: repo)
        }
    }

    // MARK: - Richieste

    private func contentsURL(_ path: String, withRef: Bool) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/repos/\(owner)/\(repo)/contents/\(path)"
        let ref = branch.trimmingCharacters(in: .whitespaces)
        if withRef, !ref.isEmpty {
            components.queryItems = [URLQueryItem(name: "ref", value: ref)]
        }
        return components.url
    }

    private func send(path: String, accept: String, session: URLSession) async throws -> (Data, Int) {
        guard let url = contentsURL(path, withRef: true) else { throw FetchError.badRepository }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let token = token.nonEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: request)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
}

private struct ContentFile: Decodable {
    var content: String
    var sha: String
}

private struct SavedFile: Decodable {
    struct Content: Decodable { var sha: String }
    var content: Content
}

enum FetchError: LocalizedError {
    case badRepository
    case badToken
    case missingToken
    case noWritePermission
    case conflict
    case rateLimited
    case notFound(owner: String, repo: String)
    case http(Int)

    init(status: Int, owner: String, repo: String) {
        switch status {
        case 401: self = .badToken
        case 403, 429: self = .rateLimited
        case 404: self = .notFound(owner: owner, repo: repo)
        default: self = .http(status)
        }
    }

    var errorDescription: String? {
        switch self {
        case .badRepository:
            return "Nome del repository non valido: controllalo nelle Impostazioni."
        case .badToken:
            return "Il token GitHub non è valido o è scaduto: controllalo nelle Impostazioni."
        case .missingToken:
            return "Per aggiungere voli serve il token GitHub: inseriscilo nelle Impostazioni (sezione GitHub)."
        case .noWritePermission:
            return "Il token GitHub non può modificare il repository: crealo con il permesso Contents: Read and write."
        case .conflict:
            return "I voli sono stati modificati nel frattempo: riprova."
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
