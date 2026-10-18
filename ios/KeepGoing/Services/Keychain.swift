import Foundation
#if os(iOS)
import Security
#endif

/// Salva la chiave di Google Voli.
enum Keychain {
    #if os(iOS)
    // iPhone: nel Portachiavi.
    private static let service = "keepgoing"

    static func read(_ account: String) -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ value: String, account: String) {
        SecItemDelete(baseQuery(account) as CFDictionary)
        guard !value.isEmpty else { return }
        var query = baseQuery(account)
        query[kSecValueData as String] = Data(value.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
    #else
    // Mac: l'app compilata da Xcode senza account sviluppatore cambia firma a ogni compilazione e
    // il Portachiavi chiederebbe ogni volta la password. La chiave (gratuita) resta nelle preferenze.
    static func read(_ account: String) -> String? {
        UserDefaults.standard.string(forKey: "secret.\(account)")
    }

    static func save(_ value: String, account: String) {
        if value.isEmpty {
            UserDefaults.standard.removeObject(forKey: "secret.\(account)")
        } else {
            UserDefaults.standard.set(value, forKey: "secret.\(account)")
        }
    }
    #endif
}
