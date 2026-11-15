//
//  RootView.swift
//  Emerald Coast
//

import SwiftUI

struct RootView: View {
    @State private var store = GameStore()
    @State private var tab: AppTab = .grow
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppBackground()

            Group {
                switch tab {
                case .grow:
                    GrowView(onSettings: { showSettings = true })
                case .shop:
                    ShopView()
                case .brands:
                    BrandsView()
                case .crew:
                    ComingSoonView(tab: tab)
                }
            }
            .transition(.opacity)

            FloatingTabBar(selection: $tab)
                .frame(maxWidth: 560)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
        }
        .environment(store)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(store)
        }
        .overlay(alignment: .top) {
            if let toast = store.toast {
                ToastBanner(store: store, toast: toast)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: store.toast?.id)
    }
}

/// Platzhalter für die Bereiche, die noch kommen.
struct ComingSoonView: View {
    let tab: AppTab

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: tab.icon)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Theme.emerald)
                .frame(width: 96, height: 96)
                .glassPanel(cornerRadius: 48, tint: Theme.emerald.opacity(0.12))

            Text(tab.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 44)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var subtitle: String {
        switch tab {
        case .crew: return "Grower und Budtender, die für dich arbeiten, kommen mit dem nächsten Ausbau."
        default: return ""
        }
    }
}
