//
//  BrandsView.swift
//  Emerald Coast
//
//  Kalifornische Marken, ihre Lizenzen und Sorten.
//

import SwiftUI
import UIKit

private enum LicenseFilter: String, CaseIterable, Identifiable {
    case all
    case licensed
    case locked

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "Alle"
        case .licensed: return "Freigeschaltet"
        case .locked: return "Gesperrt"
        }
    }
}

struct BrandsView: View {
    @Environment(GameStore.self) private var store

    @State private var filter: LicenseFilter = .all
    @State private var brandFilterID: String?

    private var visibleBrands: [Brand] {
        Brands.all.filter { brand in
            if let brandFilterID, brand.id != brandFilterID { return false }
            switch filter {
            case .all: return true
            case .licensed: return store.isLicensed(brand)
            case .locked: return !store.isLicensed(brand)
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                BrandMark()
                    .padding(.top, 4)

                header
                filterChips

                if visibleBrands.isEmpty {
                    emptyState
                } else {
                    ForEach(visibleBrands) { brand in
                        BrandCard(brand: brand)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 104)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: filter)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: brandFilterID)
    }

    // MARK: Kopfzeile

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Brands")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Deine Lizenzen aus Kalifornien")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer(minLength: 4)

            Menu {
                ForEach(LicenseFilter.allCases) { option in
                    Button {
                        Haptics.light()
                        filter = option
                    } label: {
                        if filter == option {
                            Label(option.label, systemImage: "checkmark")
                        } else {
                            Text(option.label)
                        }
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "leaf")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.emerald)
                    Text(filter.label)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .glassPanel(cornerRadius: 22)
            }
            .buttonStyle(SoftPressStyle())
            .accessibilityLabel("Lizenz-Filter")
        }
    }

    // MARK: Filter-Chips

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                chip(title: "Alle", isSelected: brandFilterID == nil) {
                    brandFilterID = nil
                }

                ForEach(Brands.all) { brand in
                    chip(title: brand.name, isSelected: brandFilterID == brand.id) {
                        brandFilterID = brand.id
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                action()
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Theme.onAccent : Color.white.opacity(0.82))
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background {
                    Capsule(style: .continuous)
                        .fill(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Theme.lime, Theme.emerald],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(Color.white.opacity(0.07))
                        )
                }
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(isSelected ? .clear : .white.opacity(0.14), lineWidth: 1)
                )
        }
        .buttonStyle(SoftPressStyle())
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tag.slash")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.textTertiary)
            Text("Keine Marke in diesem Filter")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassPanel(cornerRadius: 26)
    }
}

// MARK: - Marken-Karte

struct BrandCard: View {
    @Environment(GameStore.self) private var store
    let brand: Brand

    @State private var showStrains = false

    private var licensed: Bool { store.isLicensed(brand) }
    private var levelLocked: Bool { store.level < brand.requiredLevel }
    private var unlockedStrains: Int { store.unlockedStrainCount(in: brand) }

