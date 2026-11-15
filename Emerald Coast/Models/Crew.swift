//
//  Crew.swift
//  Emerald Coast
//
//  Grower und Budtender: Team, Löhne und Bewerber.
//

import Foundation
import SwiftUI

enum CrewRole: String, Codable, CaseIterable {
    case grower
    case budtender

    var title: String {
        switch self {
        case .grower: return "Grower"
        case .budtender: return "Budtender"
        }
    }

    var icon: String {
        switch self {
        case .grower: return "leaf.fill"
        case .budtender: return "cart.fill"
        }
    }

    var tint: Color {
        switch self {
        case .grower: return Theme.lime
        case .budtender: return Theme.amber
        }
    }

    /// Tageslohn (8-Stunden-Schicht) auf Stufe 1 und Fähigkeit 1.
    var baseWage: Double {
        switch self {
        case .grower: return 200
        case .budtender: return 144
        }
    }

    /// Aktionen pro Minute auf Stufe 1 und Fähigkeit 1.
    var baseActions: Double {
        switch self {
        case .grower: return 4
        case .budtender: return 6
        }
    }

    var actionLabel: String {
        switch self {
        case .grower: return "Ernten und Anpflanzen"
        case .budtender: return "Verkäufe"
        }
    }
}

struct CrewMember: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var role: CrewRole
    /// 1 bis 5 Sterne, bestimmt Starttempo und Lohn.
    var skill: Int
    var level: Int = 1
    var xp: Double = 0
    var look: Int = 0
    var hiredAt: Date = Date()

    var xpNeeded: Double { 60 * Double(level) }
    var xpProgress: Double { min(1, max(0, xp / xpNeeded)) }
}

struct CrewApplicant: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var role: CrewRole
    var skill: Int
    var look: Int = 0
    var hireCost: Double
}

enum CrewNames {
    static let all: [String] = [
        "Marisol", "Devon", "Kai", "Rosa", "Tyrell", "Juno", "Andre",
        "Sofia", "Malik", "Nico", "Priya", "Owen", "Zaria", "Luca",
        "Ines", "Rafael", "Maya", "Tobias", "Nia", "Emilio"
    ]

    static func random(excluding used: Set<String>) -> String {
        let free = all.filter { !used.contains($0) }
        return free.randomElement() ?? all.randomElement() ?? "Sam"
    }
}
