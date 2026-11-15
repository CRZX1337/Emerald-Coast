//
//  GameModels.swift
//  Emerald Coast
//
//  Sorten, Grow Rooms, Pflanzen und Upgrades.
//

import SwiftUI

// MARK: - Seltenheit

enum Rarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case exotic

    var label: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .exotic: return "Exotic"
        }
    }

    var color: Color {
        switch self {
        case .common: return Color.white.opacity(0.62)
        case .uncommon: return Theme.emerald
        case .rare: return Color(red: 0.44, green: 0.82, blue: 0.96)
        case .exotic: return Theme.lime
        }
    }
}

// MARK: - Sorte

struct Strain: Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let brandID: String
    let brandName: String
    let rarity: Rarity
    /// Potenz in Prozent THC.
    let thc: Double
    /// Grundwachstumszeit in Sekunden.
    let baseGrowth: TimeInterval
    /// Grundertrag in Gramm.
    let baseYield: Double
    /// Grundwert in Dollar pro Gramm.
    let baseValue: Double
    /// Ab diesem Level lässt sich die Sorte anbauen.
    var requiredLevel: Int = 1
}

enum Strains {
    static let base = Strain(
        id: "humboldt-og",
        name: "Humboldt OG",
        type: "Indica",
        brandID: "coast",
        brandName: "Emerald Coast",
        rarity: .common,
        thc: 22,
        baseGrowth: 60,
        baseYield: 14,
        baseValue: 30
    )
}

// MARK: - Marken

struct Brand: Identifiable, Hashable {
    let id: String
    let name: String
    let monogram: String
    let rarity: Rarity
    let licensePrice: Double
    let requiredLevel: Int
    /// Marken-Bonus auf den Verkaufswert.
    let valueBonus: Double
    let tint: Color
    let strains: [Strain]
}

enum Brands {
    private typealias Row = (
        id: String,
        name: String,
        type: String,
        rarity: Rarity,
        thc: Double,
        growth: Double,
        yield: Double,
        value: Double,
        level: Int
    )

    private static func build(_ brandID: String, _ brandName: String, _ rows: [Row]) -> [Strain] {
        rows.map { row in
            Strain(
                id: "\(brandID)-\(row.id)",
                name: row.name,
                type: row.type,
                brandID: brandID,
                brandName: brandName,
                rarity: row.rarity,
                thc: row.thc,
                baseGrowth: row.growth,
                baseYield: row.yield,
                baseValue: row.value,
                requiredLevel: row.level
            )
        }
    }

    static let wizardTrees = Brand(
        id: "wizard-trees",
        name: "Wizard Trees",
        monogram: "WT",
        rarity: .exotic,
        licensePrice: 8500,
        requiredLevel: 1,
        valueBonus: 1.22,
        tint: Theme.lime,
        strains: build("wizard-trees", "Wizard Trees", [
            ("zangria", "Zangria", "Sativa", .exotic, 27, 62, 17.0, 44, 1),
            ("rs11", "RS11", "Hybrid", .exotic, 26, 58, 16.0, 42, 1),
            ("zoap", "Zoap", "Hybrid", .rare, 25, 56, 15.5, 38, 1),
            ("guava", "Guava", "Indica", .uncommon, 23, 54, 15.0, 34, 1),
            ("cherry-slushy", "Cherry Slushy", "Indica", .rare, 24, 60, 16.5, 40, 5),
            ("purple-octane", "Purple Octane", "Indica", .exotic, 28, 66, 18.0, 48, 8)
        ])
    )

    static let theTen = Brand(
        id: "the-ten",
        name: "The Ten",
        monogram: "TT",
        rarity: .exotic,
        licensePrice: 8500,
        requiredLevel: 1,
        valueBonus: 1.20,
        tint: Color(red: 0.88, green: 0.80, blue: 0.56),
        strains: build("the-ten", "The Ten", [
            ("ten-co-og", "Ten Co OG", "Indica", .exotic, 27, 60, 17.0, 43, 1),
            ("lemon-cherry-gelato", "Lemon Cherry Gelato", "Hybrid", .exotic, 26, 57, 16.0, 41, 1),
            ("gelato-41", "Gelato 41", "Hybrid", .rare, 25, 55, 15.5, 37, 1),
            ("biscotti", "Biscotti", "Indica", .uncommon, 24, 53, 15.0, 34, 1),
            ("sherbanger", "Sherbanger", "Sativa", .rare, 25, 59, 16.5, 39, 5),
            ("sunset-sherbet", "Sunset Sherbet", "Indica", .exotic, 28, 64, 17.5, 46, 8)
        ])
    )

