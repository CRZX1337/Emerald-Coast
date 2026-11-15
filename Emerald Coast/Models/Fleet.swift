//
//  Fleet.swift
//  Emerald Coast
//
//  Lieferstädte, Fahrzeuge, Fahrer und Aufträge.
//

import Foundation
import SwiftUI

// MARK: - Städte

struct DeliveryCity: Identifiable, Hashable {
    let id: String
    let name: String
    /// Position auf der gezeichneten Karte, 0…1.
    let x: Double
    let y: Double
    /// Straßenkilometer ab Humboldt County.
    let distance: Double

    var shortName: String {
        switch id {
        case "san-francisco": return "SF"
        case "los-angeles": return "LA"
        default: return name
        }
    }
}

enum DeliveryCities {
    static let home = DeliveryCity(id: "humboldt", name: "Humboldt", x: 0.0239, y: 0.1274, distance: 0)

    static let all: [DeliveryCity] = [
        home,
        DeliveryCity(id: "san-francisco", name: "San Francisco", x: 0.1936, y: 0.4469, distance: 500),
        DeliveryCity(id: "oakland", name: "Oakland", x: 0.2081, y: 0.4438, distance: 480),
        DeliveryCity(id: "los-angeles", name: "Los Angeles", x: 0.5999, y: 0.8398, distance: 1050)
    ]

    static let destinations: [DeliveryCity] = all.filter { $0.id != home.id }

    static func city(id: String) -> DeliveryCity {
        all.first { $0.id == id } ?? home
    }

    /// Breite/Höhe des kalifornischen Umrisses. Die Karte wird immer in
    /// diesem Seitenverhältnis gezeichnet, damit sie nicht verzerrt.
    static let aspect: CGFloat = 0.863

    /// Echter, vereinfachter Umriss Kaliforniens (WGS84 → normalisiert).
    /// Quelle: US States GeoJSON (glynnbird/usstatesgeojson), RDP-vereinfacht.
    static let outline: [CGPoint] = [
        CGPoint(x: 0.0335, y: 0.0575),
        CGPoint(x: 0.0255, y: 0.0308),
        CGPoint(x: 0.0149, y: 0.0239),
        CGPoint(x: 0.0193, y: 0.0012),
        CGPoint(x: 0.4291, y: 0.0016),
        CGPoint(x: 0.4289, y: 0.3177),
        CGPoint(x: 0.6722, y: 0.5054),
        CGPoint(x: 0.9512, y: 0.7395),
        CGPoint(x: 0.9512, y: 0.7535),
        CGPoint(x: 1.0000, y: 0.8178),
        CGPoint(x: 0.9706, y: 0.8360),
        CGPoint(x: 0.9607, y: 0.8908),
        CGPoint(x: 0.9426, y: 0.9089),
        CGPoint(x: 0.9439, y: 0.9412),
        CGPoint(x: 0.9672, y: 0.9538),
        CGPoint(x: 0.9529, y: 0.9795),
        CGPoint(x: 0.7088, y: 1.0000),
        CGPoint(x: 0.6752, y: 0.9196),
        CGPoint(x: 0.6107, y: 0.8713),
        CGPoint(x: 0.5836, y: 0.8725),
        CGPoint(x: 0.5731, y: 0.8424),
        CGPoint(x: 0.5453, y: 0.8452),
        CGPoint(x: 0.5137, y: 0.8347),
        CGPoint(x: 0.4719, y: 0.8017),
        CGPoint(x: 0.3832, y: 0.7980),
        CGPoint(x: 0.3670, y: 0.7855),
        CGPoint(x: 0.3663, y: 0.7250),
        CGPoint(x: 0.3457, y: 0.7180),
        CGPoint(x: 0.3429, y: 0.6944),
        CGPoint(x: 0.3040, y: 0.6686),
        CGPoint(x: 0.2828, y: 0.6342),
        CGPoint(x: 0.2453, y: 0.6023),
        CGPoint(x: 0.2365, y: 0.5730),
        CGPoint(x: 0.2525, y: 0.5622),
        CGPoint(x: 0.2478, y: 0.5359),
        CGPoint(x: 0.2241, y: 0.5333),
        CGPoint(x: 0.1950, y: 0.5080),
        CGPoint(x: 0.1844, y: 0.4463),
        CGPoint(x: 0.1957, y: 0.4437),
        CGPoint(x: 0.1976, y: 0.4648),
        CGPoint(x: 0.2236, y: 0.4751),
        CGPoint(x: 0.1926, y: 0.4270),
        CGPoint(x: 0.2079, y: 0.4153),
        CGPoint(x: 0.1959, y: 0.4073),
        CGPoint(x: 0.1868, y: 0.4113),
        CGPoint(x: 0.1918, y: 0.4357),
        CGPoint(x: 0.1853, y: 0.4419),
        CGPoint(x: 0.1486, y: 0.4205),
        CGPoint(x: 0.1348, y: 0.4237),
        CGPoint(x: 0.1394, y: 0.3949),
        CGPoint(x: 0.0666, y: 0.3263),
        CGPoint(x: 0.0543, y: 0.2298),
        CGPoint(x: 0.0045, y: 0.1845),
        CGPoint(x: 0.0000, y: 0.1658),
        CGPoint(x: 0.0265, y: 0.1144)
    ]
}

// MARK: - Fahrzeuge

enum DeliveryVehicle: String, Codable, CaseIterable, Identifiable {
    case car
    case van
    case sprinter
    case ev

    var id: String { rawValue }

    var name: String {
        switch self {
        case .car: return "Kombi"
        case .van: return "Transporter"
        case .sprinter: return "Sprinter"
        case .ev: return "EV-Flotte"
        }
    }

    var icon: String {
        switch self {
        case .car: return "car.fill"
        case .van: return "box.truck.fill"
        case .sprinter: return "bus.fill"
        case .ev: return "bolt.car.fill"
        }
    }

    /// Reisegeschwindigkeit, 1.0 ist der Kombi.
    var speed: Double {
        switch self {
        case .car: return 1.0
        case .van: return 1.25
        case .sprinter: return 1.55
        case .ev: return 1.9
        }
    }

    /// Kosten für den Umbau auf dieses Fahrzeug.
    var upgradeCost: Double {
        switch self {
        case .car: return 0
        case .van: return 2400
        case .sprinter: return 6800
        case .ev: return 16000
        }
    }

    var next: DeliveryVehicle? {
        switch self {
        case .car: return .van
        case .van: return .sprinter
        case .sprinter: return .ev
        case .ev: return nil
        }
    }

    /// Reisezeit in Sekunden für eine Strecke.
    func tripDuration(for distance: Double) -> TimeInterval {
        max(20, distance / 100 * 26 / speed)
    }
}

// MARK: - Fahrer

struct DeliveryDriver: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var vehicle: DeliveryVehicle
    var look: Int = 0
    var completedTrips: Int = 0
}

// MARK: - Auftrag

struct DeliveryOrder: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var cityID: String
    var strainID: String
    var grams: Double
    /// Warenwert in Dollar.
    var value: Double
    /// Trinkgeld in Dollar.
    var tip: Double
    var createdAt: Date = Date()

    var city: DeliveryCity { DeliveryCities.city(id: cityID) }
}

// MARK: - Fahrt

struct DeliveryTrip: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var order: DeliveryOrder
    var driverID: UUID
    var startedAt: Date = Date()
    var duration: TimeInterval

    func progress(now: Date = Date()) -> Double {
        guard duration > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(startedAt) / duration))
    }

    func remaining(now: Date = Date()) -> TimeInterval {
        max(0, duration - now.timeIntervalSince(startedAt))
    }
}
