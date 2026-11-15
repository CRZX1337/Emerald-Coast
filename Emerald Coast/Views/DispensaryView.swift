//
//  DispensaryView.swift
//  Emerald Coast
//
//  Der eigene Laden: Kunden, Sortiment mit Preisen, Tagesbilanz.
//

import SwiftUI

struct DispensaryView: View {
    @Environment(GameStore.self) private var store

    @State private var showAllStock = false
    @State private var floatingSale: ShopSale?
    @State private var chartRange: ChartRange = .today

    private enum ChartRange: String, CaseIterable, Identifiable {
        case today = "Heute"
        case week = "Woche"

        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                queueCard
                shelfSection
                reportCard
                adjustButton
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 130)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .top) { floatingSaleOverlay }
        .onChange(of: store.lastSale) { _, sale in
            guard let sale else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                floatingSale = sale
            }
            Task {
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                withAnimation(.easeOut(duration: 0.35)) {
                    if floatingSale?.id == sale.id {
                        floatingSale = nil
                    }
                }
            }
        }
        .sheet(isPresented: $showAllStock) {
            StockSheet()
                .environment(store)
        }
    }

    // MARK: Kopfzeile

    private var header: some View {
        VStack(spacing: 8) {
            BrandMark()
                .padding(.bottom, 2)

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Dispensary")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            store.toggleShop()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(store.shopOpen ? Theme.lime : Color.white.opacity(0.35))
                                .frame(width: 7, height: 7)
                                .shadow(color: store.shopOpen ? Theme.lime.opacity(0.9) : .clear, radius: 5)
                            Text(store.shopOpen ? "Geöffnet" : "Geschlossen")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(store.shopOpen ? Theme.lime : Theme.textSecondary)
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .glassPanel(cornerRadius: 14)
                    }
                    .buttonStyle(SoftPressStyle())
                    .accessibilityLabel(store.shopOpen ? "Laden schließen" : "Laden öffnen")
                }

                Spacer(minLength: 0)

                MoneyPill(money: store.money)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // MARK: Kunden

    private var queueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Kunden")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text(queueLabel)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }

            HStack(spacing: 10) {
                if store.queue.isEmpty {
                    Text(store.shopOpen ? "Wartet auf Kundschaft" : "Laden ist geschlossen")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(height: 46)
                } else {
                    ForEach(store.queue.prefix(3)) { customer in
                        CustomerAvatar(look: customer.look, size: 46)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }

                    if let first = store.queue.first {
                        Text(bubbleText(for: first))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .glassPanel(cornerRadius: 16, tint: Theme.emerald.opacity(0.10))
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(height: 48)
            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: store.queue.count)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 26, tint: Theme.emerald.opacity(0.06))
    }

    private var queueLabel: String {
        if !store.shopOpen { return "Geschlossen" }
        if store.shelf.isEmpty { return "Regal ist leer" }
        let count = store.queue.count
        return count == 1 ? "1 in der Warteschlange" : "\(count) in der Warteschlange"
    }

    private func bubbleText(for customer: ShopCustomer) -> String {
        let strain = Brands.strain(id: customer.strainID) ?? Strains.base
        return "\(strain.name), \(Format.grams(customer.grams))"
    }

    // MARK: Sortiment

    private var shelfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Unser Sortiment")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    Haptics.light()
                    showAllStock = true
                } label: {
                    HStack(spacing: 3) {
                        Text("Alle anzeigen")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(SoftPressStyle())
            }

            if store.shelf.isEmpty {
                emptyShelf
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(store.shelf.prefix(6)) { item in
                            ShelfCard(item: item)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var emptyShelf: some View {
        VStack(spacing: 10) {
            Image(systemName: "shippingbox")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.textTertiary)
            Text("Noch kein Bestand")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
            Text("Ernte im Grow House, um dein Regal zu füllen.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
                .multilineTextAlignment(.center)

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    store.restock()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("40 g \(store.strain.name) · \(Format.money(store.restockCost))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.amber)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassPanel(cornerRadius: 18, tint: Theme.amber.opacity(0.10))
            }
            .buttonStyle(SoftPressStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 18)
        .glassPanel(cornerRadius: 26)
    }

    // MARK: Tagesbilanz

    private var reportCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Tagesbilanz")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                Menu {
                    ForEach(ChartRange.allCases) { range in
                        Button {
                            Haptics.light()
                            chartRange = range
                        } label: {
                            if chartRange == range {
                                Label(range.rawValue, systemImage: "checkmark")
                            } else {
                                Text(range.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(chartRange.rawValue)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Theme.textSecondary)
                }
            }

            HStack(spacing: 0) {
                metric(title: "Umsatz", value: Format.money(store.todayRevenue), tint: Theme.amber)
                metricDivider
                metric(title: "Verkauft", value: Format.grams(store.todayGrams), tint: .white)
                metricDivider
                metric(title: "Kunden", value: "\(store.todayCustomers)", tint: .white)
            }

            SalesChart(bars: chartBars)
                .frame(height: 120)

            HStack(spacing: 7) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.amber)

                if let best = store.bestSellerToday {
                    Text("Beliebteste Sorte: \(best.strain.name) · \(Format.grams(best.grams))")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("Noch keine Verkäufe heute")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 26)
    }

    private var chartBars: [Double] {
        switch chartRange {
        case .today:
            return store.hourlySales
        case .week:
            // Die Woche zeigt die letzten sieben Tageswerte, der heutige Tag ist der letzte.
            var values = Array(store.hourlySales.suffix(6))
            values.append(store.todayRevenue)
            return values
        }
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.09))
            .frame(width: 1, height: 34)
    }

    private func metric(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Preis-Button

    private var adjustButton: some View {
        Button {
            Haptics.medium()
            showAllStock = true
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Preise anpassen")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 17)
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
            .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: Theme.emerald.opacity(0.5), radius: 18, y: 6)
        }
        .buttonStyle(SoftPressStyle())
    }

    // MARK: Schwebende Preise

    private var floatingSaleOverlay: some View {
        Group {
            if let sale = floatingSale {
                HStack(spacing: 7) {
                    CoinIcon(size: 16)
                    Text("+\(Format.money(sale.amount))")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.amber)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .glassPanel(cornerRadius: 20, tint: Theme.amber.opacity(0.14), glow: Theme.amber)
                .offset(y: 150)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .offset(y: -70).combined(with: .opacity)
                    )
                )
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Regal-Karte

struct ShelfCard: View {
    @Environment(GameStore.self) private var store
    let item: ShelfItem

    private var strain: Strain { store.strain(for: item) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            JarArtView(strainName: strain.name, size: 132)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

            Text(strain.name)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 5) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text(Format.grams(item.grams))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(item.grams > 0 ? Theme.emerald : Color(red: 1.0, green: 0.55, blue: 0.52))

            HStack(spacing: 0) {
                priceButton(icon: "minus", delta: -1)

                Spacer(minLength: 2)

                VStack(spacing: 0) {
                    Text("\(Format.plainMoney(item.price)) $/g")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.amber)
                        .contentTransition(.numericText(value: item.price))
                        .monospacedDigit()
                }
                .frame(minWidth: 62)

                Spacer(minLength: 2)

                priceButton(icon: "plus", delta: 1)
            }
            .padding(4)
            .background(
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.06))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1))
            )
        }
        .padding(12)
        .frame(width: 168)
        .glassPanel(cornerRadius: 24)
    }

    private func priceButton(icon: String, delta: Double) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                store.changePrice(of: item.strainID, by: delta)
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 26, height: 26)
                .background(Circle().fill(.white.opacity(0.10)))
        }
        .buttonStyle(SoftPressStyle())
        .accessibilityLabel(icon == "plus" ? "Preis erhöhen" : "Preis senken")
    }
}

