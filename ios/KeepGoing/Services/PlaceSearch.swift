import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Suggerimenti di città e aeroporti mentre si scrive (servizio pubblico di Travelpayouts, niente chiave).
enum PlaceSearch {
    private static let url = "https://autocomplete.travelpayouts.com/places2"

    static func places(matching term: String, types: [String] = ["city", "airport"], session: URLSession = .shared) async throws -> [Place] {
        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2, var components = URLComponents(string: url) else { return [] }
        components.queryItems = [URLQueryItem(name: "locale", value: "it"), URLQueryItem(name: "term", value: term)]
            + types.map { URLQueryItem(name: "types[]", value: $0) }
        guard let url = components.url else { return [] }
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([Place].self, from: data)
    }

    /// Gli aeroporti di una città: Google Voli vuole i codici degli aeroporti (MIL → MXP,BGY,LIN).
    static func airports(forCity code: String, session: URLSession = .shared) async throws -> [String] {
        try await places(matching: code, types: ["airport"], session: session)
            .filter { $0.cityCode == code }
            .map(\.code)
            .prefix(6)
            .map { $0 }
    }

    /// Il valore da passare a Google Voli: il codice dell'aeroporto, o tutti quelli della città.
    static func searchCodes(for place: Place, defaults: UserDefaults = .standard) async -> String {
        guard !place.isAirport else { return place.code }
        let key = "airports.\(place.code)"
        if let cached = defaults.string(forKey: key) { return cached }
        let airports = (try? await airports(forCity: place.code)) ?? []
        guard !airports.isEmpty else { return place.code }  // es. BCN: città e aeroporto hanno lo stesso codice
        let value = airports.joined(separator: ",")
        defaults.set(value, forKey: key)
        return value
    }
}
