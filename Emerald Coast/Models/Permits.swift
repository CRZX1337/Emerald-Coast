//
//  Permits.swift
//  Emerald Coast
//
//  Viertel, Permits und die Compliance-Regeln (Heat, Kontrolle, Buchhaltung).
//

import Foundation
import SwiftUI

// MARK: - Bonus eines Viertels

enum DistrictBonus: String {
    case yield
    case customers
    case prices
    case orders

    var label: String {
        switch self {
        case .yield: return "Ertrag"
        case .customers: return "Kunden"
        case .prices: return "Preise"
        case .orders: return "Auftragsvolumen"
        }
    }

    var icon: String {
        switch self {
        case .yield: return "leaf.fill"
        case .customers: return "person.3.fill"
        case .prices: return "tag.fill"
        case .orders: return "box.truck.fill"
        }
    }
}

// MARK: - Viertel

struct District: Identifiable, Hashable {
    let id: String
    let name: String
    let bonus: DistrictBonus
    /// Bonus als Anteil, z. B. 0.12 für +12 %.
    let bonusValue: Double
    let permitPrice: Double
    let requiredLevel: Int
    let tint: Color
    let note: String

    var bonusLabel: String {
        "+\(Int((bonusValue * 100).rounded())) % \(bonus.label)"
    }

    /// Liegt das Viertel auf der Lieferkarte?
    var isDeliveryCity: Bool {
        id != Districts.home.id
    }
}

enum Districts {
    /// Der eigene Laden und das Grow House stehen in Humboldt.
    static let home = District(
        id: "humboldt",
        name: "Humboldt",
        bonus: .yield,
        bonusValue: 0.12,
        permitPrice: 1_500,
        requiredLevel: 1,
        tint: Theme.lime,
        note: "Grow House und Dispensary. Ohne Permit steigt die Heat bei jedem Verkauf."
    )

    static let oakland = District(
        id: "oakland",
        name: "Oakland",
        bonus: .customers,
        bonusValue: 0.15,
        permitPrice: 3_200,
        requiredLevel: 2,
        tint: Theme.emerald,
        note: "Mehr Laufkundschaft im Laden."
    )

    static let sanFrancisco = District(
        id: "san-francisco",
        name: "San Francisco",
        bonus: .prices,
        bonusValue: 0.10,
        permitPrice: 4_800,
        requiredLevel: 3,
        tint: Color(red: 0.45, green: 0.82, blue: 0.96),
        note: "Höhere Preise im Laden."
    )

    static let losAngeles = District(
        id: "los-angeles",
        name: "Los Angeles",
        bonus: .orders,
        bonusValue: 0.20,
        permitPrice: 7_500,
        requiredLevel: 5,
        tint: Color(red: 0.96, green: 0.78, blue: 0.40),
        note: "Größere Lieferaufträge in die Stadt."
    )

    static let all: [District] = [home, oakland, sanFrancisco, losAngeles]

    static func district(id: String) -> District? {
        all.first { $0.id == id }
    }
}

// MARK: - Compliance

enum Compliance {
    /// Ab diesem Wert steht die Heat am Anschlag.
    static let inspectionThreshold: Double = 100

    /// Heat, die pro Sekunde von selbst abgebaut wird.
    static let decayPerSecond: Double = 0.25

    /// Zusätzlicher Abbau pro Sekunde, solange die Buchhaltung läuft.
    static let accountingDecayPerSecond: Double = 1.0

    static let accountingDuration: TimeInterval = 180
    static let accountingCost: Double = 1_200

    /// Heat pro Verkauf ohne Permit für Humboldt.
    static let heatPerUnlicensedSale: Double = 2.0

    /// Heat pro Verkauf unter Einstand.
    static let heatPerBelowCostSale: Double = 1.2

    /// So lange bleibt der Laden nach einer Kontrolle zu.
    static let shutdownDuration: TimeInterval = 120

    static func status(for heat: Double) -> String {
        switch heat {
        case ..<25: return "Ruhig"
        case ..<50: return "Beobachtet"
        case ..<75: return "Auffällig"
        case ..<inspectionThreshold: return "Kritisch"
        default: return "Am Anschlag"
        }
    }

    static func color(for heat: Double) -> Color {
        switch heat {
        case ..<40: return Theme.emerald
        case ..<70: return Theme.amber
        default: return Color(red: 1.0, green: 0.48, blue: 0.45)
        }
    }
}
