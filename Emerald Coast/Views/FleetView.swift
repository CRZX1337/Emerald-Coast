//
//  FleetView.swift
//  Emerald Coast
//
//  Lieferungen: kalifornische Karte, Aufträge, Fahrer und Fahrzeuge.
//

import SwiftUI

struct FleetView: View {
    @Environment(GameStore.self) private var store

    @State private var selectedOrder: DeliveryOrder?
    @State private var confirmFireDriver: DeliveryDriver?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BrandMark()
                    .padding(.top, 4)

                header
                mapCard
                summaryCard
                ordersSection
                driversSection
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 104)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $selectedOrder) { order in
            DispatchSheet(order: order)
                .environment(store)
        }
        .confirmationDialog(
            "\(confirmFireDriver?.name ?? "") entlassen?",
            isPresented: Binding(
                get: { confirmFireDriver != nil },
                set: { if !$0 { confirmFireDriver = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Entlassen", role: .destructive) {
                if let driver = confirmFireDriver {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                        store.fireDriver(driver)
                    }
                }
                confirmFireDriver = nil
            }
            Button("Behalten", role: .cancel) {
                confirmFireDriver = nil
            }
        } message: {
            Text("Der Fahrer nimmt keine Aufträge mehr an. Eine laufende Fahrt läuft weiter.")
        }
    }

    // MARK: Kopfzeile

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lieferungen")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Humboldt County → Kalifornien")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            MoneyPill(money: store.money)
        }
    }

    // MARK: Karte

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Karte")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Text(store.trips.isEmpty ? "Keine Fahrt unterwegs" : "\(store.trips.count) unterwegs")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            FleetMapView()
                .environment(store)
        }
        .padding(16)
        .glassPanel(cornerRadius: 26)
    }

    // MARK: Übersicht

    private var summaryCard: some View {
        HStack(spacing: 0) {
            metric(title: "Fahrer", value: "\(store.drivers.count)", tint: .white)
            divider
            metric(title: "Heute geliefert", value: "\(store.deliveriesToday)", tint: Theme.emerald)
            divider
            metric(title: "Trinkgeld heute", value: Format.money(store.tipsToday), tint: Theme.amber)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .glassPanel(cornerRadius: 24)
    }

    private var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.09))
            .frame(width: 1, height: 30)
    }

    private func metric(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Aufträge

    private var ordersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Aufträge", trailing: store.drivers.isEmpty ? "Erst Fahrer einstellen" : "\(store.orders.count) offen")

            if store.orders.isEmpty {
                emptyOrders
            } else {
                ForEach(store.orders) { order in
                    OrderCard(order: order) {
                        selectedOrder = order
                    }
                }
            }
        }
    }

    private var emptyOrders: some View {
        VStack(spacing: 10) {
            Image(systemName: "shippingbox")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.textTertiary)

            Text(store.drivers.isEmpty ? "Noch keine Flotte" : (hasPermittedCity ? "Gerade keine Bestellung" : "Kein Permit für eine Stadt"))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))

            Text(emptyHint)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 20)
        .glassPanel(cornerRadius: 26)
    }

    /// Hat mindestens eine Lieferstadt ein Permit?
    private var hasPermittedCity: Bool {
        DeliveryCities.destinations.contains { store.canDeliver(to: $0) }
    }

    private var emptyHint: String {
        if store.drivers.isEmpty {
            return "Stelle unten einen Fahrer ein, dann kommen Bestellungen herein."
        }
        if !hasPermittedCity {
            return "Kaufe im Permits-Screen eine Lizenz für eine Stadt, sonst kommen keine Aufträge."
        }
        return "Neue Bestellungen treffen automatisch ein, solange Ware im Regal liegt."
    }

    // MARK: Fahrer

    private var driversSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Flotte", trailing: "\(store.drivers.count) von \(store.maxDrivers)")

            ForEach(store.drivers) { driver in
                DriverCard(driver: driver) {
                    confirmFireDriver = driver
                }
            }

            if store.drivers.count < store.maxDrivers {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                        store.hireDriver()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Fahrer einstellen")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                        Spacer()
                        CoinIcon(size: 15)
                        Text(Format.plainMoney(store.nextDriverCost))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(store.money >= store.nextDriverCost ? Theme.amber : Color.white.opacity(0.4))
                            .contentTransition(.numericText(value: store.nextDriverCost))
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                    .glassPanel(cornerRadius: 22, tint: Theme.emerald.opacity(0.08))
                }
                .buttonStyle(SoftPressStyle())
                .disabled(store.money < store.nextDriverCost)
            }
        }
    }
}

// MARK: - Auftrag

struct OrderCard: View {
    @Environment(GameStore.self) private var store
    let order: DeliveryOrder
    let onDispatch: () -> Void

    private var strain: Strain {
        Brands.strain(id: order.strainID) ?? Strains.base
    }

