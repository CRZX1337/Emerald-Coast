//
//  GameStore.swift
//  Emerald Coast
//
//  Der Spielstand: Geld, Level, Grow Rooms, Upgrades – gespeichert in UserDefaults.
//

import Foundation
import Observation

@Observable
final class GameStore {

    // MARK: Zustand

    var money: Double = 250
    var xp: Double = 0
    var level: Int = 1
    var rooms: [GrowRoom] = GrowRoom.defaults
    var upgradeLevels: [String: Int] = [:]
    var selectedRoom: Int = 0
    var totalHarvests: Int = 0
    var licensedBrandIDs: Set<String> = []
    var selectedStrainID: String = Strains.base.id
    var toast: ToastMessage?

    private let saveKey = "emerald-coast-save-v1"

    private struct SaveData: Codable {
        var money: Double
        var xp: Double
        var level: Int
        var rooms: [GrowRoom]
        var upgradeLevels: [String: Int]
        var selectedRoom: Int
        var totalHarvests: Int
        var licensedBrandIDs: [String]?
        var selectedStrainID: String?
    }

    init() {
        load()
    }

    // MARK: Sorte & Boni

    var strain: Strain {
        Brands.strain(id: selectedStrainID) ?? Strains.base
    }

    /// Marken-Bonus auf den Verkaufswert, sobald die Lizenz vorhanden ist.
    func brandBonus(for strain: Strain) -> Double {
        guard strain.brandID != Strains.base.brandID,
              licensedBrandIDs.contains(strain.brandID),
              let brand = Brands.brand(id: strain.brandID) else { return 1 }
        return brand.valueBonus
    }

    func isLicensed(_ brand: Brand) -> Bool {
        licensedBrandIDs.contains(brand.id)
    }

    func unlockedStrainCount(in brand: Brand) -> Int {
        brand.strains.filter { level >= $0.requiredLevel }.count
    }

    func isStrainUnlocked(_ strain: Strain) -> Bool {
        if strain.brandID == Strains.base.brandID { return true }
        guard licensedBrandIDs.contains(strain.brandID) else { return false }
        return level >= strain.requiredLevel
    }

    func licenseBrand(_ brand: Brand) {
        guard !isLicensed(brand) else { return }

        if level < brand.requiredLevel {
            Haptics.warning()
            showToast("Ab Level \(brand.requiredLevel)", icon: "lock.fill")
            return
        }

        guard money >= brand.licensePrice else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= brand.licensePrice
        licensedBrandIDs.insert(brand.id)
        Haptics.success()
        showToast("\(brand.name) lizenziert", icon: "checkmark.seal.fill")
        save()
    }

    func selectStrain(_ strain: Strain) {
        guard isStrainUnlocked(strain) else {
            Haptics.warning()
            if !licensedBrandIDs.contains(strain.brandID) {
                showToast("Erst Lizenz sichern", icon: "lock.fill")
            } else {
                showToast("Ab Level \(strain.requiredLevel)", icon: "lock.fill")
            }
            return
        }

        selectedStrainID = strain.id
        Haptics.medium()
        showToast("\(strain.name) ausgewählt", icon: "leaf.fill")
        save()
    }

    func upgradeLevel(_ id: String) -> Int {
        upgradeLevels[id] ?? 0
    }

    /// Schnellere Lampen verkürzen die Wachstumszeit.
    var growthMultiplier: Double {
        pow(0.93, Double(upgradeLevel("lamps")))
    }

    /// Nährstoffe erhöhen den Ertrag.
    var yieldMultiplier: Double {
        1 + 0.12 * Double(upgradeLevel("nutrients"))
    }

    /// Genetik erhöht den Verkaufswert.
    var valueMultiplier: Double {
        1 + 0.08 * Double(upgradeLevel("genetics"))
    }

    // MARK: Zeit

    func remaining(in room: GrowRoom, now: Date = Date()) -> TimeInterval {
        room.plant?.remaining(now: now) ?? 0
    }

    func progress(in room: GrowRoom, now: Date = Date()) -> Double {
        room.plant?.progress(now: now) ?? 0
    }

    func isReady(_ room: GrowRoom, now: Date = Date()) -> Bool {
        room.plant != nil && remaining(in: room, now: now) <= 0
    }

    var selected: GrowRoom {
        rooms[min(max(0, selectedRoom), rooms.count - 1)]
    }

    // MARK: Level

    func xpNeeded(for level: Int) -> Double {
        50 * pow(1.3, Double(max(0, level - 1)))
    }

    var levelProgress: Double {
        min(1, max(0, xp / xpNeeded(for: level)))
    }

    private func checkLevelUp() {
        while xp >= xpNeeded(for: level) {
            xp -= xpNeeded(for: level)
            level += 1
            Haptics.success()
            showToast("Level \(level) erreicht", icon: "star.fill")
        }
    }

    // MARK: Aktionen

    func plant(in index: Int) {
        guard rooms.indices.contains(index) else { return }
        guard rooms[index].unlocked, rooms[index].plant == nil else { return }

        let duration = strain.baseGrowth * growthMultiplier
        rooms[index].plant = Plant(strainID: strain.id, plantedAt: Date(), duration: duration)
        selectedRoom = index
        Haptics.medium()
        showToast("Samen gesetzt", icon: "leaf.fill")
        save()
    }

