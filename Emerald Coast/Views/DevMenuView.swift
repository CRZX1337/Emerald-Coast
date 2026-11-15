//
//  DevMenuView.swift
//  Emerald Coast
//
//  Verstecktes Entwickler-Menü. Erreichbar über 7 Taps auf die Versionszeile
//  in den Einstellungen. Nicht für Spieler gedacht.
//

import SwiftUI

struct DevMenuView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var confirmReset = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    statusCard
                    section("Guthaben") {
                        action("+ 10.000 $", icon: "banknote.fill", tint: Theme.amber) { store.devAddMoney(10_000) }
                        action("+ 100.000 $", icon: "banknote.fill", tint: Theme.amber) { store.devAddMoney(100_000) }
                        action("Auf 1.000.000 $ setzen", icon: "dollarsign.circle.fill", tint: Theme.amber) {
                            store.money = 1_000_000
                            store.save()
                        }
                    }
                    section("Fortschritt") {
                        action("Level + 5", icon: "star.fill", tint: Theme.lime) { store.devSetLevel(store.level + 5) }
                        action("Alle Marken & Rooms", icon: "lock.open.fill", tint: Theme.emerald) {
                            store.devUnlockEverything()
                        }
                        action("Upgrades maximieren", icon: "slider.horizontal.3", tint: Theme.emerald) {
                            store.devMaxUpgrades()
                        }
                    }
                    section("Testdaten") {
                        action("Regal mit allen Sorten füllen", icon: "shippingbox.fill", tint: Theme.emerald) {
                            store.devFillShelf()
                        }
                        action("Alle Pflanzen erntereif", icon: "scissors", tint: Theme.lime) {
                            store.devRipenPlants()
                        }
                        action("Fahrer anheuern", icon: "car.fill", tint: Theme.amber) {
                            store.devAddDriver()
                        }
                        action("Fleet-Auftrag erzeugen", icon: "shippingbox.and.arrow.backward.fill", tint: Theme.amber) {
                            store.spawnOrder()
                        }
                    }
                    section("Gefahrenzone") {
                        action("Spielstand zurücksetzen", icon: "arrow.counterclockwise", tint: Color(red: 1, green: 0.55, blue: 0.52)) {
                            confirmReset = true
                        }
                    }

                    Text("Dev-Modus · Änderungen werden sofort gespeichert.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
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
        .confirmationDialog("Spielstand zurücksetzen?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Alles zurücksetzen", role: .destructive) {
                store.reset()
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Dev Menu")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Nur für Tests · nicht für Spieler")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.amber)
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

    private var statusCard: some View {
        HStack(spacing: 0) {
            statusValue(Format.money(store.money), label: "Guthaben", tint: Theme.amber)
            divider
            statusValue("Level \(store.level)", label: "Fortschritt", tint: Theme.emerald)
            divider
            statusValue("\(store.rooms.filter { $0.unlocked }.count)/\(store.rooms.count)", label: "Rooms", tint: Theme.lime)
        }
        .padding(.vertical, 14)
        .glassPanel(cornerRadius: 22)
    }

    private func statusValue(_ value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.08))
            .frame(width: 1, height: 30)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .tracking(0.8)
            VStack(spacing: 7) {
                content()
            }
        }
    }

    private func action(_ title: String, icon: String, tint: Color, perform: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            perform()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(tint.opacity(0.12)))
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.07), lineWidth: 1))
        }
        .buttonStyle(SoftPressStyle())
    }
}