    static let breezy = Brand(
        id: "breezy",
        name: "Breezy",
        monogram: "BR",
        rarity: .exotic,
        licensePrice: 8500,
        requiredLevel: 1,
        valueBonus: 1.18,
        tint: Color(red: 0.42, green: 0.82, blue: 0.86),
        strains: build("breezy", "Breezy", [
            ("breezy-og", "Breezy OG", "Hybrid", .exotic, 26, 56, 16.5, 40, 1),
            ("blue-dream", "Blue Dream", "Sativa", .uncommon, 22, 58, 16.0, 32, 1),
            ("cereal-milk", "Cereal Milk", "Hybrid", .rare, 25, 55, 15.5, 38, 1),
            ("rainbow-sherbet", "Rainbow Sherbet", "Hybrid", .rare, 24, 57, 16.0, 37, 1),
            ("tropical-zkittlez", "Tropical Zkittlez", "Sativa", .exotic, 27, 61, 17.0, 43, 5),
            ("pink-runtz", "Pink Runtz", "Hybrid", .exotic, 28, 63, 17.5, 45, 8)
        ])
    )

    static let doja = Brand(
        id: "doja",
        name: "Doja",
        monogram: "DJ",
        rarity: .exotic,
        licensePrice: 24000,
        requiredLevel: 7,
        valueBonus: 1.30,
        tint: Color(red: 0.52, green: 0.58, blue: 0.98),
        strains: build("doja", "Doja", [
            ("doja-og", "Doja OG", "Indica", .exotic, 29, 64, 18.0, 52, 1),
            ("lemon-doja", "Lemon Doja", "Sativa", .exotic, 28, 62, 17.5, 50, 1),
            ("doja-pak", "Doja Pak", "Hybrid", .rare, 27, 60, 17.0, 46, 1),
            ("purple-doja", "Purple Doja", "Indica", .rare, 26, 58, 16.5, 44, 1),
            ("sunset-doja", "Sunset Doja", "Hybrid", .exotic, 30, 66, 18.5, 54, 5),
            ("doja-cream", "Doja Cream", "Indica", .exotic, 31, 68, 19.0, 58, 8)
        ])
    )

    static let jungleBoys = Brand(
        id: "jungle-boys",
        name: "Jungle Boys",
        monogram: "JB",
        rarity: .rare,
        licensePrice: 14000,
        requiredLevel: 4,
        valueBonus: 1.16,
        tint: Color(red: 0.36, green: 0.80, blue: 0.55),
        strains: build("jungle-boys", "Jungle Boys", [
            ("jungle-cake", "Jungle Cake", "Hybrid", .rare, 26, 58, 16.5, 38, 1),
            ("sfv-og", "SFV OG", "Indica", .uncommon, 24, 56, 15.5, 34, 1),
            ("strawberry-shortcake", "Strawberry Shortcake", "Hybrid", .rare, 25, 60, 16.0, 39, 1),
            ("motorbreath", "Motorbreath", "Indica", .uncommon, 23, 62, 15.0, 33, 1),
            ("jungle-mintz", "Jungle Mintz", "Hybrid", .exotic, 28, 63, 17.5, 45, 5),
            ("la-kush-cake", "LA Kush Cake", "Indica", .exotic, 29, 65, 18.0, 47, 8)
        ])
    )

    static let backpackBoyz = Brand(
        id: "backpack-boyz",
        name: "Backpack Boyz",
        monogram: "BB",
        rarity: .rare,
        licensePrice: 18000,
        requiredLevel: 5,
        valueBonus: 1.24,
        tint: Color(red: 0.92, green: 0.62, blue: 0.72),
        strains: build("backpack-boyz", "Backpack Boyz", [
            ("backpack-og", "Backpack OG", "Indica", .rare, 26, 60, 16.5, 40, 1),
            ("guava-cake", "Guava Cake", "Hybrid", .uncommon, 24, 57, 15.5, 35, 1),
            ("mango-mintz", "Mango Mintz", "Sativa", .rare, 25, 59, 16.0, 38, 1),
            ("blue-zushi", "Blue Zushi", "Hybrid", .exotic, 28, 62, 17.5, 46, 1),
            ("gelato-45", "Gelato 45", "Hybrid", .rare, 26, 61, 16.5, 41, 5),
            ("sherb-cream", "Sherb Cream", "Indica", .exotic, 29, 66, 18.0, 49, 8)
        ])
    )