    func water(in index: Int) {
        guard rooms.indices.contains(index), var plant = rooms[index].plant else { return }
        guard plant.remaining(now: Date()) > 0 else { return }

        if let last = plant.lastWatered, Date().timeIntervalSince(last) < 8 {
            Haptics.warning()
            showToast("Gleich wieder gießbar", icon: "hourglass")
            return
        }

        plant.timeSaved += plant.duration * 0.12
        plant.lastWatered = Date()
        rooms[index].plant = plant
        Haptics.light()
        save()
    }

    func boostCost(for room: GrowRoom) -> Double {
        let harvestValue = strain.baseYield * yieldMultiplier * strain.baseValue * valueMultiplier
        return max(25, (harvestValue * 0.12 / 5).rounded() * 5)
    }

    func boost(in index: Int) {
        guard rooms.indices.contains(index), var plant = rooms[index].plant else { return }
        guard plant.remaining(now: Date()) > 0 else { return }

        let cost = boostCost(for: rooms[index])
        guard money >= cost else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= cost
        plant.timeSaved += plant.duration * 0.20
        rooms[index].plant = plant
        Haptics.medium()
        save()
    }

    @discardableResult
    func harvest(in index: Int) -> HarvestResult? {
        guard rooms.indices.contains(index), let plant = rooms[index].plant else { return nil }
        guard plant.remaining(now: Date()) <= 0 else {
            Haptics.warning()
            showToast("Noch nicht reif", icon: "clock")
            return nil
        }

        let grams = (strain.baseYield * yieldMultiplier * 10).rounded() / 10
        let earned = (grams * strain.baseValue * valueMultiplier * brandBonus(for: strain)).rounded()
        let result = HarvestResult(grams: grams, earned: earned)

        money += earned
        xp += 14 + grams * 1.2
        rooms[index].plant = nil
        totalHarvests += 1

        checkLevelUp()
        Haptics.success()
        showToast("+\(Format.money(earned)) · \(Format.grams(grams))", icon: "scissors")
        save()
        return result
    }

    func tapRoom(_ index: Int) {
        guard rooms.indices.contains(index) else { return }
        let room = rooms[index]

        if !room.unlocked {
            if level < room.requiredLevel {
                Haptics.warning()
                showToast("Ab Level \(room.requiredLevel)", icon: "lock.fill")
                return
            }
            guard money >= room.price else {
                Haptics.warning()
                showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
                return
            }
            money -= room.price
            rooms[index].unlocked = true
            selectedRoom = index
            Haptics.success()
            showToast("Grow Room \(index + 1) gekauft", icon: "checkmark.seal.fill")
            save()
            return
        }

        selectedRoom = index
        Haptics.light()
    }

    func buyUpgrade(_ def: UpgradeDef) {
        let current = upgradeLevel(def.id)
        guard current < def.maxLevel else { return }

        let cost = def.cost(level: current)
        guard money >= cost else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= cost
        upgradeLevels[def.id] = current + 1
        Haptics.success()
        showToast("\(def.name) · Stufe \(current + 1)", icon: def.icon)
        save()
    }

    // MARK: Toast

    func showToast(_ text: String, icon: String) {
        toast = ToastMessage(text: text, icon: icon)
    }

    func clearToast(_ id: UUID) {
        if toast?.id == id {
            toast = nil
        }
    }

    // MARK: Speichern

    func save() {
        let data = SaveData(
            money: money,
            xp: xp,
            level: level,
            rooms: rooms,
            upgradeLevels: upgradeLevels,
            selectedRoom: selectedRoom,
            totalHarvests: totalHarvests,
            licensedBrandIDs: Array(licensedBrandIDs),
            selectedStrainID: selectedStrainID
        )
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        UserDefaults.standard.set(encoded, forKey: saveKey)
    }

    private func load() {
        guard let raw = UserDefaults.standard.data(forKey: saveKey),
              let data = try? JSONDecoder().decode(SaveData.self, from: raw) else {
            seedFirstRun()
            return
        }

        money = data.money
        xp = data.xp
        level = max(1, data.level)
        rooms = data.rooms.isEmpty ? GrowRoom.defaults : data.rooms
        upgradeLevels = data.upgradeLevels
        totalHarvests = data.totalHarvests
        selectedRoom = min(max(0, data.selectedRoom), max(0, rooms.count - 1))
        licensedBrandIDs = Set(data.licensedBrandIDs ?? [])

        let savedStrain = Brands.strain(id: data.selectedStrainID ?? Strains.base.id) ?? Strains.base
        if isStrainUnlocked(savedStrain) {
            selectedStrainID = savedStrain.id
        } else {
            selectedStrainID = Strains.base.id
        }
    }

    /// Beim allerersten Start wächst schon eine Pflanze im ersten Raum.
    private func seedFirstRun() {
        let duration = strain.baseGrowth * growthMultiplier
        rooms[0].plant = Plant(
            strainID: strain.id,
            plantedAt: Date().addingTimeInterval(-duration * 0.34),
            duration: duration
        )
        save()
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: saveKey)
        money = 250
        xp = 0
        level = 1
        rooms = GrowRoom.defaults
        upgradeLevels = [:]
        selectedRoom = 0
        totalHarvests = 0
        licensedBrandIDs = []
        selectedStrainID = Strains.base.id
        Haptics.success()
        showToast("Fortschritt zurückgesetzt", icon: "arrow.counterclockwise")
    }
}
