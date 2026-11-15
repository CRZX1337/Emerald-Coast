//
//  GrowView.swift
//  Emerald Coast
//
//  Das Grow House: Pflanze, Gießen, Ernten, Grow Rooms.
//

import SwiftUI

struct GrowView: View {
    @Environment(GameStore.self) private var store
    let onSettings: () -> Void

    @State private var burst: HarvestResult?
    @State private var showUpgrades = false
    @State private var showSeedPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BrandMark()
                    .padding(.top, 4)
                topBar
                heroSection
                actionRow
                roomsSection
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 104)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .overlay { burstOverlay }
        .sheet(isPresented: $showUpgrades) {
            UpgradesSheet()
                .environment(store)
        }
        .sheet(isPresented: $showSeedPicker) {
            SeedPickerView(roomID: store.selectedRoom)
                .environment(store)
        }
    }

    // MARK: Kopfzeile

    private var topBar: some View {
        HStack(spacing: 10) {
            LevelBadge(level: store.level, progress: store.levelProgress)
            Spacer(minLength: 6)
            MoneyPill(money: store.money)
            Button {
                Haptics.light()
                onSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .glassPanel(cornerRadius: 22)
            }
            .buttonStyle(SoftPressStyle())
            .accessibilityLabel("Einstellungen")
        }
    }

    // MARK: Hero

    private var heroSection: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let room = store.selected
            let now = context.date
            heroCard(
                room: room,
                progress: store.progress(in: room, now: now),
                remaining: store.remaining(in: room, now: now),
                ready: store.isReady(room, now: now)
            )
        }
    }

    private func heroCard(room: GrowRoom, progress: Double, remaining: TimeInterval, ready: Bool) -> some View {
        let plantStrain = room.plant.flatMap { Brands.strain(id: $0.strainID) } ?? store.strain(for: room)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 9) {
                    Text(plantStrain.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(plantStrain.type)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.emerald)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Theme.emerald.opacity(0.15)))
                        .overlay(Capsule().strokeBorder(Theme.emerald.opacity(0.32), lineWidth: 1))

                    Button {
                        store.selectedRoom = room.id
                        Haptics.light()
                        showSeedPicker = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "leaf.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text(room.plant == nil ? "Sorte wählen" : "Nächster Batch")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(Theme.emerald)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.05)))
                        .overlay(Capsule().strokeBorder(.white.opacity(0.09), lineWidth: 1))
                    }
                    .buttonStyle(SoftPressStyle())
                    .accessibilityLabel("Samen für Grow Room \(room.id + 1) wählen")
                }
                Spacer(minLength: 8)
                if room.plant != nil {
                    boostButton(room: room, ready: ready)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            HStack(alignment: .bottom, spacing: 6) {
                Group {
                    if room.plant == nil {
                        EmptyPlantArt()
                    } else {
                        PlantArtView(progress: progress, isReady: ready)
                    }
                }
                .frame(height: 194)
                .frame(maxWidth: .infinity)

                VStack(spacing: 8) {
                    ZStack {
                        RingProgress(progress: progress)
                        VStack(spacing: 1) {
                            Text("Reifegrad")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                            Text(Format.percent(progress))
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText(value: progress))
                                .monospacedDigit()
                        }
                    }
                    .frame(width: 126, height: 126)

                    Text(timerText(room: room, remaining: remaining, ready: ready))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(ready ? Theme.lime : Theme.textSecondary)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(width: 132)
            }
            .padding(.leading, 10)
            .padding(.trailing, 14)
            .padding(.top, 2)
            .padding(.bottom, 12)
        }
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [Theme.emerald.opacity(ready ? 0.22 : 0.13), .clear],
                        center: UnitPoint(x: 0.5, y: 0.15),
                        startRadius: 10,
                        endRadius: 260
                    )
                )
        }
        .glassPanel(
            cornerRadius: 30,
            tint: Theme.emerald.opacity(ready ? 0.14 : 0.06),
            glow: ready ? Theme.emerald : nil
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: ready)
    }

    private func timerText(room: GrowRoom, remaining: TimeInterval, ready: Bool) -> String {
        if room.plant == nil { return "Bereit zum Pflanzen" }
        if ready { return "Bereit zur Ernte" }
        return "Ernte in \(Format.clock(remaining))"
    }

    private func boostButton(room: GrowRoom, ready: Bool) -> some View {
        let cost = store.boostCost(for: room)
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                store.boost(in: room.id)
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.lime)
                Text("Boost")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Text(Format.plainMoney(cost))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.amber)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .glassPanel(cornerRadius: 18, tint: Theme.amber.opacity(0.10))
        }
        .buttonStyle(SoftPressStyle())
        .disabled(ready || (room.plant?.isBoosted ?? false))
        .opacity(ready || (room.plant?.isBoosted ?? false) ? 0.35 : 1)
        .accessibilityLabel("Wachstum boosten für \(Format.money(cost))")
    }

    // MARK: Aktionen

    private var actionRow: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let room = store.selected
            let ready = store.isReady(room, now: context.date)
            let hasPlant = room.plant != nil

            HStack(spacing: 10) {
                if hasPlant {
                    let feedCount = room.plant?.feedCount ?? 0
                    let watered = room.plant?.hasWatered ?? false

                    GlassActionButton(
                        title: watered ? "Gegossen" : "Gießen",
                        icon: watered ? "checkmark" : "drop.fill",
                        enabled: !ready && !watered
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            store.water(in: room.id)
                        }
                    }

                    GlassActionButton(
                        title: "Düngen \(feedCount)/3",
                        icon: "drop.circle.fill",
                        enabled: !ready && feedCount < 3
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            store.feed(in: room.id)
                        }
                    }

                    GlassActionButton(
                        title: "Ernten",
                        icon: "scissors",
                        prominent: true,
                        glow: ready ? Theme.emerald : nil,
                        enabled: ready
                    ) {
                        harvest()
                    }
                } else {
                    let roomStrain = store.strain(for: room)
                    GlassActionButton(title: "Samen setzen · \(Format.money(store.plantCost(for: roomStrain)))", icon: "leaf.fill", prominent: true) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            store.plant(in: room.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: Grow Rooms

    private var roomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Grow Rooms")
                .overlay(alignment: .trailing) {
                    Button {
                        Haptics.light()
                        showUpgrades = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 10, weight: .bold))
                            Text("Ausrüstung")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Theme.emerald)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .glassPanel(cornerRadius: 14, tint: Theme.emerald.opacity(0.10))
                    }
                    .buttonStyle(SoftPressStyle())
                }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(store.rooms) { room in
                    GrowRoomCard(room: room, isSelected: store.selectedRoom == room.id)
                }
            }
        }
        .padding(.top, 6)
    }

    // MARK: Ernte-Rückmeldung

    private func harvest() {
        guard let result = store.harvest(in: store.selectedRoom) else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            burst = result
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_050_000_000)
            withAnimation(.easeOut(duration: 0.35)) {
                burst = nil
            }
        }
    }

    private var burstOverlay: some View {
        Group {
            if let result = burst {
                VStack(spacing: 2) {
                    Text("+\(Format.grams(result.grams))")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.amber)
                        .shadow(color: Theme.amber.opacity(0.7), radius: 16)
                    Text("ins Regal · ~\(Format.money(result.value)) Wholesale")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 18)
                .glassPanel(cornerRadius: 26, tint: Theme.amber.opacity(0.12), glow: Theme.amber)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .offset(y: -90).combined(with: .opacity)
                    )
                )
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Grow Room Karte

