//
//  CrewArt.swift
//  Emerald Coast
//
//  Gezeichnetes Porträt für Teammitglieder und Bewerber.
//

import SwiftUI

struct CrewAvatar: View {
    var look: Int
    var role: CrewRole
    var size: CGFloat = 58

    private var palette: [(Color, Color)] {
        [
            (Color(red: 0.62, green: 0.88, blue: 0.55), Color(red: 0.14, green: 0.44, blue: 0.26)),
            (Color(red: 0.55, green: 0.78, blue: 0.95), Color(red: 0.16, green: 0.32, blue: 0.58)),
            (Color(red: 0.95, green: 0.75, blue: 0.45), Color(red: 0.48, green: 0.30, blue: 0.10)),
            (Color(red: 0.85, green: 0.60, blue: 0.92), Color(red: 0.36, green: 0.20, blue: 0.50)),
            (Color(red: 0.95, green: 0.62, blue: 0.60), Color(red: 0.50, green: 0.22, blue: 0.26)),
            (Color(red: 0.55, green: 0.90, blue: 0.86), Color(red: 0.13, green: 0.40, blue: 0.40))
        ]
    }

    var body: some View {
        let colors = palette[abs(look) % palette.count]

        ZStack(alignment: .bottomTrailing) {
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
                    .font(.system(size: size * 0.46, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .offset(y: size * 0.02)
            }
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(.white.opacity(0.30), lineWidth: 1.4))

            Image(systemName: role.icon)
                .font(.system(size: size * 0.17, weight: .bold))
                .foregroundStyle(Theme.onAccent)
                .frame(width: size * 0.34, height: size * 0.34)
                .background(Circle().fill(role.tint))
                .overlay(Circle().strokeBorder(.black.opacity(0.25), lineWidth: 1))
                .offset(x: size * 0.03, y: size * 0.02)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.32), radius: 8, y: 4)
    }
}

/// Sterne für die Fähigkeit eines Bewerbers.
struct SkillStars: View {
    var skill: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < skill ? "star.fill" : "star")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(index < skill ? Theme.amber : Color.white.opacity(0.22))
            }
        }
    }
}