    private var freeDriver: DeliveryDriver? {
        store.drivers.first { !store.isDriverBusy($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.emerald.opacity(0.14))
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.emerald)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(order.city.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(strain.name) · \(Format.grams(order.grams)) · \(Int(order.city.distance)) km")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Format.money(order.value)) + \(Format.money(order.tip)) Tip")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.amber)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("Fahrt \(Format.money(store.driverCost(for: order))) · Netto \(Format.money(order.value + order.tip - store.driverCost(for: order)))")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(tripTime)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer(minLength: 4)

                GreenCapsuleButton(
                    title: freeDriver == nil ? "Kein Fahrer frei" : "Losfahren",
                    icon: freeDriver == nil ? "clock" : "box.truck.fill",
                    enabled: freeDriver != nil
                ) {
                    onDispatch()
                }
                .frame(maxWidth: 190)
            }
        }
        .padding(15)
        .glassPanel(cornerRadius: 24)
    }

    private var tripTime: String {
        let vehicle = freeDriver?.vehicle ?? .car
        return "Fahrt ca. \(Format.clock(vehicle.tripDuration(for: order.city.distance)))"
    }
}

// MARK: - Fahrer

struct DriverCard: View {
    @Environment(GameStore.self) private var store
    let driver: DeliveryDriver
    let onFire: () -> Void

    private var trip: DeliveryTrip? {
        store.currentTrip(for: driver)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CustomerAvatar(look: driver.look, size: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text(driver.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(driver.vehicle.name) · \(driver.completedTrips) Fahrten")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer(minLength: 0)

                VehicleBadge(vehicle: driver.vehicle)

                Button {
                    Haptics.light()
                    onFire()
                } label: {
                    Image(systemName: "person.badge.minus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(red: 1.0, green: 0.60, blue: 0.56))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.red.opacity(0.14)))
                }
                .buttonStyle(SoftPressStyle())
                .accessibilityLabel("\(driver.name) entlassen")
            }

            if let trip {
                TimelineView(.periodic(from: .now, by: 0.5)) { context in
                    let progress = store.progress(of: trip, now: context.date)
                    let remaining = store.remaining(of: trip, now: context.date)

                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "box.truck.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Theme.lime)
                            Text("Unterwegs nach \(trip.order.city.name)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                            Spacer(minLength: 0)
                            Text(remaining <= 0 ? "Ankunft" : Format.clock(remaining))
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.lime)
                                .monospacedDigit()
                        }

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
                                    .frame(width: max(4, geo.size.width * progress))
                            }
                        }
                        .frame(height: 6)
                        .animation(.linear(duration: 0.5), value: progress)
                    }
                }
            } else if let next = driver.vehicle.next {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                        store.upgradeVehicle(for: driver)
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: next.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text("Auf \(next.name) umrüsten")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 4)
                        CoinIcon(size: 14)
                        Text(Format.plainMoney(next.upgradeCost))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(store.money >= next.upgradeCost ? Theme.amber : Color.white.opacity(0.4))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .glassPanel(cornerRadius: 18, tint: Theme.amber.opacity(0.08))
                }
                .buttonStyle(SoftPressStyle())
                .disabled(store.money < next.upgradeCost)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Beste Fahrzeugklasse")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Theme.emerald)
            }
        }
        .padding(15)
        .glassPanel(cornerRadius: 24)
    }
}

// MARK: - Fahrt starten

struct DispatchSheet: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let order: DeliveryOrder

    private var strain: Strain {
        Brands.strain(id: order.strainID) ?? Strains.base
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Fahrt starten")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("\(order.city.name) · \(Int(order.city.distance)) km")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
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

                    VStack(alignment: .leading, spacing: 8) {
                        row("Sorte", "\(strain.name) · \(Format.grams(order.grams))")
                        row("Warenwert", Format.money(order.value), tint: Theme.amber)
                        row("Trinkgeld", Format.money(order.tip), tint: Theme.amber)
                        row("Fahrtkosten", "-\(Format.money(store.driverCost(for: order)))", tint: Color(red: 1.0, green: 0.62, blue: 0.58))
                        row("Netto", Format.money(order.value + order.tip - store.driverCost(for: order)), tint: Theme.lime)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassPanel(cornerRadius: 22)

                    Text("Fahrer wählen")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(store.drivers) { driver in
                        driverRow(driver)
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

    private func driverRow(_ driver: DeliveryDriver) -> some View {
        let busy = store.isDriverBusy(driver)

        return Button {
            Haptics.medium()
            if store.dispatch(order: order, driver: driver) {
                dismiss()
            }
        } label: {
            HStack(spacing: 12) {
                CustomerAvatar(look: driver.look, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(driver.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(busy ? Color.white.opacity(0.5) : .white)
                    Text(busy ? "Unterwegs" : "\(driver.vehicle.name) · \(Format.clock(driver.vehicle.tripDuration(for: order.city.distance)))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: busy ? "clock" : "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(14)
            .glassPanel(cornerRadius: 20)
            .opacity(busy ? 0.55 : 1)
        }
        .buttonStyle(SoftPressStyle())
        .disabled(busy)
    }

    private func row(_ title: String, _ value: String, tint: Color = .white) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
    }
}
