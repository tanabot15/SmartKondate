//
//  ContentView.swift
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
        case menus
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
                Label("Patterns", systemImage: "calendar.day.timeline.left")
            }
            .tag(Tab.patterns)
            
            NavigationStack {
                MenuListView()
            }
            .tabItem {
                Label("Menus", systemImage: "fork.knife")
            }
            .tag(Tab.menus)
            
            NavigationStack {
                StockCheckListView()
            }
            .tabItem {
                Label("Stock", systemImage: "checklist")
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
        // 初回起動時（false）の場合のみ OnboardingView を全画面表示
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
