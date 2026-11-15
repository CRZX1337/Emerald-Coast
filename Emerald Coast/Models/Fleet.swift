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
    static let home = DeliveryCity(id: "humboldt", name: "Humboldt", x: 0.074, y: 0.141, distance: 0)

    static let all: [DeliveryCity] = [
        home,
        DeliveryCity(id: "oakland", name: "Oakland", x: 0.237, y: 0.444, distance: 450),
        DeliveryCity(id: "san-francisco", name: "San Francisco", x: 0.224, y: 0.448, distance: 430),
        DeliveryCity(id: "los-angeles", name: "Los Angeles", x: 0.588, y: 0.823, distance: 1000)
    ]

    static let destinations: [DeliveryCity] = all.filter { $0.id != home.id }

    static func city(id: String) -> DeliveryCity {
        all.first { $0.id == id } ?? home
    }

    /// Vereinfachte Umrisse Kaliforniens als normalisierte Punkte.
    static let outline: [CGPoint] = [
        CGPoint(x: 0.070, y: 0.020),
        CGPoint(x: 0.435, y: 0.020),
        CGPoint(x: 0.435, y: 0.323),
        CGPoint(x: 0.904, y: 0.727),
        CGPoint(x: 0.913, y: 0.788),
        CGPoint(x: 0.904, y: 0.889),
        CGPoint(x: 0.687, y: 0.970),
        CGPoint(x: 0.652, y: 0.899),
        CGPoint(x: 0.574, y: 0.848),
        CGPoint(x: 0.470, y: 0.788),
        CGPoint(x: 0.383, y: 0.768),
        CGPoint(x: 0.270, y: 0.596),
        CGPoint(x: 0.217, y: 0.444),
        CGPoint(x: 0.113, y: 0.293),
        CGPoint(x: 0.052, y: 0.182)
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