// MARK: - Diagramm

struct SalesChart: View {
    let bars: [Double]

    private var maxValue: Double {
        max(1, bars.max() ?? 1)
    }

    private var labels: [String] {
        if bars.count > 12 {
            return (0..<bars.count).map { index in
                index % 2 == 0 ? "\(index) Uhr" : ""
            }
        }
        return bars.indices.map { "\($0 + 1)" }
    }

    var body: some View {
        GeometryReader { geo in
            let count = max(1, bars.count)
            let spacing: CGFloat = 3
            let barWidth = max(2, (geo.size.width - spacing * CGFloat(count - 1)) / CGFloat(count))

            VStack(spacing: 6) {
                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { index, value in
                        let ratio = value / maxValue
                        RoundedRectangle(cornerRadius: barWidth * 0.32, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.lime, Theme.emerald.opacity(0.65)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(
                                width: barWidth,
                                height: max(4, (geo.size.height - 22) * ratio)
                            )
                            .opacity(index == bars.count - 1 ? 1 : 0.78)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: maxValue)

                HStack(spacing: spacing) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textTertiary)
                            .frame(width: barWidth + spacing, alignment: .center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
        }
    }
}

// MARK: - Bestands-Sheet

struct StockSheet: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Sortiment")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Preis pro Gramm · zu teuer kostet Kunden")
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