    static let connected = Brand(
        id: "connected",
        name: "Connected",
        monogram: "CC",
        rarity: .exotic,
        licensePrice: 32000,
        requiredLevel: 9,
        valueBonus: 1.32,
        tint: Color(red: 0.98, green: 0.76, blue: 0.42),
        strains: build("connected", "Connected", [
            ("gelonade", "Gelonade", "Sativa", .exotic, 30, 64, 18.0, 54, 1),
            ("lemonatti", "Lemonatti", "Hybrid", .exotic, 29, 62, 17.5, 52, 1),
            ("guava-2", "Guava 2.0", "Hybrid", .rare, 27, 60, 17.0, 47, 1),
            ("xeno", "Xeno", "Indica", .rare, 28, 61, 16.5, 48, 1),
            ("atomic-apple", "Atomic Apple", "Hybrid", .exotic, 31, 67, 19.0, 56, 5),
            ("biscotti-supreme", "Biscotti Supreme", "Indica", .exotic, 32, 69, 19.5, 60, 8)
        ])
    )

    static let all: [Brand] = [
        wizardTrees,
        theTen,
        breezy,
        doja,
        jungleBoys,
        backpackBoyz,
        connected
    ]

    static func brand(id: String) -> Brand? {
        all.first { $0.id == id }
    }

    static func strain(id: String) -> Strain? {
        if id == Strains.base.id { return Strains.base }
        for brand in all {
            if let strain = brand.strains.first(where: { $0.id == id }) {
                return strain
            }
        }
        return nil
    }
}

// MARK: - Pflanze

struct Plant: Codable, Hashable {
    var strainID: String
    var plantedAt: Date
    var duration: TimeInterval
    var timeSaved: TimeInterval = 0
    var lastWatered: Date?

    func remaining(now: Date) -> TimeInterval {
        let elapsed = now.timeIntervalSince(plantedAt) + timeSaved
        return max(0, duration - elapsed)
    }

    func progress(now: Date) -> Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, 1 - remaining(now: now) / duration))
    }
}

// MARK: - Grow Room

struct GrowRoom: Codable, Identifiable, Hashable {
    var id: Int
    var unlocked: Bool
    var price: Double
    var requiredLevel: Int
    var plant: Plant?

    static let defaults: [GrowRoom] = [
        GrowRoom(id: 0, unlocked: true, price: 0, requiredLevel: 1, plant: nil),
        GrowRoom(id: 1, unlocked: false, price: 2400, requiredLevel: 1, plant: nil),
        GrowRoom(id: 2, unlocked: false, price: 6800, requiredLevel: 1, plant: nil),
        GrowRoom(id: 3, unlocked: false, price: 18000, requiredLevel: 5, plant: nil)
    ]
}

// MARK: - Upgrades

struct UpgradeDef: Identifiable {
    let id: String
    let name: String
    let icon: String
    let tint: Color
    let baseCost: Double
    let costGrowth: Double
    let maxLevel: Int
    let effect: (Int) -> String

    func cost(level: Int) -> Double {
        let raw = baseCost * pow(costGrowth, Double(level))
        return (raw / 10).rounded() * 10
    }
}

enum Upgrades {
    static let all: [UpgradeDef] = [
        UpgradeDef(
            id: "lamps",
            name: "LED-Lampen",
            icon: "lightbulb.fill",
            tint: Theme.lime,
            baseCost: 350,
            costGrowth: 1.6,
            maxLevel: 10,
            effect: { level in
                level == 0
                    ? "Standard-Beleuchtung"
                    : "-\(Int((1 - pow(0.93, Double(level))) * 100)) % Wachstumszeit"
            }
        ),
        UpgradeDef(
            id: "nutrients",
            name: "Nährstoffe",
            icon: "drop.fill",
            tint: Theme.emerald,
            baseCost: 500,
            costGrowth: 1.7,
            maxLevel: 10,
            effect: { level in
                level == 0
                    ? "Keine Düngung"
                    : "+\(Int(0.12 * Double(level) * 100)) % Ertrag"
            }
        ),
        UpgradeDef(
            id: "genetics",
            name: "Genetik",
            icon: "atom",
            tint: Theme.amber,
            baseCost: 800,
            costGrowth: 1.8,
            maxLevel: 10,
            effect: { level in
                level == 0
                    ? "Standard-Genetik"
                    : "+\(Int(0.08 * Double(level) * 100)) % Verkaufswert"
            }
        )
    ]
}

// MARK: - Rückmeldungen

struct HarvestResult: Identifiable {
    let id = UUID()
    let grams: Double
    let earned: Double
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
}
