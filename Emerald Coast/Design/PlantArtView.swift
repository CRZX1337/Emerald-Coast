//
//  PlantArtView.swift
//  Emerald Coast
//
//  Eine gezeichnete Cannabis-Pflanze: Stamm, Fächerblätter, Colas.
//  Keine Bilddateien, alles im Canvas.
//

import SwiftUI

struct PlantArtView: View {
    var progress: Double
    var isReady: Bool

    @State private var sway = false

    private let stemColor = Color(red: 0.24, green: 0.52, blue: 0.23)
    private let leafStroke = Color(red: 0.05, green: 0.21, blue: 0.10)
    private let pistilColor = Color(red: 0.86, green: 0.48, blue: 0.18)

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .rotationEffect(.degrees(sway ? 1.1 : -1.1), anchor: .bottom)
        .animation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true), value: sway)
        .onAppear { sway = true }
    }

    // MARK: - Szene

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let clamped = CGFloat(min(1, max(0, progress)))

        let potW = w * 0.52
        let potH = h * 0.22
        let potX = (w - potW) / 2
        let potTop = h * 0.72

        let stemX = w * 0.50
        let plantHeight = h * (0.16 + 0.50 * clamped)
        let stemTop = potTop - plantHeight

        // Boden-Schatten
        context.fill(
            Path(ellipseIn: CGRect(x: potX - potW * 0.10, y: potTop + potH * 0.82,
                                   width: potW * 1.20, height: potH * 0.30)),
            with: .color(.black.opacity(0.28))
        )

        if isReady {
            context.fill(
                Path(ellipseIn: CGRect(x: w * 0.30, y: h * 0.16, width: w * 0.40, height: h * 0.52)),
                with: .radialGradient(
                    Gradient(colors: [Theme.lime.opacity(0.22), .clear]),
                    center: CGPoint(x: w * 0.5, y: h * 0.40),
                    startRadius: 2,
                    endRadius: w * 0.36
                )
            )
        }

        drawStem(in: &context, size: size, stemX: stemX, potTop: potTop, stemTop: stemTop)

        // Seitentriebe + Fächerblätter
        let nodes: [(t: CGFloat, direction: CGFloat, length: CGFloat)] = [
            (0.16, -1, 0.31),
            (0.34, 1, 0.30),
            (0.50, -1, 0.26),
            (0.66, 1, 0.23),
            (0.80, -1, 0.18)
        ]

        for (index, node) in nodes.enumerated() {
            let nodeAge = CGFloat(node.t) * 0.55
            let reveal = min(1, max(0, (clamped - nodeAge) / 0.20))
            guard reveal > 0.01 else { continue }

            let y = potTop - plantHeight * node.t
            let tip = CGPoint(
                x: stemX + node.direction * w * node.length,
                y: y - h * 0.09
            )

            var branch = Path()
            branch.move(to: CGPoint(x: stemX, y: y))
            branch.addQuadCurve(
                to: tip,
                control: CGPoint(x: stemX + node.direction * w * node.length * 0.55, y: y - h * 0.055)
            )
            context.stroke(branch, with: .color(stemColor), lineWidth: max(1.4, w * 0.010))

            let leafScale = w * (0.30 - 0.045 * CGFloat(index))
            drawFanLeaf(
                in: &context,
                base: tip,
                scale: leafScale * (0.55 + 0.45 * reveal),
                angle: node.direction * 0.55,
                tint: leafTint(for: node.t),
                reveal: reveal
            )

            if clamped > 0.56 {
                let budScale = w * 0.19 * budReveal(clamped)
                drawCola(
                    in: &context,
                    center: CGPoint(x: tip.x, y: tip.y - h * 0.055),
                    scale: budScale,
                    reveal: budReveal(clamped)
                )
            }
        }

        // Zwei Blätter direkt am Hauptstamm
        drawFanLeaf(
            in: &context,
            base: CGPoint(x: stemX, y: potTop - plantHeight * 0.26),
            scale: w * 0.26,
            angle: -0.95,
            tint: leafTint(for: 0.30),
            reveal: min(1, max(0, (clamped - 0.10) / 0.20))
        )
        drawFanLeaf(
            in: &context,
            base: CGPoint(x: stemX, y: potTop - plantHeight * 0.45),
            scale: w * 0.23,
            angle: 0.95,
            tint: leafTint(for: 0.48),
            reveal: min(1, max(0, (clamped - 0.22) / 0.20))
        )

        // Top-Cola
        if clamped > 0.40 {
            let reveal = budReveal(clamped)
            drawSugarLeaves(
                in: &context,
                center: CGPoint(x: stemX, y: stemTop + h * 0.02),
                scale: w * 0.16,
                reveal: reveal
            )
            drawCola(
                in: &context,
                center: CGPoint(x: stemX, y: stemTop - h * 0.01),
                scale: w * 0.28 * reveal,
                reveal: reveal
            )
        }

        drawPot(in: &context, size: size, potX: potX, potTop: potTop, potW: potW, potH: potH)
    }

    private func drawStem(in context: inout GraphicsContext, size: CGSize,
                          stemX: CGFloat, potTop: CGFloat, stemTop: CGFloat) {
        var stem = Path()
        stem.move(to: CGPoint(x: stemX, y: potTop + 4))
        stem.addQuadCurve(
            to: CGPoint(x: stemX - 2, y: stemTop),
            control: CGPoint(x: stemX + 5, y: (potTop + stemTop) / 2)
        )
        context.stroke(
            stem,
            with: .linearGradient(
                Gradient(colors: [stemColor.opacity(0.95), stemColor.opacity(0.65)]),
                startPoint: CGPoint(x: stemX, y: potTop),
                endPoint: CGPoint(x: stemX, y: stemTop)
            ),
            lineWidth: max(2.2, size.width * 0.017)
        )
    }

    private func drawPot(in context: inout GraphicsContext, size: CGSize,
                         potX: CGFloat, potTop: CGFloat, potW: CGFloat, potH: CGFloat) {
        var pot = Path()
        pot.move(to: CGPoint(x: potX, y: potTop))
        pot.addLine(to: CGPoint(x: potX + potW, y: potTop))
        pot.addLine(to: CGPoint(x: potX + potW * 0.91, y: potTop + potH))
        pot.addQuadCurve(
            to: CGPoint(x: potX + potW * 0.85, y: potTop + potH + 3),
            control: CGPoint(x: potX + potW * 0.91, y: potTop + potH + 3)
        )
        pot.addLine(to: CGPoint(x: potX + potW * 0.15, y: potTop + potH + 3))
        pot.addQuadCurve(
            to: CGPoint(x: potX + potW * 0.09, y: potTop + potH),
            control: CGPoint(x: potX + potW * 0.09, y: potTop + potH + 3)
        )
        pot.closeSubpath()

        context.fill(
            pot,
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.84, green: 0.48, blue: 0.29),
                    Color(red: 0.57, green: 0.27, blue: 0.15)
                ]),
                startPoint: CGPoint(x: potX, y: potTop),
                endPoint: CGPoint(x: potX + potW, y: potTop + potH)
            )
        )
        context.stroke(pot, with: .color(Color(red: 0.33, green: 0.15, blue: 0.08).opacity(0.65)), lineWidth: 1)

        // Erde
        context.fill(
            Path(ellipseIn: CGRect(x: potX + potW * 0.05, y: potTop - 5,
                                   width: potW * 0.90, height: 12)),
            with: .color(Color(red: 0.19, green: 0.11, blue: 0.06))
        )
    }

    // MARK: - Blätter

    private func leafTint(for height: CGFloat) -> Color {
        let light = Color(red: 0.47, green: 0.83, blue: 0.40)
        let dark = Color(red: 0.20, green: 0.55, blue: 0.27)
        return height < 0.45 ? light : dark
    }

    private func drawFanLeaf(in context: inout GraphicsContext, base: CGPoint,
                             scale: CGFloat, angle: CGFloat, tint: Color, reveal: CGFloat) {
        guard reveal > 0.02 else { return }

        let s = CGFloat(sin(Double(angle)))
        let c = CGFloat(cos(Double(angle)))
        let center = CGPoint(x: base.x + s * scale * 0.16, y: base.y - c * scale * 0.16)

        var petiole = Path()
        petiole.move(to: base)
        petiole.addLine(to: center)
        context.stroke(petiole, with: .color(stemColor), lineWidth: max(1, scale * 0.020))

        // 7 Fiedern: mittlere am längsten, äußere kürzer.
        let specs: [(CGFloat, CGFloat)] = [
            (-1.26, 0.56), (-0.88, 0.72), (-0.46, 0.88),
            (0.00, 1.00),
            (0.46, 0.88), (0.88, 0.72), (1.26, 0.56)
        ]

        for (offset, lengthFactor) in specs {
            let length = scale * lengthFactor * reveal
            let path = leafletPath(
                base: center,
                angle: angle + offset,
                length: length,
                width: scale * 0.072
            )

            let tip = CGPoint(
                x: center.x + CGFloat(sin(Double(angle + offset))) * length,
                y: center.y - CGFloat(cos(Double(angle + offset))) * length
            )

            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [tint.opacity(0.98), tint.opacity(0.68)]),
                    startPoint: center,
                    endPoint: tip
                )
            )
            context.stroke(path, with: .color(leafStroke.opacity(0.65)), lineWidth: 0.65)

            var vein = Path()
            vein.move(to: center)
            vein.addLine(to: tip)
            context.stroke(vein, with: .color(.white.opacity(0.10)), lineWidth: 0.5)
        }
    }

    private func leafletPath(base: CGPoint, angle: CGFloat,
                             length: CGFloat, width: CGFloat) -> Path {
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        let steps = 24
        let s = CGFloat(sin(Double(angle)))
        let c = CGFloat(cos(Double(angle)))

        for step in 0...steps {
            let u = CGFloat(step) / CGFloat(steps)
            let taper = CGFloat(pow(Double(sin(.pi * u)), 0.55))
            let tooth = 1 + 0.30 * CGFloat(sin(Double(u) * .pi * 22))
            let halfWidth = width * taper * tooth
            let along = CGPoint(x: base.x + s * length * u, y: base.y - c * length * u)
            left.append(CGPoint(x: along.x + c * halfWidth, y: along.y + s * halfWidth))
            right.append(CGPoint(x: along.x - c * halfWidth, y: along.y - s * halfWidth))
        }

        var path = Path()
        path.move(to: base)
        for point in left { path.addLine(to: point) }
        for point in right.reversed() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }

    // MARK: - Colas

    private func budReveal(_ progress: CGFloat) -> CGFloat {
        min(1, max(0, (progress - 0.40) / 0.36))
    }

    private func drawCola(in context: inout GraphicsContext, center: CGPoint,
                          scale: CGFloat, reveal: CGFloat) {
        guard scale > 1 else { return }

        // Dichte, unregelmäßige Cola aus vielen Kelchen.
        for index in 0..<26 {
            let t = CGFloat(index) / 25
            let y = center.y + scale * (0.55 - t * 1.08)
            let spread = scale * (0.10 + 0.26 * CGFloat(pow(Double(sin(.pi * min(1, t * 1.05))), 0.8)))
            let x = center.x + spread * CGFloat(sin(Double(index) * 2.7)) * 0.55
            let radius = scale * (0.055 + 0.035 * CGFloat(sin(.pi * t))) * (0.75 + 0.25 * reveal)
            let bright = index % 4 == 0

            let calyx = Path(ellipseIn: CGRect(x: x - radius, y: y - radius * 1.55,
                                               width: radius * 2, height: radius * 3.1))
            context.fill(
                calyx,
                with: .linearGradient(
                    Gradient(colors: bright
                             ? [Color(red: 0.80, green: 0.92, blue: 0.58), Color(red: 0.47, green: 0.72, blue: 0.36)]
                             : [Color(red: 0.58, green: 0.82, blue: 0.44), Color(red: 0.33, green: 0.60, blue: 0.31)]),
                    startPoint: CGPoint(x: x, y: y - radius),
                    endPoint: CGPoint(x: x, y: y + radius)
                )
            )
            context.stroke(calyx, with: .color(leafStroke.opacity(0.55)), lineWidth: 0.6)
        }

        // Pistillen
        for index in 0..<12 {
            let t = CGFloat(index) / 11
            let y = center.y + scale * (0.30 - t * 0.78)
            let x = center.x + scale * 0.17 * CGFloat(sin(Double(index) * 2.1))

            var hair = Path()
            hair.move(to: CGPoint(x: x, y: y))
            hair.addQuadCurve(
                to: CGPoint(x: x + scale * 0.10, y: y - scale * 0.06),
                control: CGPoint(x: x + scale * 0.02, y: y - scale * 0.09)
            )
            context.stroke(hair, with: .color(pistilColor.opacity(0.80)), lineWidth: max(0.6, scale * 0.013))
        }

        // Frost / Trichome
        for index in 0..<36 {
            let angle = CGFloat(index) * 2.399
            let radius = scale * 0.30 * CGFloat((index % 8) + 1) / 8
            let x = center.x + CGFloat(cos(Double(angle))) * radius * 0.55
            let y = center.y + scale * 0.05 - CGFloat(sin(Double(angle))) * radius
            let dot = Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2))
            context.fill(dot, with: .color(.white.opacity(0.55)))
        }
    }

    private func drawSugarLeaves(in context: inout GraphicsContext, center: CGPoint,
                                 scale: CGFloat, reveal: CGFloat) {
        drawFanLeaf(in: &context, base: CGPoint(x: center.x - scale * 0.4, y: center.y + scale * 0.5),
                    scale: scale * 0.9, angle: -0.85,
                    tint: Color(red: 0.30, green: 0.62, blue: 0.30), reveal: reveal)
        drawFanLeaf(in: &context, base: CGPoint(x: center.x + scale * 0.4, y: center.y + scale * 0.5),
                    scale: scale * 0.9, angle: 0.85,
                    tint: Color(red: 0.30, green: 0.62, blue: 0.30), reveal: reveal)
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
