//
//  Theme.swift
//  Emerald Coast
//
//  Farben, Hintergrund und das Glas-System der App.
//

import SwiftUI

enum Theme {
    static let emerald = Color(red: 0.31, green: 0.87, blue: 0.50)
    static let lime = Color(red: 0.69, green: 0.96, blue: 0.44)
    static let amber = Color(red: 0.98, green: 0.76, blue: 0.29)
    static let deepGreen = Color(red: 0.03, green: 0.12, blue: 0.07)
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.42)
    static let onAccent = Color(red: 0.02, green: 0.13, blue: 0.06)

    /// Tap-driven UI: critically damped, no bounce.
    static let tap = Animation.smooth(duration: 0.28)
}

/// Dunkelgrüner Verlauf mit weichem Emerald-Glow – der Hintergrund der ganzen App.
struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.135, blue: 0.078),
                    Color(red: 0.012, green: 0.055, blue: 0.032),
                    Color(red: 0.008, green: 0.032, blue: 0.021)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Theme.emerald.opacity(0.26), Theme.emerald.opacity(0.0)],
                center: UnitPoint(x: 0.5, y: 0.06),
                startRadius: 8,
                endRadius: 430
            )
            RadialGradient(
                colors: [Theme.lime.opacity(0.10), Theme.lime.opacity(0.0)],
                center: UnitPoint(x: 0.95, y: 0.88),
                startRadius: 4,
                endRadius: 340
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glas

/// Eine gläserne Fläche: natives Liquid Glass, feine helle Kontur und weicher Schatten.
struct GlassPanel: ViewModifier {
    var cornerRadius: CGFloat = 26
    var tint: Color = .clear
    var glow: Color?

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular.tint(tint), in: shape)
            .overlay {
                shape
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.26), .white.opacity(0.05), .white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
            .shadow(
                color: glow?.opacity(0.42) ?? Color.black.opacity(0.28),
                radius: glow == nil ? 16 : 26,
                y: glow == nil ? 10 : 2
            )
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat = 26, tint: Color = .clear, glow: Color? = nil) -> some View {
        modifier(GlassPanel(cornerRadius: cornerRadius, tint: tint, glow: glow))
    }
}

/// Weiches Feder-Feedback für jeden Tap.
struct SoftPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .brightness(configuration.isPressed ? 0.04 : 0)
            .animation(.smooth(duration: 0.18), value: configuration.isPressed)
    }
}
