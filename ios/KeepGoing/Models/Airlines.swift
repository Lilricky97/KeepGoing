import Foundation

/// Nomi delle compagnie più comuni in Europa, dal codice IATA.
enum Airlines {
    private static let names: [String: String] = [
        "A3": "Aegean", "AA": "American Airlines", "AF": "Air France", "AY": "Finnair",
        "AZ": "ITA Airways", "BA": "British Airways", "BT": "airBaltic", "DL": "Delta",
        "DY": "Norwegian", "EI": "Aer Lingus", "EK": "Emirates", "EW": "Eurowings",
        "EY": "Etihad", "FR": "Ryanair", "HV": "Transavia", "IB": "Iberia",
        "JU": "Air Serbia", "KL": "KLM", "LH": "Lufthansa", "LO": "LOT",
        "LS": "Jet2", "LX": "Swiss", "NO": "Neos", "OS": "Austrian",
        "PC": "Pegasus", "QR": "Qatar Airways", "RO": "Tarom", "SK": "SAS",
        "SN": "Brussels Airlines", "TO": "Transavia France", "TP": "TAP Air Portugal", "TK": "Turkish Airlines",
        "U2": "easyJet", "UA": "United", "UX": "Air Europa", "V7": "Volotea",
        "VY": "Vueling", "W4": "Wizz Air Malta", "W6": "Wizz Air", "XQ": "SunExpress",
    ]

    static func name(for code: String?) -> String? {
        guard let code else { return nil }
        return names[code.uppercased()] ?? code
    }

    /// Logo della compagnia (servizio pubblico di Aviasales).
    static func logoURL(for code: String?) -> URL? {
        guard let code, !code.isEmpty else { return nil }
        return URL(string: "https://pics.avs.io/120/120/\(code.uppercased()).png")
    }
}
