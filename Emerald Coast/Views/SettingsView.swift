//
//  SettingsView.swift
//  Emerald Coast
//

import SwiftUI

struct SettingsView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var confirmReset = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("Einstellungen")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
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
                    .padding(.bottom, 4)

                    VStack(spacing: 0) {
                        statRow(title: "Guthaben", value: Format.money(store.money), icon: "creditcard.fill", tint: Theme.amber)
                        divider
                        statRow(title: "Level", value: "\(store.level)", icon: "star.fill", tint: Theme.emerald)
                        divider
                        statRow(title: "Ernten", value: "\(store.totalHarvests)", icon: "scissors", tint: Theme.lime)
                        divider
                        statRow(
                            title: "Aktive Grow Rooms",
                            value: "\(store.rooms.filter { $0.unlocked }.count)",
                            icon: "square.grid.2x2.fill",
                            tint: Theme.emerald
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .glassPanel(cornerRadius: 26)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Fortschritt")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Setzt Guthaben, Level, Grow Rooms und Upgrades auf den Start zurück.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Button {
                            Haptics.medium()
                            confirmReset = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Spielstand zurücksetzen")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.52))
                            .padding(.vertical, 13)
                            .frame(maxWidth: .infinity)
                            .background(Capsule().fill(Color.red.opacity(0.14)))
                            .overlay(Capsule().strokeBorder(Color.red.opacity(0.30), lineWidth: 1))
                        }
                        .buttonStyle(SoftPressStyle())
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassPanel(cornerRadius: 26)

                    Text("CANNABIZ · Humboldt County · Version \(appVersion)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, 6)
                }
                .padding(20)
                .padding(.bottom, 30)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.clear)
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Spielstand wirklich zurücksetzen?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Alles zurücksetzen", role: .destructive) {
                store.reset()
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Guthaben, Level und Upgrades werden gelöscht.")
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.07))
            .frame(height: 1)
    }

    /// Version und Build aus dem Bundle, damit man sieht, was installiert ist.
    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }

    private func statRow(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(Circle().fill(tint.opacity(0.13)))

            Text(title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
    }
}
