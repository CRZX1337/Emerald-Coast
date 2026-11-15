//
//  CrewView.swift
//  Emerald Coast
//
//  Das Team: Grower und Budtender, Löhne, Bewerber.
//

import SwiftUI

struct CrewView: View {
    @Environment(GameStore.self) private var store

    @State private var confirmFire: CrewMember?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BrandMark()
                    .padding(.top, 4)

                header
                summaryCard
                teamSection
                applicantSection
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 130)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .confirmationDialog(
            "\(confirmFire?.name ?? "") entlassen?",
            isPresented: Binding(
                get: { confirmFire != nil },
                set: { if !$0 { confirmFire = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Entlassen", role: .destructive) {
                if let member = confirmFire {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                        store.fire(member)
                    }
                }
                confirmFire = nil
            }
            Button("Behalten", role: .cancel) {
                confirmFire = nil
            }
        } message: {
            Text("Der Lohn fällt dann sofort weg, die Person arbeitet nicht mehr.")
        }
    }

    // MARK: Kopfzeile

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Crew")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Dein Team in Humboldt County")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            MoneyPill(money: store.money)
        }
    }

    // MARK: Übersicht

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 0) {
                metric(
                    title: "Team",
                    value: "\(store.crew.count)",
                    tint: .white
                )
                divider
                metric(
                    title: "Lohn / Std.",
                    value: Format.money(store.wagesPerHour),
                    tint: Color(red: 1.0, green: 0.62, blue: 0.58)
                )
                divider
                metric(
                    title: "Effekt / Std.",
                    value: store.crewNetPerHour >= 0 ? "+\(Format.money(store.crewNetPerHour))" : Format.money(store.crewNetPerHour),
                    tint: store.crewNetPerHour >= 0 ? Theme.emerald : Color(red: 1.0, green: 0.55, blue: 0.52)
                )
            }

            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "scissors")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.lime)
                    Text("\(store.crewHarvestsToday) Ernten heute")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                    Text("\(store.crewSalesToday) Verkäufe heute")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 26)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.09))
            .frame(width: 1, height: 32)
    }

    private func metric(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Team

    private var teamSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Team", trailing: "\(store.crew.count) von 8")

            if store.crew.isEmpty {
                emptyTeam
            } else {
                ForEach(store.crew) { member in
                    CrewMemberCard(member: member) {
                        confirmFire = member
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
        }
    }

    private var emptyTeam: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.textTertiary)
            Text("Noch niemand eingestellt")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            Text("Grower ernten und pflanzen von selbst, Budtender bedienen deine Kunden.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 20)
        .glassPanel(cornerRadius: 26)
    }

    // MARK: Bewerber

    private var applicantSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Bewerber", trailing: "Einstellen kostet einmalig")

            ForEach(store.applicants) { applicant in
                ApplicantCard(applicant: applicant)
            }

            Button {
                Haptics.light()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    store.refreshApplicantsIfNeeded(force: true)
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Neue Bewerber")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Theme.emerald)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassPanel(cornerRadius: 18, tint: Theme.emerald.opacity(0.10))
            }
            .buttonStyle(SoftPressStyle())
        }
    }
}

// MARK: - Teammitglied

struct CrewMemberCard: View {
    @Environment(GameStore.self) private var store
    let member: CrewMember
    let onFire: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CrewAvatar(look: member.look, role: member.role, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(member.name)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Stufe \(member.level)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.emerald)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Theme.emerald.opacity(0.14)))
                    }

                    HStack(spacing: 6) {
                        Text(member.role.title)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(member.role.tint)
                        SkillStars(skill: member.skill)
                    }
                }

                Spacer(minLength: 0)

                Button {
                    Haptics.light()
                    onFire()
                } label: {
                    Image(systemName: "person.badge.minus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 1.0, green: 0.60, blue: 0.56))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.red.opacity(0.14)))
                }
                .buttonStyle(SoftPressStyle())
                .accessibilityLabel("\(member.name) entlassen")
            }

            HStack(spacing: 0) {
                stat(
                    title: "Lohn / Min.",
                    value: Format.money(store.wage(for: member)),
                    tint: Color(red: 1.0, green: 0.62, blue: 0.58)
                )
                stat(
                    title: member.role == .grower ? "Ernten / Min." : "Verkäufe / Min.",
                    value: String(format: "%.1f", store.actionsPerMinute(for: member)),
                    tint: .white
                )
                stat(
                    title: "Effekt / Std.",
                    value: effectPerHour,
                    tint: Theme.emerald
                )
            }

            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.10))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.emerald, Theme.lime],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(4, geo.size.width * member.xpProgress))
                    }
                }
                .frame(height: 5)

                Text("\(Int(member.xp)) / \(Int(member.xpNeeded)) XP bis Stufe \(member.level + 1)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: member.xpProgress)
        }
        .padding(15)
        .glassPanel(cornerRadius: 24)
    }

    private var effectPerHour: String {
        let perMinute = store.actionsPerMinute(for: member)
        if member.role == .grower {
            let grams = perMinute * store.strain.baseYield * store.yieldMultiplier
            return "\(Format.grams(grams * 60))"
        }
        let price = store.shelf.first?.price ?? store.basePrice(for: store.strain)
        return Format.money(perMinute * 3.5 * price * 60)
    }

    private func stat(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Bewerber-Karte

struct ApplicantCard: View {
    @Environment(GameStore.self) private var store
    let applicant: CrewApplicant

    private var affordable: Bool { store.money >= applicant.hireCost }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CrewAvatar(look: applicant.look, role: applicant.role, size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(applicant.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Text(applicant.role.title)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(applicant.role.tint)
                        SkillStars(skill: applicant.skill)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    CoinIcon(size: 14)
                    Text(Format.plainMoney(applicant.hireCost))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(affordable ? Theme.amber : Color.white.opacity(0.4))
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(Capsule().fill(.white.opacity(0.06)))
                .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1))

                Spacer(minLength: 4)

                GreenCapsuleButton(
                    title: "Einstellen",
                    icon: "person.badge.plus",
                    enabled: affordable && store.crew.count < 8
                ) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                        store.hire(applicant)
                    }
                }
                .frame(maxWidth: 170)
            }
        }
        .padding(15)
        .glassPanel(cornerRadius: 24)
    }
}
