//
//  Format.swift
//  Emerald Coast
//
//  Deutsche Zahlen- und Zeitformate für Geld, Gramm und Countdowns.
//

import Foundation

enum Format {
    private static let moneyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private static let gramFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }()

    static func money(_ value: Double) -> String {
        "\(plainMoney(value)) $"
    }

    static func cents(_ cents: Int) -> String {
        String(format: "%.2f $", locale: Locale(identifier: "de_DE"), Double(cents) / 100)
    }

    static func plainMoney(_ value: Double) -> String {
        let rounded = max(0, value.rounded())
        return moneyFormatter.string(from: NSNumber(value: rounded)) ?? "0"
    }

    static func grams(_ value: Double) -> String {
        let text = gramFormatter.string(from: NSNumber(value: max(0, value))) ?? "0"
        return "\(text) g"
    }

    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds.rounded(.up)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    static func percent(_ value: Double) -> String {
        "\(Int((min(1, max(0, value)) * 100).rounded())) %"
    }
}
