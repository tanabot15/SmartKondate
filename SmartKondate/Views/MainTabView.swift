//
//  MainTabView.swift
//  SmartKondate
//
//  Created by Kenichiro Suzuki on 2026/08/06.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab {
        case dashboard
        case patterns
        case shopping
        case stock
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2.fill")
            }
            .tag(Tab.dashboard)
            
            NavigationStack {
                PatternListView()
            }
            .tabItem {
                Label("Patterns", systemImage: "slider.horizontal.2.rectangle.and.arrow.trianglehead.2.clockwise.rotate.90")
            }
            .tag(Tab.patterns)
            
            NavigationStack {
                ShoppingSetupView()
            }
            .tabItem {
                Label("Shopping", systemImage: "cart.fill")
            }
            .tag(Tab.shopping)
            
            NavigationStack {
                StockCheckListView()
            }
            .tabItem {
                Label("Stock", systemImage: "refrigerator.fill")
            }
            .tag(Tab.stock)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasCompletedOnboarding },
            set: { hasCompletedOnboarding = !$0 }
        )) {
            OnboardingView()
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            Ingredient.self,
            Menu.self,
            PatternDay.self,
            KondatePattern.self,
            StockItem.self
        ], inMemory: true)
}