struct GrowRoomCard: View {
    @Environment(GameStore.self) private var store
    let room: GrowRoom
    let isSelected: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                store.tapRoom(room.id)
            }
        } label: {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                content(now: context.date)
            }
        }
        .buttonStyle(SoftPressStyle())
    }

    private func content(now: Date) -> some View {
        let progress = store.progress(in: room, now: now)
        let ready = store.isReady(room, now: now)

        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                Text("Grow Room \(room.id + 1)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                if room.unlocked {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            HStack(spacing: 6) {
                Image(systemName: room.plant == nil ? "leaf" : "leaf.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(status(ready: ready))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(statusColor(ready: ready))

            Text(store.strain(for: room).name)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            bottomRow(progress: progress, ready: ready)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .background {
            if isSelected && room.unlocked {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.emerald.opacity(0.10))
            }
        }
        .glassPanel(
            cornerRadius: 24,
            tint: isSelected && room.unlocked ? Theme.emerald.opacity(0.14) : .clear,
            glow: ready ? Theme.emerald.opacity(0.8) : nil
        )
        .overlay {
            if isSelected && room.unlocked {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Theme.emerald.opacity(0.45), lineWidth: 1)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isSelected)
    }

    private func status(ready: Bool) -> String {
        if !room.unlocked {
            return levelLocked ? "Ab Level \(room.requiredLevel)" : "verfügbar"
        }
        if room.plant == nil { return "leer" }
        return ready ? "erntebereit" : "blüht"
    }

    private var levelLocked: Bool {
        store.level < room.requiredLevel
    }

    private func statusColor(ready: Bool) -> Color {
        if !room.unlocked { return Theme.textSecondary }
        if room.plant == nil { return Theme.textSecondary }
        return ready ? Theme.lime : Theme.emerald
    }

    @ViewBuilder
    private func bottomRow(progress: Double, ready: Bool) -> some View {
        if !room.unlocked {
            if levelLocked {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Wird später freigeschaltet")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .foregroundStyle(Theme.textTertiary)
            } else {
                pricePill(text: Format.money(room.price), affordable: store.money >= room.price)
            }
        } else if room.plant == nil {
            Text("Tippen zum Pflanzen")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        } else {
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.12))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.emerald, Theme.lime],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(4, geo.size.width * progress))
                    }
                }
                .frame(height: 7)

                Text(Format.percent(progress))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
            }
            .animation(.easeOut(duration: 0.4), value: progress)
        }
    }

    private func pricePill(text: String, affordable: Bool) -> some View {
        HStack(spacing: 6) {
            CoinIcon(size: 14)
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(affordable ? Theme.amber : Color.white.opacity(0.4))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(.white.opacity(0.06)))
        .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1))
    }
}
