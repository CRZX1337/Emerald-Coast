//
//  Dispensary.swift
//  Emerald Coast
//
//  Bestand im Regal, Kunden und Verkäufe des eigenen Ladens.
//

import Foundation

/// Eine Sorte im Regal: Bestand in Gramm und der Preis, den der Spieler setzt.
struct ShelfItem: Codable, Identifiable, Hashable {
    var strainID: String
    var grams: Double
    var price: Double

    var id: String { strainID }
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
