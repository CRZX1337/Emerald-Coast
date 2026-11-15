//
//  Dispensary.swift
//  Emerald Coast
//
//  Bestand im Regal, Kunden und Verkäufe des eigenen Ladens.
//

import Foundation

/// Eine Sorte im Regal: Bestand in Gramm, Preis und Einstand.
struct ShelfItem: Codable, Identifiable, Hashable {
    var strainID: String
    var grams: Double
    var price: Double
    /// Einstand pro Gramm (COGS + Ernte/Pack). Optional für alte Spielstände.
    var unitCost: Double? = nil

    var id: String { strainID }

    var marginPerGram: Double {
        max(0, price - (unitCost ?? 0))
    }
}

/// Ein Kunde in der Schlange.
struct ShopCustomer: Identifiable, Hashable {
    let id = UUID()
    let strainID: String
    let grams: Double
    /// Nur für die Optik des Avatars.
    let look: Int
}

/// Ein abgeschlossener Verkauf, für die schwebenden Preise.
struct ShopSale: Identifiable, Hashable {
    let id = UUID()
    let amount: Double
    let grams: Double
    let strainName: String
}