    var body: some View {
        VStack(spacing: 13) {
            HStack(alignment: .top, spacing: 14) {
                MonogramTile(brand: brand, size: 84)

                VStack(alignment: .leading, spacing: 7) {
                    Text(brand.name)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("\(brand.strains.count) Sorten · \(unlockedStrains) freigeschaltet")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)

                    HStack(spacing: 7) {
                        RarityChip(rarity: brand.rarity)
                        HStack(spacing: 3) {
                            Image(systemName: "mappin")
                                .font(.system(size: 9, weight: .semibold))
                            Text(brand.city)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(Theme.textTertiary)
                    }
                }

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(height: 1)

            if licensed {
                licensedFooter
            } else {
                lockedFooter
            }
        }
        .padding(16)
        .blur(radius: levelLocked ? 6 : 0)
        .opacity(levelLocked ? 0.55 : 1)
        .glassPanel(
            cornerRadius: 28,
            tint: licensed ? Theme.emerald.opacity(0.10) : .clear,
            glow: licensed ? Theme.emerald.opacity(0.5) : nil
        )
        .overlay {
            if levelLocked {
                levelLockOverlay
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: licensed)
        .sheet(isPresented: $showStrains) {
            StrainPickerView(brand: brand)
                .environment(store)
        }
    }

    // MARK: Fußzeilen

    private var licensedFooter: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold))
                Text("Lizenziert")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Theme.emerald)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.emerald.opacity(0.13)))
            .overlay(Capsule().strokeBorder(Theme.emerald.opacity(0.28), lineWidth: 1))

            Spacer(minLength: 4)

            GreenCapsuleButton(title: "Sorten anbauen", icon: "leaf.fill") {
                showStrains = true
            }
            .frame(maxWidth: 210)
        }
    }

    private var lockedFooter: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                CoinIcon(size: 16)
                Text("\(Format.plainMoney(brand.licensePrice)) · \(Int(brand.royaltyRate * 100)) %")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(store.money >= brand.licensePrice ? Theme.amber : Color.white.opacity(0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.06)))
            .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1))

            Spacer(minLength: 4)

            GreenCapsuleButton(
                title: "Lizenz sichern",
                icon: "tag.fill",
                enabled: store.money >= brand.licensePrice && !levelLocked
            ) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    store.licenseBrand(brand)
                }
            }
            .frame(maxWidth: 210)
        }
    }

    // MARK: Level-Sperre

    private var levelLockOverlay: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.6), radius: 8)

            Text("Ab Level \(brand.requiredLevel)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.16))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Theme.emerald, Theme.lime],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, 120 * min(1, Double(store.level) / Double(brand.requiredLevel))))
            }
            .frame(width: 120, height: 5)

            Text("Level \(store.level) von \(brand.requiredLevel)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Monogramm

struct MonogramTile: View {
    let brand: Brand
    var size: CGFloat = 84

    private var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
    }

    private var tileBackground: LinearGradient {
        if brand.logoOnDark {
            return LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.18, blue: 0.11),
                    Color(red: 0.02, green: 0.08, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [
                Color(red: 0.97, green: 0.95, blue: 0.90),
                Color(red: 0.89, green: 0.86, blue: 0.79)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            tileShape.fill(tileBackground)

            if let logo = brand.logoAsset, UIImage(named: logo) != nil {
                Image(logo)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.15)
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 1)
            } else {
                Text(brand.monogram)
                    .font(.system(size: size * 0.4, weight: .semibold, design: .serif))
                    .foregroundStyle(brand.logoOnDark ? Color.white.opacity(0.94) : Color(red: 0.10, green: 0.20, blue: 0.13))
                    .shadow(color: brand.tint.opacity(0.35), radius: 6)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            tileShape.strokeBorder(
                LinearGradient(
                    colors: [
                        .white.opacity(brand.logoOnDark ? 0.30 : 0.55),
                        .white.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        }
        .shadow(color: brand.tint.opacity(0.22), radius: 12, y: 6)
    }
}

// MARK: - Seltenheit

struct RarityChip: View {
    let rarity: Rarity

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 10, weight: .semibold))
            Text(rarity.label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(rarity.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(rarity.color.opacity(0.13)))
        .overlay(Capsule().strokeBorder(rarity.color.opacity(0.30), lineWidth: 1))
    }
}

// MARK: - Grüner Button

struct GreenCapsuleButton: View {
    let title: String
    var icon: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else { return }
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(.white.opacity(0.24), lineWidth: 1)
            )
            .shadow(color: Theme.emerald.opacity(0.45), radius: 12, y: 4)
            .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(SoftPressStyle())
        .disabled(!enabled)
    }
}

// MARK: - Sorten-Auswahl

struct StrainPickerView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let brand: Brand

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        MonogramTile(brand: brand, size: 54)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(brand.name)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("\(brand.city) · Bonus +\(Int((brand.valueBonus - 1) * 100)) % Wert")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.emerald)
                        }

                        Spacer(minLength: 4)

                        Button {
                            Haptics.light()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                                .frame(width: 34, height: 34)
                                .glassPanel(cornerRadius: 17)
                        }
                        .buttonStyle(SoftPressStyle())
                        .accessibilityLabel("Schließen")
                    }
                    .padding(.bottom, 2)

                    Text(brand.note)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)

                    ForEach(brand.strains) { strain in
                        StrainRow(strain: strain) {
                            store.selectStrain(strain)
                            if store.isStrainSelected(strain) {
                                dismiss()
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 104)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.clear)
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

struct StrainRow: View {
    @Environment(GameStore.self) private var store
    let strain: Strain
    let onSelect: () -> Void

    private var unlocked: Bool { store.isStrainUnlocked(strain) }
    private var isSelected: Bool { store.isStrainSelected(strain) }

    var body: some View {
        Button {
            Haptics.light()
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(strain.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(unlocked ? .white : Color.white.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 4)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.emerald)
                    } else if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                HStack(spacing: 7) {
                    RarityChip(rarity: strain.rarity)
                    metaChip(text: strain.type, icon: "leaf")
                    metaChip(text: "\(Int(strain.thc)) % THC", icon: "bolt.fill")
                    Spacer(minLength: 0)
                }

                HStack(spacing: 5) {
                    Image(systemName: "dna")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Text(strain.genetics)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                HStack(spacing: 12) {
                    stat(text: Format.grams(strain.baseYield), label: "Ertrag")
                    stat(text: "\(Format.plainMoney(strain.baseValue)) $/g", label: "Retail")
                    stat(text: "\(Format.plainMoney(strain.wholesaleValue)) $/g", label: "Wholesale")
                    Spacer(minLength: 0)
                    if !unlocked {
                        Text("Ab Level \(strain.requiredLevel)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.amber)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(unlocked ? 1 : 0.65)
            .glassPanel(
                cornerRadius: 22,
                tint: isSelected ? Theme.emerald.opacity(0.12) : .clear
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Theme.emerald.opacity(0.45), lineWidth: 1)
                }
            }
        }
        .buttonStyle(SoftPressStyle())
    }

    private func metaChip(text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(.white.opacity(0.06)))
    }

    private func stat(text: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
    }
}
