import Foundation

/// Un volo aggiunto dall'app. Viene salvato in watches.json sul repository GitHub,
/// dove il motore lo legge (keepgoing/config.py, load_app_watches).
struct AppWatch: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var origin: String
    var destination: String
    var depart: String  // "YYYY-MM" (tutto il mese) oppure "YYYY-MM-DD"
    var returnDate: String?  // nil = solo andata
    var directOnly: Bool
    var targetPrice: Double?
    var addedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, origin, destination, depart
        case returnDate = "return"
        case directOnly = "direct_only"
        case targetPrice = "target_price"
        case addedAt = "added_at"
    }

    init(
        name: String,
        origin: String,
        destination: String,
        depart: String,
        returnDate: String?,
        directOnly: Bool,
        targetPrice: Double?,
        addedAt: Date = .now
    ) {
        self.id = Self.makeID(origin: origin, destination: destination, depart: depart, returnDate: returnDate)
        self.name = name
        self.origin = origin
        self.destination = destination
        self.depart = depart
        self.returnDate = returnDate
        self.directOnly = directOnly
        self.targetPrice = targetPrice
        self.addedAt = ISO8601DateFormatter().string(from: addedAt)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        origin = try c.decode(String.self, forKey: .origin).uppercased()
        destination = try c.decode(String.self, forKey: .destination).uppercased()
        depart = try c.decode(String.self, forKey: .depart)
        returnDate = try c.decodeIfPresent(String.self, forKey: .returnDate)
        id = try c.decodeIfPresent(String.self, forKey: .id)
            ?? Self.makeID(origin: origin, destination: destination, depart: depart, returnDate: returnDate)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "\(origin) → \(destination)"
        directOnly = try c.decodeIfPresent(Bool.self, forKey: .directOnly) ?? false
        targetPrice = try c.decodeIfPresent(Double.self, forKey: .targetPrice)
        addedAt = try c.decodeIfPresent(String.self, forKey: .addedAt)
    }

    /// Lo stesso id che calcola il motore per un volo senza id esplicito.
    static func makeID(origin: String, destination: String, depart: String, returnDate: String?) -> String {
        [origin, destination, depart, returnDate].compactMap { $0 }.joined(separator: "-").lowercased()
    }

    var info: WatchInfo {
        WatchInfo(
            name: name, origin: origin, destination: destination, depart: depart,
            returnDate: returnDate, directOnly: directOnly, targetPrice: targetPrice, source: "app"
        )
    }
}

/// Contenuto di watches.json.
struct WatchList: Codable {
    var version = 1
    var watches: [AppWatch] = []

    init(watches: [AppWatch] = []) {
        self.watches = watches
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        watches = try c.decodeIfPresent([AppWatch].self, forKey: .watches) ?? []
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self) + Data("\n".utf8)
    }
}