                    if store.shelf.isEmpty {
                        Text("Das Regal ist leer. Ernte im Grow House oder fülle es unten auf.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .glassPanel(cornerRadius: 22)
                    }

                    ForEach(store.shelf) { item in
                        StockRow(item: item)
                    }

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                            store.restock()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("40 g \(store.strain.name) nachkaufen")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                            Spacer()
                            CoinIcon(size: 15)
                            Text(Format.plainMoney(store.restockCost))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.amber)
                        }
                        .foregroundStyle(.white)
                        .padding(16)
                        .glassPanel(cornerRadius: 22, tint: Theme.amber.opacity(0.10))
                    }
                    .buttonStyle(SoftPressStyle())
                }
                .padding(20)
                .padding(.bottom, 24)
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

struct StockRow: View {
    @Environment(GameStore.self) private var store
    let item: ShelfItem

    private var strain: Strain { store.strain(for: item) }
    private var appeal: Double { store.priceAppeal(for: item) }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 12) {
                JarArtView(strainName: strain.name, size: 54)

                VStack(alignment: .leading, spacing: 3) {
                    Text(strain.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(strain.brandName) · \(strain.type)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textTertiary)
                    Text(Format.grams(item.grams))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(item.grams > 0 ? Theme.emerald : Color(red: 1.0, green: 0.55, blue: 0.52))
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Format.plainMoney(item.price)) $/g")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.amber)
                        .contentTransition(.numericText(value: item.price))
                        .monospacedDigit()
                    Text(appealLabel)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(appealColor)
                }
            }

            HStack(spacing: 10) {
                Slider(
                    value: Binding(
                        get: { item.price },
                        set: { newValue in
                            store.changePrice(of: item.strainID, by: newValue - item.price)
                        }
                    ),
                    in: max(1, (store.basePrice(for: strain) * 0.5).rounded())...(store.basePrice(for: strain) * 2).rounded(),
                    step: 1
                )
                .tint(Theme.emerald)

                Text(Format.money(item.price * 3.5))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(width: 58, alignment: .trailing)
            }
        }
        .padding(14)
        .glassPanel(cornerRadius: 22)
    }

    private var appealLabel: String {
        switch appeal {
        case 0.85...: return "Sehr gefragt"
        case 0.6..<0.85: return "Fair"
        case 0.35..<0.6: return "Zu teuer"
        default: return "Kauft kaum"
        }
    }

    private var appealColor: Color {
        switch appeal {
        case 0.85...: return Theme.lime
        case 0.6..<0.85: return Theme.emerald
        case 0.35..<0.6: return Theme.amber
        default: return Color(red: 1.0, green: 0.55, blue: 0.52)
        }
    }
}
