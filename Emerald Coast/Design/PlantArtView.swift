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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sway = false

    private let stemColor = Color(red: 0.24, green: 0.52, blue: 0.23)
    private let leafStroke = Color(red: 0.05, green: 0.21, blue: 0.10)
    private let pistilColor = Color(red: 0.86, green: 0.48, blue: 0.18)

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .rotationEffect(.degrees(reduceMotion ? 0 : (sway ? 1.1 : -1.1)), anchor: .bottom)
        .animation(reduceMotion ? nil : .easeInOut(duration: 3.6).repeatForever(autoreverses: true), value: sway)
        .onAppear { sway = !reduceMotion }
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
        let plantHeight = h * (0.14 + 0.42 * clamped)
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
            (0.16, -1, 0.26),
            (0.34, 1, 0.25),
            (0.50, -1, 0.22),
            (0.66, 1, 0.19),
            (0.80, -1, 0.16)
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

            let leafScale = w * (0.26 - 0.040 * CGFloat(index))
            drawFanLeaf(
                in: &context,
                base: tip,
                scale: leafScale * (0.55 + 0.45 * reveal),
                angle: node.direction * 0.55,
                tint: leafTint(for: node.t),
                reveal: reveal
            )

            if clamped > 0.40 {
                let budScale = w * 0.22 * budReveal(clamped)
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
                center: CGPoint(x: stemX, y: stemTop + h * 0.03),
                scale: w * 0.30 * reveal,
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

    private func budNoise(_ index: Int, _ salt: Double) -> CGFloat {
        let value = sin(Double(index) * 12.9898 + salt * 78.233) * 43758.5453
        return CGFloat(value - floor(value))
    }

    /// Ein Kelch: unten rund, oben spitz zulaufend – keine Kugel.
    private func calyxPath(center: CGPoint, width: CGFloat, height: CGFloat, lean: CGFloat) -> Path {
        var path = Path()
        let tip = CGPoint(x: center.x + lean * width, y: center.y - height)
        path.move(to: tip)
        path.addQuadCurve(
            to: CGPoint(x: center.x + width, y: center.y + height * 0.08),
            control: CGPoint(x: center.x + width * 0.94, y: center.y - height * 0.52)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x, y: center.y + height),
            control: CGPoint(x: center.x + width * 0.78, y: center.y + height * 0.80)
        )
        path.addQuadCurve(
            to: CGPoint(x: center.x - width, y: center.y + height * 0.08),
            control: CGPoint(x: center.x - width * 0.78, y: center.y + height * 0.80)
        )
        path.addQuadCurve(
            to: tip,
            control: CGPoint(x: center.x - width * 0.94, y: center.y - height * 0.52)
        )
        path.closeSubpath()
        return path
    }

    private func drawCola(in context: inout GraphicsContext, center: CGPoint,
                          scale: CGFloat, reveal: CGFloat) {
        guard scale > 1, reveal > 0.01 else { return }

        let s = scale * (0.52 + 0.48 * reveal)
        let alpha = Double(min(1, reveal * 1.15))

        // Zuckerblätter hinter der Cola
        for (index, angle) in [CGFloat(-1.45), -1.05, 1.05, 1.45].enumerated() {
            let side: CGFloat = index < 2 ? -1 : 1
            let base = CGPoint(
                x: center.x + side * s * 0.17,
                y: center.y + s * 0.42
            )
            drawFanLeaf(
                in: &context,
                base: base,
                scale: s * 0.34,
                angle: angle,
                tint: Color(red: 0.34, green: 0.62, blue: 0.30),
                reveal: reveal
            )
        }

        // Weiche, unregelmäßige Grundsilhouette aus überlappenden Kelchen.
        for index in 0..<46 {
            let t = (CGFloat(index) + 0.5) / 46
            let profile = CGFloat(pow(Double(sin(.pi * min(1, t * 1.02))), 0.58))
            let y = center.y + s * (0.55 - t * 1.10)
            let width = s * (0.085 + 0.235 * profile) * (0.88 + 0.24 * budNoise(index, 1.7))
            let x = center.x + (budNoise(index, 4.2) - 0.5) * s * 0.07
            let path = calyxPath(
                center: CGPoint(x: x, y: y),
                width: width,
                height: width * (1.25 + 0.35 * budNoise(index, 8.1)),
                lean: (budNoise(index, 12.4) - 0.5) * 0.35
            )
            context.fill(path, with: .color(Color(red: 0.10, green: 0.22, blue: 0.10).opacity(0.96 * alpha)))
        }

        // Drei Tiefenlagen: dunkle Basis, mittlere Kelche, wenige helle Spitzen.
        let layers: [(count: Int, width: CGFloat, light: Color, dark: Color, stroke: Double)] = [
            (24, 0.072, Color(red: 0.33, green: 0.50, blue: 0.24), Color(red: 0.13, green: 0.26, blue: 0.12), 0.18),
            (30, 0.049, Color(red: 0.52, green: 0.70, blue: 0.34), Color(red: 0.23, green: 0.40, blue: 0.18), 0.30),
            (22, 0.030, Color(red: 0.68, green: 0.82, blue: 0.45), Color(red: 0.36, green: 0.55, blue: 0.25), 0.16)
        ]

        for (layerIndex, layer) in layers.enumerated() {
            for index in 0..<layer.count {
                let salt = Double(layerIndex) * 31.7 + 3.3
                let t = (CGFloat(index) + 0.35 + 0.3 * budNoise(index, salt)) / CGFloat(layer.count)
                let profile = CGFloat(pow(Double(sin(.pi * min(1, t * 1.02))), 0.58))
                let y = center.y + s * (0.51 - t * 1.02)
                let spread = s * (0.06 + 0.22 * profile)
                let x = center.x + (budNoise(index, salt + 2.1) - 0.5) * 2 * spread
                let width = s * layer.width * (0.78 + 0.46 * budNoise(index, salt + 5.4))
                let height = width * (1.20 + 0.42 * budNoise(index, salt + 9.9))
                let lean = (budNoise(index, salt + 13.2) - 0.5) * 0.55
                let path = calyxPath(center: CGPoint(x: x, y: y), width: width, height: height, lean: lean)

                context.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [layer.light.opacity(alpha), layer.dark.opacity(alpha)]),
                        startPoint: CGPoint(x: x - width * 0.25, y: y - height),
                        endPoint: CGPoint(x: x + width * 0.25, y: y + height)
                    )
                )
                if layer.stroke > 0 {
                    context.stroke(path, with: .color(leafStroke.opacity(Double(layer.stroke) * alpha)), lineWidth: 0.45)
                }

                // Dunkle Kerbe am Kelchansatz – erzeugt Tiefe statt Glitzer.
                if layerIndex == 1 && index % 3 == 0 {
                    var crease = Path()
                    crease.move(to: CGPoint(x: x - width * 0.35, y: y + height * 0.62))
                    crease.addQuadCurve(
                        to: CGPoint(x: x + width * 0.40, y: y + height * 0.55),
                        control: CGPoint(x: x, y: y + height * 0.92)
                    )
                    context.stroke(crease, with: .color(Color.black.opacity(0.12 * alpha)), lineWidth: 0.7)
                }
            }
        }

        // Zuckerblätter vor der Cola
        for angle in [CGFloat(-1.35), 1.35] {
            drawFanLeaf(
                in: &context,
                base: CGPoint(x: center.x + (angle < 0 ? -1 : 1) * s * 0.22,
                              y: center.y + s * 0.28),
                scale: s * 0.26,
                angle: angle,
                tint: Color(red: 0.34, green: 0.64, blue: 0.31),
                reveal: reveal
            )
        }

        // Pistillen: fein, gebogen, spärlich – kein Streumuster.
        for index in 0..<14 {
            let t = (CGFloat(index) + 0.5) / 14
            let y = center.y + s * (0.38 - t * 0.86)
            let side: CGFloat = index % 2 == 0 ? -1 : 1
            let x = center.x + side * s * (0.06 + 0.14 * budNoise(index, 21.3))
            let length = s * (0.055 + 0.055 * budNoise(index, 24.8))

            var hair = Path()
            hair.move(to: CGPoint(x: x, y: y))
            hair.addQuadCurve(
                to: CGPoint(x: x + side * length, y: y - length * 0.70),
                control: CGPoint(x: x + side * length * 0.30, y: y - length * 0.85)
            )
            context.stroke(hair, with: .color(pistilColor.opacity(0.72 * alpha)), lineWidth: max(0.5, s * 0.009))
        }

        // Trichome: nur an den oberen Rändern, sehr zurückhaltend.
        for index in 0..<54 {
            let t = CGFloat(index) / 53
            let y = center.y + s * (0.40 - t * 0.94)
            let profile = CGFloat(pow(Double(sin(.pi * min(1, t * 1.02))), 0.58))
            let side: CGFloat = index % 2 == 0 ? -1 : 1
            let x = center.x + side * s * (0.04 + (0.20 * profile) * (0.65 + 0.35 * budNoise(index, 30.1)))
            let size = 0.7 + 0.7 * budNoise(index, 33.6)
            let dot = Path(ellipseIn: CGRect(x: x, y: y, width: size, height: size))
            context.fill(dot, with: .color(.white.opacity(Double(0.16 + 0.24 * budNoise(index, 37.9)) * alpha)))
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
