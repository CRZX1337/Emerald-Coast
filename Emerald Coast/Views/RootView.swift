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
                    DispensaryView()
                case .brands:
                    BrandsView()
                case .crew:
                    CrewView()
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
