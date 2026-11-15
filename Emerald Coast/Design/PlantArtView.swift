//
//  PlantArtView.swift
//  Emerald Coast
//
//  Die Pflanze, der Topf und die Buds – komplett gezeichnet, ohne Bilddateien.
//

import SwiftUI

/// Ein einzelnes Blatt mit sieben gezackten Fiedern.
struct CannabisLeafShape: Shape {
    var lobes: Int = 7
    var spread: CGFloat = 0.82
    var serration: CGFloat = 0.18

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let base = CGPoint(x: rect.midX, y: rect.maxY)

        for index in 0..<lobes {
            let step = lobes > 1 ? CGFloat(index) / CGFloat(lobes - 1) : 0.5
            let centered = step - 0.5
            let angle = centered * .pi * spread
            let length = rect.height * (1 - 0.46 * abs(centered) * 2)
            let width = length * 0.19
            path.addPath(leaflet(from: base, angle: angle, length: length, width: width))
        }
        return path
    }

    private func leaflet(from base: CGPoint, angle: CGFloat, length: CGFloat, width: CGFloat) -> Path {
        var path = Path()
        let dir = CGVector(dx: sin(angle), dy: -cos(angle))
        let normal = CGVector(dx: cos(angle), dy: sin(angle))
        let steps = 16

        var left: [CGPoint] = []
        var right: [CGPoint] = []

        for step in 0...steps {
            let u = CGFloat(step) / CGFloat(steps)
            let taper = pow(sin(.pi * u), 0.72)
            let teeth = 1 + serration * CGFloat(sin(Double(u) * .pi * 7))
            let w = width * taper * teeth
            let along = CGPoint(x: base.x + dir.dx * length * u, y: base.y + dir.dy * length * u)
            left.append(CGPoint(x: along.x + normal.dx * w, y: along.y + normal.dy * w))
            right.append(CGPoint(x: along.x - normal.dx * w, y: along.y - normal.dy * w))
        }

        path.move(to: base)
        for point in left { path.addLine(to: point) }
        for point in right.reversed() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }
}

/// Ein Bud mit Fäden und Frost.
struct BudView: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.68, green: 0.90, blue: 0.48), Color(red: 0.26, green: 0.60, blue: 0.30)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.52, height: size * 0.52)
                    .offset(
                        x: CGFloat(cos(Double(index) / 7 * 2 * .pi)) * size * 0.24,
                        y: CGFloat(sin(Double(index) / 7 * 2 * .pi)) * size * 0.28
                    )
            }
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.86, green: 0.97, blue: 0.62), Color(red: 0.36, green: 0.70, blue: 0.34)],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.58, height: size * 0.58)

            ForEach(0..<5, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.75))
                    .frame(width: 1, height: size * 0.26)
                    .offset(y: -size * 0.26)
                    .rotationEffect(.degrees(Double(index - 2) * 24))
            }
        }
        .frame(width: size * 1.2, height: size * 1.2)
        .shadow(color: Theme.lime.opacity(0.35), radius: 6)
    }
}

/// Terrakotta-Topf mit Erde.
struct PotShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rimHeight = rect.height * 0.2

        path.addRoundedRect(
            in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rimHeight),
            cornerSize: CGSize(width: 5, height: 5)
        )

        let bodyTop = rect.minY + rimHeight * 0.75
        let inset = rect.width * 0.11
        let bottom = rect.maxY

        path.move(to: CGPoint(x: rect.minX + 2, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: bottom - 8))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + inset + 10, y: bottom),
            control: CGPoint(x: rect.minX + inset, y: bottom)
        )
        path.addLine(to: CGPoint(x: rect.maxX - inset - 10, y: bottom))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - inset, y: bottom - 8),
            control: CGPoint(x: rect.maxX - inset, y: bottom)
        )
        path.addLine(to: CGPoint(x: rect.maxX - 2, y: bodyTop))
        path.closeSubpath()
        return path
    }
}

private struct LeafSpec {
    let dx: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
}

/// Die wachsende Pflanze im Topf.
struct PlantArtView: View {
    var progress: Double
    var isReady: Bool

    @State private var sway = false

