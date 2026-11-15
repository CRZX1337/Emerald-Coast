//
//  Components.swift
//  Emerald Coast
//
//  Wiederverwendbare Glas-Bausteine: Geld, Level, Ring, Tab-Leiste, Toast.
//

import SwiftUI

// MARK: - Münze

struct CoinIcon: View {
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.99, green: 0.86, blue: 0.48), Color(red: 0.86, green: 0.60, blue: 0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text("$")
                .font(.system(size: size * 0.56, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.40, green: 0.26, blue: 0.04))
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 0.8))
        .shadow(color: Theme.amber.opacity(0.45), radius: 5)
    }
}

// MARK: - Geld

struct MoneyPill: View {
    let money: Double

    var body: some View {
        HStack(spacing: 8) {
            CoinIcon(size: 21)
            Text(Format.plainMoney(money))
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.amber)
                .contentTransition(.numericText(value: money))
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassPanel(cornerRadius: 24, tint: Theme.amber.opacity(0.12))
        .accessibilityLabel("Guthaben \(Format.money(money))")
    }
}

// MARK: - Level

struct LevelBadge: View {
    let level: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.emerald)
                .shadow(color: Theme.emerald.opacity(0.6), radius: 5)

            VStack(alignment: .leading, spacing: 6) {
                Text("Level \(level)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.14))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.emerald, Theme.lime],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(5, geo.size.width * min(1, max(0, progress))))
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 162, alignment: .leading)
        .glassPanel(cornerRadius: 24, tint: Theme.emerald.opacity(0.12))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
    }
}

// MARK: - Fortschrittsring

struct RingProgress: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.09), lineWidth: 15)

            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(
                    AngularGradient(
                        colors: [Theme.emerald, Theme.lime, Theme.emerald],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 15, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.lime.opacity(0.55), radius: 9)
                .animation(.easeOut(duration: 0.45), value: progress)
        }
    }
}

// MARK: - Glas-Buttons

struct GlassActionButton: View {
    let title: String
    let icon: String
    var prominent: Bool = false
    var glow: Color? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else { return }
            action()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
            .foregroundStyle(prominent ? Color.white : Color.white.opacity(0.9))
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background {
                if prominent {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.42, green: 0.86, blue: 0.44),
                                    Color(red: 0.20, green: 0.66, blue: 0.34)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .glassPanel(cornerRadius: 30, tint: prominent ? .clear : Theme.emerald.opacity(0.10), glow: glow)
            .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(SoftPressStyle())
        .disabled(!enabled)
    }
}

// MARK: - Toast

struct ToastBanner: View {
    let store: GameStore
    let toast: ToastMessage

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: toast.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.emerald)
            Text(toast.text)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .glassPanel(cornerRadius: 22)
        .task(id: toast.id) {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            store.clearToast(toast.id)
        }
    }
}

// MARK: - Tabs

enum AppTab: String, CaseIterable, Identifiable {
    case grow
    case brands
    case shop
    case fleet
    case crew

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grow: return "Grow"
        case .brands: return "Brands"
        case .shop: return "Shop"
        case .fleet: return "Fleet"
        case .crew: return "Crew"
        }
    }

    var icon: String {
        switch self {
        case .grow: return "leaf.fill"
        case .brands: return "tag.fill"
        case .shop: return "cart.fill"
        case .fleet: return "box.truck.fill"
        case .crew: return "person.2.fill"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { tab in
                Button {
                    Haptics.light()
                    withAnimation(reduceMotion ? nil : Theme.tap) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(selection == tab ? Theme.emerald : Color.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if selection == tab {
                            Capsule(style: .continuous)
                                .fill(Theme.emerald.opacity(0.16))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(Theme.emerald.opacity(0.28), lineWidth: 1)
                                )
                                .matchedGeometryEffect(id: "tabPill", in: namespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(SoftPressStyle())
            }
        }
        .padding(6)
        .glassPanel(cornerRadius: 32)
    }
}

// MARK: - Kleine Bausteine

struct SectionTitle: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }
}

struct BrandMark: View {
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.emerald)
                .shadow(color: Theme.emerald.opacity(0.7), radius: 6)
            Text("CANNABIZ")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.72))
        }
    }
}
