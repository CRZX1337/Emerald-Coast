//
//  ShopView.swift
//  Emerald Coast
//
//  Upgrades für Lampen, Nährstoffe und Genetik.
//

import SwiftUI

struct ShopView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Shop")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Ausrüstung und Genetik für mehr Ertrag")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

                ForEach(Upgrades.all) { def in
                    UpgradeCard(def: def)
                }

                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Upgrades gelten für alle Grow Rooms.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 130)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }
}

struct UpgradeCard: View {
    @Environment(GameStore.self) private var store
    let def: UpgradeDef

    private var level: Int { store.upgradeLevel(def.id) }
    private var maxed: Bool { level >= def.maxLevel }
    private var cost: Double { def.cost(level: level) }
    private var affordable: Bool { store.money >= cost }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: def.icon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(def.tint)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(def.tint.opacity(0.14)))
                    .overlay(Circle().strokeBorder(def.tint.opacity(0.28), lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text(def.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(maxed ? "Maximal ausgebaut" : "Stufe \(level) von \(def.maxLevel)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer(minLength: 4)

                if !maxed {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            store.buyUpgrade(def)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            CoinIcon(size: 14)
                            Text(Format.plainMoney(cost))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(affordable ? Theme.amber : Color.white.opacity(0.4))
                                .contentTransition(.numericText(value: cost))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .glassPanel(cornerRadius: 18, tint: affordable ? Theme.amber.opacity(0.12) : .clear)
                    }
                    .buttonStyle(SoftPressStyle())
                    .disabled(!affordable)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.emerald)
                }
            }

            HStack(spacing: 4) {
                ForEach(0..<def.maxLevel, id: \.self) { index in
                    Capsule()
                        .fill(index < level
                              ? AnyShapeStyle(LinearGradient(colors: [Theme.emerald, Theme.lime], startPoint: .leading, endPoint: .trailing))
                              : AnyShapeStyle(Color.white.opacity(0.12)))
                        .frame(height: 5)
                }
            }

            Text(def.effect(level))
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(level > 0 ? Theme.emerald : Theme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 26)
    }
}
