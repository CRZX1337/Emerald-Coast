//
//  DispensaryArt.swift
//  Emerald Coast
//
//  Gezeichnetes Sortenglas und Kunden-Avatare für den Laden.
//

import SwiftUI

/// Ein Glas mit Buds und Etikett – komplett gezeichnet.
struct JarArtView: View {
    var strainName: String
    var size: CGFloat = 150

    var body: some View {
        ZStack {
            // Etikett im Glas
            VStack(spacing: 2) {
                Text("CANNABIZ")
                    .font(.system(size: size * 0.045, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.55))
                Text(strainName.uppercased())
                    .font(.system(size: size * 0.062, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, size * 0.08)
            .padding(.vertical, size * 0.05)
            .background(
                RoundedRectangle(cornerRadius: size * 0.03, style: .continuous)
                    .fill(Color(red: 0.05, green: 0.20, blue: 0.11).opacity(0.85))
            )
            .frame(width: size * 0.52)
            .offset(y: size * 0.04)

            // Buds
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.62, green: 0.88, blue: 0.42),
                                Color(red: 0.22, green: 0.55, blue: 0.28)
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: size * 0.12
                        )
                    )
                    .frame(width: size * 0.2, height: size * 0.2)
                    .offset(
                        x: CGFloat(cos(Double(index) / 6 * 2 * .pi)) * size * 0.14,
                        y: size * 0.1 + CGFloat(sin(Double(index) / 6 * 2 * .pi)) * size * 0.1
                    )
                    .blur(radius: 0.4)
            }

            // Glas
            RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.20), .white.opacity(0.05), .white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.07, style: .continuous)
                        .strokeBorder(.white.opacity(0.30), lineWidth: 1)
                )
                .frame(width: size * 0.62, height: size * 0.68)
                .offset(y: size * 0.06)

            // Deckel
            RoundedRectangle(cornerRadius: size * 0.03, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.72, green: 0.55, blue: 0.32), Color(red: 0.42, green: 0.29, blue: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.66, height: size * 0.11)
                .offset(y: -size * 0.27)

            // Glanzstreifen
            Capsule()
                .fill(.white.opacity(0.22))
                .frame(width: size * 0.035, height: size * 0.42)
                .offset(x: -size * 0.18, y: size * 0.04)
                .blur(radius: 1)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
    }
}

/// Ein Kunde als gezeichneter Avatar.
struct CustomerAvatar: View {
    var look: Int
    var size: CGFloat = 46

    private var palette: [(Color, Color)] {
        [
            (Color(red: 0.96, green: 0.66, blue: 0.36), Color(red: 0.55, green: 0.30, blue: 0.14)),
            (Color(red: 0.92, green: 0.55, blue: 0.55), Color(red: 0.48, green: 0.22, blue: 0.30)),
            (Color(red: 0.55, green: 0.82, blue: 0.72), Color(red: 0.16, green: 0.42, blue: 0.38)),
            (Color(red: 0.62, green: 0.68, blue: 0.96), Color(red: 0.24, green: 0.28, blue: 0.55)),
            (Color(red: 0.95, green: 0.84, blue: 0.55), Color(red: 0.50, green: 0.40, blue: 0.18)),
            (Color(red: 0.80, green: 0.60, blue: 0.95), Color(red: 0.35, green: 0.20, blue: 0.50))
        ]
    }

    var body: some View {
        let colors = palette[abs(look) % palette.count]
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [colors.0, colors.1],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.44, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1.4))
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
    }
}
