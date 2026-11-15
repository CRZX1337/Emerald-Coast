//
//  SeedPickerView.swift
//  Emerald Coast
//
//  Samen-Auswahl für den ausgewählten Grow Room.
//

import SwiftUI

struct SeedPickerView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let roomID: Int
    @State private var query = ""

    private var room: GrowRoom {
        store.rooms.first(where: { $0.id == roomID }) ?? store.selected
    }

    private var currentStrain: Strain {
        store.strain(for: room)
    }

    private var groups: [SeedGroup] {
        Brands.all.compactMap { brand in
            let strains = brand.strains.filter { strain in
                guard store.isStrainUnlocked(strain) else { return false }
                guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return true }
                return strain.name.localizedCaseInsensitiveContains(query)
                    || strain.type.localizedCaseInsensitiveContains(query)
            }
            guard !strains.isEmpty else { return nil }
            return SeedGroup(brand: brand, strains: strains)
        }
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    searchField
                    currentCard

                    ForEach(groups) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                MonogramTile(brand: group.brand, size: 26)
                                Text(group.brand.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.86))
                                Spacer()
                                Text("\(group.strains.count)")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(Theme.textTertiary)
                            }

                            VStack(spacing: 8) {
                                ForEach(group.strains) { strain in
                                    seedRow(strain, brand: group.brand)
                                }
                            }
                        }
                    }

                    Text("4 Samen pro Batch. Weitere Sorten schaltest du über Marken-Lizenzen im Brands-Tab frei.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
                .padding(20)
                .padding(.bottom, 28)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.large])
        .presentationBackground(.clear)
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Samen wählen")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Grow Room \(roomID + 1) · Auswahl gilt für den nächsten Batch")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Button {
                Haptics.light()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .glassPanel(cornerRadius: 18)
            }
            .buttonStyle(SoftPressStyle())
            .accessibilityLabel("Schließen")
        }
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textTertiary)
            TextField("Sorte suchen", text: $query)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.08), lineWidth: 1))
    }

    private var currentCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.emerald)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.emerald.opacity(0.14)))

            VStack(alignment: .leading, spacing: 2) {
                Text("Aktuell ausgewählt")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                Text(currentStrain.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            Text(currentStrain.type)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.emerald)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(Theme.emerald.opacity(0.13)))
        }
        .padding(14)
        .glassPanel(cornerRadius: 20, tint: Theme.emerald.opacity(0.06))
    }

    private func seedRow(_ strain: Strain, brand: Brand) -> some View {
        let selected = currentStrain.id == strain.id

        return Button {
            store.selectedRoom = roomID
            store.selectStrain(strain)
            if store.strain(for: room).id == strain.id {
                dismiss()
            }
        } label: {
            HStack(spacing: 12) {
                MonogramTile(brand: brand, size: 40)

                VStack(alignment: .leading, spacing: 3) {
                    Text(strain.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(strain.type) · \(Format.percent(Double(strain.thc) / 100)) THC")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer(minLength: 8)

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.emerald)
                } else {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Format.money(strain.seedPrice))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        Text("pro Samen")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? Theme.emerald.opacity(0.12) : .white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(selected ? Theme.emerald.opacity(0.38) : .white.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(SoftPressStyle())
    }
}

private struct SeedGroup: Identifiable {
    let brand: Brand
    let strains: [Strain]
    var id: String { brand.id }
}
