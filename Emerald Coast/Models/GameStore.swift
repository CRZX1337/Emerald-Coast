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

    // MARK: Laden

    var shelf: [ShelfItem] = []
    var shopOpen: Bool = true
    var todayRevenue: Double = 0
    var todayGrams: Double = 0
    var todayCustomers: Int = 0
    var hourlySales: [Double] = Array(repeating: 0, count: 24)
    var todaySalesByStrain: [String: Double] = [:]
    var queue: [ShopCustomer] = []
    var lastSale: ShopSale?

    private var shopTask: Task<Void, Never>?
    private var dayKey: String = ""
    private var tickCount: Int = 0

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

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
        var shelf: [ShelfItem]?
        var shopOpen: Bool?
        var todayRevenue: Double?
        var todayGrams: Double?
        var todayCustomers: Int?
        var hourlySales: [Double]?
        var dayKey: String?
        var todaySalesByStrain: [String: Double]?
    }

    init() {
        load()
        startShopLoop()
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
        stockShelf(with: strain.id, grams: grams)

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

    // MARK: Laden – Regal

    /// Legt eine Ernte ins Regal. Existiert die Sorte schon, wird aufaddiert.
    func stockShelf(with strainID: String, grams: Double) {
        guard grams > 0 else { return }

        if let index = shelf.firstIndex(where: { $0.strainID == strainID }) {
            shelf[index].grams += grams
        } else {
            let strain = Brands.strain(id: strainID) ?? Strains.base
            let price = (strain.baseValue * valueMultiplier * brandBonus(for: strain)).rounded()
            shelf.append(ShelfItem(strainID: strainID, grams: grams, price: max(1, price)))
        }
        save()
    }

    func shelfItem(_ strainID: String) -> ShelfItem? {
        shelf.first { $0.strainID == strainID }
    }

    func strain(for item: ShelfItem) -> Strain {
        Brands.strain(id: item.strainID) ?? Strains.base
    }

    /// Referenzpreis, den der Laden für diese Sorte verlangt.
    func basePrice(for strain: Strain) -> Double {
        max(1, (strain.baseValue * valueMultiplier * brandBonus(for: strain)).rounded())
    }

    func changePrice(of strainID: String, by delta: Double) {
        guard let index = shelf.firstIndex(where: { $0.strainID == strainID }) else { return }
        let strain = self.strain(for: shelf[index])
        let lower = max(1, (basePrice(for: strain) * 0.5).rounded())
        let upper = (basePrice(for: strain) * 2).rounded()
        let next = min(upper, max(lower, shelf[index].price + delta))

        guard next != shelf[index].price else {
            Haptics.warning()
            return
        }

        shelf[index].price = next
        Haptics.light()
        save()
    }

    /// Wie attraktiv der Preis ist: 1 bei Referenzpreis, sinkt mit jedem Aufschlag.
    func priceAppeal(for item: ShelfItem) -> Double {
        let reference = basePrice(for: strain(for: item))
        guard reference > 0 else { return 1 }
        let ratio = item.price / reference
        return max(0.12, 1.35 - 0.35 * ratio - 0.45 * max(0, ratio - 1))
    }

    var restockCost: Double { 60 }

    /// Füllt ein leeres Regal mit einer kleinen Charge der aktuell gewählten Sorte.
    func restock() {
        guard money >= restockCost else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= restockCost
        stockShelf(with: strain.id, grams: 40)
        Haptics.success()
        showToast("40 g \(strain.name) eingelagert", icon: "shippingbox.fill")
    }

    func toggleShop() {
        shopOpen.toggle()
        Haptics.medium()
        if !shopOpen {
            queue.removeAll()
        }
        save()
    }

    // MARK: Laden – Kunden

    /// Wie viele Kunden pro Tick hereinkommen, abhängig von Preis, Bestand und Level.
    var customerRate: Double {
        guard shopOpen, !shelf.isEmpty else { return 0 }
        let appeal = shelf.map { priceAppeal(for: $0) }.max() ?? 0
        let levelBonus = 1 + Double(level - 1) * 0.06
        return appeal * levelBonus
    }

    private func startShopLoop() {
        shopTask?.cancel()
        shopTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                self?.tickShop()
            }
        }
    }

    /// Ein Takt des Ladens: Kunden kommen herein, warten kurz und kaufen.
    @MainActor
    func tickShop() {
        rollDayIfNeeded()
        tickCount += 1

        guard shopOpen, !shelf.isEmpty else { return }

        if queue.count < 3, Double.random(in: 0...1) < customerRate {
            let stock = shelf.filter { $0.grams > 0 }
            guard let pick = stock.randomElement() else { return }
            let strain = strain(for: pick)
            let grams = [3.5, 7.0, 1.0].randomElement() ?? 3.5
            queue.append(ShopCustomer(strainID: strain.id, grams: min(grams, pick.grams), look: Int.random(in: 0..<6)))
        }

        if tickCount % 2 == 0 {
            serveNextCustomer()
        }
    }

    @MainActor
    private func serveNextCustomer() {
        guard let customer = queue.first else { return }
        queue.removeFirst()

        guard let index = shelf.firstIndex(where: { $0.strainID == customer.strainID }) else { return }
        let item = shelf[index]
        guard item.grams > 0 else { return }

        let grams = min(customer.grams, item.grams)
        let amount = (grams * item.price).rounded()

        shelf[index].grams -= grams
        if shelf[index].grams < 0.05 {
            shelf.remove(at: index)
        }

        money += amount
        xp += grams * 0.35
        todayRevenue += amount
        todayGrams += grams
        todayCustomers += 1

        let hour = Calendar.current.component(.hour, from: Date())
        if hourlySales.indices.contains(hour) {
            hourlySales[hour] += amount
        }

        todaySalesByStrain[item.strainID, default: 0] += grams

        let sale = ShopSale(amount: amount, grams: grams, strainName: strain(for: item).name)
        lastSale = sale

        checkLevelUp()
        Haptics.light()
        save()
    }

    private func rollDayIfNeeded() {
        let today = Self.dayFormatter.string(from: Date())
        guard today != dayKey else { return }

        dayKey = today
        todayRevenue = 0
        todayGrams = 0
        todayCustomers = 0
        hourlySales = Array(repeating: 0, count: 24)
        todaySalesByStrain = [:]
    }

    /// Die meistverkaufte Sorte des Tages.
    var bestSellerToday: (strain: Strain, grams: Double)? {
        guard let top = todaySalesByStrain.max(by: { $0.value < $1.value }),
              top.value > 0 else { return nil }
        let strain = Brands.strain(id: top.key) ?? Strains.base
        return (strain, top.value)
    }

    var bestSeller: ShelfItem? {
        shelf.max { $0.grams < $1.grams }
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
            selectedStrainID: selectedStrainID,
            shelf: shelf,
            shopOpen: shopOpen,
            todayRevenue: todayRevenue,
            todayGrams: todayGrams,
            todayCustomers: todayCustomers,
            hourlySales: hourlySales,
            dayKey: dayKey,
            todaySalesByStrain: todaySalesByStrain
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

        shelf = data.shelf ?? []
        shopOpen = data.shopOpen ?? true
        todayRevenue = data.todayRevenue ?? 0
        todayGrams = data.todayGrams ?? 0
        todayCustomers = data.todayCustomers ?? 0
        hourlySales = data.hourlySales ?? Array(repeating: 0, count: 24)
        todaySalesByStrain = data.todaySalesByStrain ?? [:]
        dayKey = data.dayKey ?? ""
        rollDayIfNeeded()
    }

    /// Beim allerersten Start wächst schon eine Pflanze im ersten Raum,
    /// und das Regal hat eine kleine Startcharge.
    private func seedFirstRun() {
        let duration = strain.baseGrowth * growthMultiplier
        rooms[0].plant = Plant(
            strainID: strain.id,
            plantedAt: Date().addingTimeInterval(-duration * 0.34),
            duration: duration
        )
        dayKey = Self.dayFormatter.string(from: Date())
        shelf = [
            ShelfItem(
                strainID: strain.id,
                grams: 24,
                price: basePrice(for: strain)
            )
        ]
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
        shelf = []
        shopOpen = true
        todayRevenue = 0
        todayGrams = 0
        todayCustomers = 0
        hourlySales = Array(repeating: 0, count: 24)
        todaySalesByStrain = [:]
        dayKey = Self.dayFormatter.string(from: Date())
        queue = []
        lastSale = nil
        Haptics.success()
        showToast("Fortschritt zurückgesetzt", icon: "arrow.counterclockwise")
    }
}