    private let leaves: [LeafSpec] = [
        LeafSpec(dx: 0.00, y: 0.56, rotation: 0, scale: 1.00),
        LeafSpec(dx: -0.15, y: 0.55, rotation: -32, scale: 0.94),
        LeafSpec(dx: 0.15, y: 0.55, rotation: 32, scale: 0.94),
        LeafSpec(dx: -0.25, y: 0.48, rotation: -58, scale: 0.78),
        LeafSpec(dx: 0.25, y: 0.48, rotation: 58, scale: 0.78),
        LeafSpec(dx: -0.11, y: 0.42, rotation: -18, scale: 0.90),
        LeafSpec(dx: 0.11, y: 0.42, rotation: 18, scale: 0.90),
        LeafSpec(dx: 0.00, y: 0.37, rotation: 2, scale: 0.92),
        LeafSpec(dx: -0.17, y: 0.33, rotation: -48, scale: 0.66),
        LeafSpec(dx: 0.17, y: 0.33, rotation: 48, scale: 0.66),
        LeafSpec(dx: 0.00, y: 0.25, rotation: -3, scale: 0.70)
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let potWidth = w * 0.56
            let potHeight = h * 0.25
            let potTop = h * 0.66

            ZStack {
                if isReady {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.lime.opacity(0.34), Theme.lime.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: w * 0.5
                            )
                        )
                        .frame(width: w * 1.1, height: w * 1.1)
                        .blur(radius: 14)
                        .offset(y: -h * 0.05)
                }

                // Stiel
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.30, green: 0.62, blue: 0.26), Color(red: 0.16, green: 0.44, blue: 0.22)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: w * 0.035, height: h * 0.46)
                    .position(x: w * 0.5, y: potTop - h * 0.2)

                ForEach(Array(leaves.enumerated()), id: \.offset) { item in
                    let reveal = revealAmount(item.offset)
                    let spec = item.element
                    CannabisLeafShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.50, green: 0.88, blue: 0.44),
                                    Color(red: 0.20, green: 0.60, blue: 0.29)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            CannabisLeafShape()
                                .stroke(Color(red: 0.05, green: 0.24, blue: 0.12).opacity(0.45), lineWidth: 0.7)
                        )
                        .frame(width: w * 0.42 * spec.scale, height: h * 0.36 * spec.scale)
                        .rotationEffect(.degrees(spec.rotation))
                        .position(x: w * (0.5 + spec.dx), y: h * spec.y)
                        .scaleEffect(0.5 + 0.5 * reveal)
                        .opacity(reveal)
                        .shadow(color: Color(red: 0.02, green: 0.10, blue: 0.05).opacity(0.5), radius: 5, y: 3)
                }

                if progress > 0.52 {
                    let budReveal = min(1, max(0, (progress - 0.52) / 0.4))
                    BudView(size: w * 0.19)
                        .position(x: w * 0.5, y: h * 0.22)
                        .scaleEffect(0.6 + 0.4 * budReveal)
                        .opacity(budReveal)
                    BudView(size: w * 0.15)
                        .position(x: w * 0.38, y: h * 0.32)
                        .scaleEffect(0.6 + 0.4 * budReveal)
                        .opacity(budReveal * 0.95)
                    BudView(size: w * 0.15)
                        .position(x: w * 0.62, y: h * 0.31)
                        .scaleEffect(0.6 + 0.4 * budReveal)
                        .opacity(budReveal * 0.95)
                }

                // Topf
                PotShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.84, green: 0.48, blue: 0.29),
                                Color(red: 0.60, green: 0.29, blue: 0.16)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: potWidth, height: potHeight)
                    .position(x: w * 0.5, y: potTop + potHeight * 0.5)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 5)

                Ellipse()
                    .fill(Color(red: 0.20, green: 0.12, blue: 0.07))
                    .frame(width: potWidth * 0.78, height: potHeight * 0.13)
                    .position(x: w * 0.5, y: potTop + potHeight * 0.10)
            }
            .rotationEffect(.degrees(sway ? 1.4 : -1.4), anchor: .bottom)
            .animation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true), value: sway)
            .onAppear { sway = true }
        }
    }

    private func revealAmount(_ index: Int) -> Double {
        let threshold = Double(index) / Double(leaves.count) * 0.62
        return min(1, max(0, (progress - threshold) / 0.18))
    }
}

/// Platzhalter, solange kein Samen gesetzt ist.
struct EmptyPlantArt: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: size * 0.62, height: size * 0.62)
                Circle()
                    .strokeBorder(.white.opacity(0.16), style: StrokeStyle(lineWidth: 1.5, dash: [6, 7]))
                    .frame(width: size * 0.62, height: size * 0.62)
                Image(systemName: "leaf")
                    .font(.system(size: size * 0.22, weight: .light))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
