import Foundation

extension PriceData {
    /// Dati di esempio per le anteprime di Xcode (stesso formato di data/prices.json).
    static let sample: PriceData = {
        let json = """
        {
          "version": 1,
          "updated_at": "2026-10-14T12:17:00+00:00",
          "active": ["mil-bcn-2026-12-2026-12", "rom-lon-2027-02-14"],
          "watches": {
            "mil-bcn-2026-12-2026-12": {
              "watch": {"name": "Milano → Barcellona", "origin": "MIL", "destination": "BCN",
                        "depart": "2026-12", "return": "2026-12", "direct_only": false, "target_price": 80},
              "baseline": 84, "lowest": 84, "lowest_at": "2026-10-14T12:17:00+00:00",
              "last": {"price": 84, "currency": "EUR", "provider": "travelpayouts", "airline": "VY",
                       "flight_number": "VY6312", "departure_at": "2026-12-10T09:30:00+01:00",
                       "return_at": "2026-12-17T18:00:00+01:00", "transfers": 0,
                       "link": "https://www.aviasales.com", "checked_at": "2026-10-14T12:17:00+00:00"},
              "history": [
                {"at": "2026-10-12T09:17:00+00:00", "price": 112},
                {"at": "2026-10-12T21:17:00+00:00", "price": 109},
                {"at": "2026-10-13T09:17:00+00:00", "price": 118},
                {"at": "2026-10-13T21:17:00+00:00", "price": 97},
                {"at": "2026-10-14T03:17:00+00:00", "price": 95},
                {"at": "2026-10-14T12:17:00+00:00", "price": 84}
              ]
            },
            "rom-lon-2027-02-14": {
              "watch": {"name": "Roma → Londra", "origin": "ROM", "destination": "LON",
                        "depart": "2027-02-14", "return": null, "direct_only": true, "target_price": null},
              "baseline": 61, "lowest": 58,
              "last": {"price": 64, "currency": "EUR", "provider": "travelpayouts", "transfers": 0,
                       "departure_at": "2027-02-14T07:05:00+01:00", "checked_at": "2026-10-14T12:17:00+00:00"},
              "history": [
                {"at": "2026-10-13T21:17:00+00:00", "price": 58},
                {"at": "2026-10-14T12:17:00+00:00", "price": 64}
              ]
            }
          }
        }
        """
        return try! PriceData.decode(Data(json.utf8))
    }()
}
