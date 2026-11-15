//
//  GameModels.swift
//  Emerald Coast
//
//  Sorten, Marken, Grow Rooms, Pflanzen und Upgrades.
//  Marken, Sorten und Abstammungen sind nach öffentlich dokumentierten
//  Angaben der kalifornischen Betriebe und der Fachpresse recherchiert.
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

    /// Ertrags- und Wertfaktor der Seltenheit.
    var factor: Double {
        switch self {
        case .common: return 1.00
        case .uncommon: return 1.06
        case .rare: return 1.12
        case .exotic: return 1.20
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
    /// Abstammung, wie sie der Betrieb dokumentiert.
    let genetics: String
    /// Grundwachstumszeit in Sekunden.
    let baseGrowth: TimeInterval
    /// Grundertrag in Gramm.
    let baseYield: Double
    /// Grundwert in Dollar pro Gramm im eigenen Laden (Retail).
    let baseValue: Double
    /// Wholesale-Wert pro Gramm (das zahlen Dispensaries/Händler).
    let wholesaleValue: Double
    /// Ab diesem Level lässt sich die Sorte anbauen.
    var requiredLevel: Int = 1
}

enum Strains {
    /// Der Haus-Cut des Spielers, bevor eine Marke lizenziert ist.
    static let base = Strain(
        id: "house-og",
        name: "Emerald Coast OG",
        type: "Indica",
        brandID: "house",
        brandName: "CANNABIZ",
        rarity: .common,
        thc: 22,
        genetics: "OG Kush × Humboldt Heirloom",
        baseGrowth: 60,
        baseYield: 100,
        baseValue: 10.0,
        wholesaleValue: 3.2
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
    /// Royalty an den Lizenzgeber, Anteil am Umsatz.
    let royaltyRate: Double
    let tint: Color
    let city: String
    let note: String
    let strains: [Strain]

    /// Asset-Name des Marken-Logos. Breezy hat (noch) kein freigelegtes Logo.
    var logoAsset: String? {
        id == "breezy" ? nil : "brand-\(id)"
    }

    /// Weiße/goldene Logos brauchen eine dunkle Kachel.
    var logoOnDark: Bool {
        switch id {
        case "cookies", "wizard-trees", "seed-junky", "team-elite": return true
        default: return false
        }
    }
}

enum Brands {

    private struct Row {
        let id: String
        let name: String
        let type: String
        let genetics: String
        let thc: Double
        let rarity: Rarity
        let level: Int

        init(_ id: String, _ name: String, _ type: String, _ genetics: String, _ thc: Double, _ rarity: Rarity, _ level: Int = 1) {
            self.id = id
            self.name = name
            self.type = type
            self.genetics = genetics
            self.thc = thc
            self.rarity = rarity
            self.level = level
        }
    }

    /// Ertrag, Wert und Wachstumszeit folgen aus Potenz und Seltenheit.
    private static func build(_ brandID: String, _ brandName: String, _ rows: [Row]) -> [Strain] {
        rows.map { row in
            let factor = row.rarity.factor
            // Retail-Preis: 8–18 $/g, Wholesale ca. 30 % davon.
            let retailFactor = 1 + (factor - 1) * 0.5
            let rawRetail = (8.5 + (row.thc - 20) * 0.75) * retailFactor
            let retail = (min(18, max(8, rawRetail)) * 10).rounded() / 10
            let wholesale = (retail * 0.30 * 10).rounded() / 10
            // Ein Grow Room ist ein kleines Batch, keine Einzelpflanze.
            let yield = ((95 + (row.thc - 20) * 2.5) * factor).rounded()
            let growth = max(48, 64 - (row.thc - 20) * 1.0)

            return Strain(
                id: "\(brandID)-\(row.id)",
                name: row.name,
                type: row.type,
                brandID: brandID,
                brandName: brandName,
                rarity: row.rarity,
                thc: row.thc,
                genetics: row.genetics,
                baseGrowth: growth,
                baseYield: yield,
                baseValue: retail,
                wholesaleValue: wholesale,
                requiredLevel: row.level
            )
        }
    }

    // MARK: Breezy (Los Angeles)

    static let breezy = Brand(
        id: "breezy",
        name: "Breezy",
        monogram: "BR",
        rarity: .rare,
        licensePrice: 2500,
        requiredLevel: 1,
        valueBonus: 1.04,
        royaltyRate: 0.05,
        tint: Color(red: 0.42, green: 0.80, blue: 0.92),
        city: "Los Angeles",
        note: "Delivery-Marke aus dem San Fernando Valley. Kein eigener Anbau – Breezy kuratiert die Regale und verkauft die Cuts anderer Züchter.",
        strains: build("breezy", "Breezy", [
            Row("white-runtz", "White Runtz", "Hybrid", "Zkittlez × Gelato", 26, .rare),
            Row("syndicate-og", "Syndicate OG", "Indica", "OG Kush Selection", 25, .uncommon),
            Row("apple-slushie", "Apple Slushie", "Hybrid", "Sativa × Gas Cut", 24, .uncommon),
            Row("delicata-grapes", "Delicata Grapes", "Indica", "Grape Selection", 23, .common),
            Row("citrus-sap", "Citrus Sap", "Sativa", "Citrus Haze × Sap", 22, .common),
            Row("canal-st", "Canal St.", "Hybrid", "Sour × Cookies", 25, .rare, 5)
        ])
    )

    // MARK: Wizard Trees (Los Angeles)

    static let wizardTrees = Brand(
        id: "wizard-trees",
        name: "Wizard Trees",
        monogram: "WT",
        rarity: .exotic,
        licensePrice: 6500,
        requiredLevel: 1,
        valueBonus: 1.12,
        royaltyRate: 0.1,
        tint: Color(red: 0.66, green: 0.48, blue: 0.98),
        city: "Los Angeles",
        note: "Scott Lanes Zuchtbetrieb aus LA. RS-11 und Zoap stammen aus der Deep-East-Linie von DEO Farms, Black Magic und Zangria sind eigene House-Cuts.",
        strains: build("wizard-trees", "Wizard Trees", [
            Row("rs11", "RS-11", "Hybrid", "OZK × Pink Guava × Black Sherb Bx", 28, .exotic),
            Row("zoza", "Zoza", "Hybrid", "Zoap × Zangria", 27, .exotic),
            Row("zangria", "Zangria", "Hybrid", "House Cut · Candy & Cream", 26, .rare),
            Row("black-magic", "Black Magic", "Indica", "Clone-only · Candy & Gas", 28, .exotic),
            Row("limelight", "Limelight", "Hybrid", "Gelonade × Zangria", 25, .rare),
            Row("tea-party", "Tea Party", "Hybrid", "Tea Time × Zangria", 25, .rare, 5),
            Row("zangbanger", "Zangbanger", "Sativa", "Zangria × Sherbanger 22", 27, .exotic, 7),
            Row("studio-54", "Studio 54", "Hybrid", "RS-11 Selection (RS-54)", 29, .exotic, 9)
        ])
    )

    // MARK: The Ten Co (Los Angeles)

    static let theTen = Brand(
        id: "the-ten",
        name: "The Ten Co",
        monogram: "10",
        rarity: .exotic,
        licensePrice: 7500,
        requiredLevel: 2,
        valueBonus: 1.13,
        royaltyRate: 0.1,
        tint: Color(red: 0.55, green: 0.85, blue: 0.98),
        city: "Los Angeles",
        note: "Staks und Gerry bauten die Zushi-Familie um Zkittlez × Kush Mints. Blue Zushi war 2021, 2022 und 2023 bester Geschmack beim Zalympix.",
        strains: build("the-ten", "The Ten Co", [
            Row("blue-zushi", "Blue Zushi", "Indica", "Zkittlez × Kush Mints #18", 30, .exotic),
            Row("yellow-zushi", "Yellow Zushi", "Hybrid", "Zkittlez × Kush Mints #6", 28, .exotic),
            Row("pink-zushi", "Pink Zushi", "Hybrid", "Zushi Family · Coi-Leray-Cut", 34, .exotic, 7),
            Row("zoy-zushi", "Zoy Zushi", "Hybrid", "Zushi × Gelato", 27, .rare),
            Row("wasabi-zushi", "Wasabi Zushi", "Hybrid", "Zkittlez × Kush Mints", 26, .rare),
            Row("nozu", "Nozu", "Hybrid", "Zushi Evolution", 29, .exotic, 5),
            Row("black-zushi", "Black Zushi", "Indica", "Blue Zushi S1", 31, .exotic, 9)
        ])
    )

    // MARK: Doja Pak (Sacramento)

    static let doja = Brand(
        id: "doja",
        name: "Doja Pak",
        monogram: "D",
        rarity: .exotic,
        licensePrice: 9000,
        requiredLevel: 3,
        valueBonus: 1.14,
        royaltyRate: 0.1,
        tint: Color(red: 0.95, green: 0.35, blue: 0.40),
        city: "Sacramento",
        note: "Ryan Bartholomews Doja Exclusive aus Sacramento. Doja selektiert und benennt die Cuts – Permanent Marker kam von Seed Junky, den Namen fand Doja.",
        strains: build("doja", "Doja Pak", [
            Row("permanent-marker", "Permanent Marker", "Indica", "(Biscotti S1 × Sherb Bx1) × Jealousy F2", 30, .exotic),
            Row("rs11-doja", "RS-11", "Hybrid", "OZK × Pink Guava × Black Sherb Bx", 28, .exotic),
            Row("studio-54-doja", "Studio 54", "Hybrid", "RS-11 Selection (RS-54)", 27, .rare),
            Row("neon-wormz", "Neon Wormz", "Hybrid", "Sour SFV #10 × Z Bx2", 26, .rare),
            Row("sour-wormz", "Sour Wormz", "Sativa", "Sour SFV × Z Bx2", 25, .rare),
            Row("giraffe-puzzy", "Giraffe Puzzy", "Hybrid", "Doja Exclusive", 29, .exotic, 6),
            Row("american-pie", "American Pie", "Indica", "Doja Exclusive", 27, .rare, 8)
        ])
    )

    // MARK: Jungle Boys (Los Angeles)

    static let jungleBoys = Brand(
        id: "jungle-boys",
        name: "Jungle Boys",
        monogram: "JB",
        rarity: .rare,
        licensePrice: 10000,
        requiredLevel: 4,
        valueBonus: 1.08,
        royaltyRate: 0.08,
        tint: Color(red: 0.72, green: 0.92, blue: 0.35),
        city: "Los Angeles",
        note: "Die Jungle-Cake-Linie von Seed Junky wurde hier zum Standard. Dazu die Cuts, die Jungle Boys groß gemacht haben: Wedding Cake, Sundae Driver, SFV OG.",
        strains: build("jungle-boys", "Jungle Boys", [
            Row("jungle-cake", "Jungle Cake", "Indica", "White Fire #43 × Wedding Cake", 28, .exotic),
            Row("la-kush-cake", "LA Kush Cake", "Indica", "Kush Mints × Wedding Cake", 29, .exotic),
            Row("motor-breath", "Motor Breath", "Indica", "SFV OG × Chemdawg", 27, .rare),
            Row("gator-breath", "Gator Breath", "Indica", "Motorbreath 15 × Triangle Kush", 26, .rare),
            Row("jungle-driver", "Jungle Driver", "Hybrid", "Sundae Driver × Jungle Cake", 25, .rare),
            Row("zacks-pie", "Zach's Pie", "Indica", "Wedding Cake × Grape Pie", 24, .uncommon),
            Row("topanga-og", "Topanga Canyon OG", "Indica", "707 Headband × OG", 23, .uncommon),
            Row("strawberry-shortcake", "Strawberry Shortcake", "Hybrid", "White Wookies × The White", 22, .common)
        ])
    )

    // MARK: Backpack Boyz (Los Angeles)

    static let backpackBoyz = Brand(
        id: "backpack-boyz",
        name: "Backpack Boyz",
        monogram: "BB",
        rarity: .rare,
        licensePrice: 9500,
        requiredLevel: 4,
        valueBonus: 1.09,
        royaltyRate: 0.08,
        tint: Color(red: 0.36, green: 0.55, blue: 0.98),
        city: "Los Angeles",
        note: "Lemon Cherry Gelato machte die Boyz weltbekannt: Sunset Sherbet × Girl Scout Cookies. Heute kreuzen sie alles mit Melon Fresca und OZ Kush.",
        strains: build("backpack-boyz", "Backpack Boyz", [
            Row("lemon-cherry-gelato", "Lemon Cherry Gelato", "Hybrid", "Sunset Sherbet × Girl Scout Cookies", 30, .exotic),
            Row("guava-gelato", "Guava Gelato", "Hybrid", "Gelato 41 × Guava", 26, .rare),
            Row("blue-guava-gelato", "Blue Guava Gelato", "Hybrid", "Blue Gotti × Guava Gelato", 25, .rare),
            Row("blue-tommyz", "Blue Tommyz", "Hybrid", "Blue Gotti × Sunset Sherbet", 26, .rare),
            Row("bubblegum-gelato", "Bubblegum Gelato", "Hybrid", "Bubblegum × Gelato", 24, .uncommon),
            Row("white-cherry-gelato", "White Cherry Gelato", "Hybrid", "White Gelato × Cherry", 27, .rare, 5),
            Row("melon-fresca", "Melon Fresca", "Hybrid", "Zkittlez Bx1", 25, .uncommon, 7)
        ])
    )

    // MARK: Connected (Sacramento)

    static let connected = Brand(
        id: "connected",
        name: "Connected",
        monogram: "CC",
        rarity: .exotic,
        licensePrice: 12000,
        requiredLevel: 5,
        valueBonus: 1.13,
        royaltyRate: 0.1,
        tint: Color(red: 0.96, green: 0.78, blue: 0.40),
        city: "Sacramento",
        note: "Gelonade, Biscotti und Lemonatti sind Connected-Originale. Biscotti entstand 2016 aus South Florida OG × Gelato #25, Lemonatti ist Gelonade × Biscotti #17.",
        strains: build("connected", "Connected", [
            Row("gelonade", "Gelonade", "Sativa", "Lemon Tree × Gelato #41", 27, .exotic),
            Row("biscotti", "Biscotti", "Indica", "South Florida OG × Gelato #25", 29, .exotic),
            Row("lemonatti", "Lemonatti", "Sativa", "Gelonade × Biscotti #17", 28, .exotic),
            Row("guava-2", "Guava 2.0", "Hybrid", "Gelato 41 × Guava", 26, .rare),
            Row("xeno", "Xeno", "Indica", "Gelato Line", 27, .rare),
            Row("gelato-41", "Gelato 41", "Hybrid", "Sunset Sherbet × Thin Mint Cookies", 25, .rare),
            Row("gushers", "Gushers", "Hybrid", "Gelato 41 × Triangle Kush", 26, .rare, 6)
        ])
    )

    // MARK: Cookies (San Francisco)

    static let cookies = Brand(
        id: "cookies",
        name: "Cookies",
        monogram: "CK",
        rarity: .exotic,
        licensePrice: 14000,
        requiredLevel: 6,
        valueBonus: 1.12,
        royaltyRate: 0.1,
        tint: Color(red: 0.35, green: 0.62, blue: 0.96),
        city: "San Francisco",
        note: "Berners Haus aus der Bay: Girl Scout Cookies, Runtz und die Snowman-Linie mit Gary Payton und Cereal Milk, gezüchtet mit Powerzzzup.",
        strains: build("cookies", "Cookies", [
            Row("gary-payton", "Gary Payton", "Hybrid", "Y Life × Snowman #20", 27, .exotic),
            Row("cereal-milk", "Cereal Milk", "Hybrid", "Y Life × Snowman #18", 26, .exotic),
            Row("london-pound-cake", "London Pound Cake", "Indica", "Sunset Sherbet × Nip OG", 25, .rare),
            Row("georgia-pie", "Georgia Pie", "Indica", "Gelatti × Kush Mints", 27, .exotic),
            Row("the-soap", "The Soap", "Hybrid", "Animal Mints #9 × Kush Mints #11", 28, .exotic),
            Row("blue-suede", "Blue Suede", "Hybrid", "Blue Cookies × Project 4516", 26, .rare),
            Row("cheetah-piss", "Cheetah Piss", "Sativa", "Lemonnade × Gelato 41", 26, .rare, 7)
        ])
    )

    // MARK: Seed Junky Genetics (San Fernando Valley)

    static let seedJunky = Brand(
        id: "seed-junky",
        name: "Seed Junky",
        monogram: "SJ",
        rarity: .exotic,
        licensePrice: 16000,
        requiredLevel: 7,
        valueBonus: 1.15,
        royaltyRate: 0.12,
        tint: Color(red: 0.30, green: 0.82, blue: 0.55),
        city: "San Fernando Valley",
        note: "Jbeezys Zuchthaus. Wedding Cake, Kush Mints und Jealousy kommen von hier – alle drei wurden Leafly-Strain-of-the-Year.",
        strains: build("seed-junky", "Seed Junky", [
            Row("wedding-cake", "Wedding Cake", "Indica", "Triangle Mints #23", 27, .exotic),
            Row("kush-mints", "Kush Mints", "Indica", "Animal Mints × Bubba Kush", 28, .exotic),
            Row("jealousy", "Jealousy", "Hybrid", "Sherb Bx1 × Gelato 41", 30, .exotic),
            Row("permanent-marker-sj", "Permanent Marker", "Indica", "(Biscotti S1 × Sherb Bx1) × Jealousy F2", 30, .exotic),
            Row("ice-cream-cake", "Ice Cream Cake", "Indica", "Wedding Cake × Gelato 33", 26, .rare),
            Row("animal-mints", "Animal Mints", "Indica", "Animal Cookies × Sin Mint Cookies", 27, .rare),
            Row("giraffe-p", "Giraffe P", "Hybrid", "Seed Junky Exclusive", 29, .exotic, 8)
        ])
    )

    // MARK: Alien Labs (Redding / Los Angeles)

    static let alienLabs = Brand(
        id: "alien-labs",
        name: "Alien Labs",
        monogram: "AL",
        rarity: .exotic,
        licensePrice: 18000,
        requiredLevel: 8,
        valueBonus: 1.14,
        royaltyRate: 0.11,
        tint: Color(red: 0.55, green: 0.98, blue: 0.60),
        city: "Redding",
        note: "Ted Lidie startete in Redding, heute mit Connected zusammen. Area 41 ist Lemon Fuel OG × Gelato #41, Biskanté Melonade × Biscotti #6.",
        strains: build("alien-labs", "Alien Labs", [
            Row("area-41", "Area 41", "Indica", "Lemon Fuel OG × Gelato #41", 30, .exotic),
            Row("biskante", "Biskanté", "Sativa", "Melonade × Biscotti #6", 29, .exotic),
            Row("atomic-apple", "Atomic Apple", "Hybrid", "Triangle Mints × Apple Fritter", 29, .exotic),
            Row("baklava", "Baklava", "Indica", "Alien Labs Exclusive", 28, .rare),
            Row("zookies", "Zookies", "Hybrid", "GG4 × Animal Cookies", 26, .rare),
            Row("sherbacio", "Sherbacio", "Hybrid", "Sunset Sherbet × Bacio Gelato", 27, .rare),
            Row("melonade", "Melonade", "Sativa", "Alien Labs Exclusive", 26, .uncommon, 9)
        ])
    )

    // MARK: Team Elite Genetics (Orange County)

    static let teamElite = Brand(
        id: "team-elite",
        name: "Team Elite",
        monogram: "TE",
        rarity: .exotic,
        licensePrice: 20000,
        requiredLevel: 9,
        valueBonus: 1.13,
        royaltyRate: 0.1,
        tint: Color(red: 0.30, green: 0.88, blue: 0.78),
        city: "Orange County",
        note: "Familienbetrieb von Steve und Jade Castillo mit Living Soil und über 30 High-Times-Cups. Styrofoam Cup, Pearadise und Orange Soda sind die Zugpferde.",
        strains: build("team-elite", "Team Elite", [
            Row("styrofoam-cup", "Styrofoam Cup", "Indica", "Cannarado Genetics Cut", 28, .exotic),
            Row("pearadise", "Pearadise", "Sativa", "Team Elite Exclusive", 27, .exotic),
            Row("orange-soda", "Orange Soda", "Sativa", "Team Elite Exclusive", 27, .exotic),
            Row("peach-ozz", "Peach Ozz", "Hybrid", "Team Elite Exclusive", 26, .rare),
            Row("banana-taffy", "Banana Taffy", "Hybrid", "Team Elite Exclusive", 25, .rare),
            Row("goat-cheese", "Goat Cheese", "Hybrid", "Grandma's Cookies × UK Cheese", 26, .rare),
            Row("purple-dump-truck", "Purple Dump Truck", "Indica", "Team Elite Exclusive", 27, .exotic, 10)
        ])
    )

    // MARK: Sherbinskis (San Francisco)

    static let sherbinskis = Brand(
        id: "sherbinskis",
        name: "Sherbinskis",
        monogram: "SH",
        rarity: .exotic,
        licensePrice: 22000,
        requiredLevel: 10,
        valueBonus: 1.15,
        royaltyRate: 0.11,
        tint: Color(red: 0.98, green: 0.55, blue: 0.72),
        city: "San Francisco",
        note: "Mario Guzman, Mr. Sherbinski, baute im Sunset District erst Sunset Sherbet, dann 2014 mit Jigga Gelato aus Sunset Sherbet × Thin Mint Cookies.",
        strains: build("sherbinskis", "Sherbinskis", [
            Row("bacio-41", "Bacio Gelato 41", "Hybrid", "Sunset Sherbet × Thin Mint Cookies", 28, .exotic),
            Row("sunset-sherbet", "Sunset Sherbet", "Hybrid", "Girl Scout Cookies × Pink Panties", 25, .rare),
            Row("mochi-gelato", "Mochi Gelato", "Hybrid", "Gelato Family · Dough Cut", 26, .rare),
            Row("acai-berry", "Acai Berry Gelato", "Hybrid", "Gelato Family · Berry Cut", 27, .exotic),
            Row("gello-gelato", "Gello Gelato", "Hybrid", "Gelato Family · Fruit Cut", 26, .rare),
            Row("pink-panties", "Pink Panties", "Indica", "Burmese Kush × Florida Kush", 22, .uncommon),
            Row("gelato-33", "Gelato 33", "Hybrid", "Gelato Family · Larry Bird", 27, .exotic, 11)
        ])
    )

    // MARK: Fig Farms (Humboldt County)

    static let figFarms = Brand(
        id: "fig-farms",
        name: "Fig Farms",
        monogram: "FF",
        rarity: .exotic,
        licensePrice: 24000,
        requiredLevel: 11,
        valueBonus: 1.16,
        royaltyRate: 0.12,
        tint: Color(red: 0.75, green: 0.52, blue: 0.90),
        city: "Humboldt County",
        note: "Owner-farmed aus Nordkalifornien, 100 % in Familienhand. Blue Face ist Face Off OG × Animal Mints in der blauen Phäno, aus eigener Selektion.",
        strains: build("fig-farms", "Fig Farms", [
            Row("blue-face", "Blue Face", "Hybrid", "Face Off OG × Animal Mints (Blue)", 29, .exotic),
            Row("strawberry-guava", "Strawberry Guava", "Hybrid", "Fig Farms Exclusive", 27, .exotic),
            Row("fabulosa", "Fabulosa", "Sativa", "Fig Farms Exclusive", 28, .exotic),
            Row("hijinx", "Hijinx", "Hybrid", "Fig Farms Exclusive", 26, .rare),
            Row("fig-farmers", "Fig Farmer's Cut", "Indica", "Fig Farms Selection", 25, .rare),
            Row("blue-face-2", "Blue Face #2", "Hybrid", "Face Off OG × Animal Mints", 30, .exotic, 12)
        ])
    )

    static let all: [Brand] = [
        breezy,
        wizardTrees,
        theTen,
        doja,
        jungleBoys,
        backpackBoyz,
        connected,
        cookies,
        seedJunky,
        alienLabs,
        teamElite,
        sherbinskis,
        figFarms
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
    /// Pflege pro Batch. Optional, damit alte Spielstände weiter laden.
    var waterings: Int?
    var feedings: Int?
    var boosted: Bool?
    /// Was der Batch beim Anpflanzen gekostet hat.
    var batchCost: Double?

    var hasWatered: Bool { (waterings ?? 0) > 0 }
    var feedCount: Int { feedings ?? 0 }
    var isBoosted: Bool { boosted ?? false }

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
        GrowRoom(id: 1, unlocked: false, price: 6_000, requiredLevel: 2, plant: nil),
        GrowRoom(id: 2, unlocked: false, price: 18_000, requiredLevel: 5, plant: nil),
        GrowRoom(id: 3, unlocked: false, price: 45_000, requiredLevel: 8, plant: nil)
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
            baseCost: 900,
            costGrowth: 1.55,
            maxLevel: 8,
            effect: { level in
                level == 0
                    ? "Standard-Beleuchtung"
                    : "-\(Int((1 - pow(0.94, Double(level))) * 100)) % Wachstumszeit"
            }
        ),
        UpgradeDef(
            id: "nutrients",
            name: "Nährstoffe",
            icon: "drop.fill",
            tint: Theme.emerald,
            baseCost: 1_200,
            costGrowth: 1.7,
            maxLevel: 6,
            effect: { level in
                level == 0
                    ? "Keine Düngung"
                    : "+\(Int(0.08 * Double(level) * 100)) % Ertrag"
            }
        ),
        UpgradeDef(
            id: "genetics",
            name: "Genetik",
            icon: "atom",
            tint: Theme.amber,
            baseCost: 2_200,
            costGrowth: 1.8,
            maxLevel: 5,
            effect: { level in
                level == 0
                    ? "Standard-Genetik"
                    : "+\(Int(0.06 * Double(level) * 100)) % Verkaufswert"
            }
        )
    ]
}

// MARK: - Rückmeldungen

struct HarvestResult: Identifiable {
    let id = UUID()
    let grams: Double
    /// Geschätzter Wholesale-Wert der Ernte (kein Sofortgeld).
    let value: Double
}

struct ToastMessage: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
}
