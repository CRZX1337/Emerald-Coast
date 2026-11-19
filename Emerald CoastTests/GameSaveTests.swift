import Foundation
import Testing
@testable import Emerald_Coast

@MainActor
struct GameSaveTests {
    private let key = "spielstand"

    // Feste JSON-Daten im Format von 1.6 (Build 26), nicht vom aktuellen Encoder erzeugt.
    private let v16 = Data("""
    {
      "money":8123.5,"xp":75,"level":6,"totalHarvests":9,"selectedRoom":0,
      "rooms":[{"id":0,"unlocked":true,"price":0,"requiredLevel":1,"selectionID":"house-og"}],
      "upgradeLevels":{"lamps":2},"licensedBrandIDs":["breezy"],"selectedStrainID":"house-og",
      "shelf":[{"strainID":"house-og","grams":42,"price":12,"unitCost":3.5}],
      "permittedDistrictIDs":["oakland"],"heat":18,"shopOpen":false
    }
    """.utf8)

    private func withDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let suite = "GameSaveTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults)
    }

    @Test func ersterStartOhneWarnung() throws {
        try withDefaults { defaults in
            let store = GameStore(saveKey: key, defaults: defaults)
            #expect(store.rooms.first?.plant != nil)
            #expect(store.toast == nil)
            #expect(defaults.data(forKey: key) != nil)
            #expect(defaults.object(forKey: key + ".quarantine") == nil)
        }
    }

    @Test func spielstandAusVersion16BleibtSpielbar() throws {
        try withDefaults { defaults in
            defaults.set(v16, forKey: key)
            let store = GameStore(saveKey: key, defaults: defaults)
            #expect(defaults.data(forKey: key + ".backup") == v16)
            #expect(store.toast == nil)
            store.save()
            let loaded = GameStore(saveKey: key, defaults: defaults)
            #expect(loaded.money == 8123.5)
            #expect(loaded.totalHarvests == 9)
            #expect(loaded.rooms.first?.selectionID == "house-og")
            #expect(loaded.shelf.first?.grams == 42)
            #expect(loaded.upgradeLevels["lamps"] == 2)
            #expect(loaded.permittedDistrictIDs.contains("oakland"))
            #expect(!loaded.shopOpen)
        }
    }

    @Test func letzteLesbareVersionWirdWiederhergestellt() throws {
        try withDefaults { defaults in
            let store = GameStore(saveKey: key, defaults: defaults)
            store.money = 123
            store.save()
            let good = try #require(defaults.data(forKey: key))
            store.money = 456
            store.save()
            #expect(defaults.data(forKey: key + ".backup") == good)

            let broken = Data([0xff, 0])
            defaults.set(broken, forKey: key)
            let recovered = GameStore(saveKey: key, defaults: defaults)
            #expect(recovered.money == 123)
            #expect(recovered.toast?.text.contains("Sicherung") == true)
            #expect(defaults.data(forKey: key + ".quarantine") == broken)
            let next = GameStore(saveKey: key, defaults: defaults)
            #expect(next.money == 123)
            #expect(next.toast == nil)
        }
    }

    @Test func fehlenderHauptstandNutztVorhandeneSicherung() throws {
        try withDefaults { defaults in
            defaults.set(v16, forKey: key + ".backup")
            let loaded = GameStore(saveKey: key, defaults: defaults)
            #expect(loaded.money == 8123.5)
            #expect(loaded.toast?.text.contains("Sicherung") == true)
            #expect(defaults.object(forKey: key + ".quarantine") == nil)
        }
    }

    @Test func zweiDefekteStaendeBleibenBeimNeustartErhalten() throws {
        try withDefaults { defaults in
            let brokenBackup = Data("{}".utf8)
            defaults.set("kein Datenobjekt", forKey: key)
            defaults.set(brokenBackup, forKey: key + ".backup")
            let store = GameStore(saveKey: key, defaults: defaults)
            #expect(store.rooms.first?.plant != nil)
            #expect(store.toast?.text.contains("Neues Spiel") == true)
            store.save()
            #expect(defaults.string(forKey: key + ".quarantine") == "kein Datenobjekt")
            #expect(defaults.data(forKey: key + ".backup.quarantine") == brokenBackup)
        }
    }

    @Test(arguments: [false, true]) func resetVerwirftAuchSicherungUndQuarantaene(beimStart: Bool) throws {
        try withDefaults { defaults in
            let store = GameStore(saveKey: key, defaults: defaults)
            defaults.set(v16, forKey: key)
            defaults.set(v16, forKey: key + ".backup")
            defaults.set(Data([1]), forKey: key + ".quarantine")
            defaults.set(Data([2]), forKey: key + ".backup.quarantine")
            if beimStart {
                defaults.set(true, forKey: "resetSave")
                _ = GameStore(saveKey: key, defaults: defaults)
                defaults.removeObject(forKey: "resetSave")
            } else {
                store.reset()
            }
            #expect(defaults.data(forKey: key + ".backup") != v16)
            #expect(defaults.object(forKey: key + ".quarantine") == nil)
            #expect(defaults.object(forKey: key + ".backup.quarantine") == nil)
            let next = GameStore(saveKey: key, defaults: defaults)
            #expect(next.money == 4000)
            #expect(next.toast == nil)
        }
    }
}