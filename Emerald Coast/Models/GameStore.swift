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

    var money: Double = 4_000
    var xp: Double = 0
    var level: Int = 1
    var rooms: [GrowRoom] = GrowRoom.defaults
    var upgradeLevels: [String: Int] = [:]
    var selectedRoom: Int = 0
    var totalHarvests: Int = 0
    var licensedBrandIDs: Set<String> = []
    var selectedStrainID: String = Strains.base.id
    var toast: ToastMessage?
    /// Umsatz der letzten sieben abgeschlossenen Tage.
    var dailyHistory: [Double] = []

    // MARK: Laden

    var shelf: [ShelfItem] = []
    var shopOpen: Bool = true
    var todayRevenue: Double = 0
    var todayFees: Double = 0
    var todayGrams: Double = 0
    var todayCustomers: Int = 0
    var hourlySales: [Double] = Array(repeating: 0, count: 24)
    var todaySalesByStrain: [String: Double] = [:]
    var queue: [ShopCustomer] = []
    var lastSale: ShopSale?

    // MARK: Crew

    var crew: [CrewMember] = []
    var applicants: [CrewApplicant] = []
    var wagesPaidToday: Double = 0
    var crewHarvestsToday: Int = 0
    var crewSalesToday: Int = 0

    private var crewTask: Task<Void, Never>?
    private var crewTickCount: Int = 0
    private var wageCarry: Double = 0

    // MARK: Flotte

    var drivers: [DeliveryDriver] = []
    var orders: [DeliveryOrder] = []
    var trips: [DeliveryTrip] = []
    var deliveriesToday: Int = 0
    var tipsToday: Double = 0
    var driverHireCost: Double = 0

    private var fleetTask: Task<Void, Never>?
    private var orderTask: Task<Void, Never>?
    private var orderTickCount: Int = 0

    // MARK: Permits & Compliance

    /// Viertel, für die ein Permit vorliegt.
    var permittedDistrictIDs: Set<String> = []
    /// 0…100. Steigt bei Verstößen, sinkt von selbst wieder.
    var heat: Double = 0
    var inspectionsToday: Int = 0
    var finesToday: Double = 0
    /// Läuft gerade die bezahlte Buchhaltung?
    var accountingUntil: Date?
    /// Bis wann der Laden nach einer Kontrolle geschlossen bleibt.
    var shutdownUntil: Date?

    private var complianceTask: Task<Void, Never>?

    private var shopTask: Task<Void, Never>?
    private var dayKey: String = ""
    private var tickCount: Int = 0

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private let defaults: UserDefaults
    private let saveKey: String

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
        var todayFees: Double?
        var dailyHistory: [Double]?
        var todayGrams: Double?
        var todayCustomers: Int?
        var hourlySales: [Double]?
        var dayKey: String?
        var todaySalesByStrain: [String: Double]?
        var crew: [CrewMember]?
        var applicants: [CrewApplicant]?
        var wagesPaidToday: Double?
        var crewHarvestsToday: Int?
        var crewSalesToday: Int?
        var drivers: [DeliveryDriver]?
        var orders: [DeliveryOrder]?
        var trips: [DeliveryTrip]?
        var deliveriesToday: Int?
        var tipsToday: Double?
        var driverHireCost: Double?
        var permittedDistrictIDs: [String]?
        var heat: Double?
        var inspectionsToday: Int?
        var finesToday: Double?
        var accountingUntil: Date?
        var shutdownUntil: Date?
    }

    init(saveKey: String = "emerald-coast-save-v1", defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.saveKey = saveKey
        if defaults.bool(forKey: "resetSave") {
            clearSaveFiles()
        }
        load()
        refreshApplicantsIfNeeded()
        refreshOrdersIfNeeded()
        startShopLoop()
        startCrewLoop()
        startFleetLoop()
        startOrderLoop()
        startComplianceLoop()
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

    /// Sorte, die für einen konkreten Grow Room ausgewählt ist.
    func strain(for room: GrowRoom) -> Strain {
        let id = room.selectionID ?? selectedStrainID
        return Brands.strain(id: id) ?? Strains.base
    }

    /// Stabile Auswahl-Prüfung für die Sortenliste.
    func isStrainSelected(_ strain: Strain) -> Bool {
        guard rooms.indices.contains(selectedRoom) else {
            return selectedStrainID == strain.id
        }
        return self.strain(for: rooms[selectedRoom]).id == strain.id
    }

    /// Royalty-Satz, der beim Verkauf einer lizenzierten Marke abgeht.
    func licensedRoyalty(for strain: Strain) -> Double {
        guard strain.brandID != Strains.base.brandID,
              licensedBrandIDs.contains(strain.brandID),
              let brand = Brands.brand(id: strain.brandID) else { return 0 }
        return brand.royaltyRate
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
        refreshShelfPrices()
        Haptics.success()
        showToast("\(brand.name) lizenziert", icon: "checkmark.seal.fill")
        save()
    }

    /// Setzt die Regalpreise auf den aktuellen Vorschlagspreis zurück.
    func refreshShelfPrices() {
        for index in shelf.indices {
            let plantStrain = strain(for: shelf[index])
            shelf[index].price = basePrice(for: plantStrain)
        }
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
        if rooms.indices.contains(selectedRoom) {
            rooms[selectedRoom].selectionID = strain.id
        }
        Haptics.medium()
        showToast("\(strain.name) ausgewählt", icon: "leaf.fill")
        save()
    }

    func upgradeLevel(_ id: String) -> Int {
        upgradeLevels[id] ?? 0
    }

    /// Schnellere Lampen verkürzen die Wachstumszeit.
    var growthMultiplier: Double {
        pow(0.94, Double(upgradeLevel("lamps")))
    }

    /// Nährstoffe erhöhen den Ertrag.
    var yieldMultiplier: Double {
        1 + 0.08 * Double(upgradeLevel("nutrients"))
    }

    /// Genetik erhöht den Verkaufswert.
    var valueMultiplier: Double {
        1 + 0.06 * Double(upgradeLevel("genetics"))
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

    /// Was ein Grow Room pro Batch kostet: Strom, Medium, Nährstoffe, Miete.
    func plantCost(for strain: Strain) -> Double {
        let expected = strain.baseYield * yieldMultiplier
        let seeds = strain.seedPrice * 4
        let raw = expected * 1.05 + 95 + seeds
        return max(145, (raw / 5).rounded() * 5)
    }

    func plant(in index: Int) {
        guard rooms.indices.contains(index) else { return }
        guard rooms[index].unlocked, rooms[index].plant == nil else { return }

        let plantStrain = strain(for: rooms[index])
        let cost = plantCost(for: plantStrain)
        guard money >= cost else {
            Haptics.warning()
            showToast("Nicht genug Geld für den Batch", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= cost
        let duration = plantStrain.baseGrowth * growthMultiplier
        rooms[index].plant = Plant(
            strainID: plantStrain.id,
            plantedAt: Date(),
            duration: duration,
            waterings: 0,
            feedings: 0,
            boosted: false,
            batchCost: cost,
            pheno: Double.random(in: 0.92...1.08)
        )
        selectedRoom = index
        Haptics.medium()
        showToast("Batch gesetzt · -\(Format.money(cost))", icon: "leaf.fill")
        save()
    }

    func water(in index: Int) {
        guard rooms.indices.contains(index), var plant = rooms[index].plant else { return }
        guard plant.remaining(now: Date()) > 0 else { return }
        guard !plant.hasWatered else {
            Haptics.warning()
            showToast("Schon gegossen – nur 1× pro Batch", icon: "drop.slash")
            return
        }

        plant.timeSaved += plant.duration * 0.04
        plant.lastWatered = Date()
        plant.waterings = 1
        rooms[index].plant = plant
        Haptics.light()
        save()
    }

    /// Düngen kostet Geld und ist pro Batch auf drei Gaben begrenzt.
    func feedCost(for strain: Strain) -> Double {
        max(18, (plantCost(for: strain) * 0.12 / 2).rounded() * 2)
    }

    func feed(in index: Int) {
        guard rooms.indices.contains(index), var plant = rooms[index].plant else { return }
        guard plant.remaining(now: Date()) > 0 else { return }
        guard plant.feedCount < 3 else {
            Haptics.warning()
            showToast("Maximal 3× düngen pro Batch", icon: "flask")
            return
        }

        let strain = Brands.strain(id: plant.strainID) ?? Strains.base
        let cost = feedCost(for: strain)
        guard money >= cost else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= cost
        plant.feedings = plant.feedCount + 1
        plant.batchCost = (plant.batchCost ?? 0) + cost
        rooms[index].plant = plant
        Haptics.medium()
        showToast("Gedüngt · +5 % Ertrag · -\(Format.money(cost))", icon: "drop.fill")
        save()
    }

    func boostCost(for room: GrowRoom) -> Double {
        let plantStrain = room.plant.flatMap { Brands.strain(id: $0.strainID) } ?? strain
        let harvestValue = plantStrain.baseYield * yieldMultiplier * plantStrain.baseValue * valueMultiplier
        return max(45, (harvestValue * 0.05 / 5).rounded() * 5)
    }

    func boost(in index: Int) {
        guard rooms.indices.contains(index), var plant = rooms[index].plant else { return }
        guard plant.remaining(now: Date()) > 0 else { return }
        guard !plant.isBoosted else {
            Haptics.warning()
            showToast("Batch ist schon geboostet", icon: "bolt.slash")
            return
        }

        let cost = boostCost(for: rooms[index])
        guard money >= cost else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= cost
        plant.timeSaved += plant.duration * 0.10
        plant.boosted = true
        rooms[index].plant = plant
        Haptics.medium()
        showToast("Boost · -\(Format.money(cost))", icon: "bolt.fill")
        save()
    }

    /// Ertrag eines Batches. Düngung wirkt nur auf diesen Batch.
    func harvestGrams(for strain: Strain, plant: Plant) -> Double {
        let care = 1 + 0.05 * Double(plant.feedCount)
        let pheno = plant.pheno ?? 1
        return (strain.baseYield * yieldMultiplier * care * pheno * districtYieldMultiplier * 10).rounded() / 10
    }

    @discardableResult
    func harvest(in index: Int) -> HarvestResult? {
        guard rooms.indices.contains(index), let plant = rooms[index].plant else { return nil }
        guard plant.remaining(now: Date()) <= 0 else {
            Haptics.warning()
            showToast("Noch nicht reif", icon: "clock")
            return nil
        }

        let plantStrain = Brands.strain(id: plant.strainID) ?? Strains.base
        let grams = harvestGrams(for: plantStrain, plant: plant)
        let cost = plant.batchCost ?? plantCost(for: plantStrain)
        let result = HarvestResult(grams: grams, value: grams * plantStrain.wholesaleValue)

        rooms[index].plant = nil
        totalHarvests += 1
        stockShelf(
            with: plantStrain.id,
            grams: grams,
            unitCost: (cost + grams * 0.50) / grams
        )
        xp += 8 + grams * 0.25

        checkLevelUp()
        Haptics.success()
        showToast("\(Format.grams(grams)) ins Regal", icon: "shippingbox")
        save()
        return result
    }

    /// Ernte ohne Ton und Toast – für die Automatik der Grower.
    @discardableResult
    func silentHarvest(in index: Int) -> Bool {
        guard rooms.indices.contains(index), let plant = rooms[index].plant else { return false }
        guard plant.remaining(now: Date()) <= 0 else { return false }

        let plantStrain = Brands.strain(id: plant.strainID) ?? Strains.base
        let grams = harvestGrams(for: plantStrain, plant: plant)
        let cost = plant.batchCost ?? plantCost(for: plantStrain)

        rooms[index].plant = nil
        totalHarvests += 1
        stockShelf(
            with: plantStrain.id,
            grams: grams,
            unitCost: (cost + grams * 0.50) / grams
        )
        xp += 8 + grams * 0.25
        checkLevelUp()
        return true
    }

    /// Pflanzt ohne Ton und Toast – für die Automatik der Grower.
    @discardableResult
    func silentPlant(in index: Int) -> Bool {
        guard rooms.indices.contains(index) else { return false }
        guard rooms[index].unlocked, rooms[index].plant == nil else { return false }

        let plantStrain = strain(for: rooms[index])
        let cost = plantCost(for: plantStrain)
        guard money >= cost else { return false }

        money -= cost
        let duration = plantStrain.baseGrowth * growthMultiplier
        rooms[index].plant = Plant(
            strainID: plantStrain.id,
            plantedAt: Date(),
            duration: duration,
            waterings: 0,
            feedings: 0,
            boosted: false,
            batchCost: cost,
            pheno: Double.random(in: 0.92...1.08)
        )
        return true
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
        if def.id == "genetics" {
            refreshShelfPrices()
        }
        Haptics.success()
        showToast("\(def.name) · Stufe \(current + 1)", icon: def.icon)
        save()
    }

    // MARK: Laden – Regal

    /// Legt Ware ins Regal. `unitCost` ist der Einstand pro Gramm.
    func stockShelf(with strainID: String, grams: Double, unitCost: Double? = nil) {
        guard grams > 0 else { return }

        let plantStrain = Brands.strain(id: strainID) ?? Strains.base
        let cost = unitCost ?? plantStrain.wholesaleValue

        if let index = shelf.firstIndex(where: { $0.strainID == strainID }) {
            let oldGrams = shelf[index].grams
            let oldCost = shelf[index].unitCost ?? cost
            shelf[index].grams += grams
            shelf[index].unitCost = (oldCost * oldGrams + cost * grams) / (oldGrams + grams)
        } else {
            let price = max(1, (plantStrain.baseValue * valueMultiplier * brandBonus(for: plantStrain)).rounded())
            shelf.append(ShelfItem(strainID: strainID, grams: grams, price: price, unitCost: cost))
        }
        save()
    }

    func shelfItem(_ strainID: String) -> ShelfItem? {
        shelf.first { $0.strainID == strainID }
    }

    func strain(for item: ShelfItem) -> Strain {
        Brands.strain(id: item.strainID) ?? Strains.base
    }

    /// Vorschlagspreis, den der Laden für diese Sorte verlangt.
    func basePrice(for strain: Strain) -> Double {
        max(1, (strain.baseValue * valueMultiplier * brandBonus(for: strain) * districtPriceMultiplier).rounded())
    }

    func changePrice(of strainID: String, by delta: Double) {
        guard let index = shelf.firstIndex(where: { $0.strainID == strainID }) else { return }
        let plantStrain = strain(for: shelf[index])
        let reference = basePrice(for: plantStrain)
        let lower = max(1, (reference * 0.70).rounded())
        let upper = (reference * 1.60).rounded()
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
        return max(0.10, 1.35 - 0.35 * ratio - 0.45 * max(0, ratio - 1))
    }

    /// Einkaufspreis für 40 g beim Großhändler (Wholesale + 15 % Handling).
    var restockCost: Double {
        max(20, (strain.wholesaleValue * 40 * 1.15 / 5).rounded() * 5)
    }

    /// Füllt ein leeres Regal mit einer kleinen Charge der aktuell gewählten Sorte.
    func restock() {
        let cost = restockCost
        guard money >= cost else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= cost
        stockShelf(with: strain.id, grams: 40, unitCost: cost / 40)
        Haptics.success()
        showToast("40 g \(strain.name) eingekauft · -\(Format.money(cost))", icon: "shippingbox.fill")
    }

    func toggleShop() {
        if isShutDown {
            Haptics.warning()
            showToast("Wegen Kontrolle geschlossen · noch \(Format.clock(shutdownRemaining))", icon: "exclamationmark.octagon.fill")
            return
        }

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
        let totalGrams = shelf.reduce(0) { $0 + $1.grams }
        guard totalGrams > 0 else { return 0 }

        let weightedAppeal = shelf.reduce(0.0) { partial, item in
            partial + priceAppeal(for: item) * item.grams
        } / totalGrams
        let levelBonus = 1 + Double(level - 1) * 0.04
        return min(1.2, max(0, weightedAppeal * levelBonus * districtCustomerMultiplier))
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

        guard shopOpen, !shelf.isEmpty, !isShutDown else { return }

        if queue.count < 3, Double.random(in: 0...1) < customerRate {
            let stock = shelf.filter { $0.grams >= 1 }
            guard !stock.isEmpty else { return }

            // Kunden wählen nach Preis-Attraktivität und verfügbarer Menge.
            let weights = stock.map { max(0.05, priceAppeal(for: $0)) * $0.grams }
            let totalWeight = weights.reduce(0, +)
            guard totalWeight > 0 else { return }

            var roll = Double.random(in: 0..<totalWeight)
            var pick = stock[0]
            for (index, item) in stock.enumerated() {
                roll -= weights[index]
                if roll <= 0 {
                    pick = item
                    break
                }
            }

            let plantStrain = strain(for: pick)
            let grams = [3.5, 7.0, 1.0].randomElement() ?? 3.5
            queue.append(ShopCustomer(strainID: plantStrain.id, grams: min(grams, pick.grams), look: Int.random(in: 0..<6)))
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
        let gross = (grams * item.price).rounded()

        // Steuern und Abgaben: 15 % Excise, Royalty an die Marke,
        // 5 % Budtender-Provision, wenn Personal im Laden steht.
        let excise = (gross * 0.15 * 100).rounded() / 100
        let royaltyRate = licensedRoyalty(for: strain(for: item))
        let royalty = (gross * royaltyRate * 100).rounded() / 100
        let commission = (members(.budtender).isEmpty ? 0 : gross * 0.05 * 100).rounded() / 100
        let net = max(0, gross - excise - royalty - commission)

        shelf[index].grams -= grams
        if shelf[index].grams < 0.05 {
            shelf.remove(at: index)
        }

        money += net
        xp += grams * 0.35
        todayRevenue += gross
        todayFees += excise + royalty + commission
        todayGrams += grams
        todayCustomers += 1

        let hour = Calendar.current.component(.hour, from: Date())
        if hourlySales.indices.contains(hour) {
            hourlySales[hour] += gross
        }

        todaySalesByStrain[item.strainID, default: 0] += grams

        // Compliance: ohne Humboldt-Permit und unter Einstand wird es heiß.
        if !hasPermit(Districts.home) {
            addHeat(Compliance.heatPerUnlicensedSale)
        }
        let unitCost = item.unitCost ?? strain(for: item).wholesaleValue
        if item.price < unitCost {
            addHeat(Compliance.heatPerBelowCostSale)
        }

        let sale = ShopSale(amount: net, grams: grams, strainName: strain(for: item).name)
        lastSale = sale

        checkLevelUp()
        Haptics.light()
        save()
    }

    private func rollDayIfNeeded() {
        let today = Self.dayFormatter.string(from: Date())
        guard today != dayKey else { return }

        // Alten Tag für den Wochen-Chart archivieren.
        if !dayKey.isEmpty {
            dailyHistory.append(todayRevenue)
            if dailyHistory.count > 7 {
                dailyHistory.removeFirst(dailyHistory.count - 7)
            }
        }

        dayKey = today
        todayRevenue = 0
        todayFees = 0
        todayGrams = 0
        todayCustomers = 0
        hourlySales = Array(repeating: 0, count: 24)
        todaySalesByStrain = [:]
        wagesPaidToday = 0
        crewHarvestsToday = 0
        crewSalesToday = 0
        deliveriesToday = 0
        tipsToday = 0
        inspectionsToday = 0
        finesToday = 0
    }

    /// Sieben Tageswerte + heute, für den Wochen-Chart.
    var weekBars: [Double] {
        var bars = Array(dailyHistory.suffix(6))
        while bars.count < 6 { bars.insert(0.0, at: 0) }
        bars.append(todayRevenue)
        return bars
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

    // MARK: Crew – Kennzahlen

    func members(_ role: CrewRole) -> [CrewMember] {
        crew.filter { $0.role == role }
    }

    /// Tempo einer Person: Aktionen pro Minute.
    func actionsPerMinute(for member: CrewMember) -> Double {
        let skillFactor = 0.85 + 0.12 * Double(member.skill)
        let levelFactor = 1 + 0.18 * Double(member.level - 1)
        return member.role.baseActions * skillFactor * levelFactor
    }

    /// Tageslohn einer Person (eine Schicht).
    func wage(for member: CrewMember) -> Double {
        let skillFactor = 0.8 + 0.16 * Double(member.skill)
        let levelFactor = 1 + 0.12 * Double(member.level - 1)
        return (member.role.baseWage * skillFactor * levelFactor * 10).rounded() / 10
    }

    var totalWagesPerDay: Double {
        crew.reduce(0) { $0 + wage(for: $1) }
    }

    var wagesPerDay: Double {
        totalWagesPerDay
    }

    /// Erwarteter Umsatz der Crew pro Tag (ein Spieltag = ein Batch-Zyklus).
    var crewRevenuePerDay: Double {
        let growerActions = members(.grower).reduce(0) { $0 + actionsPerMinute(for: $1) }
        let budtenderActions = members(.budtender).reduce(0) { $0 + actionsPerMinute(for: $1) }

        let gramsPerHarvest = strain.baseYield * yieldMultiplier
        let price = shelf.first.map { $0.price } ?? basePrice(for: strain)
        let growIncome = growerActions * gramsPerHarvest * price * 0.80
        let sellIncome = budtenderActions * 3.5 * price
        return growIncome + sellIncome
    }

    var crewNetPerDay: Double {
        crewRevenuePerDay - wagesPerDay
    }

    // MARK: Crew – Einstellen und Entlassen

    func hire(_ applicant: CrewApplicant) {
        guard crew.count < 8 else {
            Haptics.warning()
            showToast("Team ist voll", icon: "person.3.fill")
            return
        }
        guard money >= applicant.hireCost else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= applicant.hireCost
        var member = CrewMember(
            name: applicant.name,
            role: applicant.role,
            skill: applicant.skill,
            look: applicant.look
        )
        member.id = applicant.id
        crew.append(member)
        applicants.removeAll { $0.id == applicant.id }
        Haptics.success()
        showToast("\(applicant.name) eingestellt", icon: "person.badge.plus")
        refreshApplicantsIfNeeded()
        save()
    }

    func fire(_ member: CrewMember) {
        crew.removeAll { $0.id == member.id }
        Haptics.medium()
        showToast("\(member.name) entlassen", icon: "person.badge.minus")
        refreshApplicantsIfNeeded()
        save()
    }

    /// Hält drei Bewerber im Angebot.
    func refreshApplicantsIfNeeded(force: Bool = false) {
        guard force || applicants.count < 3 else { return }

        var used = Set(crew.map(\.name)).union(applicants.map(\.name))
        while applicants.count < 3 {
            let role = Bool.random() ? CrewRole.grower : CrewRole.budtender
            let skill = Int.random(in: 1...5)
            let name = CrewNames.random(excluding: used)
            used.insert(name)

            let cost = ((40 + Double(skill) * 55) * (role == .grower ? 1.15 : 1.0) * 10).rounded()
            applicants.append(
                CrewApplicant(name: name, role: role, skill: skill, look: Int.random(in: 0..<6), hireCost: cost)
            )
        }
    }

    // MARK: Crew – Automatik

    private func startCrewLoop() {
        crewTask?.cancel()
        crewTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.tickCrew()
            }
        }
    }

    /// Ein Takt pro Sekunde: Löhne laufen, Grower und Budtender arbeiten.
    @MainActor
    func tickCrew() {
        rollDayIfNeeded()
        guard !crew.isEmpty else { return }

        crewTickCount += 1

        // Löhne: ein Spieltag entspricht einem Batch-Zyklus (60 s).
        wageCarry += totalWagesPerDay / 60
        if wageCarry >= 1 {
            let due = wageCarry.rounded(.down)
            wageCarry -= due
            let paid = min(money, due)
            money -= paid
            wagesPaidToday += paid
        }

        let growerActions = members(.grower).reduce(0) { $0 + actionsPerMinute(for: $1) } / 60
        let budtenderActions = members(.budtender).reduce(0) { $0 + actionsPerMinute(for: $1) } / 60

        if growerActions > 0, Double.random(in: 0...1) < min(1, growerActions * 3) {
            runGrowerWork()
        }

        if budtenderActions > 0, Double.random(in: 0...1) < min(1, budtenderActions) {
            runBudtenderWork()
        }

        if crewTickCount % 5 == 0 {
            levelUpCrew()
            save()
        }
    }

    private func runGrowerWork() {
        var didWork = false

        for index in rooms.indices where rooms[index].unlocked {
            if silentHarvest(in: index) {
                crewHarvestsToday += 1
                didWork = true
                silentPlant(in: index)
                break
            }
        }

        if !didWork {
            for index in rooms.indices where rooms[index].unlocked && rooms[index].plant == nil {
                if silentPlant(in: index) {
                    didWork = true
                    break
                }
            }
        }
    }

    @MainActor
    private func runBudtenderWork() {
        guard shopOpen, !queue.isEmpty else { return }
        serveNextCustomer()
        crewSalesToday += 1
    }

    private func levelUpCrew() {
        for index in crew.indices {
            guard crew[index].level < 20 else { continue }
            crew[index].xp += Double.random(in: 4...9) * Double(crew[index].skill)
            while crew[index].xp >= crew[index].xpNeeded, crew[index].level < 20 {
                crew[index].xp -= crew[index].xpNeeded
                crew[index].level += 1
            }
        }
    }

    // MARK: Flotte – Fahrer

    /// Kosten für den nächsten Fahrer; steigt mit jedem Angestellten.
    var nextDriverCost: Double {
        (900 * pow(1.55, Double(drivers.count)) / 10).rounded() * 10
    }

    var maxDrivers: Int { 6 }

    func hireDriver() {
        guard drivers.count < maxDrivers else {
            Haptics.warning()
            showToast("Flotte ist voll", icon: "car.2.fill")
            return
        }

        let cost = nextDriverCost
        guard money >= cost else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= cost
        let used = Set(drivers.map(\.name))
        let name = CrewNames.random(excluding: used)

        drivers.append(
            DeliveryDriver(
                name: name,
                vehicle: .car,
                look: Int.random(in: 0..<6)
            )
        )
        Haptics.success()
        showToast("\(name) fährt für dich", icon: "car.fill")
        save()
    }

    func upgradeVehicle(for driver: DeliveryDriver) {
        guard let index = drivers.firstIndex(where: { $0.id == driver.id }),
              let next = drivers[index].vehicle.next else { return }

        guard money >= next.upgradeCost else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= next.upgradeCost
        drivers[index].vehicle = next
        Haptics.success()
        showToast("\(drivers[index].name) · \(next.name)", icon: next.icon)
        save()
    }

    func isDriverBusy(_ driver: DeliveryDriver) -> Bool {
        trips.contains { $0.driverID == driver.id }
    }

    func fireDriver(_ driver: DeliveryDriver) {
        drivers.removeAll { $0.id == driver.id }
        Haptics.medium()
        showToast("\(driver.name) entlassen", icon: "person.badge.minus")
        save()
    }

    func currentTrip(for driver: DeliveryDriver) -> DeliveryTrip? {
        trips.first { $0.driverID == driver.id }
    }

    // MARK: Flotte – Aufträge

    /// Warenwert (Wholesale) + Lieferpauschale. Kein Retail-Aufschlag.
    func orderValue(grams: Double, strain: Strain, city: DeliveryCity) -> Double {
        let goods = grams * strain.wholesaleValue * brandBonus(for: strain)
        let fee = 18 + city.distance * 0.10
        return (goods + fee).rounded()
    }

    /// Trinkgeld: ca. 10 % des Warenwerts.
    func orderTip(value: Double, city: DeliveryCity) -> Double {
        max(3, (value * 0.10).rounded())
    }

    /// Was die Fahrt kostet: Fahrerlohn + Sprit/Mileage.
    func driverCost(for order: DeliveryOrder) -> Double {
        (28 + order.city.distance * 0.55).rounded()
    }

    func fleetQuote(for order: DeliveryOrder) -> FleetQuote {
        let fallback = (Brands.strain(id: order.strainID) ?? Strains.base).wholesaleValue
        let unitCost = shelfItem(order.strainID)?.unitCost ?? fallback
        return FleetQuote(cashChangeCents: Int(((order.value + order.tip - driverCost(for: order)) * 100).rounded()),
                         goodsCostCents: Int((unitCost * order.grams * 100).rounded()))
    }

    /// Wie viele offene Aufträge gleichzeitig möglich sind – mehr Fahrer, mehr Volumen.
    var maxOpenOrders: Int {
        min(6, 2 + drivers.count)
    }

    /// Legt einen neuen Auftrag an, solange das Regal Ware hat.
    func spawnOrder() {
        guard orders.count < maxOpenOrders else { return }
        guard let item = shelf.filter({ $0.grams >= 28 }).randomElement() else { return }

        // Nur Städte mit Permit bekommen Aufträge.
        let cities = DeliveryCities.destinations.filter { canDeliver(to: $0) }
        guard let city = cities.randomElement() else { return }

        let wanted = [28.0, 56.0, 112.0].map { $0 * districtOrderMultiplier }.randomElement() ?? 28.0
        let grams = min(wanted, item.grams)
        guard grams >= 28 else { return }

        let plantStrain = strain(for: item)
        let value = orderValue(grams: grams, strain: plantStrain, city: city)
        let tip = orderTip(value: value, city: city)

        orders.append(
            DeliveryOrder(
                cityID: city.id,
                strainID: item.strainID,
                grams: grams,
                value: value,
                tip: tip
            )
        )
        save()
    }

    func refreshOrdersIfNeeded() {
        guard !drivers.isEmpty else { return }
        if orders.isEmpty {
            spawnOrder()
        }
    }

    /// Schickt einen Fahrer mit einem Auftrag auf die Straße.
    @discardableResult
    func dispatch(order: DeliveryOrder, driver: DeliveryDriver) -> Bool {
        guard let driverIndex = drivers.firstIndex(where: { $0.id == driver.id }) else { return false }
        guard !isDriverBusy(driver) else {
            Haptics.warning()
            showToast("\(driver.name) ist unterwegs", icon: "clock")
            return false
        }
        guard let orderIndex = orders.firstIndex(where: { $0.id == order.id }) else { return false }

        guard canDeliver(to: order.city) else {
            Haptics.warning()
            showToast("Kein Permit für \(order.city.name)", icon: "lock.fill")
            return false
        }

        // Die Ware verlässt beim Losfahren das Regal.
        guard let itemIndex = shelf.firstIndex(where: { $0.strainID == order.strainID }),
              shelf[itemIndex].grams >= order.grams else {
            Haptics.warning()
            showToast("Nicht genug Ware im Regal", icon: "shippingbox")
            return false
        }

        let vehicle = drivers[driverIndex].vehicle
        let city = order.city
        let duration = vehicle.tripDuration(for: city.distance)

        let quote = fleetQuote(for: order)
        guard money + 0.000001 >= quote.departureCost else {
            showToast("Guthaben reicht nicht für den Fahrtverlust", icon: "exclamationmark.triangle")
            return false
        }
        money = max(0, money - quote.departureCost)
        shelf[itemIndex].grams -= order.grams
        if shelf[itemIndex].grams < 0.05 {
            shelf.remove(at: itemIndex)
        }

        trips.append(
            DeliveryTrip(order: order, driverID: driver.id, quote: quote, duration: duration)
        )
        orders.remove(at: orderIndex)

        Haptics.medium()
        showToast("\(driver.name) → \(city.name)", icon: "box.truck.fill")
        save()
        return true
    }

    func progress(of trip: DeliveryTrip, now: Date = Date()) -> Double {
        trip.progress(now: now)
    }

    func remaining(of trip: DeliveryTrip, now: Date = Date()) -> TimeInterval {
        trip.remaining(now: now)
    }

    /// Position des Fahrers auf der Karte, 0 = Humboldt, 1 = Ziel.
    func mapPosition(for trip: DeliveryTrip, now: Date = Date()) -> CGPoint {
        let city = trip.order.city
        let t = CGFloat(progress(of: trip, now: now))
        let start = CGPoint(x: DeliveryCities.home.x, y: DeliveryCities.home.y)
        let end = CGPoint(x: city.x, y: city.y)
        return CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
    }

    private func startFleetLoop() {
        fleetTask?.cancel()
        fleetTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.tickFleet()
            }
        }
    }

    private func startOrderLoop() {
        orderTask?.cancel()
        orderTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.tickOrders()
            }
        }
    }

    /// Bringt Fahrten voran und liefert ab, was angekommen ist.
    @MainActor
    func tickFleet() {
        guard !trips.isEmpty else { return }

        let now = Date()
        let finished = trips.filter { $0.remaining(now: now) <= 0 }
        guard !finished.isEmpty else { return }

        for trip in finished {
            completeTrip(trip)
        }
        trips.removeAll { trip in finished.contains(where: { $0.id == trip.id }) }
        save()
    }

    private func completeTrip(_ trip: DeliveryTrip) {
        let gross = trip.order.value + trip.order.tip
        let cost = driverCost(for: trip.order)
        let net = trip.quote?.arrivalPayment ?? max(0, gross - cost)

        money += net
        todayFees += cost
        xp += 2 + trip.order.grams * 0.4
        deliveriesToday += 1
        tipsToday += trip.order.tip

        if let index = drivers.firstIndex(where: { $0.id == trip.driverID }) {
            drivers[index].completedTrips += 1
        }

        checkLevelUp()
        Haptics.success()
        let result = trip.quote.map { "Gewinn " + Format.cents($0.profitCents) } ?? "Auszahlung " + Format.money(net)
        showToast("\(trip.order.city.name) · \(result)", icon: "checkmark.circle.fill")
    }

    /// Neue Bestellungen treffen ein, abhängig von der Flottengröße.
    @MainActor
    func tickOrders() {
        rollDayIfNeeded()
        orderTickCount += 1

        guard !drivers.isEmpty, orders.count < maxOpenOrders else { return }
        guard shelf.contains(where: { $0.grams >= 28 }) else { return }
        guard DeliveryCities.destinations.contains(where: { canDeliver(to: $0) }) else { return }

        let chance = min(0.85, 0.18 + Double(drivers.count) * 0.14)
        if Double.random(in: 0...1) < chance {
            spawnOrder()
        }
    }

    // MARK: Permits

    func hasPermit(_ district: District) -> Bool {
        permittedDistrictIDs.contains(district.id)
    }

    /// Hat das Viertel ein Permit und wirkt sein Bonus dadurch?
    func isBonusActive(_ district: District) -> Bool {
        hasPermit(district)
    }

    /// Ertragsbonus aus dem Humboldt-Permit.
    var districtYieldMultiplier: Double {
        isBonusActive(Districts.home) ? 1 + Districts.home.bonusValue : 1
    }

    /// Kundenbonus aus dem Oakland-Permit.
    var districtCustomerMultiplier: Double {
        isBonusActive(Districts.oakland) ? 1 + Districts.oakland.bonusValue : 1
    }

    /// Preisbonus aus dem San-Francisco-Permit.
    var districtPriceMultiplier: Double {
        isBonusActive(Districts.sanFrancisco) ? 1 + Districts.sanFrancisco.bonusValue : 1
    }

    /// Auftragsvolumen-Bonus aus dem Los-Angeles-Permit.
    var districtOrderMultiplier: Double {
        isBonusActive(Districts.losAngeles) ? 1 + Districts.losAngeles.bonusValue : 1
    }

    /// Darf in dieser Stadt ausgeliefert werden?
    func canDeliver(to city: DeliveryCity) -> Bool {
        guard let district = Districts.district(id: city.id) else { return true }
        return hasPermit(district)
    }

    func buyPermit(_ district: District) {
        guard !hasPermit(district) else { return }

        if level < district.requiredLevel {
            Haptics.warning()
            showToast("Ab Level \(district.requiredLevel)", icon: "lock.fill")
            return
        }

        guard money >= district.permitPrice else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= district.permitPrice
        permittedDistrictIDs.insert(district.id)
        if district.id == Districts.home.id {
            reduceHeat(12)
        }
        Haptics.success()
        showToast("Permit für \(district.name)", icon: "checkmark.seal.fill")
        save()
    }

    // MARK: Compliance

    /// Läuft gerade die bezahlte Buchhaltung?
    var isAccountingActive: Bool {
        guard let until = accountingUntil else { return false }
        return until > Date()
    }

    var accountingRemaining: TimeInterval {
        guard let until = accountingUntil else { return 0 }
        return max(0, until.timeIntervalSinceNow)
    }

    /// Ist der Laden wegen einer Kontrolle geschlossen?
    var isShutDown: Bool {
        guard let until = shutdownUntil else { return false }
        return until > Date()
    }

    var shutdownRemaining: TimeInterval {
        guard let until = shutdownUntil else { return 0 }
        return max(0, until.timeIntervalSinceNow)
    }

    func addHeat(_ amount: Double) {
        guard amount > 0 else { return }
        heat = min(Compliance.inspectionThreshold, heat + amount)

        if heat >= Compliance.inspectionThreshold {
            runInspection()
        }
    }

    func reduceHeat(_ amount: Double) {
        heat = max(0, heat - amount)
    }

    func buyAccounting() {
        guard !isAccountingActive else {
            Haptics.warning()
            showToast("Buchhaltung läuft schon", icon: "clock")
            return
        }
        guard money >= Compliance.accountingCost else {
            Haptics.warning()
            showToast("Nicht genug Geld", icon: "exclamationmark.triangle.fill")
            return
        }

        money -= Compliance.accountingCost
        accountingUntil = Date().addingTimeInterval(Compliance.accountingDuration)
        Haptics.success()
        showToast("Buchhaltung läuft · Heat sinkt schneller", icon: "doc.text.fill")
        save()
    }

    /// Eine Kontrolle: Strafe in Höhe eines Tagesumsatzes, Laden zu, Heat zurückgesetzt.
    private func runInspection() {
        let fine = max(150, (todayRevenue).rounded())
        let paid = min(money, fine)
        money -= paid
        finesToday += paid
        inspectionsToday += 1

        heat = 0
        shutdownUntil = Date().addingTimeInterval(Compliance.shutdownDuration)
        shopOpen = false
        queue.removeAll()

        Haptics.warning()
        showToast("Kontrolle · Strafe \(Format.money(paid)) · Laden \(Int(Compliance.shutdownDuration / 60)) Min zu", icon: "exclamationmark.triangle.fill")
        save()
    }

    private func startComplianceLoop() {
        complianceTask?.cancel()
        complianceTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.tickCompliance()
            }
        }
    }

    /// Heat baut sich langsam ab; nach einer Kontrolle öffnet der Laden wieder.
    @MainActor
    func tickCompliance() {
        if heat > 0 {
            var decay = Compliance.decayPerSecond
            if isAccountingActive {
                decay += Compliance.accountingDecayPerSecond
            }
            heat = max(0, heat - decay)
        }

        if let until = accountingUntil, until <= Date() {
            accountingUntil = nil
        }

        if let until = shutdownUntil, until <= Date() {
            shutdownUntil = nil
            shopOpen = true
            showToast("Laden wieder geöffnet", icon: "storefront.fill")
        }
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
            todayFees: todayFees,
            dailyHistory: dailyHistory,
            todayGrams: todayGrams,
            todayCustomers: todayCustomers,
            hourlySales: hourlySales,
            dayKey: dayKey,
            todaySalesByStrain: todaySalesByStrain,
            crew: crew,
            applicants: applicants,
            wagesPaidToday: wagesPaidToday,
            crewHarvestsToday: crewHarvestsToday,
            crewSalesToday: crewSalesToday,
            drivers: drivers,
            orders: orders,
            trips: trips,
            deliveriesToday: deliveriesToday,
            tipsToday: tipsToday,
            driverHireCost: driverHireCost,
            permittedDistrictIDs: Array(permittedDistrictIDs),
            heat: heat,
            inspectionsToday: inspectionsToday,
            finesToday: finesToday,
            accountingUntil: accountingUntil,
            shutdownUntil: shutdownUntil
        )
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        if let previous = defaults.data(forKey: saveKey), previous != encoded {
            defaults.set(previous, forKey: saveKey + ".backup")
        }
        defaults.set(encoded, forKey: saveKey)
    }

    private func clearSaveFiles() {
        for suffix in ["", ".backup", ".quarantine", ".backup.quarantine"] {
            defaults.removeObject(forKey: saveKey + suffix)
        }
    }

    private func load() {
        let backup = saveKey + ".backup"
        var damaged = false
        var decoded: SaveData?
        for key in [saveKey, backup] {
            guard let object = defaults.object(forKey: key) else { continue }
            if let bytes = object as? Data, let state = try? JSONDecoder().decode(SaveData.self, from: bytes) {
                decoded = state
                if key == backup {
                    defaults.set(bytes, forKey: saveKey)
                    showToast("Spielstand aus Sicherung wiederhergestellt", icon: "arrow.counterclockwise")
                } else if defaults.object(forKey: backup) == nil {
                    defaults.set(bytes, forKey: backup)
                }
                break
            }
            defaults.set(object, forKey: key + ".quarantine")
            defaults.removeObject(forKey: key)
            damaged = true
        }
        guard let data = decoded else {
            seedFirstRun()
            if damaged { showToast("Spielstand unlesbar und gesichert · Neues Spiel", icon: "exclamationmark.triangle") }
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

        // Migration: jeder Raum bekommt eine eigene, gültige Auswahl.
        for index in rooms.indices {
            if let id = rooms[index].selectionID,
               let candidate = Brands.strain(id: id),
               isStrainUnlocked(candidate) {
                continue
            }
            let fallback = isStrainUnlocked(savedStrain) ? savedStrain.id : Strains.base.id
            rooms[index].selectionID = fallback
        }

        shelf = data.shelf ?? []
        shopOpen = data.shopOpen ?? true
        todayRevenue = data.todayRevenue ?? 0
        todayFees = data.todayFees ?? 0
        dailyHistory = data.dailyHistory ?? []
        todayGrams = data.todayGrams ?? 0
        todayCustomers = data.todayCustomers ?? 0
        hourlySales = data.hourlySales ?? Array(repeating: 0, count: 24)
        todaySalesByStrain = data.todaySalesByStrain ?? [:]
        crew = data.crew ?? []
        applicants = data.applicants ?? []
        wagesPaidToday = data.wagesPaidToday ?? 0
        crewHarvestsToday = data.crewHarvestsToday ?? 0
        crewSalesToday = data.crewSalesToday ?? 0
        drivers = data.drivers ?? []
        orders = data.orders ?? []
        trips = data.trips ?? []
        deliveriesToday = data.deliveriesToday ?? 0
        tipsToday = data.tipsToday ?? 0
        driverHireCost = data.driverHireCost ?? 0
        permittedDistrictIDs = Set(data.permittedDistrictIDs ?? [])
        heat = data.heat ?? 0
        inspectionsToday = data.inspectionsToday ?? 0
        finesToday = data.finesToday ?? 0
        accountingUntil = data.accountingUntil
        shutdownUntil = data.shutdownUntil
        dayKey = data.dayKey ?? ""
        rollDayIfNeeded()
    }

    /// Beim allerersten Start wächst schon eine Pflanze im ersten Raum,
    /// und das Regal hat eine kleine Startcharge.
    private func seedFirstRun() {
        let duration = strain.baseGrowth * growthMultiplier
        let demoProgress = defaults.double(forKey: "demoProgress")
        let startProgress = demoProgress > 0.05 ? min(0.99, demoProgress) : 0.34
        rooms[0].selectionID = strain.id
        rooms[0].plant = Plant(
            strainID: strain.id,
            plantedAt: Date().addingTimeInterval(-duration * startProgress),
            duration: duration,
            waterings: 0,
            feedings: 0,
            boosted: false,
            batchCost: plantCost(for: strain),
            pheno: Double.random(in: 0.92...1.08)
        )
        dayKey = Self.dayFormatter.string(from: Date())
        shelf = [
            ShelfItem(
                strainID: strain.id,
                grams: 24,
                price: basePrice(for: strain),
                unitCost: strain.wholesaleValue
            )
        ]
        save()
    }

    func reset() {
        clearSaveFiles()
        money = 4_000
        xp = 0
        level = 1
        rooms = GrowRoom.defaults
        for index in rooms.indices {
            rooms[index].selectionID = Strains.base.id
        }
        upgradeLevels = [:]
        selectedRoom = 0
        totalHarvests = 0
        licensedBrandIDs = []
        selectedStrainID = Strains.base.id
        shelf = []
        shopOpen = true
        todayRevenue = 0
        todayFees = 0
        dailyHistory = []
        todayGrams = 0
        todayCustomers = 0
        hourlySales = Array(repeating: 0, count: 24)
        todaySalesByStrain = [:]
        crew = []
        applicants = []
        wagesPaidToday = 0
        crewHarvestsToday = 0
        crewSalesToday = 0
        drivers = []
        orders = []
        trips = []
        deliveriesToday = 0
        tipsToday = 0
        driverHireCost = 0
        permittedDistrictIDs = []
        heat = 0
        inspectionsToday = 0
        finesToday = 0
        accountingUntil = nil
        shutdownUntil = nil
        dayKey = Self.dayFormatter.string(from: Date())
        queue = []
        lastSale = nil
        Haptics.success()
        showToast("Fortschritt zurückgesetzt", icon: "arrow.counterclockwise")
    }

    // MARK: - Dev-Menü (versteckt)

    func devAddMoney(_ amount: Double) {
        money += amount
        Haptics.success()
        showToast("+\(Format.money(amount))", icon: "banknote.fill")
        save()
    }

    func devSetLevel(_ newLevel: Int) {
        level = max(1, newLevel)
        xp = 0
        Haptics.success()
        showToast("Level \(level)", icon: "star.fill")
        save()
    }

    func devUnlockEverything() {
        licensedBrandIDs = Set(Brands.all.map(\.id))
        permittedDistrictIDs = Set(Districts.all.map(\.id))
        level = max(level, 10)
        for index in rooms.indices {
            rooms[index].unlocked = true
            if rooms[index].selectionID == nil {
                rooms[index].selectionID = Strains.base.id
            }
        }
        refreshShelfPrices()
        Haptics.success()
        showToast("Alles freigeschaltet", icon: "lock.open.fill")
        save()
    }

    func devMaxUpgrades() {
        upgradeLevels = Dictionary(uniqueKeysWithValues: Upgrades.all.map { ($0.id, $0.maxLevel) })
        refreshShelfPrices()
        Haptics.success()
        showToast("Upgrades maximiert", icon: "slider.horizontal.3")
        save()
    }

    func devFillShelf() {
        for brand in Brands.all {
            for strain in brand.strains where isStrainUnlocked(strain) {
                stockShelf(with: strain.id, grams: 100)
            }
        }
        Haptics.success()
        showToast("Regal gefüllt", icon: "shippingbox.fill")
    }

    func devRipenPlants() {
        for index in rooms.indices {
            guard var plant = rooms[index].plant else { continue }
            plant.plantedAt = Date().addingTimeInterval(-plant.duration * 1.01)
            rooms[index].plant = plant
        }
        Haptics.success()
        showToast("Pflanzen erntereif", icon: "scissors")
        save()
    }

    func devAddDriver() {
        let driver = DeliveryDriver(name: "Dev Driver", vehicle: .car)
        drivers.append(driver)
        Haptics.success()
        showToast("Fahrer angeheuert", icon: "car.fill")
        save()
    }
}
