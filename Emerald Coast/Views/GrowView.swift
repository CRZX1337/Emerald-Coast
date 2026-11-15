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
    @State private var showPermits = false

    var body: some View {
        GeometryReader { proxy in
            // Auf niedrigen Geräten wird die Pflanze kleiner, damit nichts scrollt.
            let compact = proxy.size.height < 640

            ScrollView {
                VStack(spacing: compact ? 8 : 10) {
                    BrandMark()
                    topBar
                    heroSection(artHeight: compact ? 116 : 148, ringSize: compact ? 92 : 106)
                    actionRow
                    roomsSection(compact: compact)
                }
                .padding(.horizontal, 16)
                .padding(.top, 2)
                .padding(.bottom, 12)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .overlay { burstOverlay }
        .sheet(isPresented: $showUpgrades) {
            UpgradesSheet()
                .environment(store)
        }
        .sheet(isPresented: $showSeedPicker) {
            SeedPickerView(roomID: store.selectedRoom)
                .environment(store)
        }
        .sheet(isPresented: $showPermits) {
            PermitsView()
                .environment(store)
        }
        .task {
            guard UserDefaults.standard.bool(forKey: "openSeedPicker") else { return }
            try? await Task.sleep(for: .milliseconds(600))
            showSeedPicker = true
        }
    }

    // MARK: Kopfzeile

    private var topBar: some View {
        HStack(spacing: 8) {
            LevelBadge(level: store.level, progress: store.levelProgress)
            Spacer(minLength: 4)
            MoneyPill(money: store.money)
            Button {
                Haptics.light()
                showPermits = true
            } label: {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(heatTint)
                    .frame(width: 40, height: 40)
                    .glassPanel(cornerRadius: 20)
                    .overlay(alignment: .topTrailing) {
                        if store.heat >= 60 || store.isShutDown {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.48, blue: 0.45))
                                .frame(width: 8, height: 8)
                                .offset(x: -2, y: 2)
                        }
                    }
            }
            .buttonStyle(SoftPressStyle())
            .accessibilityLabel("Permits und Heat")
            Button {
                Haptics.light()
                onSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 40, height: 40)
                    .glassPanel(cornerRadius: 20)
            }
            .buttonStyle(SoftPressStyle())
            .accessibilityLabel("Einstellungen")
        }
    }

    private var heatTint: Color {
        if store.isShutDown { return Color(red: 1.0, green: 0.48, blue: 0.45) }
        switch store.heat {
        case ..<1: return .white.opacity(0.85)
        case ..<40: return Theme.emerald
        case ..<70: return Theme.amber
        default: return Color(red: 1.0, green: 0.48, blue: 0.45)
        }
    }

    // MARK: Hero

    private func heroSection(artHeight: CGFloat, ringSize: CGFloat) -> some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let room = store.selected
            let now = context.date
            heroCard(
                room: room,
                progress: store.progress(in: room, now: now),
                remaining: store.remaining(in: room, now: now),
                ready: store.isReady(room, now: now),
                artHeight: artHeight,
                ringSize: ringSize
            )
        }
    }

    private func heroCard(
        room: GrowRoom,
        progress: Double,
        remaining: TimeInterval,
        ready: Bool,
        artHeight: CGFloat,
        ringSize: CGFloat
    ) -> some View {
        let plantStrain = room.plant.flatMap { Brands.strain(id: $0.strainID) } ?? store.strain(for: room)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(plantStrain.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Spacer(minLength: 4)

                if room.plant != nil {
                    boostButton(room: room, ready: ready)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            HStack(spacing: 8) {
                Text(plantStrain.type)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.emerald)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.emerald.opacity(0.15)))
                    .overlay(Capsule().strokeBorder(Theme.emerald.opacity(0.32), lineWidth: 1))

                Button {
                    store.selectedRoom = room.id
                    Haptics.light()
                    showSeedPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(room.plant == nil ? "Sorte wählen" : "Nächster Batch")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(Theme.emerald)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.white.opacity(0.05)))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.09), lineWidth: 1))
                }
                .buttonStyle(SoftPressStyle())
                .accessibilityLabel("Samen für Grow Room \(room.id + 1) wählen")

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            HStack(alignment: .center, spacing: 4) {
                Group {
                    if room.plant == nil {
                        EmptyPlantArt()
                    } else {
                        PlantArtView(progress: progress, isReady: ready)
                    }
                }
                .frame(width: artHeight * 1.07, height: artHeight)

                Spacer(minLength: 0)

                VStack(spacing: 5) {
                    ZStack {
                        RingProgress(progress: progress)
                        VStack(spacing: 0) {
                            Text("Reifegrad")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                            Text(Format.percent(progress))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText(value: progress))
                                .monospacedDigit()
                        }
                    }
                    .frame(width: ringSize, height: ringSize)

                    Text(timerText(room: room, remaining: remaining, ready: ready))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(ready ? Theme.lime : Theme.textSecondary)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(width: ringSize + 12)
            }
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .padding(.top, 2)
            .padding(.bottom, 10)
        }
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [Theme.emerald.opacity(ready ? 0.22 : 0.13), .clear],
                        center: UnitPoint(x: 0.5, y: 0.15),
                        startRadius: 10,
                        endRadius: 240
                    )
                )
        }
        .glassPanel(
            cornerRadius: 28,
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

    private func roomsSection(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center) {
                Text("Grow Rooms")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

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
                    .padding(.vertical, 5)
                    .glassPanel(cornerRadius: 14, tint: Theme.emerald.opacity(0.10))
                }
                .buttonStyle(SoftPressStyle())
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 9),
                    GridItem(.flexible(), spacing: 9)
                ],
                spacing: 9
            ) {
                ForEach(store.rooms) { room in
                    GrowRoomCard(room: room, isSelected: store.selectedRoom == room.id, compact: compact)
                }
            }
        }
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
    var compact: Bool = false

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

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Text("Room \(room.id + 1)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if room.unlocked {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            HStack(spacing: 4) {
                Image(systemName: room.plant == nil ? "leaf" : "leaf.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text(status(ready: ready))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(statusColor(ready: ready))

            if room.unlocked {
                Text(store.strain(for: room).name)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 2)

            bottomRow(progress: progress, ready: ready)
        }
        .padding(11)
        .frame(maxWidth: .infinity, minHeight: compact ? 84 : 94, alignment: .topLeading)
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
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        } else {
            HStack(spacing: 6) {
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
                .frame(height: 6)

                Text(Format.percent(progress))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
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
