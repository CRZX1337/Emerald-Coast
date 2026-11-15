//
//  PermitsView.swift
//  Emerald Coast
//
//  Permits, Viertel und Heat – der Compliance-Screen.
//

import SwiftUI

struct PermitsView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                heatCard
                districtSection
                footnote
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Kopfzeile

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Permits")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Lizenzen, Viertel und Heat")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                MoneyPill(money: store.money)

                Button {
                    Haptics.light()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .glassPanel(cornerRadius: 18)
                }
                .buttonStyle(SoftPressStyle())
                .accessibilityLabel("Schließen")
            }
        }
    }

    // MARK: Heat

    private var heatCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text("Heat")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text(Format.percent(store.heat / Compliance.inspectionThreshold))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Compliance.color(for: store.heat))
                    .contentTransition(.numericText(value: store.heat))
                    .monospacedDigit()
            }

            HeatBar(value: store.heat / Compliance.inspectionThreshold)

            HStack(spacing: 7) {
                Image(systemName: heatIcon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Compliance.color(for: store.heat))

                Text(heatStatusText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        store.buyAccounting()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(store.isAccountingActive ? Format.clock(store.accountingRemaining) : "Buchhaltung")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                        if !store.isAccountingActive {
                            Text(Format.plainMoney(Compliance.accountingCost))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.amber)
                        }
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .glassPanel(cornerRadius: 16, tint: Theme.emerald.opacity(0.10))
                }
                .buttonStyle(SoftPressStyle())
                .disabled(store.isAccountingActive || store.money < Compliance.accountingCost)
                .opacity(store.isAccountingActive || store.money < Compliance.accountingCost ? 0.5 : 1)
                .accessibilityLabel("Buchhaltung buchen")
            }

            if store.inspectionsToday > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(red: 1.0, green: 0.48, blue: 0.45))
                    Text("\(store.inspectionsToday)× Kontrolle heute · \(Format.money(store.finesToday)) Strafe")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(
            cornerRadius: 26,
            tint: store.heat >= 60 ? Color.red.opacity(0.10) : Theme.emerald.opacity(0.06)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: store.heat)
    }

    private var heatIcon: String {
        if store.isShutDown { return "lock.fill" }
        if store.isAccountingActive { return "doc.text.fill" }
        switch store.heat {
        case ..<40: return "checkmark.shield.fill"
        case ..<70: return "exclamationmark.triangle.fill"
        default: return "exclamationmark.octagon.fill"
        }
    }

    private var heatStatusText: String {
        if store.isShutDown {
            return "Kontrolle · Laden noch \(Format.clock(store.shutdownRemaining)) zu"
        }
        if store.isAccountingActive {
            return "Buchhaltung läuft · Heat sinkt schneller"
        }
        switch store.heat {
        case ..<1:
            return "Ruhig · keine Kontrolle in Sicht"
        case ..<40:
            return "Beobachtet · Heat baut sich von selbst ab"
        case ..<70:
            return "Auffällig · Permit jetzt kaufen"
        default:
            return "Kritisch · die nächste Kontrolle kommt bald"
        }
    }

    // MARK: Viertel

    private var districtSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(
                text: "Viertel",
                trailing: "\(store.permittedDistrictIDs.count) von \(Districts.all.count) lizenziert"
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(Districts.all) { district in
                    DistrictCard(district: district)
                }
            }
        }
    }

    private var footnote: some View {
        HStack(spacing: 8) {
            Image(systemName: "stamp.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            Text("Ohne Permit keine Lieferungen in die Stadt. Boni wirken erst mit Permit.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }
}

// MARK: - Heat-Balken

struct HeatBar: View {
    /// 0…1
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.10))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.emerald,
                                Theme.lime,
                                Theme.amber,
                                Color(red: 1.0, green: 0.42, blue: 0.40)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, geo.size.width * min(1, max(0, value))))
                    .shadow(color: Compliance.color(for: value * Compliance.inspectionThreshold).opacity(0.55), radius: 8)
            }
        }
        .frame(height: 12)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: value)
    }
}

// MARK: - Viertel-Karte

struct DistrictCard: View {
    @Environment(GameStore.self) private var store
    let district: District

    private var licensed: Bool { store.hasPermit(district) }
    private var levelLocked: Bool { store.level < district.requiredLevel }
    private var affordable: Bool { store.money >= district.permitPrice }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: district.bonus.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(district.tint)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(district.tint.opacity(0.14)))
                    .overlay(Circle().strokeBorder(district.tint.opacity(0.26), lineWidth: 1))

                Spacer(minLength: 0)

                Text(licensed ? "Aktiv" : (levelLocked ? "Ab Level \(district.requiredLevel)" : "Offen"))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(licensed ? Theme.emerald : (levelLocked ? Theme.textTertiary : Theme.amber))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(
                            licensed ? Theme.emerald.opacity(0.14)
                                : (levelLocked ? Color.white.opacity(0.06) : Theme.amber.opacity(0.14))
                        )
                    )
            }

            Text(district.name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(district.bonusLabel)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(licensed ? Theme.lime : Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            if licensed {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Permit vorhanden")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(Theme.emerald)
            } else if levelLocked {
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Level \(store.level) von \(district.requiredLevel)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(Theme.textTertiary)
            } else {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                        store.buyPermit(district)
                    }
                } label: {
                    HStack(spacing: 4) {
                        CoinIcon(size: 13)
                        Text(Format.plainMoney(district.permitPrice))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(affordable ? Theme.amber : Color.white.opacity(0.42))
                            .contentTransition(.numericText(value: district.permitPrice))
                        Spacer(minLength: 2)
                        Text("Permit kaufen")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
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
                    )
                    .overlay(Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 1))
                    .opacity(affordable ? 1 : 0.5)
                }
                .buttonStyle(SoftPressStyle())
                .disabled(!affordable)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 158, alignment: .topLeading)
        .glassPanel(
            cornerRadius: 24,
            tint: licensed ? Theme.emerald.opacity(0.10) : .clear,
            glow: licensed ? Theme.emerald.opacity(0.5) : nil
        )
        .overlay {
            if licensed {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.emerald.opacity(0.40), lineWidth: 1)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: licensed)
    }
}
